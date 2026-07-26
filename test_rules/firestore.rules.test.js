/**
 * Firestore Security Rules tests for Sprint 4D.
 *
 * Prerequisites (run these once before running tests):
 *   cd test_rules && npm install
 *
 * To run:
 *   From project root:
 *     firebase emulators:exec --only firestore "cd test_rules && npx jest --forceExit"
 *
 *   Or in two terminals:
 *     Terminal 1: firebase emulators:start --only firestore
 *     Terminal 2: cd test_rules && npx jest --forceExit
 *
 * NOTE: These tests require the Firebase CLI and the Firestore emulator.
 *   Install if missing:
 *     npm install -g firebase-tools
 *     firebase setup:emulators:firestore
 */

const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const { readFileSync } = require('fs');
const { resolve } = require('path');

const PROJECT_ID = 'rules-test-project';
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

// ── Helpers ──────────────────────────────────────────────────────────────────

function userContext(uid) {
  return testEnv.authenticatedContext(uid);
}

function unauthContext() {
  return testEnv.unauthenticatedContext();
}

function adminContext() {
  return testEnv.withSecurityRulesDisabled(async (ctx) => ctx.firestore());
}

async function seedDoc(ownerUid, setId, data) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx
      .firestore()
      .collection('users')
      .doc(ownerUid)
      .collection('word_match_sets')
      .doc(setId)
      .set(data);
  });
}

async function seedReceipt(ownerUid, receiptId, data) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx
      .firestore()
      .collection('users')
      .doc(ownerUid)
      .collection('outbox_receipts')
      .doc(receiptId)
      .set(data);
  });
}

function wordSetDoc(ownerUid, entityId, version = 1, opId = 'op_1') {
  return {
    ownerUid,
    entityId,
    entityType: 'word_set',
    remoteVersion: version,
    lastOperationId: opId,
    isTombstone: false,
    name: 'Test Deck',
    visibility: 'private',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    serverUpdatedAt: new Date().toISOString(),
  };
}

function receiptDoc(ownerUid, operationId, entityId, version = 1) {
  return {
    operationId,
    ownerUid,
    entityType: 'word_set',
    entityId,
    appliedRemoteVersion: version,
    appliedAt: new Date().toISOString(),
  };
}

// ── word_match_sets Tests ─────────────────────────────────────────────────────

describe('word_match_sets', () => {
  // ── Read ──────────────────────────────────────────────────────────────────

  test('Owner can read their own document', async () => {
    await seedDoc('user_A', 'set1', wordSetDoc('user_A', 'set1'));
    const db = userContext('user_A').firestore();
    await assertSucceeds(
      db.collection('users').doc('user_A').collection('word_match_sets').doc('set1').get()
    );
  });

  test('User A cannot read User B document', async () => {
    await seedDoc('user_B', 'set2', wordSetDoc('user_B', 'set2'));
    const db = userContext('user_A').firestore();
    await assertFails(
      db.collection('users').doc('user_B').collection('word_match_sets').doc('set2').get()
    );
  });

  test('Unauthenticated client cannot read', async () => {
    await seedDoc('user_A', 'set3', wordSetDoc('user_A', 'set3'));
    const db = unauthContext().firestore();
    await assertFails(
      db.collection('users').doc('user_A').collection('word_match_sets').doc('set3').get()
    );
  });

  // ── Create ────────────────────────────────────────────────────────────────

  test('Owner can create valid document with ownerUid=own, entityId=setId, remoteVersion=1', async () => {
    const db = userContext('user_A').firestore();
    await assertSucceeds(
      db
        .collection('users')
        .doc('user_A')
        .collection('word_match_sets')
        .doc('setC1')
        .set(wordSetDoc('user_A', 'setC1', 1, 'op_create_1'))
    );
  });

  test('Create rejected: ownerUid differs from auth.uid', async () => {
    const db = userContext('user_A').firestore();
    const doc = { ...wordSetDoc('user_B', 'setC2', 1, 'op_2') }; // ownerUid=user_B but auth=user_A
    await assertFails(
      db.collection('users').doc('user_A').collection('word_match_sets').doc('setC2').set(doc)
    );
  });

  test('Create rejected: entityId does not match document path (setId)', async () => {
    const db = userContext('user_A').firestore();
    const doc = { ...wordSetDoc('user_A', 'wrong_entity_id', 1, 'op_3') };
    await assertFails(
      db.collection('users').doc('user_A').collection('word_match_sets').doc('setC3').set(doc)
    );
  });

  test('Create rejected: remoteVersion != 1', async () => {
    const db = userContext('user_A').firestore();
    const doc = { ...wordSetDoc('user_A', 'setC4', 5, 'op_4') }; // remoteVersion=5
    await assertFails(
      db.collection('users').doc('user_A').collection('word_match_sets').doc('setC4').set(doc)
    );
  });

  // ── Update ────────────────────────────────────────────────────────────────

  test('Valid remoteVersion +1 update accepted', async () => {
    await seedDoc('user_A', 'setU1', wordSetDoc('user_A', 'setU1', 1, 'op_v1'));
    const db = userContext('user_A').firestore();
    const update = {
      ...wordSetDoc('user_A', 'setU1', 2, 'op_v2'), // version 1 → 2
    };
    await assertSucceeds(
      db.collection('users').doc('user_A').collection('word_match_sets').doc('setU1').set(update)
    );
  });

  test('Update rejected: ownerUid change attempt', async () => {
    await seedDoc('user_A', 'setU2', wordSetDoc('user_A', 'setU2', 1, 'op_v1'));
    const db = userContext('user_A').firestore();
    const update = {
      ...wordSetDoc('user_A', 'setU2', 2, 'op_v2'),
      ownerUid: 'user_EVIL', // changed ownerUid
    };
    await assertFails(
      db.collection('users').doc('user_A').collection('word_match_sets').doc('setU2').set(update)
    );
  });

  test('Update rejected: entityId change attempt', async () => {
    await seedDoc('user_A', 'setU3', wordSetDoc('user_A', 'setU3', 1, 'op_v1'));
    const db = userContext('user_A').firestore();
    const update = {
      ...wordSetDoc('user_A', 'setU3', 2, 'op_v2'),
      entityId: 'setU3_CHANGED', // changed entityId
    };
    await assertFails(
      db.collection('users').doc('user_A').collection('word_match_sets').doc('setU3').set(update)
    );
  });

  test('Update rejected: remoteVersion rollback (version goes backward)', async () => {
    await seedDoc('user_A', 'setU4', wordSetDoc('user_A', 'setU4', 3, 'op_v3'));
    const db = userContext('user_A').firestore();
    const update = { ...wordSetDoc('user_A', 'setU4', 2, 'op_v2') }; // 3 → 2 (backward)
    await assertFails(
      db.collection('users').doc('user_A').collection('word_match_sets').doc('setU4').set(update)
    );
  });

  test('Update rejected: remoteVersion same (no increment)', async () => {
    await seedDoc('user_A', 'setU5', wordSetDoc('user_A', 'setU5', 2, 'op_v2'));
    const db = userContext('user_A').firestore();
    const update = { ...wordSetDoc('user_A', 'setU5', 2, 'op_v2_dup') }; // stays at 2
    await assertFails(
      db.collection('users').doc('user_A').collection('word_match_sets').doc('setU5').set(update)
    );
  });

  test('Update rejected: remoteVersion skips by +2', async () => {
    await seedDoc('user_A', 'setU6', wordSetDoc('user_A', 'setU6', 1, 'op_v1'));
    const db = userContext('user_A').firestore();
    const update = { ...wordSetDoc('user_A', 'setU6', 3, 'op_v3') }; // 1 → 3 (skip)
    await assertFails(
      db.collection('users').doc('user_A').collection('word_match_sets').doc('setU6').set(update)
    );
  });

  test('Valid tombstone update accepted: isTombstone=true with deletedAt present', async () => {
    await seedDoc('user_A', 'setU7', wordSetDoc('user_A', 'setU7', 1, 'op_v1'));
    const db = userContext('user_A').firestore();
    const tombstone = {
      ownerUid: 'user_A',
      entityId: 'setU7',
      entityType: 'word_set',
      remoteVersion: 2,
      lastOperationId: 'op_del',
      isTombstone: true,
      deletedAt: new Date().toISOString(),
      serverUpdatedAt: new Date().toISOString(),
    };
    await assertSucceeds(
      db.collection('users').doc('user_A').collection('word_match_sets').doc('setU7').set(tombstone)
    );
  });

  test('Update rejected: isTombstone=true but deletedAt missing', async () => {
    await seedDoc('user_A', 'setU8', wordSetDoc('user_A', 'setU8', 1, 'op_v1'));
    const db = userContext('user_A').firestore();
    const badTombstone = {
      ownerUid: 'user_A',
      entityId: 'setU8',
      entityType: 'word_set',
      remoteVersion: 2,
      lastOperationId: 'op_del',
      isTombstone: true,
      // deletedAt: missing
      serverUpdatedAt: new Date().toISOString(),
    };
    await assertFails(
      db.collection('users').doc('user_A').collection('word_match_sets').doc('setU8').set(badTombstone)
    );
  });

  // ── Delete ────────────────────────────────────────────────────────────────

  test('Physical delete is REJECTED (must use tombstone)', async () => {
    await seedDoc('user_A', 'setD1', wordSetDoc('user_A', 'setD1', 1));
    const db = userContext('user_A').firestore();
    await assertFails(
      db.collection('users').doc('user_A').collection('word_match_sets').doc('setD1').delete()
    );
  });

  // ── Cross-user isolation ──────────────────────────────────────────────────

  test('User A cannot update User B document', async () => {
    await seedDoc('user_B', 'setXB1', wordSetDoc('user_B', 'setXB1', 1));
    const db = userContext('user_A').firestore();
    const update = { ...wordSetDoc('user_B', 'setXB1', 2, 'op_evil') };
    await assertFails(
      db.collection('users').doc('user_B').collection('word_match_sets').doc('setXB1').set(update)
    );
  });

  test('User A cannot tombstone/delete User B document', async () => {
    await seedDoc('user_B', 'setXB2', wordSetDoc('user_B', 'setXB2', 1));
    const db = userContext('user_A').firestore();
    await assertFails(
      db.collection('users').doc('user_B').collection('word_match_sets').doc('setXB2').delete()
    );
  });

  test('Unauthenticated client cannot write', async () => {
    const db = unauthContext().firestore();
    await assertFails(
      db
        .collection('users')
        .doc('user_A')
        .collection('word_match_sets')
        .doc('unauth_set')
        .set(wordSetDoc('user_A', 'unauth_set', 1))
    );
  });
});

// ── outbox_receipts Tests ─────────────────────────────────────────────────────

describe('outbox_receipts', () => {
  // ── Read ──────────────────────────────────────────────────────────────────

  test('Owner can read their own receipt', async () => {
    await seedReceipt('user_A', 'op_receipt_1', receiptDoc('user_A', 'op_receipt_1', 'set_e1'));
    const db = userContext('user_A').firestore();
    await assertSucceeds(
      db.collection('users').doc('user_A').collection('outbox_receipts').doc('op_receipt_1').get()
    );
  });

  test('User B cannot read User A receipt', async () => {
    await seedReceipt('user_A', 'op_receipt_2', receiptDoc('user_A', 'op_receipt_2', 'set_e2'));
    const db = userContext('user_B').firestore();
    await assertFails(
      db.collection('users').doc('user_A').collection('outbox_receipts').doc('op_receipt_2').get()
    );
  });

  // ── Create ────────────────────────────────────────────────────────────────

  test('Owner can create valid receipt where receiptId == operationId', async () => {
    const db = userContext('user_A').firestore();
    const opId = 'op_valid_receipt';
    await assertSucceeds(
      db
        .collection('users')
        .doc('user_A')
        .collection('outbox_receipts')
        .doc(opId)
        .set(receiptDoc('user_A', opId, 'set_valid'))
    );
  });

  test('Create rejected: receiptId != operationId in document', async () => {
    const db = userContext('user_A').firestore();
    const wrongReceipt = {
      ...receiptDoc('user_A', 'op_DIFFERENT_ID', 'set_x'),
    };
    // docId = 'op_my_id' but operationId in doc = 'op_DIFFERENT_ID'
    await assertFails(
      db
        .collection('users')
        .doc('user_A')
        .collection('outbox_receipts')
        .doc('op_my_id')
        .set(wrongReceipt)
    );
  });

  test('Create rejected: ownerUid differs from auth.uid', async () => {
    const db = userContext('user_A').firestore();
    const opId = 'op_evil_receipt';
    await assertFails(
      db
        .collection('users')
        .doc('user_A')
        .collection('outbox_receipts')
        .doc(opId)
        .set(receiptDoc('user_B', opId, 'set_y')) // ownerUid=user_B, auth=user_A
    );
  });

  test('User B cannot create receipt under User A path', async () => {
    const db = userContext('user_B').firestore();
    const opId = 'op_b_on_a';
    await assertFails(
      db
        .collection('users')
        .doc('user_A')  // user_A's subcollection
        .collection('outbox_receipts')
        .doc(opId)
        .set(receiptDoc('user_A', opId, 'set_z'))
    );
  });

  test('Create rejected: appliedRemoteVersion is 0 (not positive)', async () => {
    const db = userContext('user_A').firestore();
    const opId = 'op_zero_ver';
    const bad = { ...receiptDoc('user_A', opId, 'set_w'), appliedRemoteVersion: 0 };
    await assertFails(
      db.collection('users').doc('user_A').collection('outbox_receipts').doc(opId).set(bad)
    );
  });

  // ── Update & Delete (immutability) ────────────────────────────────────────

  test('Receipt update is REJECTED (immutable)', async () => {
    const opId = 'op_immutable';
    await seedReceipt('user_A', opId, receiptDoc('user_A', opId, 'set_m1'));
    const db = userContext('user_A').firestore();
    await assertFails(
      db
        .collection('users')
        .doc('user_A')
        .collection('outbox_receipts')
        .doc(opId)
        .update({ appliedRemoteVersion: 99 })
    );
  });

  test('Receipt delete is REJECTED (immutable)', async () => {
    const opId = 'op_no_delete';
    await seedReceipt('user_A', opId, receiptDoc('user_A', opId, 'set_m2'));
    const db = userContext('user_A').firestore();
    await assertFails(
      db.collection('users').doc('user_A').collection('outbox_receipts').doc(opId).delete()
    );
  });
});
