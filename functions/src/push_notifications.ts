import { createHash } from 'crypto';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';

if (admin.apps.length === 0) admin.initializeApp();

const db = admin.firestore();
const allowedPlatforms = new Set(['android', 'ios', 'web', 'macos', 'windows', 'linux']);
const invalidTokenCodes = new Set([
    'messaging/invalid-registration-token',
    'messaging/registration-token-not-registered',
]);

type Auth = { uid: string } | undefined;
type RegistrationInput = { token: string; platform: string; locale: 'en' | 'tr' };

function requireAuth(auth: Auth): string {
    if (!auth?.uid) throw new HttpsError('unauthenticated', 'authentication-required');
    return auth.uid;
}

export function validateRegistrationInput(input: unknown): RegistrationInput {
    if (!input || typeof input !== 'object' || Array.isArray(input)) {
        throw new HttpsError('invalid-argument', 'invalid-registration');
    }
    const data = input as Record<string, unknown>;
    if (Object.keys(data).some((key) => !['token', 'platform', 'locale'].includes(key))) {
        throw new HttpsError('invalid-argument', 'invalid-registration');
    }
    const token = typeof data.token === 'string' ? data.token.trim() : '';
    const platform = typeof data.platform === 'string' ? data.platform : '';
    const locale = data.locale === 'tr' ? 'tr' : data.locale === 'en' ? 'en' : null;
    if (token.length < 16 || token.length > 4096 || !allowedPlatforms.has(platform) || !locale) {
        throw new HttpsError('invalid-argument', 'invalid-registration');
    }
    return { token, platform, locale };
}

export function tokenDocumentId(token: string): string {
    return createHash('sha256').update(token, 'utf8').digest('hex');
}

export function invitationDataPayload(invitationId: string): Record<string, string> {
    if (!/^[A-Za-z0-9_-]{1,128}$/.test(invitationId)) {
        throw new HttpsError('invalid-argument', 'invalid-invitation');
    }
    return {
        type: 'multiplayer_invitation',
        version: '1',
        invitationId,
    };
}

export function isInvalidRegistrationError(code: unknown): boolean {
    return typeof code === 'string' && invalidTokenCodes.has(code);
}

export type RegisteredDevice = {
    id: string;
    token: string;
    locale: 'en' | 'tr';
};

export function selectEligibleDevices(
    recipientDevices: RegisteredDevice[],
    senderDeviceIds: Set<string>,
): RegisteredDevice[] {
    return recipientDevices.filter((device) =>
        !senderDeviceIds.has(device.id) && device.token.length >= 16);
}

export function classifyDeliveryResponses(
    responses: Array<{ success: boolean; errorCode?: string }>,
) {
    const invalidIndexes: number[] = [];
    let successCount = 0;
    responses.forEach((response, index) => {
        if (response.success) successCount++;
        else if (isInvalidRegistrationError(response.errorCode)) invalidIndexes.push(index);
    });
    return { successCount, invalidIndexes };
}

export async function registerNotificationToken(auth: Auth, input: unknown) {
    const uid = requireAuth(auth);
    const registration = validateRegistrationInput(input);
    const tokenId = tokenDocumentId(registration.token);
    await db.doc(`users/${uid}/notification_tokens/${tokenId}`).set({
        token: registration.token,
        platform: registration.platform,
        locale: registration.locale,
        enabled: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    return { registered: true };
}

export async function unregisterNotificationToken(auth: Auth, input: unknown) {
    const uid = requireAuth(auth);
    if (!input || typeof input !== 'object' || Array.isArray(input)) {
        throw new HttpsError('invalid-argument', 'invalid-registration');
    }
    const data = input as Record<string, unknown>;
    if (Object.keys(data).some((key) => key !== 'token')) {
        throw new HttpsError('invalid-argument', 'invalid-registration');
    }
    const token = typeof data.token === 'string' ? data.token.trim() : '';
    if (token.length < 16 || token.length > 4096) {
        throw new HttpsError('invalid-argument', 'invalid-registration');
    }
    await db.doc(`users/${uid}/notification_tokens/${tokenDocumentId(token)}`).delete();
    return { unregistered: true };
}

export async function deliverInvitationNotification(params: {
    invitationId: string;
    senderUid: string;
    recipientUid: string;
}) {
    const payload = invitationDataPayload(params.invitationId);
    const deliveryRef = db.doc(`notification_deliveries/${params.invitationId}`);
    const claimed = await db.runTransaction(async (tx) => {
        const existing = await tx.get(deliveryRef);
        if (existing.exists) return false;
        tx.create(deliveryRef, {
            recipientUid: params.recipientUid,
            status: 'sending',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return true;
    });
    if (!claimed) return { duplicate: true, successCount: 0 };

    try {
        const [recipientTokens, senderTokens] = await Promise.all([
            db.collection(`users/${params.recipientUid}/notification_tokens`)
                .where('enabled', '==', true).get(),
            db.collection(`users/${params.senderUid}/notification_tokens`).get(),
        ]);
        const senderTokenIds = new Set(senderTokens.docs.map((doc) => doc.id));
        const devices = recipientTokens.docs
            .filter((doc) => typeof doc.data().token === 'string')
            .map((doc) => ({
                id: doc.id,
                token: doc.data().token as string,
                locale: doc.data().locale === 'tr' ? 'tr' as const : 'en' as const,
            }));
        const eligibleDevices = selectEligibleDevices(devices, senderTokenIds);
        const eligible = eligibleDevices.map((device) => ({
            device,
            ref: recipientTokens.docs.find((doc) => doc.id === device.id)!.ref,
        }));

        let successCount = 0;
        const invalidRefs: FirebaseFirestore.DocumentReference[] = [];
        for (const locale of ['en', 'tr'] as const) {
            const localized = eligible.filter((entry) => entry.device.locale === locale);
            for (let offset = 0; offset < localized.length; offset += 500) {
                const chunk = localized.slice(offset, offset + 500);
                if (chunk.length === 0) continue;
                const response = await admin.messaging().sendEachForMulticast({
                    tokens: chunk.map((entry) => entry.device.token),
                    notification: locale === 'tr'
                        ? { title: 'Oyun daveti', body: 'Bir arkadaşın seni oyuna davet etti.' }
                        : { title: 'Game invitation', body: 'A friend invited you to play.' },
                    data: payload,
                    android: { priority: 'high' },
                });
                const classified = classifyDeliveryResponses(response.responses.map((item) => ({
                    success: item.success,
                    errorCode: item.error?.code,
                })));
                successCount += classified.successCount;
                classified.invalidIndexes.forEach((index) => invalidRefs.push(chunk[index].ref));
            }
        }
        const batch = db.batch();
        invalidRefs.forEach((ref) => batch.delete(ref));
        batch.set(deliveryRef, {
            status: 'completed',
            successCount,
            invalidTokenCount: invalidRefs.length,
            completedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        await batch.commit();
        return { duplicate: false, successCount };
    } catch (error) {
        await deliveryRef.delete();
        throw error;
    }
}
