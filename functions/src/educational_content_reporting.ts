import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';

if (admin.apps.length === 0) admin.initializeApp();

const db = admin.firestore();

export const REPORT_POLICY = {
  cooldownMs: 60 * 1000,
} as const;

const validCategories = new Set([
  'typo',
  'incorrect_answer',
  'unclear_explanation',
  'audio_issue',
  'wrong_level_or_category',
  'other',
]);

const contentIdRegex = /^edu\.[a-z0-9][a-z0-9._-]*$/;

function requireAuth(auth: { uid: string } | undefined): string {
  if (!auth) throw new HttpsError('unauthenticated', 'authentication-required');
  return auth.uid;
}

function requireObject(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new HttpsError('invalid-argument', 'invalid-request');
  }
  return value as Record<string, unknown>;
}

function onlyKeys(data: Record<string, unknown>, keys: string[]) {
  if (Object.keys(data).some((key) => !keys.includes(key))) {
    throw new HttpsError('invalid-argument', 'invalid-request');
  }
}

function validateString(value: unknown, maxLength: number, required = true): string {
  if (value === undefined || value === null) {
    if (required) throw new HttpsError('invalid-argument', 'invalid-content');
    return '';
  }
  if (typeof value !== 'string') throw new HttpsError('invalid-argument', 'invalid-content');
  const normalized = value.normalize('NFKC').replace(/[\u200B-\u200D\uFEFF]/g, '');
  if (/[\u0000-\u001F\u007F]/.test(normalized)) {
    throw new HttpsError('invalid-argument', 'invalid-content');
  }
  const trimmed = normalized.trim().replace(/\s+/g, ' ');
  if (required && !trimmed) throw new HttpsError('invalid-argument', 'invalid-content');
  if (trimmed.length > maxLength) throw new HttpsError('invalid-argument', 'invalid-content');
  return trimmed;
}

export async function submitEducationalContentReport(
  auth: { uid: string } | undefined,
  input: unknown
) {
  const uid = requireAuth(auth);
  const data = requireObject(input);

  onlyKeys(data, [
    'contentId',
    'contentVersion',
    'contentType',
    'category',
    'comment',
    'locale',
    'appVersion',
  ]);

  const contentId = typeof data.contentId === 'string' ? data.contentId.trim() : '';
  if (!contentId || contentId.length > 128 || !contentIdRegex.test(contentId)) {
    throw new HttpsError('invalid-argument', 'invalid-content-id');
  }

  const contentVersion = data.contentVersion;
  if (typeof contentVersion !== 'number' || !Number.isInteger(contentVersion) || contentVersion <= 0) {
    throw new HttpsError('invalid-argument', 'invalid-content-version');
  }

  const contentType = validateString(data.contentType, 64, true);

  const category = typeof data.category === 'string' ? data.category.trim() : '';
  if (!category || !validCategories.has(category)) {
    throw new HttpsError('invalid-argument', 'invalid-category');
  }

  const comment = validateString(data.comment, 500, false);
  const locale = validateString(data.locale, 16, false) || 'en';
  const appVersion = validateString(data.appVersion, 32, false) || '1.0.0';

  const safeContentIdKey = contentId.replace(/[^a-zA-Z0-9._-]/g, '_');
  const cooldownRef = db.doc(`educational_content_report_cooldowns/${uid}_${safeContentIdKey}_${category}`);

  await db.runTransaction(async (tx) => {
    const prior = await tx.get(cooldownRef);
    const priorAt = prior.data()?.createdAt as admin.firestore.Timestamp | undefined;
    const nowMs = Date.now();
    if (priorAt && nowMs - priorAt.toMillis() < REPORT_POLICY.cooldownMs) {
      throw new HttpsError('already-exists', 'report-already-submitted');
    }

    tx.set(cooldownRef, {
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: admin.firestore.Timestamp.fromMillis(nowMs + REPORT_POLICY.cooldownMs),
    });

    const reportRef = db.collection('educational_content_reports').doc();
    tx.create(reportRef, {
      reporterUid: uid,
      contentId,
      contentVersion,
      contentType,
      category,
      comment: comment || null,
      locale,
      appVersion,
      status: 'open',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return { success: true, duplicate: false };
}
