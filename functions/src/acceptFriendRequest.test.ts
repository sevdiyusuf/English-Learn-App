import * as admin from 'firebase-admin';
const fft = require('firebase-functions-test');
import { acceptFriendRequest, requestAccountDeletion } from './index';

// Initialize firebase-functions-test to use the emulator
const testEnv = fft({
    projectId: 'demo-sprint6c',
});

// Important: connect Admin SDK to the emulator to prove it won't write to production!
if (!admin.apps.length) { admin.initializeApp({ projectId: 'demo-sprint6c' }); }
admin.firestore().settings({
    host: '127.0.0.1:8080',
    ssl: false,
});

describe('acceptFriendRequest Callable Function', () => {
    let wrapped: any;

    beforeAll(() => {
        wrapped = testEnv.wrap(acceptFriendRequest);
    });

    afterAll(() => {
        testEnv.cleanup();
    });

    afterEach(async () => {
        // Clear firestore emulator
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

    it('unauthenticated caller deny', async () => {
        await expect(wrapped({ data: { requestId: 'req1' } }))
            .rejects.toThrow();
    });

    it('eksik request ve bozuk payload reddedilsin (malformed callable requestId deny)', async () => {
        await expect(wrapped({ data: {}, auth: { uid: 'userA' } })).rejects.toThrow();
        await expect(wrapped({ data: { requestId: 'req/1' }, auth: { uid: 'userA' } })).rejects.toThrow();
    });

    it('malformed fromUid/toUid document deny', async () => {
        const db = admin.firestore();
        await db.collection('friend_requests').doc('req1').set({
            fromUid: 'userA',
            toUid: 'userA', // self friendship
            status: 'pending'
        });

        await expect(wrapped({ data: { requestId: 'req1' }, auth: { uid: 'userA' } }))
            .rejects.toThrow();
    });

    it('yalniz recipient accept edebilsin (sender deny)', async () => {
        const db = admin.firestore();
        await db.collection('friend_requests').doc('req1').set({
            fromUid: 'userA',
            toUid: 'userB',
            status: 'pending'
        });

        // userA (sender) tries to accept
        await expect(wrapped({ data: { requestId: 'req1' }, auth: { uid: 'userA' } }))
            .rejects.toThrow();
    });

    it('unrelated caller deny', async () => {
        const db = admin.firestore();
        await db.collection('friend_requests').doc('req1').set({
            fromUid: 'userA',
            toUid: 'userB',
            status: 'pending'
        });

        // userC tries to accept
        await expect(wrapped({ data: { requestId: 'req1' }, auth: { uid: 'userC' } }))
            .rejects.toThrow();
    });

    it('yalniz pending request kabul edilsin', async () => {
        const db = admin.firestore();
        await db.collection('friend_requests').doc('req1').set({
            fromUid: 'userA',
            toUid: 'userB',
            status: 'rejected'
        });

        await expect(wrapped({ data: { requestId: 'req1' }, auth: { uid: 'userB' } }))
            .rejects.toThrow();
    });

    it('iki yonlu friendship belgeleri ve accepted gecisi atomik olsun', async () => {
        const db = admin.firestore();
        await db.collection('friend_requests').doc('req1').set({
            fromUid: 'userA',
            toUid: 'userB',
            status: 'pending'
        });

        const res = await wrapped({ data: { requestId: 'req1' }, auth: { uid: 'userB' } });
        expect(res.success).toBe(true);

        const reqDoc = await db.collection('friend_requests').doc('req1').get();
        expect(reqDoc.data()?.status).toBe('accepted');

        const friendA = await db.collection('friendships').doc('userA').collection('friends').doc('userB').get();
        expect(friendA.exists).toBe(true);

        const friendB = await db.collection('friendships').doc('userB').collection('friends').doc('userA').get();
        expect(friendB.exists).toBe(true);
    });

    it('second accept call idempotent success', async () => {
        const db = admin.firestore();
        await db.collection('friend_requests').doc('req1').set({
            fromUid: 'userA',
            toUid: 'userB',
            status: 'pending'
        });

        // First call
        await wrapped({ data: { requestId: 'req1' }, auth: { uid: 'userB' } });

        // Second call
        const res2 = await wrapped({ data: { requestId: 'req1' }, auth: { uid: 'userB' } });
        expect(res2.success).toBe(true);
        expect(res2.status).toBe('alreadyAccepted');
    });

    it('unknown/missing/non-string status deny', async () => {
        const db = admin.firestore();
        await db.collection('friend_requests').doc('req_unknown').set({
            fromUid: 'userA',
            toUid: 'userB',
            status: 'weird_status'
        });
        await expect(wrapped({ data: { requestId: 'req_unknown' }, auth: { uid: 'userB' } }))
            .rejects.toThrow();

        await db.collection('friend_requests').doc('req_missing').set({
            fromUid: 'userA',
            toUid: 'userB'
        });
        await expect(wrapped({ data: { requestId: 'req_missing' }, auth: { uid: 'userB' } }))
            .rejects.toThrow();

        await db.collection('friend_requests').doc('req_number').set({
            fromUid: 'userA',
            toUid: 'userB',
            status: 123
        });
        await expect(wrapped({ data: { requestId: 'req_number' }, auth: { uid: 'userB' } }))
            .rejects.toThrow();
    });
});

describe('requestAccountDeletion Callable Function', () => {
    let wrappedDel: any;

    beforeAll(() => {
        wrappedDel = testEnv.wrap(requestAccountDeletion);
    });

    it('account deletion reciprocal friendship cleanup', async () => {
        const db = admin.firestore();
        // userA has a friend userB
        await db.collection('friendships').doc('userA').collection('friends').doc('userB').set({ createdAt: '2023' });
        await db.collection('friendships').doc('userB').collection('friends').doc('userA').set({ createdAt: '2023' });

        // Mock auth state (recent login)
        const mockAuth = {
            uid: 'userA',
            token: {
                auth_time: Math.floor(Date.now() / 1000)
            }
        };

        // We mock admin.auth().deleteUser for test
        const deleteUserSpy = jest.spyOn(admin.auth(), 'deleteUser').mockResolvedValue(undefined as any);

        const res = await wrappedDel({ data: {}, auth: mockAuth });
        expect(res.success).toBe(true);

        // Check userA is completely gone
        const friendADoc = await db.collection('friendships').doc('userA').collection('friends').doc('userB').get();
        expect(friendADoc.exists).toBe(false);

        // Check userB's reciprocal link to userA is gone
        const friendBDoc = await db.collection('friendships').doc('userB').collection('friends').doc('userA').get();
        expect(friendBDoc.exists).toBe(false);

        deleteUserSpy.mockRestore();
    });
});
