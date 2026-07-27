/**
 * Sprint 10C – Cloud Function unit tests
 *
 * Strategy:
 *   - Validation-only tests (no Firestore) run directly.
 *   - Firestore behaviour tests mock firebase-admin's Firestore through
 *     jest.mock so no emulator is required.
 *
 * Tests are grouped by concern:
 *   1. Authentication / UID derivation
 *   2. Field allowlist / spoof-rejection
 *   3. Input validation (contentId, contentVersion, contentType, category,
 *      comment, locale, appVersion)
 *   4. Firestore document fields (correct structure written)
 *   5. Cooldown / duplicate-submission behaviour
 *   6. Server-controlled fields (UID, timestamp, status)
 *   7. Privacy (no email / displayName persisted)
 */

// ── Jest module mock setup ───────────────────────────────────────────────────

// We need to mock firebase-admin BEFORE importing the module under test.
// The mock exposes capturable stubs so we can inspect what the function wrote.

let txGetResult: { exists: boolean; data: () => Record<string, unknown> | undefined } = {
  exists: false,
  data: () => undefined,
};
const txSetCalls: Array<{ ref: string; data: Record<string, unknown> }> = [];
const txCreateCalls: Array<{ ref: string; data: Record<string, unknown> }> = [];

const mockTransaction = {
  get: jest.fn(async () => txGetResult),
  set: jest.fn((ref: { path: string }, data: Record<string, unknown>) => {
    txSetCalls.push({ ref: ref.path, data });
  }),
  create: jest.fn((ref: { path: string }, data: Record<string, unknown>) => {
    txCreateCalls.push({ ref: ref.path, data });
  }),
};

const mockRunTransaction = jest.fn(async (fn: (tx: typeof mockTransaction) => Promise<void>) => {
  await fn(mockTransaction);
});

const mockCollection = jest.fn(() => ({
  doc: jest.fn(() => ({ path: 'educational_content_reports/new-id-001', id: 'new-id-001' })),
}));

const mockDoc = jest.fn((path: string) => ({ path, id: path.split('/').pop() }));

jest.mock('firebase-admin', () => {
  const Timestamp = {
    fromMillis: jest.fn((ms: number) => ({ toMillis: () => ms, _type: 'Timestamp' })),
  };
  const FieldValue = {
    serverTimestamp: jest.fn(() => ({ _type: 'ServerTimestamp' })),
  };
  const mockFirestore = () => ({
    doc: mockDoc,
    collection: mockCollection,
    runTransaction: mockRunTransaction,
  });
  // Firestore constructor props
  Object.assign(mockFirestore, { Timestamp, FieldValue });
  return {
    apps: ['dummy-app'],
    initializeApp: jest.fn(),
    firestore: mockFirestore,
  };
});

// ── Import module under test (after mock setup) ──────────────────────────────

import { submitEducationalContentReport, REPORT_POLICY } from '../educational_content_reporting';

// ── Helpers ──────────────────────────────────────────────────────────────────

function makeValidInput(overrides: Record<string, unknown> = {}) {
  return {
    contentId: 'edu.item.000001',
    contentVersion: 1,
    contentType: 'irregular_verb',
    category: 'typo',
    ...overrides,
  };
}

function resetState() {
  txGetResult = { exists: false, data: () => undefined };
  txSetCalls.length = 0;
  txCreateCalls.length = 0;
  mockTransaction.get.mockClear();
  mockTransaction.set.mockClear();
  mockTransaction.create.mockClear();
  mockRunTransaction.mockClear();
}

// ── 1. Authentication / UID derivation ───────────────────────────────────────

describe('1. Authentication and UID derivation', () => {
  beforeEach(resetState);

  it('rejects unauthenticated request', async () => {
    await expect(
      submitEducationalContentReport(undefined, makeValidInput())
    ).rejects.toThrow('authentication-required');
  });

  it('uses UID from auth context, not from client payload', async () => {
    // Even if client sends a spoofed uid field it should be rejected by onlyKeys
    await expect(
      submitEducationalContentReport(
        { uid: 'real-uid' },
        { ...makeValidInput(), uid: 'attacker-uid' }
      )
    ).rejects.toThrow('invalid-request'); // unknown field rejected

    // But with no uid field, the document is created with the auth uid
    resetState();
    await submitEducationalContentReport({ uid: 'real-uid' }, makeValidInput());
    expect(txCreateCalls.length).toBe(1);
    expect(txCreateCalls[0].data.reporterUid).toBe('real-uid');
  });
});

// ── 2. Field allowlist / spoof-rejection ─────────────────────────────────────

describe('2. Field allowlist – client spoof rejection', () => {
  beforeEach(resetState);

  it('rejects client-supplied uid field', async () => {
    await expect(
      submitEducationalContentReport(
        { uid: 'user-1' },
        { ...makeValidInput(), uid: 'attacker' }
      )
    ).rejects.toThrow('invalid-request');
  });

  it('rejects client-supplied status field', async () => {
    await expect(
      submitEducationalContentReport(
        { uid: 'user-1' },
        { ...makeValidInput(), status: 'resolved' }
      )
    ).rejects.toThrow('invalid-request');
  });

  it('rejects client-supplied reporterUid field', async () => {
    await expect(
      submitEducationalContentReport(
        { uid: 'user-1' },
        { ...makeValidInput(), reporterUid: 'attacker' }
      )
    ).rejects.toThrow('invalid-request');
  });

  it('rejects client-supplied createdAt (timestamp spoofing)', async () => {
    await expect(
      submitEducationalContentReport(
        { uid: 'user-1' },
        { ...makeValidInput(), createdAt: '2000-01-01T00:00:00Z' }
      )
    ).rejects.toThrow('invalid-request');
  });

  it('rejects client-supplied moderatorNote admin field', async () => {
    await expect(
      submitEducationalContentReport(
        { uid: 'user-1' },
        { ...makeValidInput(), moderatorNote: 'approved' }
      )
    ).rejects.toThrow('invalid-request');
  });
});

// ── 3. Input validation ───────────────────────────────────────────────────────

describe('3. Input validation', () => {
  beforeEach(resetState);

  it('rejects invalid contentId pattern', async () => {
    await expect(
      submitEducationalContentReport({ uid: 'u' }, makeValidInput({ contentId: 'invalid!@#' }))
    ).rejects.toThrow('invalid-content-id');
  });

  it('rejects non-edu contentId prefix', async () => {
    await expect(
      submitEducationalContentReport({ uid: 'u' }, makeValidInput({ contentId: 'item.000001' }))
    ).rejects.toThrow('invalid-content-id');
  });

  it('rejects contentId longer than 128 chars', async () => {
    await expect(
      submitEducationalContentReport({ uid: 'u' }, makeValidInput({ contentId: 'edu.' + 'x'.repeat(130) }))
    ).rejects.toThrow('invalid-content-id');
  });

  it('rejects zero contentVersion', async () => {
    await expect(
      submitEducationalContentReport({ uid: 'u' }, makeValidInput({ contentVersion: 0 }))
    ).rejects.toThrow('invalid-content-version');
  });

  it('rejects negative contentVersion', async () => {
    await expect(
      submitEducationalContentReport({ uid: 'u' }, makeValidInput({ contentVersion: -1 }))
    ).rejects.toThrow('invalid-content-version');
  });

  it('rejects fractional contentVersion', async () => {
    await expect(
      submitEducationalContentReport({ uid: 'u' }, makeValidInput({ contentVersion: 1.5 }))
    ).rejects.toThrow('invalid-content-version');
  });

  it('rejects missing contentType', async () => {
    const { contentType: _, ...input } = makeValidInput() as Record<string, unknown>;
    await expect(
      submitEducationalContentReport({ uid: 'u' }, input)
    ).rejects.toThrow('invalid-content');
  });

  it('rejects contentType longer than 64 chars', async () => {
    await expect(
      submitEducationalContentReport({ uid: 'u' }, makeValidInput({ contentType: 'x'.repeat(65) }))
    ).rejects.toThrow('invalid-content');
  });

  it('rejects unsupported category', async () => {
    await expect(
      submitEducationalContentReport({ uid: 'u' }, makeValidInput({ category: 'offensive_rant' }))
    ).rejects.toThrow('invalid-category');
  });

  it('rejects old category names that no longer exist', async () => {
    for (const old of ['translation_error', 'grammar_error', 'example_sentence_error', 'inappropriate_content', 'outdated_content']) {
      await expect(
        submitEducationalContentReport({ uid: 'u' }, makeValidInput({ category: old }))
      ).rejects.toThrow('invalid-category');
      resetState();
    }
  });

  it('accepts all six valid categories', async () => {
    const cats = ['typo', 'incorrect_answer', 'unclear_explanation', 'audio_issue', 'wrong_level_or_category', 'other'];
    for (const category of cats) {
      resetState();
      await expect(
        submitEducationalContentReport({ uid: 'u' }, makeValidInput({ category }))
      ).resolves.toEqual({ success: true, duplicate: false });
    }
  });

  it('rejects comment longer than 500 chars', async () => {
    await expect(
      submitEducationalContentReport({ uid: 'u' }, makeValidInput({ comment: 'a'.repeat(501) }))
    ).rejects.toThrow('invalid-content');
  });

  it('accepts empty comment (optional field)', async () => {
    await expect(
      submitEducationalContentReport({ uid: 'u' }, makeValidInput({ comment: '' }))
    ).resolves.toEqual({ success: true, duplicate: false });
  });

  it('rejects locale longer than 16 chars', async () => {
    await expect(
      submitEducationalContentReport({ uid: 'u' }, makeValidInput({ locale: 'this-is-way-too-long-for-locale' }))
    ).rejects.toThrow('invalid-content');
  });

  it('accepts valid locale string', async () => {
    resetState();
    await expect(
      submitEducationalContentReport({ uid: 'u' }, makeValidInput({ locale: 'tr' }))
    ).resolves.toEqual({ success: true, duplicate: false });
    expect(txCreateCalls[0].data.locale).toBe('tr');
  });

  it('accepts valid appVersion string', async () => {
    resetState();
    await expect(
      submitEducationalContentReport({ uid: 'u' }, makeValidInput({ appVersion: '2.3.1' }))
    ).resolves.toEqual({ success: true, duplicate: false });
    expect(txCreateCalls[0].data.appVersion).toBe('2.3.1');
  });

  it('rejects appVersion longer than 32 chars', async () => {
    await expect(
      submitEducationalContentReport({ uid: 'u' }, makeValidInput({ appVersion: 'v'.repeat(33) }))
    ).rejects.toThrow('invalid-content');
  });
});

// ── 4. Firestore document field verification ─────────────────────────────────

describe('4. Firestore document field verification', () => {
  beforeEach(resetState);

  it('writes correct report document fields', async () => {
    await submitEducationalContentReport(
      { uid: 'verified-uid' },
      makeValidInput({ comment: 'Test comment', locale: 'tr', appVersion: '1.2.3' })
    );
    expect(txCreateCalls.length).toBe(1);
    const doc = txCreateCalls[0].data;
    expect(doc.reporterUid).toBe('verified-uid');
    expect(doc.contentId).toBe('edu.item.000001');
    expect(doc.contentVersion).toBe(1);
    expect(doc.contentType).toBe('irregular_verb');
    expect(doc.category).toBe('typo');
    expect(doc.comment).toBe('Test comment');
    expect(doc.locale).toBe('tr');
    expect(doc.appVersion).toBe('1.2.3');
    expect(doc.status).toBe('open');
    expect(doc.createdAt).toEqual({ _type: 'ServerTimestamp' }); // server timestamp
  });

  it('uses server timestamp for createdAt (not client time)', async () => {
    await submitEducationalContentReport({ uid: 'u' }, makeValidInput());
    const doc = txCreateCalls[0].data;
    // Server timestamp sentinel — not a numeric Date.now() value
    expect(doc.createdAt).toMatchObject({ _type: 'ServerTimestamp' });
    // createdAt must NOT be a plain number or string
    expect(typeof doc.createdAt).not.toBe('number');
    expect(typeof doc.createdAt).not.toBe('string');
  });

  it('does NOT persist email or displayName', async () => {
    await submitEducationalContentReport({ uid: 'u' }, makeValidInput());
    const doc = txCreateCalls[0].data;
    expect(doc).not.toHaveProperty('email');
    expect(doc).not.toHaveProperty('displayName');
    expect(doc).not.toHaveProperty('phoneNumber');
  });

  it('sets status to open server-side', async () => {
    await submitEducationalContentReport({ uid: 'u' }, makeValidInput());
    expect(txCreateCalls[0].data.status).toBe('open');
  });

  it('stores null comment when comment is absent', async () => {
    await submitEducationalContentReport({ uid: 'u' }, makeValidInput());
    expect(txCreateCalls[0].data.comment).toBeNull();
  });

  it('defaults locale to en when omitted', async () => {
    await submitEducationalContentReport({ uid: 'u' }, makeValidInput());
    expect(txCreateCalls[0].data.locale).toBe('en');
  });

  it('defaults appVersion to 1.0.0 when omitted', async () => {
    await submitEducationalContentReport({ uid: 'u' }, makeValidInput());
    expect(txCreateCalls[0].data.appVersion).toBe('1.0.0');
  });
});

// ── 5. Cooldown / duplicate-submission ───────────────────────────────────────

describe('5. Cooldown and duplicate-submission behaviour', () => {
  beforeEach(resetState);

  it('allows first submission (no prior cooldown)', async () => {
    txGetResult = { exists: false, data: () => undefined };
    const result = await submitEducationalContentReport({ uid: 'u' }, makeValidInput());
    expect(result).toEqual({ success: true, duplicate: false });
    expect(txCreateCalls.length).toBe(1);
    expect(txSetCalls.length).toBe(1); // cooldown written
  });

  it('rejects duplicate submission within cooldown window with already-exists', async () => {
    // Simulate a prior submission 30s ago (within 60s window)
    const recentTimestamp = { toMillis: () => Date.now() - 30_000, _type: 'Timestamp' };
    txGetResult = { exists: true, data: () => ({ createdAt: recentTimestamp }) };
    await expect(
      submitEducationalContentReport({ uid: 'u' }, makeValidInput())
    ).rejects.toThrow('report-already-submitted');
    // No new report document written
    expect(txCreateCalls.length).toBe(0);
  });

  it('duplicate submission within cooldown returns already-exists error code', async () => {
    const recentTimestamp = { toMillis: () => Date.now() - 10_000, _type: 'Timestamp' };
    txGetResult = { exists: true, data: () => ({ createdAt: recentTimestamp }) };
    try {
      await submitEducationalContentReport({ uid: 'u' }, makeValidInput());
      fail('Expected error not thrown');
    } catch (e: any) {
      expect(e.code).toBe('already-exists');
      expect(e.message).toBe('report-already-submitted');
    }
  });

  it('allows legitimate re-submission after cooldown expires', async () => {
    // Simulate prior submission 90s ago (beyond 60s cooldown)
    const expiredTimestamp = { toMillis: () => Date.now() - 90_000, _type: 'Timestamp' };
    txGetResult = { exists: true, data: () => ({ createdAt: expiredTimestamp }) };
    const result = await submitEducationalContentReport({ uid: 'u' }, makeValidInput());
    expect(result).toEqual({ success: true, duplicate: false });
    expect(txCreateCalls.length).toBe(1);
  });

  it('double submission in concurrent transaction writes only one report', async () => {
    // The first call succeeds; the second is blocked by cooldown doc written by tx.set
    // We simulate this by having the second call see a fresh cooldown doc.
    txGetResult = { exists: false, data: () => undefined };
    const result1 = await submitEducationalContentReport({ uid: 'u' }, makeValidInput());
    expect(result1.success).toBe(true);
    expect(txCreateCalls.length).toBe(1);

    // Now simulate that the cooldown doc was written (within window)
    const now = Date.now();
    txGetResult = { exists: true, data: () => ({ createdAt: { toMillis: () => now - 1000 } }) };
    txSetCalls.length = 0;
    txCreateCalls.length = 0;

    await expect(
      submitEducationalContentReport({ uid: 'u' }, makeValidInput())
    ).rejects.toThrow('report-already-submitted');
    // Still only 0 new reports written in this second attempt
    expect(txCreateCalls.length).toBe(0);
  });

  it('cooldown key is per-uid per-contentId per-category', async () => {
    txGetResult = { exists: false, data: () => undefined };
    // First: uid=u, contentId=edu.item.000001, category=typo
    await submitEducationalContentReport({ uid: 'u' }, makeValidInput({ category: 'typo' }));
    const cooldownPath1 = txSetCalls[0].ref;

    resetState();
    // Different category → different cooldown key
    await submitEducationalContentReport({ uid: 'u' }, makeValidInput({ category: 'audio_issue' }));
    const cooldownPath2 = txSetCalls[0].ref;

    expect(cooldownPath1).not.toBe(cooldownPath2);
    expect(cooldownPath1).toContain('typo');
    expect(cooldownPath2).toContain('audio_issue');
  });
});

// ── 6. Return value ──────────────────────────────────────────────────────────

describe('6. Return value', () => {
  beforeEach(resetState);

  it('returns { success: true, duplicate: false } on success', async () => {
    const result = await submitEducationalContentReport({ uid: 'u' }, makeValidInput());
    expect(result).toEqual({ success: true, duplicate: false });
  });
});
