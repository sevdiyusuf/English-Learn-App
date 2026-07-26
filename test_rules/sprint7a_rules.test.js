const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { readFileSync } = require('fs');
const { resolve } = require('path');

const PROJECT_ID = 'rules-test-project-7a';
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

describe('Sprint 7A Room & Arena Read Authorization & Lockdown Rules Tests', () => {

  // 1. Word Match Rooms Read Rules
  describe('Word Match Rooms Read Rules', () => {
    beforeEach(async () => {
      await seedDoc('rooms/room101', {
        roomCode: '10001',
        status: 'waiting',
        hostUid: 'hostA',
        players: ['hostA', 'guestB'],
      });
      await seedDoc('rooms/room101/playedWords/w1', { word: 'apple', byUid: 'hostA' });
      await seedDoc('rooms/room101/meta/usedWords', { used: { apple: true } });
      await seedDoc('rooms/room101/receipts/op1_hostA', { result: true });
    });

    it('Member host can read room and playedWords/meta subcollections', async () => {
      const dbHost = getFirestore('hostA');
      await assertSucceeds(dbHost.doc('rooms/room101').get());
      await assertSucceeds(dbHost.doc('rooms/room101/playedWords/w1').get());
      await assertSucceeds(dbHost.doc('rooms/room101/meta/usedWords').get());
    });

    it('Member guest can read room and playedWords/meta subcollections', async () => {
      const dbGuest = getFirestore('guestB');
      await assertSucceeds(dbGuest.doc('rooms/room101').get());
      await assertSucceeds(dbGuest.doc('rooms/room101/playedWords/w1').get());
      await assertSucceeds(dbGuest.doc('rooms/room101/meta/usedWords').get());
    });

    it('Non-member authenticated user CANNOT read room or subcollections', async () => {
      const dbOutsider = getFirestore('outsiderC');
      await assertFails(dbOutsider.doc('rooms/room101').get());
      await assertFails(dbOutsider.doc('rooms/room101/playedWords/w1').get());
      await assertFails(dbOutsider.doc('rooms/room101/meta/usedWords').get());
    });

    it('Unauthenticated user CANNOT read room or subcollections', async () => {
      const dbUnauth = getFirestore(null);
      await assertFails(dbUnauth.doc('rooms/room101').get());
      await assertFails(dbUnauth.doc('rooms/room101/playedWords/w1').get());
      await assertFails(dbUnauth.doc('rooms/room101/meta/usedWords').get());
    });

    it('Client CANNOT read or write receipt documents', async () => {
      const dbHost = getFirestore('hostA');
      await assertFails(dbHost.doc('rooms/room101/receipts/op1_hostA').get());
      await assertFails(dbHost.doc('rooms/room101/receipts/op1_hostA').set({ fake: true }));
    });
  });

  // 2. Grammar Arena Rooms Read Rules
  describe('Grammar Arena Read Rules', () => {
    beforeEach(async () => {
      await seedDoc('arena_rooms/arena202', {
        roomCode: '20002',
        status: 'active',
        hostId: 'arenaHostA',
        guestId: 'arenaGuestB',
        hostScore: 10,
        guestScore: 5,
      });
      await seedDoc('arena_rooms/arena202/answers/0_arenaHostA', { isCorrect: true });
      await seedDoc('arena_rooms/arena202/round_answers/0_arenaHostA_1', { result: true });
      await seedDoc('arena_rooms/arena202/receipts/op_a1_arenaHostA', { result: true });
    });

    it('Member host can read arena room and answers', async () => {
      const dbHost = getFirestore('arenaHostA');
      await assertSucceeds(dbHost.doc('arena_rooms/arena202').get());
      await assertSucceeds(dbHost.doc('arena_rooms/arena202/answers/0_arenaHostA').get());
    });

    it('Member guest can read arena room and answers', async () => {
      const dbGuest = getFirestore('arenaGuestB');
      await assertSucceeds(dbGuest.doc('arena_rooms/arena202').get());
      await assertSucceeds(dbGuest.doc('arena_rooms/arena202/answers/0_arenaHostA').get());
    });

    it('Non-member authenticated user CANNOT read arena room or answers', async () => {
      const dbOutsider = getFirestore('outsiderC');
      await assertFails(dbOutsider.doc('arena_rooms/arena202').get());
      await assertFails(dbOutsider.doc('arena_rooms/arena202/answers/0_arenaHostA').get());
    });

    it('Unauthenticated user CANNOT read arena room or answers', async () => {
      const dbUnauth = getFirestore(null);
      await assertFails(dbUnauth.doc('arena_rooms/arena202').get());
      await assertFails(dbUnauth.doc('arena_rooms/arena202/answers/0_arenaHostA').get());
    });

    it('Client CANNOT read or write round_answers (domain-dedupe) or receipts', async () => {
      const dbHost = getFirestore('arenaHostA');
      await assertFails(dbHost.doc('arena_rooms/arena202/round_answers/0_arenaHostA_1').get());
      await assertFails(dbHost.doc('arena_rooms/arena202/round_answers/0_arenaHostA_1').set({ fake: true }));
      await assertFails(dbHost.doc('arena_rooms/arena202/receipts/op_a1_arenaHostA').get());
      await assertFails(dbHost.doc('arena_rooms/arena202/receipts/op_a1_arenaHostA').set({ fake: true }));
    });
  });
});
