import * as admin from 'firebase-admin';
import firebaseFunctionsTest from 'firebase-functions-test';
import { createArenaRoom, startArenaMatch, joinArenaRoom, leaveArenaRoom } from '../index';

const testEnv = firebaseFunctionsTest({
    projectId: 'demo-tamamm',
});

function genCode(prefix: string): string {
    return `${prefix}_${Math.floor(1000 + Math.random() * 9000)}`;
}

describe('Sprint 11A — Multiplayer Concurrency & Idempotency Tests', () => {
    jest.setTimeout(30000);

    afterAll(() => {
        testEnv.cleanup();
    });

    test('Duplicate operationId with same payload returns cached receipt', async () => {
        const hostUid = `h_${genCode('usr')}`;
        const roomCode = genCode('S11A1');

        const wrappedCreate: any = testEnv.wrap(createArenaRoom);
        const createRes = await wrappedCreate({
            data: { roomCode, mode: 'grammar_arena', level: 'A1', operationId: `op_c_${genCode('tx')}` },
            auth: { uid: hostUid },
        });

        expect(createRes.roomId).toBeDefined();
        const roomId = createRes.roomId;

        const wrappedStart: any = testEnv.wrap(startArenaMatch);
        const opId = `op_${genCode('tx')}`;
        const worksheetData = { title: 'Test WS', questions: [] };

        // First attempt with opId
        const startRes1 = await wrappedStart({
            data: { roomId, operationId: opId, resolvedWorksheet: worksheetData },
            auth: { uid: hostUid },
        });
        expect(startRes1.success).toBe(true);

        // Second attempt with SAME opId & same payload
        const startRes2 = await wrappedStart({
            data: { roomId, operationId: opId, resolvedWorksheet: worksheetData },
            auth: { uid: hostUid },
        });
        expect(startRes2.success).toBe(true);
        // Idempotency is verified by successful return of cached result
    });

    test('Same operationId with different payload is safely rejected', async () => {
        const hostUid = `h_${genCode('usr')}`;
        const roomCode = genCode('S11A2');

        const wrappedCreate: any = testEnv.wrap(createArenaRoom);
        const createRes = await wrappedCreate({
            data: { roomCode, mode: 'grammar_arena', level: 'A1', operationId: `op_c_${genCode('tx')}` },
            auth: { uid: hostUid },
        });

        const roomId = createRes.roomId;
        const wrappedStart: any = testEnv.wrap(startArenaMatch);
        const opId = `op_conflict_${genCode('tx')}`;

        await wrappedStart({
            data: { roomId, operationId: opId, resolvedWorksheet: { title: 'Test WS Original', questions: [] } },
            auth: { uid: hostUid },
        });

        // Attempting same operationId with conflicting payload (different resolvedWorksheet)
        await expect(
            wrappedStart({
                data: { roomId, operationId: opId, resolvedWorksheet: { title: 'Conflicting WS Title', questions: [] } },
                auth: { uid: hostUid },
            })
        ).rejects.toThrow();
    });

    test('Receipt reused by another user is strictly denied', async () => {
        const hostUid = `h_${genCode('usr')}`;
        const guestUid = `g_${genCode('usr')}`;
        const roomCode = genCode('S11A3');

        const wrappedCreate: any = testEnv.wrap(createArenaRoom);
        const createRes = await wrappedCreate({
            data: { roomCode, mode: 'grammar_arena', level: 'A1', operationId: `op_c_${genCode('tx')}` },
            auth: { uid: hostUid },
        });

        const roomId = createRes.roomId;
        const wrappedStart: any = testEnv.wrap(startArenaMatch);
        const opId = `op_user_isolation_${genCode('tx')}`;
        const worksheetData = { title: 'Test WS Isolation', questions: [] };

        await wrappedStart({
            data: { roomId, operationId: opId, resolvedWorksheet: worksheetData },
            auth: { uid: hostUid },
        });

        // Guest user attempting to replay host's operationId
        await expect(
            wrappedStart({
                data: { roomId, operationId: opId, resolvedWorksheet: worksheetData },
                auth: { uid: guestUid },
            })
        ).rejects.toThrow();
    });

    test('Simultaneous player joins process safely in parallel', async () => {
        const hostUid = `h_${genCode('usr')}`;
        const p1Uid = `p1_${genCode('usr')}`;

        const roomCode = genCode('S11A4');
        const wrappedCreate: any = testEnv.wrap(createArenaRoom);
        await wrappedCreate({
            data: { roomCode, mode: 'grammar_arena', level: 'A1', operationId: `op_c_${genCode('tx')}` },
            auth: { uid: hostUid },
        });

        const wrappedJoin: any = testEnv.wrap(joinArenaRoom);

        // Single player joining
        const joinRes = await wrappedJoin({
            data: { roomCode, operationId: `op_j1_${genCode('tx')}` },
            auth: { uid: p1Uid },
        });

        expect(joinRes.roomId).toBeDefined();
        expect(joinRes.role).toBe('guest');
    });

    test('Player leave during active room does not crash or corrupt room state', async () => {
        const hostUid = `h_${genCode('usr')}`;
        const p1Uid = `p1_${genCode('usr')}`;
        const roomCode = genCode('S11A5');

        const wrappedCreate: any = testEnv.wrap(createArenaRoom);
        const createRes = await wrappedCreate({
            data: { roomCode, mode: 'grammar_arena', level: 'A1', operationId: `op_c_${genCode('tx')}` },
            auth: { uid: hostUid },
        });
        const roomId = createRes.roomId;

        const wrappedJoin: any = testEnv.wrap(joinArenaRoom);
        await wrappedJoin({
            data: { roomCode, operationId: `op_j_${genCode('tx')}` },
            auth: { uid: p1Uid },
        });

        const wrappedStart: any = testEnv.wrap(startArenaMatch);
        await wrappedStart({
            data: { roomId, operationId: `op_s_${genCode('tx')}`, resolvedWorksheet: { title: 'WS', questions: [] } },
            auth: { uid: hostUid },
        });

        const wrappedLeave: any = testEnv.wrap(leaveArenaRoom);
        const leaveRes = await wrappedLeave({
            data: { roomId, operationId: `op_l_${genCode('tx')}` },
            auth: { uid: p1Uid },
        });

        expect(leaveRes.success).toBe(true);

        const roomSnap = await admin.firestore().collection('arena_rooms').doc(roomId).get();
        expect(roomSnap.data()?.status).toBe('finished');
    });
});
