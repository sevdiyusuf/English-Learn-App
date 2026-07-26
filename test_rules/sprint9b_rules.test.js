const {
  initializeTestEnvironment,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { readFileSync } = require('fs');
const { resolve } = require('path');

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-sprint9b',
    firestore: {
      rules: readFileSync(resolve(__dirname, '../firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

afterEach(() => testEnv.clearFirestore());
afterAll(() => testEnv.cleanup());

test('notification token documents deny direct owner and unrelated access', async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc('users/user-a/notification_tokens/hash-a').set({
      token: 'secret-token',
      enabled: true,
    });
  });
  const owner = testEnv.authenticatedContext('user-a').firestore();
  const unrelated = testEnv.authenticatedContext('user-b').firestore();

  await assertFails(owner.doc('users/user-a/notification_tokens/hash-a').get());
  await assertFails(
    owner.doc('users/user-a/notification_tokens/hash-new').set({
      token: 'forged-token',
      enabled: true,
    }),
  );
  await assertFails(
    unrelated.doc('users/user-a/notification_tokens/hash-a').get(),
  );
  await assertFails(
    unrelated.doc('users/user-a/notification_tokens/hash-a').delete(),
  );
});

test('notification delivery idempotency records are private and server-owned', async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc('notification_deliveries/invite-1').set({
      recipientUid: 'user-a',
      status: 'completed',
    });
  });
  const user = testEnv.authenticatedContext('user-a').firestore();
  await assertFails(user.doc('notification_deliveries/invite-1').get());
  await assertFails(
    user.doc('notification_deliveries/invite-2').set({
      recipientUid: 'user-a',
      status: 'completed',
    }),
  );
});
