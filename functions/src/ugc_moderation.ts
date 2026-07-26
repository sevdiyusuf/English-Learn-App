import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';

// This module is imported before index.ts executes its bootstrap. The guard
// also keeps isolated Jest imports usable without creating a second app.
if (admin.apps.length === 0) admin.initializeApp();

/**
 * Sprint 8's single source of truth.  Bump both versions only after the
 * document drafts have been reviewed by the product owner/legal reviewer.
 */
export const UGC_POLICY = {
  termsVersion: '2026-07-26',
  guidelinesVersion: '2026-07-26',
  reportCooldownMs: 60 * 1000,
  socialRecipientCooldownMs: 60 * 1000,
  socialSenderWindowMs: 60 * 60 * 1000,
  socialSenderWindowMax: 12,
} as const;

const db = admin.firestore();
const reasons = new Set([
  'spam', 'harassment_or_bullying', 'hateful_or_abusive',
  'inappropriate_content', 'impersonation', 'privacy_violation', 'other',
]);
const forbiddenWholeWords = new Set(['porn', 'nude', 'scam']);

export type PublicPair = { front: string; back: string };

export function normalizePublicText(value: unknown): string {
  if (typeof value !== 'string') throw new HttpsError('invalid-argument', 'invalid-content');
  // NFKC handles compatibility forms, then remove invisible format controls.
  const normalized = value.normalize('NFKC').replace(/[\u200B-\u200D\uFEFF]/g, '');
  if (/[\u0000-\u001F\u007F]/.test(normalized)) {
    throw new HttpsError('invalid-argument', 'invalid-content');
  }
  return normalized.trim().replace(/\s+/g, ' ');
}

export function validatePublicText(value: unknown, maxLength: number, required = true): string {
  const text = normalizePublicText(value);
  if ((required && !text) || text.length > maxLength) {
    throw new HttpsError('invalid-argument', 'invalid-content');
  }
  // Token matching avoids blocking harmless educational terms by substring.
  const tokens = text.toLocaleLowerCase('tr-TR').split(/[^\p{L}\p{N}]+/u);
  if (tokens.some((token) => forbiddenWholeWords.has(token))) {
    throw new HttpsError('invalid-argument', 'content-not-allowed');
  }
  return text;
}

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

export async function requireCurrentAcceptance(uid: string): Promise<void> {
  const snap = await db.doc(`users/${uid}/ugc_acceptance/current`).get();
  const data = snap.data();
  if (!data || data.termsVersion !== UGC_POLICY.termsVersion ||
      data.guidelinesVersion !== UGC_POLICY.guidelinesVersion) {
    throw new HttpsError('failed-precondition', 'ugc-acceptance-required');
  }
}

export async function acceptUgcPolicy(auth: { uid: string } | undefined, input: unknown) {
  const uid = requireAuth(auth);
  const data = requireObject(input);
  onlyKeys(data, ['termsVersion', 'guidelinesVersion', 'accepted']);
  if (data.accepted !== true || data.termsVersion !== UGC_POLICY.termsVersion ||
      data.guidelinesVersion !== UGC_POLICY.guidelinesVersion) {
    throw new HttpsError('failed-precondition', 'current-policy-acceptance-required');
  }
  const ref = db.doc(`users/${uid}/ugc_acceptance/current`);
  await db.runTransaction(async (tx) => {
    const existing = await tx.get(ref);
    const old = existing.data();
    if (old?.termsVersion === UGC_POLICY.termsVersion && old?.guidelinesVersion === UGC_POLICY.guidelinesVersion) return;
    tx.set(ref, {
      termsVersion: UGC_POLICY.termsVersion,
      guidelinesVersion: UGC_POLICY.guidelinesVersion,
      acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
  return { accepted: true, termsVersion: UGC_POLICY.termsVersion, guidelinesVersion: UGC_POLICY.guidelinesVersion };
}

async function blockedEitherWay(uid: string, otherUid: string): Promise<boolean> {
  const [a, b] = await Promise.all([
    db.doc(`users/${uid}/blocks/${otherUid}`).get(),
    db.doc(`users/${otherUid}/blocks/${uid}`).get(),
  ]);
  return a.exists || b.exists;
}

export async function blockUser(auth: { uid: string } | undefined, input: unknown, unblock = false) {
  const uid = requireAuth(auth);
  const data = requireObject(input); onlyKeys(data, ['targetUid']);
  const targetUid = typeof data.targetUid === 'string' ? data.targetUid.trim() : '';
  if (!targetUid || targetUid.length > 128 || targetUid.includes('/') || targetUid === uid) {
    throw new HttpsError('invalid-argument', 'invalid-target');
  }
  const blockRef = db.doc(`users/${uid}/blocks/${targetUid}`);
  if (unblock) { await blockRef.delete(); return { blocked: false }; }
  await db.runTransaction(async (tx) => {
    const outgoing = await tx.get(db.collection('friend_requests').where('fromUid', '==', uid));
    const incoming = await tx.get(db.collection('friend_requests').where('fromUid', '==', targetUid));
    // Invitations are stored below the recipient; both directions are removed.
    const ownInvites = await tx.get(db.collection(`users/${uid}/invitations`).where('fromUid', '==', targetUid));
    const targetInvites = await tx.get(db.collection(`users/${targetUid}/invitations`).where('fromUid', '==', uid));
    tx.set(blockRef, { blockedUid: targetUid, createdAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
    tx.delete(db.doc(`friendships/${uid}/friends/${targetUid}`));
    tx.delete(db.doc(`friendships/${targetUid}/friends/${uid}`));
    for (const doc of [...outgoing.docs, ...incoming.docs]) {
      if (doc.data().toUid === targetUid || doc.data().toUid === uid) tx.delete(doc.ref);
    }
    ownInvites.docs.forEach((doc) => tx.delete(doc.ref));
    targetInvites.docs.forEach((doc) => tx.delete(doc.ref));
  });
  return { blocked: true };
}

async function consumeSocialRateLimit(tx: FirebaseFirestore.Transaction, senderUid: string, recipientUid: string, kind: string) {
  const now = admin.firestore.Timestamp.now();
  const ref = db.doc(`social_rate_limits/${senderUid}_${recipientUid}_${kind}`);
  const snap = await tx.get(ref); const old = snap.data();
  const lastAt = old?.lastAt as FirebaseFirestore.Timestamp | undefined;
  const windowStartedAt = old?.windowStartedAt as FirebaseFirestore.Timestamp | undefined;
  const windowFresh = !!windowStartedAt && now.toMillis() - windowStartedAt.toMillis() < UGC_POLICY.socialSenderWindowMs;
  const count = windowFresh && typeof old?.count === 'number' ? old.count : 0;
  if (lastAt && now.toMillis() - lastAt.toMillis() < UGC_POLICY.socialRecipientCooldownMs || count >= UGC_POLICY.socialSenderWindowMax) {
    throw new HttpsError('resource-exhausted', 'interaction-rate-limited');
  }
  tx.set(ref, { lastAt: now, windowStartedAt: windowFresh ? windowStartedAt : now, count: count + 1,
    expiresAt: admin.firestore.Timestamp.fromMillis(now.toMillis() + UGC_POLICY.socialSenderWindowMs) });
}

export async function createFriendRequest(auth: { uid: string } | undefined, input: unknown) {
  const uid = requireAuth(auth); const data = requireObject(input); onlyKeys(data, ['targetCode']);
  const targetCode = validatePublicText(data.targetCode, 32).toUpperCase();
  const targetSnap = await db.collection('users').where('userCode', '==', targetCode).limit(1).get();
  if (targetSnap.empty || targetSnap.docs[0].id === uid) throw new HttpsError('failed-precondition', 'interaction-unavailable');
  const target = targetSnap.docs[0]; const targetUid = target.id;
  if (await blockedEitherWay(uid, targetUid)) throw new HttpsError('failed-precondition', 'interaction-unavailable');
  await db.runTransaction(async (tx) => {
    const [senderBlock, targetBlock, existing, sender] = await Promise.all([
      tx.get(db.doc(`users/${uid}/blocks/${targetUid}`)),
      tx.get(db.doc(`users/${targetUid}/blocks/${uid}`)),
      tx.get(db.collection('friend_requests').where('fromUid', '==', uid).where('toUid', '==', targetUid).where('status', '==', 'pending')),
      tx.get(db.doc(`users/${uid}`)),
    ]);
    if (senderBlock.exists || targetBlock.exists || !existing.empty) {
      throw new HttpsError('failed-precondition', 'interaction-unavailable');
    }
    await consumeSocialRateLimit(tx, uid, targetUid, 'friend_request');
    tx.create(db.collection('friend_requests').doc(), { fromUid: uid, toUid: targetUid, status: 'pending',
      fromDisplayName: sender.data()?.displayName ?? null, fromUserCode: sender.data()?.userCode ?? null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(), updatedAt: admin.firestore.FieldValue.serverTimestamp() });
  });
  return { success: true };
}

export async function resolveFriendRequest(auth: { uid: string } | undefined, input: unknown) {
  const uid = requireAuth(auth); const data = requireObject(input); onlyKeys(data, ['requestId', 'action']);
  const requestId = typeof data.requestId === 'string' ? data.requestId.trim() : '';
  const action = data.action === 'reject' || data.action === 'cancel' ? data.action : '';
  if (!requestId || !action) throw new HttpsError('invalid-argument', 'invalid-request');
  const ref = db.doc(`friend_requests/${requestId}`);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref); const request = snap.data();
    if (!snap.exists || request?.status !== 'pending' ||
      (action === 'reject' && request.toUid !== uid) || (action === 'cancel' && request.fromUid !== uid)) {
      throw new HttpsError('failed-precondition', 'interaction-unavailable');
    }
    tx.update(ref, { status: action === 'reject' ? 'rejected' : 'cancelled', updatedAt: admin.firestore.FieldValue.serverTimestamp() });
  });
  return { success: true };
}

export async function createInvitation(auth: { uid: string } | undefined, input: unknown) {
  const uid = requireAuth(auth); const data = requireObject(input); onlyKeys(data, ['toUid', 'roomId', 'gameType']);
  const toUid = typeof data.toUid === 'string' ? data.toUid.trim() : '';
  const roomId = typeof data.roomId === 'string' ? data.roomId.trim() : '';
  const gameType = data.gameType === 'word_battle' || data.gameType === 'grammar_arena' ? data.gameType : '';
  if (!toUid || !roomId || !gameType || toUid === uid) throw new HttpsError('invalid-argument', 'invalid-request');
  if (await blockedEitherWay(uid, toUid)) throw new HttpsError('failed-precondition', 'interaction-unavailable');
  await db.runTransaction(async (tx) => {
    const [senderBlock, recipientBlock, sender] = await Promise.all([
      tx.get(db.doc(`users/${uid}/blocks/${toUid}`)),
      tx.get(db.doc(`users/${toUid}/blocks/${uid}`)),
      tx.get(db.doc(`users/${uid}`)),
    ]);
    if (senderBlock.exists || recipientBlock.exists) {
      throw new HttpsError('failed-precondition', 'interaction-unavailable');
    }
    await consumeSocialRateLimit(tx, uid, toUid, 'invitation');
    tx.create(db.collection(`users/${toUid}/invitations`).doc(), { fromUid: uid, toUid, roomId, gameType, status: 'pending',
      fromName: sender.data()?.displayName ?? '', createdAt: admin.firestore.FieldValue.serverTimestamp() });
  });
  return { success: true };
}

export async function acceptInvitation(auth: { uid: string } | undefined, input: unknown) {
  const uid = requireAuth(auth); const data = requireObject(input); onlyKeys(data, ['invitationId']);
  const invitationId = typeof data.invitationId === 'string' ? data.invitationId.trim() : '';
  if (!invitationId) throw new HttpsError('invalid-argument', 'invalid-request');
  const ref = db.doc(`users/${uid}/invitations/${invitationId}`);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref); const invitation = snap.data();
    if (!snap.exists || invitation?.status !== 'pending' || typeof invitation.fromUid !== 'string' || await blockedEitherWay(uid, invitation.fromUid)) {
      throw new HttpsError('failed-precondition', 'interaction-unavailable');
    }
    tx.delete(ref);
    return { roomId: invitation.roomId, gameType: invitation.gameType };
  });
}

export async function dismissInvitation(auth: { uid: string } | undefined, input: unknown) {
  const uid = requireAuth(auth); const data = requireObject(input); onlyKeys(data, ['invitationId']);
  const invitationId = typeof data.invitationId === 'string' ? data.invitationId.trim() : '';
  if (!invitationId) throw new HttpsError('invalid-argument', 'invalid-request');
  const ref = db.doc(`users/${uid}/invitations/${invitationId}`);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return; // idempotent dismissal
    tx.delete(ref);
  });
  return { dismissed: true };
}

export async function publishShare(auth: { uid: string } | undefined, input: unknown) {
  const uid = requireAuth(auth); await requireCurrentAcceptance(uid);
  const data = requireObject(input); onlyKeys(data, ['setName', 'pairs']);
  const setName = validatePublicText(data.setName, 80);
  if (!Array.isArray(data.pairs) || data.pairs.length < 1 || data.pairs.length > 100) throw new HttpsError('invalid-argument', 'invalid-content');
  const pairs: PublicPair[] = data.pairs.map((item) => {
    const pair = requireObject(item); onlyKeys(pair, ['front', 'back']);
    return { front: validatePublicText(pair.front, 120), back: validatePublicText(pair.back, 120) };
  });
  const ref = db.collection('shares').doc();
  await ref.create({ ownerUid: uid, setName, pairs, pairsCount: pairs.length, status: 'published', visibility: 'public',
    createdAt: admin.firestore.FieldValue.serverTimestamp() });
  return { shareId: ref.id };
}

export async function updatePublicProfile(auth: { uid: string } | undefined, input: unknown) {
  const uid = requireAuth(auth); await requireCurrentAcceptance(uid);
  const data = requireObject(input); onlyKeys(data, ['displayName', 'photoUrl']);
  const displayName = data.displayName === undefined ? undefined : validatePublicText(data.displayName, 40);
  const photoUrl = data.photoUrl === undefined ? undefined : validatePublicText(data.photoUrl, 500, false);
  if (displayName === undefined && photoUrl === undefined) throw new HttpsError('invalid-argument', 'invalid-request');
  await db.doc(`users/${uid}`).set({
    ...(displayName === undefined ? {} : { displayName }),
    ...(photoUrl === undefined ? {} : { photoUrl }),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
  return { updated: true };
}

export async function removeShare(auth: { uid: string } | undefined, input: unknown) {
  const uid = requireAuth(auth); const data = requireObject(input); onlyKeys(data, ['shareId']);
  const shareId = typeof data.shareId === 'string' ? data.shareId.trim() : '';
  const ref = db.doc(`shares/${shareId}`);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists || snap.data()?.ownerUid !== uid) throw new HttpsError('permission-denied', 'not-owner');
    tx.update(ref, { status: 'removed', visibility: 'private', removedAt: admin.firestore.FieldValue.serverTimestamp() });
  });
  return { removed: true };
}

export async function submitReport(auth: { uid: string } | undefined, input: unknown) {
  const uid = requireAuth(auth); const data = requireObject(input); onlyKeys(data, ['targetType', 'targetId', 'reason', 'details']);
  const targetType = data.targetType === 'user' || data.targetType === 'share' ? data.targetType : '';
  const targetId = typeof data.targetId === 'string' ? data.targetId.trim() : '';
  const reason = typeof data.reason === 'string' ? data.reason : '';
  if (!targetType || !targetId || !reasons.has(reason)) throw new HttpsError('invalid-argument', 'invalid-report');
  const details = data.details === undefined ? '' : validatePublicText(data.details, 500, false);
  const target = await db.doc(targetType === 'user' ? `users/${targetId}` : `shares/${targetId}`).get();
  const targetOwnerUid = targetType === 'user' ? targetId : target.data()?.ownerUid;
  if (!target.exists || typeof targetOwnerUid !== 'string' || targetOwnerUid === uid) throw new HttpsError('failed-precondition', 'report-unavailable');
  const dedupeRef = db.doc(`report_cooldowns/${uid}_${targetType}_${targetId}_${reason}`);
  await db.runTransaction(async (tx) => {
    const prior = await tx.get(dedupeRef); const priorAt = prior.data()?.createdAt as FirebaseFirestore.Timestamp | undefined;
    if (priorAt && admin.firestore.Timestamp.now().toMillis() - priorAt.toMillis() < UGC_POLICY.reportCooldownMs) {
      throw new HttpsError('resource-exhausted', 'report-received');
    }
    tx.set(dedupeRef, { createdAt: admin.firestore.FieldValue.serverTimestamp(), expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + UGC_POLICY.reportCooldownMs) });
    tx.create(db.collection('moderation_reports').doc(), { reporterUid: uid, targetType, targetId, targetOwnerUid, reason, details,
      status: 'open', createdAt: admin.firestore.FieldValue.serverTimestamp() });
  });
  return { received: true };
}
