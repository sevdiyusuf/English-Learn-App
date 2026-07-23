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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.onUserDeleted = exports.submitWordV2 = exports.submitWordLegacy = exports.submitAdjective = exports.submitVerb = exports.submitWord = exports.resolveTimeoutV2 = exports.resolveTimeout = exports.startGameV2 = exports.startGame = exports.getServerTimeV2 = exports.getServerTime = void 0;
// --- src/index.ts (V2 uyumlu) ---
const admin = __importStar(require("firebase-admin"));
const https_1 = require("firebase-functions/v2/https");
const v1_1 = require("firebase-functions/v1");
const dictionary_json_1 = __importDefault(require("./dictionary.json"));
const easy_pack_json_1 = __importDefault(require("./easy_pack.json"));
const medium_pack_json_1 = __importDefault(require("./medium_pack.json"));
const hard_pack_json_1 = __importDefault(require("./hard_pack.json"));
admin.initializeApp();
const allPacks = [easy_pack_json_1.default, medium_pack_json_1.default, hard_pack_json_1.default];
const packIdToWords = new Map();
for (const packFile of allPacks) {
    for (const pack of packFile.packs ?? []) {
        const words = new Set();
        for (const w of pack.words ?? []) {
            words.add(String(w).toLowerCase());
        }
        packIdToWords.set(pack.id, words);
    }
}
const db = admin.firestore();
const dictionaryEntries = dictionary_json_1.default;
const dictionaryMap = new Map();
for (const entry of dictionaryEntries) {
    const type = entry.type.toLowerCase();
    const word = entry.word.toLowerCase();
    const set = dictionaryMap.get(type) ?? new Set();
    set.add(word);
    dictionaryMap.set(type, set);
}
const normalizeWord = (word) => {
    if (typeof word !== 'string')
        return '';
    return word.trim().toLowerCase();
};
const normalizeId = (value) => {
    if (typeof value !== 'string')
        return '';
    return value.trim();
};
const getRoomRef = (roomId) => db.collection('rooms').doc(roomId);
const nowTimestamp = () => admin.firestore.Timestamp.now();
const withTransactionRoom = async (roomId, handler) => {
    const roomRef = getRoomRef(roomId);
    return db.runTransaction(async (tx) => {
        const snapshot = await tx.get(roomRef);
        if (!snapshot.exists) {
            throw new https_1.HttpsError('not-found', 'Oda bulunamadı');
        }
        const data = snapshot.data();
        return handler(tx, roomRef, data, snapshot);
    });
};
const resolveTimeoutInternal = async (roomId) => {
    return withTransactionRoom(roomId, async (tx, roomRef, room) => {
        const deadline = room.turnDeadlineAt;
        if (!deadline)
            return false;
        const now = nowTimestamp();
        if (deadline.toMillis() > now.toMillis())
            return false;
        const active = Array.isArray(room.activePlayerIds) ? [...room.activePlayerIds] : [];
        const currentUid = room.currentTurnUid ?? null;
        const currentIndex = currentUid ? active.indexOf(currentUid) : -1;
        const updates = {
            updatedAt: now,
        };
        // Remove player who timed out
        if (currentIndex !== -1)
            active.splice(currentIndex, 1);
        updates['activePlayerIds'] = active;
        updates['currentVerb'] = null;
        // Word Battle: THEME/CORE use single type per game; legacy verb/adjective alternate
        const gameMode = room.gameMode;
        if (gameMode === 'THEME' || gameMode === 'CORE') {
            updates['currentWordType'] = room.currentWordType ?? 'word';
        }
        else if (room.currentWordType === 'verb') {
            updates['currentWordType'] = 'adjective';
        }
        else if (room.currentWordType === 'adjective') {
            updates['currentWordType'] = 'verb';
        }
        else {
            updates['currentWordType'] = 'verb';
        }
        if (active.length <= 1) {
            updates['status'] = 'finished';
            updates['winnerUid'] = active.length === 1 ? active[0] : null;
            updates['currentTurnUid'] = null;
            updates['currentTurnIndex'] = 0;
            updates['turnDeadlineAt'] = null;
            updates['currentWordType'] = null;
            updates['currentVerb'] = null;
        }
        else {
            // After removing the timed-out player, the next player is at the same index
            // (or 0 if we were at the end)
            const nextIndex = currentIndex < active.length ? currentIndex : 0;
            const nextUid = active[nextIndex];
            const duration = room.turnDurationSeconds ?? 12;
            const nextDeadline = admin.firestore.Timestamp.fromMillis(now.toMillis() + duration * 1000);
            updates['currentTurnIndex'] = nextIndex;
            updates['currentTurnUid'] = nextUid;
            updates['turnDeadlineAt'] = nextDeadline;
        }
        tx.update(roomRef, updates);
        return true;
    });
};
// --------- Callable V2 (yeni isimlerle) ---------
exports.getServerTime = (0, https_1.onCall)({ region: 'us-central1' }, async (_req) => {
    return { now: Date.now() };
});
// Alias for backward compatibility
exports.getServerTimeV2 = exports.getServerTime;
exports.startGame = (0, https_1.onCall)({ region: 'us-central1' }, async (req) => {
    const { roomId, gameMode, settings } = req.data ?? {};
    if (!roomId)
        throw new https_1.HttpsError('invalid-argument', 'roomId gerekli');
    if (!req.auth)
        throw new https_1.HttpsError('unauthenticated', 'Oturum bulunamadı');
    await withTransactionRoom(roomId, async (tx, roomRef, room) => {
        if (room.status !== 'waiting' && room.status !== 'finished') {
            throw new https_1.HttpsError('failed-precondition', 'Oyun zaten başlamış');
        }
        if (room.hostUid !== req.auth.uid) {
            throw new https_1.HttpsError('permission-denied', 'Sadece host oyunu başlatabilir');
        }
        const players = Array.isArray(room.players) ? [...room.players] : [];
        if (players.length < 2) {
            throw new https_1.HttpsError('failed-precondition', 'Oyunu başlatmak için en az iki oyuncu gerekir');
        }
        const now = nowTimestamp();
        const active = Array.from(new Set(players));
        const randomIndex = Math.floor(Math.random() * active.length);
        const nextUid = active[randomIndex];
        const duration = room.turnDurationSeconds ?? 12;
        const deadline = admin.firestore.Timestamp.fromMillis(now.toMillis() + duration * 1000);
        const mode = (gameMode ?? 'CORE').toUpperCase();
        const currentWordType = mode === 'THEME'
            ? 'word'
            : (settings?.core?.posType?.toLowerCase() ?? 'verb');
        const updatePayload = {
            status: 'active',
            activePlayerIds: active,
            currentTurnIndex: randomIndex,
            currentTurnUid: nextUid,
            turnDeadlineAt: deadline,
            currentWordType,
            currentVerb: null,
            winnerUid: null,
            updatedAt: now,
            locked: true,
            gameMode: mode,
        };
        if (settings != null) {
            updatePayload['settings'] = settings;
        }
        tx.update(roomRef, updatePayload);
        const usedDoc = roomRef.collection('meta').doc('usedWords');
        tx.set(usedDoc, { used: {} }, { merge: true });
    });
    // Clear playedWords collection after transaction (can't delete in transaction)
    // This must be done outside the transaction because batch deletes are not supported in transactions
    const playedWordsRef = admin.firestore()
        .collection('rooms')
        .doc(roomId)
        .collection('playedWords');
    const playedWordsSnapshot = await playedWordsRef.get();
    if (!playedWordsSnapshot.empty) {
        const batch = admin.firestore().batch();
        playedWordsSnapshot.docs.forEach((doc) => {
            batch.delete(doc.ref);
        });
        await batch.commit();
    }
});
// Alias for backward compatibility
exports.startGameV2 = exports.startGame;
exports.resolveTimeout = (0, https_1.onCall)({ region: 'us-central1' }, async (req) => {
    const { roomId } = req.data ?? {};
    if (!roomId)
        throw new https_1.HttpsError('invalid-argument', 'roomId gerekli');
    const resolved = await resolveTimeoutInternal(roomId);
    return { resolved };
});
// Alias for backward compatibility
exports.resolveTimeoutV2 = exports.resolveTimeout;
exports.submitWord = (0, https_1.onCall)({ region: 'us-central1' }, async (req) => {
    const { roomId, word: rawWord } = req.data ?? {};
    const word = normalizeWord(rawWord);
    if (!roomId || !word) {
        throw new https_1.HttpsError('invalid-argument', 'roomId ve kelime gerekli');
    }
    if (!req.auth) {
        throw new https_1.HttpsError('unauthenticated', 'Oturum bulunamadı');
    }
    await withTransactionRoom(roomId, async (tx, roomRef, room) => {
        const now = nowTimestamp();
        const deadline = room.turnDeadlineAt;
        if (deadline && deadline.toMillis() <= now.toMillis()) {
            throw new https_1.HttpsError('deadline-exceeded', 'TIMEOUT');
        }
        if (room.status !== 'active') {
            throw new https_1.HttpsError('failed-precondition', 'GAME_NOT_STARTED');
        }
        if (room.currentTurnUid !== req.auth.uid) {
            throw new https_1.HttpsError('permission-denied', 'Sıran geldiğinde kelime gönderebilirsin');
        }
        const settings = room.settings;
        const gameMode = (room.gameMode ?? 'CORE').toUpperCase();
        if (gameMode === 'THEME') {
            const packId = settings?.theme?.packId;
            if (!packId) {
                throw new https_1.HttpsError('failed-precondition', 'GAME_NOT_LOCKED');
            }
            const packWords = packIdToWords.get(packId);
            if (!packWords?.has(word)) {
                throw new https_1.HttpsError('invalid-argument', 'NOT_IN_PACK');
            }
        }
        else {
            const posType = settings?.core?.posType ?? 'verb';
            if (!validateDictionaryWord(word, posType)) {
                let inAnyType = false;
                for (const set of dictionaryMap.values()) {
                    if (set.has(word)) {
                        inAnyType = true;
                        break;
                    }
                }
                throw new https_1.HttpsError('invalid-argument', inAnyType ? 'WRONG_TYPE' : 'NOT_IN_DICTIONARY');
            }
        }
        const active = Array.isArray(room.activePlayerIds) ? [...room.activePlayerIds] : [];
        if (active.length === 0) {
            throw new https_1.HttpsError('failed-precondition', 'Aktif oyuncu bulunmuyor');
        }
        const usedDoc = roomRef.collection('meta').doc('usedWords');
        const usedSnap = await tx.get(usedDoc);
        const usedMap = usedSnap.exists
            ? usedSnap.get('used') ?? {}
            : {};
        if (usedMap[word]) {
            throw new https_1.HttpsError('already-exists', 'DUPLICATE');
        }
        const playedWordsRef = roomRef.collection('playedWords');
        const typeForDoc = gameMode === 'THEME' ? 'word' : (room.currentWordType ?? 'verb');
        tx.create(playedWordsRef.doc(), {
            word,
            type: typeForDoc,
            byUid: req.auth.uid,
            at: now,
        });
        tx.set(usedDoc, { used: { ...usedMap, [word]: true } }, { merge: true });
        const currentIndex = active.indexOf(req.auth.uid);
        const nextIndex = (currentIndex + 1) % active.length;
        const nextUid = active[nextIndex];
        const duration = room.turnDurationSeconds ?? 12;
        const nextDeadline = admin.firestore.Timestamp.fromMillis(now.toMillis() + duration * 1000);
        tx.update(roomRef, {
            currentTurnIndex: nextIndex,
            currentTurnUid: nextUid,
            turnDeadlineAt: nextDeadline,
            currentWordType: room.currentWordType ?? typeForDoc,
            updatedAt: now,
        });
    });
});
const validateDictionaryWord = (word, type) => {
    const set = dictionaryMap.get(type);
    return set?.has(word) ?? false;
};
// Submit verb - player submits verb, then turn switches to next player for adjective
exports.submitVerb = (0, https_1.onCall)({ region: 'us-central1' }, async (req) => {
    const { roomId, verb: rawVerb } = req.data ?? {};
    const verb = normalizeWord(rawVerb);
    if (!roomId || !verb) {
        throw new https_1.HttpsError('invalid-argument', 'roomId ve fiil gerekli');
    }
    if (!req.auth) {
        throw new https_1.HttpsError('unauthenticated', 'Oturum bulunamadı');
    }
    await withTransactionRoom(roomId, async (tx, roomRef, room) => {
        // Check deadline FIRST - before any other checks to reject expired turns immediately
        const now = nowTimestamp();
        const deadline = room.turnDeadlineAt;
        if (deadline && deadline.toMillis() <= now.toMillis()) {
            throw new https_1.HttpsError('deadline-exceeded', 'Tur süresi dolmuş');
        }
        if (room.status !== 'active') {
            throw new https_1.HttpsError('failed-precondition', 'Oyun aktif değil');
        }
        if (room.currentTurnUid !== req.auth.uid) {
            throw new https_1.HttpsError('permission-denied', 'Sıran geldiğinde kelime gönderebilirsin');
        }
        // Check if we're waiting for verb
        if (room.currentWordType !== 'verb' && room.currentWordType !== null) {
            throw new https_1.HttpsError('failed-precondition', 'Şu anda sıfat bekleniyor');
        }
        // Validate word (fast check)
        if (!validateDictionaryWord(verb, 'verb')) {
            throw new https_1.HttpsError('invalid-argument', `"${verb}" geçerli bir fiil değil`);
        }
        const active = Array.isArray(room.activePlayerIds) ? [...room.activePlayerIds] : [];
        if (active.length === 0) {
            throw new https_1.HttpsError('failed-precondition', 'Aktif oyuncu bulunmuyor');
        }
        const usedDoc = roomRef.collection('meta').doc('usedWords');
        const usedSnap = await tx.get(usedDoc);
        const usedMap = usedSnap.exists
            ? usedSnap.get('used') ?? {}
            : {};
        if (usedMap[verb]) {
            throw new https_1.HttpsError('already-exists', `"${verb}" daha önce kullanılmış`);
        }
        // Add verb to playedWords
        const playedWordsRef = roomRef.collection('playedWords');
        tx.create(playedWordsRef.doc(), {
            word: verb,
            type: 'verb',
            byUid: req.auth.uid,
            at: now,
        });
        // Mark word as used
        tx.set(usedDoc, {
            used: {
                ...usedMap,
                [verb]: true,
            },
        }, { merge: true });
        // Switch to next player for verb (ensure single word turn)
        const currentIndex = active.indexOf(req.auth.uid);
        const nextIndex = (currentIndex + 1) % active.length;
        const nextUid = active[nextIndex];
        const duration = room.turnDurationSeconds ?? 12;
        const nextDeadline = admin.firestore.Timestamp.fromMillis(now.toMillis() + duration * 1000);
        tx.update(roomRef, {
            currentTurnIndex: nextIndex,
            currentTurnUid: nextUid,
            currentWordType: 'verb',
            currentVerb: null, // No longer needed
            turnDeadlineAt: nextDeadline,
            updatedAt: now,
        });
    });
});
// Submit adjective - player submits adjective, then turn switches to next player for verb
exports.submitAdjective = (0, https_1.onCall)({ region: 'us-central1' }, async (req) => {
    const { roomId, adjective: rawAdj } = req.data ?? {};
    const adjective = normalizeWord(rawAdj);
    if (!roomId || !adjective) {
        throw new https_1.HttpsError('invalid-argument', 'roomId ve sıfat gerekli');
    }
    if (!req.auth) {
        throw new https_1.HttpsError('unauthenticated', 'Oturum bulunamadı');
    }
    await withTransactionRoom(roomId, async (tx, roomRef, room) => {
        // Check deadline FIRST - before any other checks to reject expired turns immediately
        const now = nowTimestamp();
        const deadline = room.turnDeadlineAt;
        if (deadline && deadline.toMillis() <= now.toMillis()) {
            throw new https_1.HttpsError('deadline-exceeded', 'Tur süresi dolmuş');
        }
        if (room.status !== 'active') {
            throw new https_1.HttpsError('failed-precondition', 'Oyun aktif değil');
        }
        if (room.currentTurnUid !== req.auth.uid) {
            throw new https_1.HttpsError('permission-denied', 'Sıran geldiğinde kelime gönderebilirsin');
        }
        // Check if we're waiting for adjective
        if (room.currentWordType !== 'adjective') {
            throw new https_1.HttpsError('failed-precondition', 'Şu anda fiil bekleniyor');
        }
        // Validate word (fast check)
        if (!validateDictionaryWord(adjective, 'adjective')) {
            throw new https_1.HttpsError('invalid-argument', `"${adjective}" geçerli bir sıfat değil`);
        }
        const active = Array.isArray(room.activePlayerIds) ? [...room.activePlayerIds] : [];
        if (active.length === 0) {
            throw new https_1.HttpsError('failed-precondition', 'Aktif oyuncu bulunmuyor');
        }
        const usedDoc = roomRef.collection('meta').doc('usedWords');
        const usedSnap = await tx.get(usedDoc);
        const usedMap = usedSnap.exists
            ? usedSnap.get('used') ?? {}
            : {};
        if (usedMap[adjective]) {
            throw new https_1.HttpsError('already-exists', `"${adjective}" daha önce kullanılmış`);
        }
        // Add adjective to playedWords
        const playedWordsRef = roomRef.collection('playedWords');
        tx.create(playedWordsRef.doc(), {
            word: adjective,
            type: 'adjective',
            byUid: req.auth.uid,
            at: now,
        });
        // Mark word as used
        tx.set(usedDoc, {
            used: {
                ...usedMap,
                [adjective]: true,
            },
        }, { merge: true });
        // Switch to next player for verb
        const currentIndex = active.indexOf(req.auth.uid);
        const nextIndex = (currentIndex + 1) % active.length;
        const nextUid = active[nextIndex];
        const duration = room.turnDurationSeconds ?? 12;
        const nextDeadline = admin.firestore.Timestamp.fromMillis(now.toMillis() + duration * 1000);
        tx.update(roomRef, {
            currentTurnIndex: nextIndex,
            currentTurnUid: nextUid,
            turnDeadlineAt: nextDeadline,
            currentWordType: 'verb', // Reset to verb for next player
            currentVerb: null, // No longer needed
            updatedAt: now,
        });
    });
});
exports.submitWordLegacy = (0, https_1.onCall)({ region: 'us-central1' }, async (req) => {
    // Deprecated - use submitWord (THEME/CORE) or submitVerb+submitAdjective (legacy)
    // It's kept for backward compatibility only
    // New code should use submitVerb + submitAdjective separately
    const { roomId, verb: rawVerb, adjective: rawAdj } = req.data ?? {};
    const verb = normalizeWord(rawVerb);
    const adjective = normalizeWord(rawAdj);
    if (!roomId || !verb || !adjective) {
        throw new https_1.HttpsError('invalid-argument', 'Eksik parametre');
    }
    if (!req.auth) {
        throw new https_1.HttpsError('unauthenticated', 'Oturum bulunamadı');
    }
    // Legacy: submit both at once (old behavior)
    // This doesn't use the two-phase timing system
    const timedOut = await resolveTimeoutInternal(roomId);
    if (timedOut) {
        throw new https_1.HttpsError('deadline-exceeded', 'Tur süresi dolmuş');
    }
    await withTransactionRoom(roomId, async (tx, roomRef, room) => {
        if (room.status !== 'active') {
            throw new https_1.HttpsError('failed-precondition', 'Oyun aktif değil');
        }
        if (room.currentTurnUid !== req.auth.uid) {
            throw new https_1.HttpsError('permission-denied', 'Sıran geldiğinde kelime gönderebilirsin');
        }
        if (!validateDictionaryWord(verb, 'verb')) {
            throw new https_1.HttpsError('invalid-argument', `"${verb}" geçerli bir fiil değil`);
        }
        if (!validateDictionaryWord(adjective, 'adjective')) {
            throw new https_1.HttpsError('invalid-argument', `"${adjective}" geçerli bir sıfat değil`);
        }
        const now = nowTimestamp();
        const deadline = room.turnDeadlineAt;
        if (deadline && deadline.toMillis() < now.toMillis()) {
            throw new https_1.HttpsError('deadline-exceeded', 'Tur süresi dolmuş');
        }
        const active = Array.isArray(room.activePlayerIds) ? [...room.activePlayerIds] : [];
        if (active.length === 0) {
            throw new https_1.HttpsError('failed-precondition', 'Aktif oyuncu bulunmuyor');
        }
        const usedDoc = roomRef.collection('meta').doc('usedWords');
        const usedSnap = await tx.get(usedDoc);
        const usedMap = usedSnap.exists
            ? usedSnap.get('used') ?? {}
            : {};
        if (usedMap[verb]) {
            throw new https_1.HttpsError('already-exists', `"${verb}" daha önce kullanılmış`);
        }
        if (usedMap[adjective]) {
            throw new https_1.HttpsError('already-exists', `"${adjective}" daha önce kullanılmış`);
        }
        const playedWordsRef = roomRef.collection('playedWords');
        const basePayload = {
            byUid: req.auth.uid,
            at: now,
        };
        tx.create(playedWordsRef.doc(), { ...basePayload, word: verb, type: 'verb' });
        tx.create(playedWordsRef.doc(), { ...basePayload, word: adjective, type: 'adjective' });
        tx.set(usedDoc, {
            used: {
                ...usedMap,
                [verb]: true,
                [adjective]: true,
            },
        }, { merge: true });
        const nextIndex = (room.currentTurnIndex + 1) % active.length;
        const nextUid = active[nextIndex];
        const duration = room.turnDurationSeconds ?? 12;
        const nextDeadline = admin.firestore.Timestamp.fromMillis(now.toMillis() + duration * 1000);
        tx.update(roomRef, {
            currentTurnIndex: nextIndex,
            currentTurnUid: nextUid,
            turnDeadlineAt: nextDeadline,
            currentWordType: 'verb', // Reset to verb for next player
            currentVerb: null,
            updatedAt: now,
        });
    });
});
// Alias for backward compatibility
exports.submitWordV2 = exports.submitWord;
/**
 * Automatically clean up all Firestore user data when a Firebase Auth account is deleted.
 * Cleans up user_settings/{uid}, user_stats/{uid}, users/{uid}, and friendships/{uid}
 * along with all their subcollections.
 */
exports.onUserDeleted = v1_1.auth.user().onDelete(async (user) => {
    const uid = user.uid;
    if (!uid)
        return;
    console.log(`[onUserDeleted] Starting data cleanup for user UID: ${uid}`);
    try {
        const collectionsToDelete = ['user_settings', 'user_stats', 'users', 'friendships'];
        for (const colName of collectionsToDelete) {
            const docRef = db.collection(colName).doc(uid);
            await db.recursiveDelete(docRef);
        }
        console.log(`[onUserDeleted] Successfully cleaned up data for user UID: ${uid}`);
    }
    catch (error) {
        console.error(`[onUserDeleted] Failed to clean up data for user UID ${uid}:`, error);
    }
});
