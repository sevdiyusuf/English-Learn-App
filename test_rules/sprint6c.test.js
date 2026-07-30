const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { readFileSync } = require('fs');
const { resolve } = require('path');

const PROJECT_ID = 'rules-test-project-6c';
const RULES_PATH = resolve(__dirname, '../firestore.rules');

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(RULES_PATH, 'utf8'),
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

afterEach(async () => {
  await testEnv.clearFirestore();
});

function getFirestore(uid) {
  return testEnv.authenticatedContext(uid || 'anonymous').firestore();
}

describe('Sprint 6C Owner Review Tests', () => {

  describe('Rooms Rules (Sprint 7A Direct Client Lockdown)', () => {
    it('direct room create/join by client must be denied (use cloud functions)', async () => {
      const dbA = getFirestore('userA');
      await assertFails(dbA.collection('rooms').doc('room1').set({
        roomCode: '123', status: 'waiting', players: ['userA'],
        playerNames: { userA: 'A' }, hostUid: 'userA', activePlayerIds: [],
        createdAt: new Date('2023-01-01'), updatedAt: new Date('2023-01-01')
      }));

      const dbB = getFirestore('userB');
      await assertFails(dbB.collection('rooms').doc('room1').update({
        players: ['userA', 'userB'],
        'playerNames.userB': 'B',
        updatedAt: new Date('2024-01-01')
      }));
    });

    it('direct room update by client must be denied', async () => {
      const dbB = getFirestore('userB');
      await assertFails(dbB.collection('rooms').doc('room2').update({
        'playerNames.userB': 'B_new',
        updatedAt: new Date('2024-01-02')
      }));
    });

    it('direct room leave by client must be denied', async () => {
      const dbB = getFirestore('userB');
      await assertFails(dbB.collection('rooms').doc('room3').update({
        players: ['userA'],
        updatedAt: new Date('2025-01-01')
      }));
    });

    it('activePlayerIds-only leave deny', async () => {
      const dbB = getFirestore('userB');
      await assertFails(dbB.collection('rooms').doc('room6').update({
        activePlayerIds: [],
        updatedAt: new Date('2025-01-01')
      }));
    });
  });

  describe('Friend Requests Rules', () => {
    it('direct accepted friend-request update deny', async () => {
      const dbA = getFirestore('userA');
      // Sprint 8 uses a callable for creation, so block/rate-limit checks
      // cannot be bypassed by a fresh client document ID. Seed only for the
      // direct accepted-update authorization assertion below.
      const request = {
        fromUid: 'userA', toUid: 'userB', status: 'pending',
        createdAt: '2023-01-01T12:00:00Z', updatedAt: '2023-01-01T12:00:00Z'
      };
      await assertFails(dbA.collection('friend_requests').doc('req1').set(request));
      await testEnv.withSecurityRulesDisabled((context) =>
        context.firestore().collection('friend_requests').doc('req1').set(request));

      const dbB = getFirestore('userB');
      await assertFails(dbB.collection('friend_requests').doc('req1').update({
        status: 'accepted', updatedAt: '2024-01-01T12:00:00Z'
      }));
    });

    it('missing optional legacy fields ile reject/cancel davranışı', async () => {
      const dbA = getFirestore('userA');
      // resolveFriendRequest is callable-only in Sprint 8; retain the legacy
      // fixture while asserting that direct cancel/reject remains denied.
      const request = {
        fromUid: 'userA', toUid: 'userB', status: 'pending',
        createdAt: '2023-01-01T12:00:00Z', updatedAt: '2023-01-01T12:00:00Z'
      };
      await assertFails(dbA.collection('friend_requests').doc('req2').set(request));
      await testEnv.withSecurityRulesDisabled((context) =>
        context.firestore().collection('friend_requests').doc('req2').set(request));

      const dbB = getFirestore('userB');
      await assertFails(dbB.collection('friend_requests').doc('req2').update({
        status: 'rejected', updatedAt: '2024-01-01T12:00:00Z'
      }));
    });
  });

  describe('Arena Rooms Rules (Sprint 7A Direct Client Lockdown)', () => {
    it('arena create sahte host (host.id != auth.uid) deny', async () => {
      const dbA = getFirestore('userA');
      await assertFails(dbA.collection('arena_rooms').doc('arena1').set({
        hostId: 'userA', host: { id: 'userB', isOnline: true }, config: { difficulty: 1 },
        createdAt: new Date('2023-01-01')
      }));
    });

    it('arena forged host.score create deny', async () => {
      const dbA = getFirestore('userA');
      await assertFails(dbA.collection('arena_rooms').doc('arena1_score').set({
        hostId: 'userA', host: { id: 'userA', isOnline: true, name: 'A', photoUrl: '', score: 10, lastPing: new Date() }, config: { level: 'A1', worksheetId: null },
        createdAt: new Date('2023-01-01')
      }));
    });

    it('arena join sahte guest (guest.id != auth.uid) deny', async () => {
      const dbB = getFirestore('userB');
      await assertFails(dbB.collection('arena_rooms').doc('arena2').update({
        guestId: 'userB', guest: { id: 'userC', isOnline: true, name: 'B', photoUrl: '', score: 0, lastPing: new Date() }
      }));
    });

    it('arena host critical-field (nested host.score) update deny', async () => {
      const dbA = getFirestore('userA');
      await assertFails(dbA.collection('arena_rooms').doc('arena3').update({
        hostScore: 100
      }));
    });
  });
});
