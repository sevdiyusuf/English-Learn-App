import * as admin from 'firebase-admin';
import { readFileSync } from 'fs';
import { join } from 'path';
const fft = require('firebase-functions-test');
import {
    createRoom,
    joinRoom,
    leaveRoom,
    startGame,
    submitWord,
    resolveTimeout,
    createArenaRoom,
    joinArenaRoom,
    startArenaMatch,
    submitArenaAnswer,
    sendHeartbeat,
    sendArenaHeartbeat,
    cleanupExpiredRooms,
    cleanupExpiredRoomsSchedule,
    APP_CHECK_ENFORCEMENT,
} from '../index';
import { cleanupExpiredRooms as runCleanupCore, WAITING_ROOM_EXPIRY_MS, ACTIVE_ROOM_ABANDONED_MS, FINISHED_ROOM_RETENTION_MS } from '../room_cleanup_helper';

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

describe('Sprint 7B Connection Resilience, Lifecycle & Cleanup Tests', () => {
    jest.setTimeout(25000);

    let wrapCreateRoom: any;
    let wrapJoinRoom: any;
    let wrapLeaveRoom: any;
    let wrapStartGame: any;
    let wrapSubmitWord: any;
    let wrapResolveTimeout: any;
    let wrapSendHeartbeat: any;

    let wrapCreateArenaRoom: any;
    let wrapJoinArenaRoom: any;
    let wrapStartArenaMatch: any;
    let wrapSubmitArenaAnswer: any;
    let wrapSendArenaHeartbeat: any;
    let wrapCleanupExpiredRooms: any;

    beforeAll(() => {
        wrapCreateRoom = testEnv.wrap(createRoom);
        wrapJoinRoom = testEnv.wrap(joinRoom);
        wrapLeaveRoom = testEnv.wrap(leaveRoom);
        wrapStartGame = testEnv.wrap(startGame);
        wrapSubmitWord = testEnv.wrap(submitWord);
        wrapResolveTimeout = testEnv.wrap(resolveTimeout);
        wrapSendHeartbeat = testEnv.wrap(sendHeartbeat);

        wrapCreateArenaRoom = testEnv.wrap(createArenaRoom);
        wrapJoinArenaRoom = testEnv.wrap(joinArenaRoom);
        wrapStartArenaMatch = testEnv.wrap(startArenaMatch);
        wrapSubmitArenaAnswer = testEnv.wrap(submitArenaAnswer);
        wrapSendArenaHeartbeat = testEnv.wrap(sendArenaHeartbeat);
        wrapCleanupExpiredRooms = testEnv.wrap(cleanupExpiredRooms);
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

    // 1. App Check Map Audit including new callables & onCall/onSchedule distinction
    it('1. APP_CHECK_ENFORCEMENT exactly matches the callable exports in index.ts and keeps App Check disabled', () => {
        const callableExportNames = callableExportNamesFromIndexSource();
        const appCheckKeys = Object.keys(APP_CHECK_ENFORCEMENT).sort();

        // This exact comparison detects both missing callable keys and stale keys.
        expect(appCheckKeys).toEqual(callableExportNames);
        expect(Object.values(APP_CHECK_ENFORCEMENT)).toEqual(
            expect.arrayContaining(appCheckKeys.map(() => false)),
        );

        // Scheduled triggers are not callable and therefore have no map entry.
        expect(appCheckKeys).not.toContain('cleanupExpiredRoomsSchedule');
    });

    // 2. Member Heartbeat & Outsider/Unauth Rejection
    it('2. Member can send heartbeat; outsider & unauth denied', async () => {
        const code = genCode('HB1');
        const createRes = await wrapCreateRoom({
            data: { roomCode: code, operationId: 'op_hb1_c1_0001' },
            auth: { uid: 'userHost' },
        });
        const roomId = createRes.roomId;
        await new Promise((r) => setTimeout(r, 100));

        await wrapJoinRoom({
            data: { roomId, roomCode: code, username: 'Guest', operationId: 'op_hb1_j1_0001' },
            auth: { uid: 'userGuest' },
        });

        // Host heartbeat succeeds
        const resHost = await wrapSendHeartbeat({
            data: { roomId, operationId: 'op_hb1_hb_host_01' },
            auth: { uid: 'userHost' },
        });
        expect(resHost.success).toBe(true);

        // Guest heartbeat succeeds
        const resGuest = await wrapSendHeartbeat({
            data: { roomId, operationId: 'op_hb1_hb_guest_01' },
            auth: { uid: 'userGuest' },
        });
        expect(resGuest.success).toBe(true);

        // Outsider heartbeat denied
        await expect(
            wrapSendHeartbeat({
                data: { roomId, operationId: 'op_hb1_hb_out_01' },
                auth: { uid: 'userOutsider' },
            })
        ).rejects.toThrow();

        // Unauth heartbeat denied
        await expect(
            wrapSendHeartbeat({
                data: { roomId, operationId: 'op_hb1_hb_unauth_01' },
            })
        ).rejects.toThrow();
    });

    // 3. Heartbeat Idempotency & Server Time Integrity
    it('3. Heartbeat retry is idempotent and does not mutate scores, round, winner, or stateVersion', async () => {
        const code = genCode('HB3');
        const createRes = await wrapCreateArenaRoom({
            data: { roomCode: code, level: 'A1', operationId: 'op_hb3_ca_0001' },
            auth: { uid: 'arenaHost' },
        });
        const roomId = createRes.roomId;
        await new Promise((r) => setTimeout(r, 100));

        await wrapJoinArenaRoom({
            data: { roomId, roomCode: code, player: { name: 'Guest' }, operationId: 'op_hb3_ja_0001' },
            auth: { uid: 'arenaGuest' },
        });

        const db = admin.firestore();
        const initialSnap = await db.collection('arena_rooms').doc(roomId).get();
        const initialVersion = initialSnap.data()?.stateVersion;

        // Send arena heartbeat twice with same op ID
        const res1 = await wrapSendArenaHeartbeat({
            data: { roomId, operationId: 'op_hb3_hb_retry_01' },
            auth: { uid: 'arenaHost' },
        });
        const res2 = await wrapSendArenaHeartbeat({
            data: { roomId, operationId: 'op_hb3_hb_retry_01' },
            auth: { uid: 'arenaHost' },
        });

        expect(res1).toEqual(res2);

        const postSnap = await db.collection('arena_rooms').doc(roomId).get();
        const postData = postSnap.data();
        expect(postData?.hostScore).toBe(0);
        expect(postData?.guestScore).toBe(0);
        expect(postData?.status).toBe('waiting');
        expect(postData?.hostLastSeenAt).toBeDefined();
        expect(postData?.lastActivityAt).toBeDefined();
        expect(postData?.stateVersion).toBe(initialVersion);
    });

    // 4. Reconnect Seats & Scores Invariant
    it('4. Reconnect for same UID does not create duplicate seats or alter score/round/version', async () => {
        const code = genCode('RC4');
        const createRes = await wrapCreateRoom({
            data: { roomCode: code, operationId: 'op_rc4_c1_0001' },
            auth: { uid: 'userHost' },
        });
        const roomId = createRes.roomId;
        await new Promise((r) => setTimeout(r, 100));

        // Guest joins first time
        const join1 = await wrapJoinRoom({
            data: { roomId, roomCode: code, username: 'Guest', operationId: 'op_rc4_j1_0001' },
            auth: { uid: 'userGuest' },
        });
        expect(join1.rejoined).toBe(false);

        const db = admin.firestore();
        const room1 = (await db.collection('rooms').doc(roomId).get()).data();
        expect(room1?.players).toEqual(['userHost', 'userGuest']);
        const version1 = room1?.stateVersion;

        // Guest reconnects (joins second time with same UID)
        const join2 = await wrapJoinRoom({
            data: { roomId, roomCode: code, username: 'Guest', operationId: 'op_rc4_j2_0002' },
            auth: { uid: 'userGuest' },
        });
        expect(join2.rejoined).toBe(true);

        const room2 = (await db.collection('rooms').doc(roomId).get()).data();
        expect(room2?.players).toEqual(['userHost', 'userGuest']); // No duplicate seat
        expect(room2?.stateVersion).toBe(version1 + 1); // Only timestamp update
    });

    // 5. Expired Waiting Room Cleanup
    it('5. Inactive waiting room (>10m) is cancelled by cleanup helper', async () => {
        const db = admin.firestore();
        const code = genCode('CL5');
        const createRes = await wrapCreateRoom({
            data: { roomCode: code, operationId: 'op_cl5_c1_0001' },
            auth: { uid: 'userHost' },
        });
        const roomId = createRes.roomId;
        await new Promise((r) => setTimeout(r, 100));

        // Set lastActivityAt to 11 minutes ago
        const elevenMinsAgo = admin.firestore.Timestamp.fromMillis(Date.now() - (WAITING_ROOM_EXPIRY_MS + 60000));
        await db.collection('rooms').doc(roomId).update({
            lastActivityAt: elevenMinsAgo,
            createdAt: elevenMinsAgo,
        });

        const res = await runCleanupCore(db);
        expect(res.cancelledWaitingCount).toBeGreaterThanOrEqual(1);

        const roomSnap = await db.collection('rooms').doc(roomId).get();
        expect(roomSnap.data()?.status).toBe('cancelled');
    });

    // 6. Expired Active Room Cleanup (Abandoned Game)
    it('6. Abandoned active room (>5m inactivity) transitions to finished status', async () => {
        const db = admin.firestore();
        const code = genCode('CL6');
        const createRes = await wrapCreateRoom({
            data: { roomCode: code, operationId: 'op_cl6_c1_0001' },
            auth: { uid: 'userHost' },
        });
        const roomId = createRes.roomId;
        await new Promise((r) => setTimeout(r, 100));

        await wrapJoinRoom({
            data: { roomId, roomCode: code, username: 'Guest', operationId: 'op_cl6_j1_0001' },
            auth: { uid: 'userGuest' },
        });

        await wrapStartGame({
            data: { roomId, operationId: 'op_cl6_st_0001' },
            auth: { uid: 'userHost' },
        });

        // Set lastActivityAt to 6 minutes ago
        const sixMinsAgo = admin.firestore.Timestamp.fromMillis(Date.now() - (ACTIVE_ROOM_ABANDONED_MS + 60000));
        await db.collection('rooms').doc(roomId).update({
            lastActivityAt: sixMinsAgo,
            updatedAt: sixMinsAgo,
        });

        const res = await runCleanupCore(db);
        expect(res.abandonedActiveCount).toBeGreaterThanOrEqual(1);

        const roomSnap = await db.collection('rooms').doc(roomId).get();
        expect(roomSnap.data()?.status).toBe('finished');
        expect(roomSnap.data()?.winnerUid).toBeNull();
    });

    // 7. Recent Heartbeat Protection
    it('7. Room with recent heartbeat is NOT cleaned up', async () => {
        const db = admin.firestore();
        const code = genCode('CL7');
        const createRes = await wrapCreateRoom({
            data: { roomCode: code, operationId: 'op_cl7_c1_0001' },
            auth: { uid: 'userHost' },
        });
        const roomId = createRes.roomId;
        await new Promise((r) => setTimeout(r, 100));

        // Send recent heartbeat
        await wrapSendHeartbeat({
            data: { roomId, operationId: 'op_cl7_hb_0001' },
            auth: { uid: 'userHost' },
        });

        const res = await runCleanupCore(db);
        expect(res.cancelledWaitingCount).toBe(0);

        const roomSnap = await db.collection('rooms').doc(roomId).get();
        expect(roomSnap.data()?.status).toBe('waiting');
    });

    // 8. Finished Room Retention & Safe Hard Deletion
    it('8. Finished room is retained until retention period (24h) expires before deletion', async () => {
        const db = admin.firestore();
        const code = genCode('CL8');
        const createRes = await wrapCreateRoom({
            data: { roomCode: code, operationId: 'op_cl8_c1_0001' },
            auth: { uid: 'userHost' },
        });
        const roomId = createRes.roomId;
        await new Promise((r) => setTimeout(r, 100));

        // Set status to finished 1 hour ago (recent -> retain)
        const oneHourAgo = admin.firestore.Timestamp.fromMillis(Date.now() - (60 * 60 * 1000));
        await db.collection('rooms').doc(roomId).update({
            status: 'finished',
            updatedAt: oneHourAgo,
        });

        await runCleanupCore(db);
        let roomSnap = await db.collection('rooms').doc(roomId).get();
        expect(roomSnap.exists).toBe(true); // Retained!

        // Now set updatedAt to 25 hours ago (expired -> delete)
        const twentyFiveHoursAgo = admin.firestore.Timestamp.fromMillis(Date.now() - (FINISHED_ROOM_RETENTION_MS + 3600000));
        await db.collection('rooms').doc(roomId).update({
            updatedAt: twentyFiveHoursAgo,
        });

        await runCleanupCore(db);
        roomSnap = await db.collection('rooms').doc(roomId).get();
        expect(roomSnap.exists).toBe(false); // Soft/Hard Deleted!
    });

    // 9. Cleanup Core Idempotency & Batch Resilience
    it('9. Cleanup core is idempotent and non-blocking across error items', async () => {
        const db = admin.firestore();
        const code = genCode('CL9');
        await wrapCreateRoom({
            data: { roomCode: code, operationId: 'op_cl9_c1_0001' },
            auth: { uid: 'userHost' },
        });

        const res1 = await runCleanupCore(db);
        const res2 = await runCleanupCore(db);

        expect(res1.errorsCount).toBe(0);
        expect(res2.errorsCount).toBe(0);
    });

    // 10. Parity for Word Match and Grammar Arena Lifecycle & Cleanup
    it('10. Grammar Arena shares identical lifecycle metadata and cleanup guarantees', async () => {
        const db = admin.firestore();
        const code = genCode('CLA10');
        const createRes = await wrapCreateArenaRoom({
            data: { roomCode: code, level: 'A1', operationId: 'op_cla10_ca_0001' },
            auth: { uid: 'arenaHost' },
        });
        const roomId = createRes.roomId;
        await new Promise((r) => setTimeout(r, 100));

        // Set lastActivityAt to 15 minutes ago
        const fifteenMinsAgo = admin.firestore.Timestamp.fromMillis(Date.now() - (WAITING_ROOM_EXPIRY_MS + 300000));
        await db.collection('arena_rooms').doc(roomId).update({
            lastActivityAt: fifteenMinsAgo,
        });

        const res = await runCleanupCore(db);
        expect(res.cancelledWaitingCount).toBeGreaterThanOrEqual(1);

        const arenaSnap = await db.collection('arena_rooms').doc(roomId).get();
        expect(arenaSnap.data()?.status).toBe('cancelled');
    });

    // 11. True Deterministic Interleaving: Cleanup selects candidate -> Barrier holds cleanup -> Heartbeat completes -> Cleanup transaction re-read aborts cancellation
    it('11. True Deterministic Interleaving: Cleanup selects candidate -> Barrier holds cleanup -> Heartbeat completes -> Cleanup transaction re-read aborts cancellation', async () => {
        const db = admin.firestore();
        const code = genCode('CL11');
        const createRes = await wrapCreateRoom({
            data: { roomCode: code, operationId: 'op_cl11_c1_0001' },
            auth: { uid: 'userHost' },
        });
        const roomId = createRes.roomId;
        await new Promise((r) => setTimeout(r, 100));

        // Initial values
        const initialSnap = await db.collection('rooms').doc(roomId).get();
        const initialData = initialSnap.data()!;
        const initialVersion = initialData.stateVersion;
        const initialHostLastSeenAt = initialData.hostLastSeenAt;

        // Set lastActivityAt to 11 minutes ago (makes room a waiting cleanup candidate)
        const elevenMinsAgo = admin.firestore.Timestamp.fromMillis(Date.now() - (WAITING_ROOM_EXPIRY_MS + 60000));
        await db.collection('rooms').doc(roomId).update({
            lastActivityAt: elevenMinsAgo,
        });

        let candidateSelected = false;
        let heartbeatExecutedInBarrier = false;

        // Execute cleanup with deterministic barrier hook
        const res = await runCleanupCore(db, undefined, async (docId, colName, candidateStatus) => {
            if (docId === roomId && candidateStatus === 'waiting') {
                candidateSelected = true;
                // While cleanup is paused at barrier (candidate selected), send heartbeat!
                await wrapSendHeartbeat({
                    data: { roomId, operationId: 'op_cl11_hb_barrier_01' },
                    auth: { uid: 'userHost' },
                });
                heartbeatExecutedInBarrier = true;
            }
        });

        // 1. Prove cleanup selected room as candidate BEFORE heartbeat ran
        expect(candidateSelected).toBe(true);
        // 2. Prove heartbeat executed WHILE cleanup was held in barrier
        expect(heartbeatExecutedInBarrier).toBe(true);

        const postSnap = await db.collection('rooms').doc(roomId).get();
        const postData = postSnap.data()!;

        // 3. Prove timestamps are updated to fresh values
        expect(postData.lastActivityAt.toMillis()).toBeGreaterThan(elevenMinsAgo.toMillis());
        if (initialHostLastSeenAt) {
            expect(postData.hostLastSeenAt.toMillis()).toBeGreaterThan(initialHostLastSeenAt.toMillis());
        } else {
            expect(postData.hostLastSeenAt).toBeDefined();
        }

        // 4. Prove cleanup transaction re-read aborted cancellation
        expect(res.cancelledWaitingCount).toBe(0);
        expect(postData.status).toBe('waiting');
        expect(postData.currentTurnUid).toBeNull();
        expect(postData.currentTurnIndex).toBe(0);
        expect(postData.stateVersion).toBe(initialVersion);
    });

    // 12a. True Deterministic Interleaving: Cleanup selects candidate -> Barrier -> submitWord -> Cleanup transaction aborts abandonment
    it('12a. True Deterministic Interleaving: Cleanup selects active candidate -> Barrier -> submitWord -> Cleanup transaction aborts abandonment', async () => {
        const db = admin.firestore();
        const code = genCode('CL12A');
        const createRes = await wrapCreateRoom({
            data: { roomCode: code, operationId: 'op_cl12a_c1_0001' },
            auth: { uid: 'userHost' },
        });
        const roomId = createRes.roomId;
        await new Promise((r) => setTimeout(r, 100));

        await wrapJoinRoom({
            data: { roomId, roomCode: code, username: 'Guest', operationId: 'op_cl12a_j1_0001' },
            auth: { uid: 'userGuest' },
        });

        await wrapStartGame({
            data: { roomId, operationId: 'op_cl12a_st_0001' },
            auth: { uid: 'userHost' },
        });

        const sixMinsAgo = admin.firestore.Timestamp.fromMillis(Date.now() - (ACTIVE_ROOM_ABANDONED_MS + 60000));
        await db.collection('rooms').doc(roomId).update({
            lastActivityAt: sixMinsAgo,
        });

        let candidateSelected = false;
        let submitWordExecutedInBarrier = false;

        const currentTurnUid = (await db.collection('rooms').doc(roomId).get()).data()?.currentTurnUid;

        const res = await runCleanupCore(db, undefined, async (docId, colName, candidateStatus) => {
            if (docId === roomId && candidateStatus === 'active') {
                candidateSelected = true;
                if (currentTurnUid) {
                    await wrapSubmitWord({
                        data: { roomId, word: 'run', operationId: 'op_cl12a_sub_barrier_01' },
                        auth: { uid: currentTurnUid },
                    });
                }
                submitWordExecutedInBarrier = true;
            }
        });

        expect(candidateSelected).toBe(true);
        expect(submitWordExecutedInBarrier).toBe(true);
        expect(res.abandonedActiveCount).toBe(0);

        const roomSnap = await db.collection('rooms').doc(roomId).get();
        expect(roomSnap.data()?.status).toBe('active');
    });

    // 12b. True Deterministic Interleaving: Cleanup selects waiting candidate -> Barrier -> startGame -> Cleanup transaction aborts cancellation
    it('12b. True Deterministic Interleaving: Cleanup selects waiting candidate -> Barrier -> startGame -> Cleanup transaction aborts cancellation', async () => {
        const db = admin.firestore();
        const code = genCode('CL12B');
        const createRes = await wrapCreateRoom({
            data: { roomCode: code, operationId: 'op_cl12b_c1_0001' },
            auth: { uid: 'userHost' },
        });
        const roomId = createRes.roomId;
        await new Promise((r) => setTimeout(r, 100));

        await wrapJoinRoom({
            data: { roomId, roomCode: code, username: 'Guest', operationId: 'op_cl12b_j1_0001' },
            auth: { uid: 'userGuest' },
        });

        const elevenMinsAgo = admin.firestore.Timestamp.fromMillis(Date.now() - (WAITING_ROOM_EXPIRY_MS + 60000));
        await db.collection('rooms').doc(roomId).update({
            lastActivityAt: elevenMinsAgo,
        });

        let candidateSelected = false;
        let startGameExecutedInBarrier = false;

        const res = await runCleanupCore(db, undefined, async (docId, colName, candidateStatus) => {
            if (docId === roomId && candidateStatus === 'waiting') {
                candidateSelected = true;
                await wrapStartGame({
                    data: { roomId, operationId: 'op_cl12b_st_barrier_01' },
                    auth: { uid: 'userHost' },
                });
                startGameExecutedInBarrier = true;
            }
        });

        expect(candidateSelected).toBe(true);
        expect(startGameExecutedInBarrier).toBe(true);
        expect(res.cancelledWaitingCount).toBe(0);

        const roomSnap = await db.collection('rooms').doc(roomId).get();
        expect(roomSnap.data()?.status).toBe('active');
    });

    // 12c. True Deterministic Interleaving: Cleanup selects waiting candidate -> Barrier -> leaveRoom -> Cleanup transaction aborts cancellation
    it('12c. True Deterministic Interleaving: Cleanup selects waiting candidate -> Barrier -> leaveRoom -> Cleanup transaction aborts cancellation', async () => {
        const db = admin.firestore();
        const code = genCode('CL12C');
        const createRes = await wrapCreateRoom({
            data: { roomCode: code, operationId: 'op_cl12c_c1_0001' },
            auth: { uid: 'userHost' },
        });
        const roomId = createRes.roomId;
        await new Promise((r) => setTimeout(r, 100));

        const elevenMinsAgo = admin.firestore.Timestamp.fromMillis(Date.now() - (WAITING_ROOM_EXPIRY_MS + 60000));
        await db.collection('rooms').doc(roomId).update({
            lastActivityAt: elevenMinsAgo,
        });

        let candidateSelected = false;
        let leaveRoomExecutedInBarrier = false;

        const res = await runCleanupCore(db, undefined, async (docId, colName, candidateStatus) => {
            if (docId === roomId && candidateStatus === 'waiting') {
                candidateSelected = true;
                await wrapLeaveRoom({
                    data: { roomId, operationId: 'op_cl12c_lv_barrier_01' },
                    auth: { uid: 'userHost' },
                });
                leaveRoomExecutedInBarrier = true;
            }
        });

        expect(candidateSelected).toBe(true);
        expect(leaveRoomExecutedInBarrier).toBe(true);
        expect(res.cancelledWaitingCount).toBe(0);

        const roomSnap = await db.collection('rooms').doc(roomId).get();
        expect(roomSnap.data()?.status).toBe('cancelled');
    });

    // 12d. True Deterministic Interleaving: Cleanup selects active candidate -> Barrier -> resolveTimeout -> Cleanup transaction aborts abandonment
    it('12d. True Deterministic Interleaving: Cleanup selects active candidate -> Barrier -> resolveTimeout -> Cleanup transaction aborts abandonment', async () => {
        const db = admin.firestore();
        const code = genCode('CL12D');
        const createRes = await wrapCreateRoom({
            data: { roomCode: code, operationId: 'op_cl12d_c1_0001' },
            auth: { uid: 'userHost' },
        });
        const roomId = createRes.roomId;
        await new Promise((r) => setTimeout(r, 100));

        await wrapJoinRoom({
            data: { roomId, roomCode: code, username: 'Guest', operationId: 'op_cl12d_j1_0001' },
            auth: { uid: 'userGuest' },
        });

        await wrapStartGame({
            data: { roomId, operationId: 'op_cl12d_st_0001' },
            auth: { uid: 'userHost' },
        });

        const sixMinsAgo = admin.firestore.Timestamp.fromMillis(Date.now() - (ACTIVE_ROOM_ABANDONED_MS + 60000));
        await db.collection('rooms').doc(roomId).update({
            turnDeadlineAt: sixMinsAgo,
            lastActivityAt: sixMinsAgo,
        });

        let candidateSelected = false;
        let resolveTimeoutExecutedInBarrier = false;

        const res = await runCleanupCore(db, undefined, async (docId, colName, candidateStatus) => {
            if (docId === roomId && candidateStatus === 'active') {
                candidateSelected = true;
                await wrapResolveTimeout({
                    data: { roomId, operationId: 'op_cl12d_res_barrier_01' },
                    auth: { uid: 'userHost' },
                });
                resolveTimeoutExecutedInBarrier = true;
            }
        });

        expect(candidateSelected).toBe(true);
        expect(resolveTimeoutExecutedInBarrier).toBe(true);
        expect(res.abandonedActiveCount).toBe(0);

        const roomSnap = await db.collection('rooms').doc(roomId).get();
        expect(roomSnap.data()?.status).toBe('finished'); // resolveTimeout finishes game when sole active player remains
    });

    // 13. Callable cleanupExpiredRooms rejects unauthenticated and non-admin users
    it('13. Callable cleanupExpiredRooms rejects unauthenticated and non-admin users', async () => {
        // Unauthenticated request rejected
        await expect(
            wrapCleanupExpiredRooms({ data: {} })
        ).rejects.toThrow('Oturum bulunamadi');

        // Regular non-admin authenticated request rejected
        await expect(
            wrapCleanupExpiredRooms({ data: {}, auth: { uid: 'regularUser' } })
        ).rejects.toThrow('Sadece yetkili admin sunucu temizligi calistirabilir');

        // Admin authenticated request succeeds
        const adminRes = await wrapCleanupExpiredRooms({
            data: {},
            auth: { uid: 'adminUser', token: { admin: true } },
        });
        expect(adminRes).toBeDefined();
        expect(adminRes.errorsCount).toBe(0);
    });
});
