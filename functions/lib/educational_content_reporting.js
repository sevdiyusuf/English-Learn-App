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
exports.REPORT_POLICY = void 0;
exports.submitEducationalContentReport = submitEducationalContentReport;
const admin = __importStar(require("firebase-admin"));
const https_1 = require("firebase-functions/v2/https");
if (admin.apps.length === 0)
    admin.initializeApp();
const db = admin.firestore();
exports.REPORT_POLICY = {
    cooldownMs: 60 * 1000,
};
const validCategories = new Set([
    'typo',
    'incorrect_answer',
    'unclear_explanation',
    'audio_issue',
    'wrong_level_or_category',
    'other',
]);
const contentIdRegex = /^edu\.[a-z0-9][a-z0-9._-]*$/;
function requireAuth(auth) {
    if (!auth)
        throw new https_1.HttpsError('unauthenticated', 'authentication-required');
    return auth.uid;
}
function requireObject(value) {
    if (!value || typeof value !== 'object' || Array.isArray(value)) {
        throw new https_1.HttpsError('invalid-argument', 'invalid-request');
    }
    return value;
}
function onlyKeys(data, keys) {
    if (Object.keys(data).some((key) => !keys.includes(key))) {
        throw new https_1.HttpsError('invalid-argument', 'invalid-request');
    }
}
function validateString(value, maxLength, required = true) {
    if (value === undefined || value === null) {
        if (required)
            throw new https_1.HttpsError('invalid-argument', 'invalid-content');
        return '';
    }
    if (typeof value !== 'string')
        throw new https_1.HttpsError('invalid-argument', 'invalid-content');
    const normalized = value.normalize('NFKC').replace(/[\u200B-\u200D\uFEFF]/g, '');
    if (/[\u0000-\u001F\u007F]/.test(normalized)) {
        throw new https_1.HttpsError('invalid-argument', 'invalid-content');
    }
    const trimmed = normalized.trim().replace(/\s+/g, ' ');
    if (required && !trimmed)
        throw new https_1.HttpsError('invalid-argument', 'invalid-content');
    if (trimmed.length > maxLength)
        throw new https_1.HttpsError('invalid-argument', 'invalid-content');
    return trimmed;
}
async function submitEducationalContentReport(auth, input) {
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
        throw new https_1.HttpsError('invalid-argument', 'invalid-content-id');
    }
    const contentVersion = data.contentVersion;
    if (typeof contentVersion !== 'number' || !Number.isInteger(contentVersion) || contentVersion <= 0) {
        throw new https_1.HttpsError('invalid-argument', 'invalid-content-version');
    }
    const contentType = validateString(data.contentType, 64, true);
    const category = typeof data.category === 'string' ? data.category.trim() : '';
    if (!category || !validCategories.has(category)) {
        throw new https_1.HttpsError('invalid-argument', 'invalid-category');
    }
    const comment = validateString(data.comment, 500, false);
    const locale = validateString(data.locale, 16, false) || 'en';
    const appVersion = validateString(data.appVersion, 32, false) || '1.0.0';
    const safeContentIdKey = contentId.replace(/[^a-zA-Z0-9._-]/g, '_');
    const cooldownRef = db.doc(`educational_content_report_cooldowns/${uid}_${safeContentIdKey}_${category}`);
    await db.runTransaction(async (tx) => {
        const prior = await tx.get(cooldownRef);
        const priorAt = prior.data()?.createdAt;
        const nowMs = Date.now();
        if (priorAt && nowMs - priorAt.toMillis() < exports.REPORT_POLICY.cooldownMs) {
            throw new https_1.HttpsError('already-exists', 'report-already-submitted');
        }
        tx.set(cooldownRef, {
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            expiresAt: admin.firestore.Timestamp.fromMillis(nowMs + exports.REPORT_POLICY.cooldownMs),
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
