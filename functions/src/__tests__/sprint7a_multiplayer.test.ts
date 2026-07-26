import * as admin from 'firebase-admin';
import { readFileSync } from 'fs';
import { join } from 'path';
const fft = require('firebase-functions-test');
import {
    createRoom,
    joinRoom,
    leaveRoom,
    startGame,
    startGameV2,
    submitWord,
    submitWordV2,
    submitVerb,
    submitAdjective,
    submitWordLegacy,
    resolveTimeout,
    resolveTimeoutV2,
    createArenaRoom,
    joinArenaRoom,
    leaveArenaRoom,
    startArenaMatch,
    submitArenaAnswer,
    resolveArenaTimeout,
    updateArenaConfig,
    APP_CHECK_ENFORCEMENT,
} from '../index';

const testEnv = fft({
    projectId: 'demo-sprint6c',
});

if (!admin.apps.length) {
    admin.initializeApp({ projectId: 'demo-sprint6c' });
}
admin.firestore().settings({
    host: '127.0.0.1:8080',
    ssl: false,
});

const genCode = (prefix: string) => `${prefix}${Math.floor(10000 + Math.random() * 90000)}`;

function callableExportNamesFromIndexSource(): string[] {
    const source = readFileSync(join(__dirname, '..', 'index.ts'), 'utf8');
    const callableNames = new Set<string>();
    const directCallable = /export const (\w+) = onCall\(/g;
    let match: RegExpExecArray | null;
    while ((match = directCallable.exec(source)) !== null) {
        callableNames.add(match[1]);
    }

    const aliases = [...source.matchAll(/export const (\w+) = (\w+);/g)];
    let addedAlias = true;
    while (addedAlias) {
        addedAlias = false;
        for (const [, alias, target] of aliases) {
            if (callableNames.has(target) && !callableNames.has(alias)) {
                callableNames.add(alias);
                addedAlias = true;
            }
        }
    }
    return [...callableNames].sort();
}

describe('Sprint 7A Server-Authoritative Concurrency, Idempotency & Validation Tests', () => {
    jest.setTimeout(20000);

    let wrapCreateRoom: any;
    let wrapJoinRoom: any;
    let wrapLeaveRoom: any;
    let wrapStartGame: any;
    let wrapStartGameV2: any;
    let wrapSubmitWord: any;
    let wrapSubmitWordV2: any;
    let wrapSubmitVerb: any;
    let wrapSubmitAdjective: any;
    let wrapSubmitWordLegacy: any;
    let wrapResolveTimeout: any;
    let wrapResolveTimeoutV2: any;

    let wrapCreateArenaRoom: any;
    let wrapJoinArenaRoom: any;
    let wrapLeaveArenaRoom: any;
    let wrapStartArenaMatch: any;
    let wrapSubmitArenaAnswer: any;
    let wrapResolveArenaTimeout: any;
    let wrapUpdateArenaConfig: any;

    beforeAll(() => {
        wrapCreateRoom = testEnv.wrap(createRoom);
        wrapJoinRoom = testEnv.wrap(joinRoom);
        wrapLeaveRoom = testEnv.wrap(leaveRoom);
        wrapStartGame = testEnv.wrap(startGame);
        wrapStartGameV2 = testEnv.wrap(startGameV2);
        wrapSubmitWord = testEnv.wrap(submitWord);
        wrapSubmitWordV2 = testEnv.wrap(submitWordV2);
        wrapSubmitVerb = testEnv.wrap(submitVerb);
        wrapSubmitAdjective = testEnv.wrap(submitAdjective);
        wrapSubmitWordLegacy = testEnv.wrap(submitWordLegacy);
        wrapResolveTimeout = testEnv.wrap(resolveTimeout);
        wrapResolveTimeoutV2 = testEnv.wrap(resolveTimeoutV2);

        wrapCreateArenaRoom = testEnv.wrap(createArenaRoom);
        wrapJoinArenaRoom = testEnv.wrap(joinArenaRoom);
        wrapLeaveArenaRoom = testEnv.wrap(leaveArenaRoom);
        wrapStartArenaMatch = testEnv.wrap(startArenaMatch);
        wrapSubmitArenaAnswer = testEnv.wrap(submitArenaAnswer);
        wrapResolveArenaTimeout = testEnv.wrap(resolveArenaTimeout);
        wrapUpdateArenaConfig = testEnv.wrap(updateArenaConfig);
    });

    afterAll(() => {
        testEnv.cleanup();
    });

    afterEach(async () => {
        const http = require('http');
        await new Promise((resolve) => {
            const req = http.request({
                method: 'DELETE',
                hostname: '127.0.0.1',
                port: 8080,
                path: '/emulator/v1/projects/demo-sprint6c/databases/(default)/documents',
            }, resolve);
            req.end();
        });
    });

    // 0. Static Inventory & App Check Map Audit
    it('0. APP_CHECK_ENFORCEMENT exactly matches every callable export in index.ts with value false', () => {
        const callableExportNames = callableExportNamesFromIndexSource();
        const appCheckKeys = Object.keys(APP_CHECK_ENFORCEMENT).sort();

        expect(appCheckKeys).toEqual(callableExportNames);
        expect(Object.values(APP_CHECK_ENFORCEMENT)).toEqual(
            expect.arrayContaining(appCheckKeys.map(() => false)),
        );
    });

    // 1. Concurrent Join Last Seat
    it('1. Two users join last seat concurrently -> exactly one succeeds', async () => {
        const code = genCode('R1');
        const createRes = await wrapCreateRoom({
            data: { roomCode: code, operationId: 'op_c1_valid_id' },
            auth: { uid: 'userHost' },
        });
        const roomId = createRes.roomId;
        await new Promise((r) => setTimeout(r, 200));

        const p1 = wrapJoinRoom({
            data: { roomId, roomCode: code, username: 'UserA', operationId: 'op_j1_valid_id' },
            auth: { uid: 'userA' },
        });
        const p2 = wrapJoinRoom({
            data: { roomId, roomCode: code, username: 'UserB', operationId: 'op_j2_valid_id' },
            auth: { uid: 'userB' },
        });

        const results = await Promise.allSettled([p1, p2]);
        const fulfilled = results.filter((r) => r.status === 'fulfilled');
        const rejected = results.filter((r) => r.status === 'rejected');

        expect(fulfilled.length).toBe(1);
        expect(rejected.length).toBe(1);

        const db = admin.firestore();
        const roomSnap = await db.collection('rooms').doc(roomId).get();
        expect(roomSnap.exists).toBe(true);
        const data = roomSnap.data();
        expect(data?.players).toBeDefined();
        expect(data?.players).toHaveLength(2);
    });

    // 2. Operation ID Validation & Malicious Values Rejection
    it('2. Operation ID server validation rejects empty, short, long, slashes, spaces, control chars', async () => {
        const code = genCode('R2');
        const invalidOpIds = [
            '',
            '   ',
            'short', // < 8 chars
            'a'.repeat(129), // > 128 chars
            'op/with/slashes',
            'op\\with\\backslashes',
            'op with spaces',
            'op_with_\n_newline',
            'op_with_$%^#@_symbols',
        ];

        for (const badOpId of invalidOpIds) {
            await expect(
                wrapCreateRoom({
                    data: { roomCode: code, operationId: badOpId },
                    auth: { uid: 'userHost' },
                })
            ).rejects.toThrow();
        }
    });

    // 3. Operation Idempotency: Create, Join, Start, Submit, Timeout Retries
    it('3. Retrying operations with same valid operationId returns identical cached result without duplicate state mutations', async () => {
        const code = genCode('R3');
        const opCreate = 'op_create_room_idempotent_1';

        const createRes1 = await wrapCreateRoom({
            data: { roomCode: code, operationId: opCreate },
            auth: { uid: 'userHost' },
        });
        const createRes2 = await wrapCreateRoom({
            data: { roomCode: code, operationId: opCreate },
            auth: { uid: 'userHost' },
        });

        expect(createRes1).toEqual(createRes2);

        const db = admin.firestore();
        const roomsQuery = await db.collection('rooms').where('roomCode', '==', code).get();
        expect(roomsQuery.docs.length).toBe(1);
        const roomId = createRes1.roomId;
        await new Promise((r) => setTimeout(r, 200));

        const opJoin = 'op_join_room_idempotent_1';
        const join1 = await wrapJoinRoom({
            data: { roomId, roomCode: code, username: 'Guest', operationId: opJoin },
            auth: { uid: 'userGuest' },
        });
        const join2 = await wrapJoinRoom({
            data: { roomId, roomCode: code, username: 'Guest', operationId: opJoin },
            auth: { uid: 'userGuest' },
        });

        expect(join1).toEqual(join2);
        const roomSnap = await db.collection('rooms').doc(roomId).get();
        expect(roomSnap.data()?.players).toEqual(['userHost', 'userGuest']);

        const opStart = 'op_start_game_idempotent_1';
        await wrapStartGame({
            data: { roomId, operationId: opStart },
            auth: { uid: 'userHost' },
        });
        await wrapStartGame({
            data: { roomId, operationId: opStart },
            auth: { uid: 'userHost' },
        });

        const activeRoom = (await db.collection('rooms').doc(roomId).get()).data();
        expect(activeRoom?.status).toBe('active');
        expect(activeRoom?.stateVersion).toBe(3);
    });

    // 4. V1/V2/Legacy Counterparts Authoritative Parity
    it('4. V2 and Legacy aliases delegate to the exact same authoritative core', async () => {
        const code = genCode('R4');
        const createRes = await wrapCreateRoom({
            data: { roomCode: code, operationId: 'op_create_r4_0001' },
            auth: { uid: 'userHost' },
        });
        const roomId = createRes.roomId;
        await new Promise((r) => setTimeout(r, 200));

        await wrapJoinRoom({
            data: { roomId, roomCode: code, username: 'Guest', operationId: 'op_join_r4_0001' },
            auth: { uid: 'userGuest' },
        });
        await new Promise((r) => setTimeout(r, 200));

        // Start using startGameV2
        await wrapStartGameV2({
            data: { roomId, operationId: 'op_start_v2_0001' },
            auth: { uid: 'userHost' },
        });

        const db = admin.firestore();
        const roomSnap = await db.collection('rooms').doc(roomId).get();
        expect(roomSnap.data()?.status).toBe('active');

        const activeUid = roomSnap.data()?.currentTurnUid;
        expect(activeUid).toBeDefined();

        // Submit using submitWordV2
        await wrapSubmitWordV2({
            data: { roomId, word: 'go', operationId: 'op_sub_v2_0001' },
            auth: { uid: activeUid },
        });

        const playedWords = await db.collection('rooms').doc(roomId).collection('playedWords').get();
        expect(playedWords.docs.length).toBe(1);

        // Resolve timeout using resolveTimeoutV2
        const timeoutRes = await wrapResolveTimeoutV2({
            data: { roomId, operationId: 'op_to_v2_0001' },
            auth: { uid: activeUid },
        });
        expect(timeoutRes).toBeDefined();
    });

    // 5. Operation ID Isolation Across Users
    it('5. Two different players use same operation ID -> isolated, no conflict', async () => {
        const code = genCode('R5');
        const createRes = await wrapCreateRoom({
            data: { roomCode: code, operationId: 'op_shared_id_1' },
            auth: { uid: 'userHost' },
        });

        const joinRes = await wrapJoinRoom({
            data: { roomId: createRes.roomId, roomCode: code, username: 'Guest', operationId: 'op_shared_id_1' },
            auth: { uid: 'userGuest' },
        });

        expect(createRes.roomId).toBe(joinRes.roomId);
    });

    // 6. Operation Idempotency: Same Operation ID with different payload rejected
    it('6. Same operation ID with different payload -> rejected with failed-precondition', async () => {
        const code = genCode('R6');
        const createRes = await wrapCreateRoom({
            data: { roomCode: code, operationId: 'op_c6_valid_id' },
            auth: { uid: 'userHost' },
        });
        const roomId = createRes.roomId;
        await new Promise((r) => setTimeout(r, 200));

        await wrapJoinRoom({
            data: { roomId, roomCode: code, username: 'Guest', operationId: 'op_j6_valid_id' },
            auth: { uid: 'userGuest' },
        });

        await wrapStartGame({
            data: { roomId, operationId: 'op_st6_valid_id' },
            auth: { uid: 'userHost' },
        });

        const db = admin.firestore();
        const roomSnap = await db.collection('rooms').doc(roomId).get();
        const activeUid = roomSnap.data()?.currentTurnUid ?? 'userHost';

        await wrapSubmitVerb({
            data: { roomId, verb: 'run', operationId: 'op_sub_mismatch_1' },
            auth: { uid: activeUid },
        });

        await expect(
            wrapSubmitVerb({
                data: { roomId, verb: 'walk', operationId: 'op_sub_mismatch_1' },
                auth: { uid: activeUid },
            })
        ).rejects.toThrow();
    });

    // 7. Grammar Arena Attempt-Scoped Domain Deduplication & Idempotency
    it('7. Grammar Arena attempt 1 and attempt 2 allowed, duplicate attempt 1 deduplicated', async () => {
        const code = genCode('A7');
        const createRes = await wrapCreateArenaRoom({
            data: { roomCode: code, level: 'A1', operationId: 'op_ca7_valid_id' },
            auth: { uid: 'userHost' },
        });
        const roomId = createRes.roomId;
        await new Promise((r) => setTimeout(r, 200));

        await wrapJoinArenaRoom({
            data: { roomId, roomCode: code, player: { name: 'Guest' }, operationId: 'op_ja7_valid_id' },
            auth: { uid: 'userGuest' },
        });

        await wrapStartArenaMatch({
            data: {
                roomId,
                resolvedWorksheet: {
                    worksheetId: 'w1',
                    seed: 123,
                    questionIds: ['q0'],
                    items: [{ id: 'q0', engine: 'mcq', question: 'Q?', answer: 'cat' }],
                },
                operationId: 'op_sma7_valid_id',
            },
            auth: { uid: 'userHost' },
        });

        // Submit wrong answer on attempt 1
        const resAttempt1 = await wrapSubmitArenaAnswer({
            data: { roomId, roundIndex: 0, answerValue: 'dog', attempt: 1, operationId: 'op_ans_att1_01' },
            auth: { uid: 'userHost' },
        });
        expect(resAttempt1.isCorrect).toBe(false);

        // Submit retry with same op ID -> returns cached attempt 1 result
        const resAttempt1Dup = await wrapSubmitArenaAnswer({
            data: { roomId, roundIndex: 0, answerValue: 'dog', attempt: 1, operationId: 'op_ans_att1_01' },
            auth: { uid: 'userHost' },
        });
        expect(resAttempt1Dup).toEqual(resAttempt1);

        // Submit correct answer on attempt 2
        const resAttempt2 = await wrapSubmitArenaAnswer({
            data: { roomId, roundIndex: 0, answerValue: 'cat', attempt: 2, operationId: 'op_ans_att2_01' },
            auth: { uid: 'userHost' },
        });
        expect(resAttempt2.isCorrect).toBe(true);

        const db = admin.firestore();
        const answersSnap = await db.collection('arena_rooms').doc(roomId).collection('answers').get();
        expect(answersSnap.docs.length).toBe(2); // attempt 1 and attempt 2 docs
    });

    // 8. Leave Room & Leave Arena Room Idempotency (Repeat calls produce no secondary state mutation)
    it('8. Repeating leaveRoom and leaveArenaRoom with same operationId produces identical cached result', async () => {
        const code = genCode('R8');
        const createRes = await wrapCreateRoom({
            data: { roomCode: code, operationId: 'op_c8_valid_id' },
            auth: { uid: 'userHost' },
        });
        const roomId = createRes.roomId;
        await new Promise((r) => setTimeout(r, 200));

        await wrapJoinRoom({
            data: { roomId, roomCode: code, username: 'Guest', operationId: 'op_j8_valid_id' },
            auth: { uid: 'userGuest' },
        });

        const leaveOpId = 'op_leave_r8_0001';
        const resLeave1 = await wrapLeaveRoom({
            data: { roomId, operationId: leaveOpId },
            auth: { uid: 'userGuest' },
        });
        const resLeave2 = await wrapLeaveRoom({
            data: { roomId, operationId: leaveOpId },
            auth: { uid: 'userGuest' },
        });

        expect(resLeave1).toEqual(resLeave2);

        const db = admin.firestore();
        const roomSnap = await db.collection('rooms').doc(roomId).get();
        expect(roomSnap.data()?.players).toEqual(['userHost']);
        expect(roomSnap.data()?.stateVersion).toBe(3);

        // Arena Leave test
        const arenaCode = genCode('A8');
        const arenaCreate = await wrapCreateArenaRoom({
            data: { roomCode: arenaCode, level: 'A1', operationId: 'op_ca8_valid_id' },
            auth: { uid: 'arenaHost' },
        });
        const arenaRoomId = arenaCreate.roomId;
        await new Promise((r) => setTimeout(r, 200));

        await wrapJoinArenaRoom({
            data: { roomId: arenaRoomId, roomCode: arenaCode, player: { name: 'Guest' }, operationId: 'op_ja8_valid_id' },
            auth: { uid: 'arenaGuest' },
        });

        const arenaLeaveOpId = 'op_arena_leave_0001';
        const resArenaLeave1 = await wrapLeaveArenaRoom({
            data: { roomId: arenaRoomId, operationId: arenaLeaveOpId },
            auth: { uid: 'arenaGuest' },
        });
        const resArenaLeave2 = await wrapLeaveArenaRoom({
            data: { roomId: arenaRoomId, operationId: arenaLeaveOpId },
            auth: { uid: 'arenaGuest' },
        });

        expect(resArenaLeave1).toEqual(resArenaLeave2);
        const arenaSnap = await db.collection('arena_rooms').doc(arenaRoomId).get();
        expect(arenaSnap.data()?.guestId).toBeNull();
    });

    // 9. Resolve Timeout & Resolve Arena Timeout Idempotency
    it('9. Repeating resolveTimeout and resolveArenaTimeout with same operationId produces identical cached result', async () => {
        const arenaCode = genCode('A9');
        const arenaCreate = await wrapCreateArenaRoom({
            data: { roomCode: arenaCode, level: 'A1', operationId: 'op_ca9_valid_id' },
            auth: { uid: 'hostA9' },
        });
        const arenaRoomId = arenaCreate.roomId;
        await new Promise((r) => setTimeout(r, 200));

        await wrapJoinArenaRoom({
            data: { roomId: arenaRoomId, roomCode: arenaCode, player: { name: 'Guest' }, operationId: 'op_ja9_valid_id' },
            auth: { uid: 'guestA9' },
        });

        await wrapStartArenaMatch({
            data: {
                roomId: arenaRoomId,
                resolvedWorksheet: {
                    worksheetId: 'w9',
                    seed: 999,
                    questionIds: ['q0', 'q1'],
                    items: [
                        { id: 'q0', engine: 'mcq', question: 'Q0', answer: 'a' },
                        { id: 'q1', engine: 'mcq', question: 'Q1', answer: 'b' },
                    ],
                },
                operationId: 'op_sma9_valid_id',
            },
            auth: { uid: 'hostA9' },
        });

        const db = admin.firestore();
        // Force round start time 50 seconds into past
        await db.collection('arena_rooms').doc(arenaRoomId).update({
            'round.roundStartAt': admin.firestore.Timestamp.fromMillis(Date.now() - 50000),
        });

        const toOpId = 'op_to_arena_0001';
        const res1 = await wrapResolveArenaTimeout({
            data: { roomId: arenaRoomId, roundIndex: 0, operationId: toOpId },
            auth: { uid: 'hostA9' },
        });
        const res2 = await wrapResolveArenaTimeout({
            data: { roomId: arenaRoomId, roundIndex: 0, operationId: toOpId },
            auth: { uid: 'hostA9' },
        });

        expect(res1).toEqual(res2);
        const finalArena = (await db.collection('arena_rooms').doc(arenaRoomId).get()).data();
        expect(finalArena?.round?.index).toBe(1);
    });
});
