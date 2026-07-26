"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.validateRegistrationInput = validateRegistrationInput;
exports.tokenDocumentId = tokenDocumentId;
exports.invitationDataPayload = invitationDataPayload;
exports.isInvalidRegistrationError = isInvalidRegistrationError;
exports.selectEligibleDevices = selectEligibleDevices;
exports.classifyDeliveryResponses = classifyDeliveryResponses;
exports.registerNotificationToken = registerNotificationToken;
exports.unregisterNotificationToken = unregisterNotificationToken;
exports.deliverInvitationNotification = deliverInvitationNotification;
const crypto_1 = require("crypto");
const admin = __importStar(require("firebase-admin"));
const https_1 = require("firebase-functions/v2/https");
if (admin.apps.length === 0)
    admin.initializeApp();
const db = admin.firestore();
const allowedPlatforms = new Set(['android', 'ios', 'web', 'macos', 'windows', 'linux']);
const invalidTokenCodes = new Set([
    'messaging/invalid-registration-token',
    'messaging/registration-token-not-registered',
]);
function requireAuth(auth) {
    if (!auth?.uid)
        throw new https_1.HttpsError('unauthenticated', 'authentication-required');
    return auth.uid;
}
function validateRegistrationInput(input) {
    if (!input || typeof input !== 'object' || Array.isArray(input)) {
        throw new https_1.HttpsError('invalid-argument', 'invalid-registration');
    }
    const data = input;
    if (Object.keys(data).some((key) => !['token', 'platform', 'locale'].includes(key))) {
        throw new https_1.HttpsError('invalid-argument', 'invalid-registration');
    }
    const token = typeof data.token === 'string' ? data.token.trim() : '';
    const platform = typeof data.platform === 'string' ? data.platform : '';
    const locale = data.locale === 'tr' ? 'tr' : data.locale === 'en' ? 'en' : null;
    if (token.length < 16 || token.length > 4096 || !allowedPlatforms.has(platform) || !locale) {
        throw new https_1.HttpsError('invalid-argument', 'invalid-registration');
    }
    return { token, platform, locale };
}
function tokenDocumentId(token) {
    return (0, crypto_1.createHash)('sha256').update(token, 'utf8').digest('hex');
}
function invitationDataPayload(invitationId) {
    if (!/^[A-Za-z0-9_-]{1,128}$/.test(invitationId)) {
        throw new https_1.HttpsError('invalid-argument', 'invalid-invitation');
    }
    return {
        type: 'multiplayer_invitation',
        version: '1',
        invitationId,
    };
}
function isInvalidRegistrationError(code) {
    return typeof code === 'string' && invalidTokenCodes.has(code);
}
function selectEligibleDevices(recipientDevices, senderDeviceIds) {
    return recipientDevices.filter((device) => !senderDeviceIds.has(device.id) && device.token.length >= 16);
}
function classifyDeliveryResponses(responses) {
    const invalidIndexes = [];
    let successCount = 0;
    responses.forEach((response, index) => {
        if (response.success)
            successCount++;
        else if (isInvalidRegistrationError(response.errorCode))
            invalidIndexes.push(index);
    });
    return { successCount, invalidIndexes };
}
async function registerNotificationToken(auth, input) {
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
async function unregisterNotificationToken(auth, input) {
    const uid = requireAuth(auth);
    if (!input || typeof input !== 'object' || Array.isArray(input)) {
        throw new https_1.HttpsError('invalid-argument', 'invalid-registration');
    }
    const data = input;
    if (Object.keys(data).some((key) => key !== 'token')) {
        throw new https_1.HttpsError('invalid-argument', 'invalid-registration');
    }
    const token = typeof data.token === 'string' ? data.token.trim() : '';
    if (token.length < 16 || token.length > 4096) {
        throw new https_1.HttpsError('invalid-argument', 'invalid-registration');
    }
    await db.doc(`users/${uid}/notification_tokens/${tokenDocumentId(token)}`).delete();
    return { unregistered: true };
}
async function deliverInvitationNotification(params) {
    const payload = invitationDataPayload(params.invitationId);
    const deliveryRef = db.doc(`notification_deliveries/${params.invitationId}`);
    const claimed = await db.runTransaction(async (tx) => {
        const existing = await tx.get(deliveryRef);
        if (existing.exists)
            return false;
        tx.create(deliveryRef, {
            recipientUid: params.recipientUid,
            status: 'sending',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return true;
    });
    if (!claimed)
        return { duplicate: true, successCount: 0 };
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
            token: doc.data().token,
            locale: doc.data().locale === 'tr' ? 'tr' : 'en',
        }));
        const eligibleDevices = selectEligibleDevices(devices, senderTokenIds);
        const eligible = eligibleDevices.map((device) => ({
            device,
            ref: recipientTokens.docs.find((doc) => doc.id === device.id).ref,
        }));
        let successCount = 0;
        const invalidRefs = [];
        for (const locale of ['en', 'tr']) {
            const localized = eligible.filter((entry) => entry.device.locale === locale);
            for (let offset = 0; offset < localized.length; offset += 500) {
                const chunk = localized.slice(offset, offset + 500);
                if (chunk.length === 0)
                    continue;
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
    }
    catch (error) {
        await deliveryRef.delete();
        throw error;
    }
}
