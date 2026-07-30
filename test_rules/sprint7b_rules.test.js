const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { readFileSync } = require('fs');
const { resolve } = require('path');

const PROJECT_ID = 'rules-test-project-7b';
const RULES_PATH = resolve(__dirname, '../firestore.rules');

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(RULES_PATH, 'utf8'),
      host: '127.0.0.1',
      port: 8080,
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
  return uid ? testEnv.authenticatedContext(uid).firestore() : testEnv.unauthenticatedContext().firestore();
}

async function seedDoc(path, data) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc(path).set(data);
  });
}

describe('Sprint 7B Room Lifecycle & Presence Rules Authorization Tests', () => {

  describe('Word Match Lifecycle Rules', () => {
    beforeEach(async () => {
      await seedDoc('rooms/room7b_1', {
        roomCode: '70001',
        status: 'waiting',
        hostUid: 'host7b',
        players: ['host7b', 'guest7b'],
        lastActivityAt: '2026-07-26T00:00:00Z',
        hostLastSeenAt: '2026-07-26T00:00:00Z',
        guestLastSeenAt: '2026-07-26T00:00:00Z',
      });
    });

    it('Host member can read room lifecycle metadata', async () => {
      const dbHost = getFirestore('host7b');
      await assertSucceeds(dbHost.doc('rooms/room7b_1').get());
    });

    it('Guest member can read room lifecycle metadata', async () => {
      const dbGuest = getFirestore('guest7b');
      await assertSucceeds(dbGuest.doc('rooms/room7b_1').get());
    });

    it('Outsider authenticated user CANNOT read room lifecycle metadata', async () => {
      const dbOutsider = getFirestore('outsider7b');
      await assertFails(dbOutsider.doc('rooms/room7b_1').get());
    });

    it('Unauthenticated user CANNOT read room lifecycle metadata', async () => {
      const dbUnauth = getFirestore(null);
      await assertFails(dbUnauth.doc('rooms/room7b_1').get());
    });

    it('Client CANNOT write or update room lifecycle or heartbeat metadata', async () => {
      const dbHost = getFirestore('host7b');
      await assertFails(dbHost.doc('rooms/room7b_1').update({ hostLastSeenAt: 'fake_now' }));
      await assertFails(dbHost.doc('rooms/room7b_1').set({ hostUid: 'host7b', lastActivityAt: 'fake_now' }));
    });
  });

  describe('Grammar Arena Lifecycle Rules', () => {
    beforeEach(async () => {
      await seedDoc('arena_rooms/arena7b_1', {
        roomCode: '70002',
        status: 'active',
        hostId: 'arenaHost7b',
        guestId: 'arenaGuest7b',
        lastActivityAt: '2026-07-26T00:00:00Z',
        hostLastSeenAt: '2026-07-26T00:00:00Z',
        guestLastSeenAt: '2026-07-26T00:00:00Z',
      });
    });

    it('Arena Host can read room lifecycle metadata', async () => {
      const dbHost = getFirestore('arenaHost7b');
      await assertSucceeds(dbHost.doc('arena_rooms/arena7b_1').get());
    });

    it('Arena Guest can read room lifecycle metadata', async () => {
      const dbGuest = getFirestore('arenaGuest7b');
      await assertSucceeds(dbGuest.doc('arena_rooms/arena7b_1').get());
    });

    it('Outsider CANNOT read arena room lifecycle metadata', async () => {
      const dbOutsider = getFirestore('outsider7b');
      await assertFails(dbOutsider.doc('arena_rooms/arena7b_1').get());
    });

    it('Client CANNOT write to arena room lifecycle/heartbeat fields', async () => {
      const dbGuest = getFirestore('arenaGuest7b');
      await assertFails(dbGuest.doc('arena_rooms/arena7b_1').update({ guestLastSeenAt: 'fake_now' }));
    });
  });
});
