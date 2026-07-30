const {
  initializeTestEnvironment,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { readFileSync } = require('fs');
const { resolve } = require('path');

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-sprint10c',
    firestore: {
      rules: readFileSync(resolve(__dirname, '../firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

afterEach(() => testEnv.clearFirestore());
afterAll(() => testEnv.cleanup());

// ── educational_content_reports ──────────────────────────────────────────────

test('unauthenticated direct write to educational_content_reports is denied', async () => {
  const unauthed = testEnv.unauthenticatedContext().firestore();
  await assertFails(
    unauthed.collection('educational_content_reports').doc('r1').set({
      contentId: 'edu.item.000001',
      category: 'typo',
    }),
  );
});

test('authenticated direct create to educational_content_reports is denied', async () => {
  const user = testEnv.authenticatedContext('user-a').firestore();
  await assertFails(
    user.collection('educational_content_reports').doc('r1').set({
      contentId: 'edu.item.000001',
      contentVersion: 1,
      category: 'typo',
      reporterUid: 'user-a',
    }),
  );
});

test('authenticated update of educational_content_reports is denied', async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc('educational_content_reports/r1').set({
      contentId: 'edu.item.000001',
      category: 'typo',
      status: 'open',
    });
  });
  const user = testEnv.authenticatedContext('user-a').firestore();
  await assertFails(
    user.doc('educational_content_reports/r1').update({ status: 'resolved' }),
  );
});

test('authenticated delete of educational_content_reports is denied', async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc('educational_content_reports/r1').set({
      contentId: 'edu.item.000001',
      status: 'open',
    });
  });
  const user = testEnv.authenticatedContext('user-a').firestore();
  await assertFails(user.doc('educational_content_reports/r1').delete());
});

test('authenticated read of educational_content_reports is denied', async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc('educational_content_reports/r1').set({
      contentId: 'edu.item.000001',
      reporterUid: 'user-a',
    });
  });
  const owner = testEnv.authenticatedContext('user-a').firestore();
  await assertFails(owner.doc('educational_content_reports/r1').get());
});

test('spoofed reporterUid write attempt to educational_content_reports is denied', async () => {
  const attacker = testEnv.authenticatedContext('attacker').firestore();
  await assertFails(
    attacker.collection('educational_content_reports').doc('r2').set({
      reporterUid: 'victim-uid',
      contentId: 'edu.item.000001',
      status: 'open',
      category: 'other',
    }),
  );
});

test('admin/status field manipulation attempt is denied', async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc('educational_content_reports/r3').set({
      status: 'open',
      contentId: 'edu.item.000001',
    });
  });
  const user = testEnv.authenticatedContext('user-b').firestore();
  await assertFails(
    user.doc('educational_content_reports/r3').update({ status: 'resolved', moderatorNote: 'approved' }),
  );
});

// ── educational_content_report_cooldowns ────────────────────────────────────

test('unauthenticated direct write to cooldowns is denied', async () => {
  const unauthed = testEnv.unauthenticatedContext().firestore();
  await assertFails(
    unauthed.doc('educational_content_report_cooldowns/user-a_edu.item.000001_typo').set({
      createdAt: new Date(),
    }),
  );
});

test('authenticated direct write to cooldowns is denied', async () => {
  const user = testEnv.authenticatedContext('user-a').firestore();
  await assertFails(
    user.doc('educational_content_report_cooldowns/user-a_edu.item.000001_typo').set({
      createdAt: new Date(),
    }),
  );
});

test('authenticated read of cooldowns is denied', async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc('educational_content_report_cooldowns/cooldown-1').set({
      createdAt: new Date(),
    });
  });
  const user = testEnv.authenticatedContext('user-a').firestore();
  await assertFails(user.doc('educational_content_report_cooldowns/cooldown-1').get());
});
