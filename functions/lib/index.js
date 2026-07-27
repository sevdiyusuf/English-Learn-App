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
exports.requestAccountDeletion = exports.onAuthUserDeleted = exports.cleanupUserData = exports.acceptFriendRequest = exports.unregisterNotificationToken = exports.registerNotificationToken = exports.submitEducationalContentReport = exports.updatePublicProfile = exports.removeWordMatchShare = exports.publishWordMatchShare = exports.dismissSocialInvitation = exports.acceptSocialInvitation = exports.createSocialInvitation = exports.resolveFriendRequest = exports.createFriendRequest = exports.unblockUser = exports.blockUser = exports.submitModerationReport = exports.acceptCurrentUgcPolicy = exports.cleanupExpiredRoomsSchedule = exports.cleanupExpiredRooms = exports.sendArenaHeartbeat = exports.updateArenaConfig = exports.resolveArenaTimeout = exports.submitArenaAnswer = exports.startArenaMatch = exports.leaveArenaRoom = exports.joinArenaRoom = exports.createArenaRoom = exports.sendHeartbeat = exports.resolveTimeoutV2 = exports.resolveTimeout = exports.submitWordLegacy = exports.submitAdjective = exports.submitVerb = exports.submitWordV2 = exports.submitWord = exports.startGameV2 = exports.startGame = exports.leaveRoom = exports.joinRoom = exports.createRoom = exports.getServerTimeV2 = exports.getServerTime = exports.validateOperationId = exports.APP_CHECK_ENFORCEMENT = void 0;
// --- src/index.ts (Sprint 7B Server-Authoritative Core & Lifecycle) ---
const admin = __importStar(require("firebase-admin"));
const https_1 = require("firebase-functions/v2/https");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const v1_1 = require("firebase-functions/v1");
const dictionary_json_1 = __importDefault(require("./dictionary.json"));
const easy_pack_json_1 = __importDefault(require("./easy_pack.json"));
const medium_pack_json_1 = __importDefault(require("./medium_pack.json"));
const hard_pack_json_1 = __importDefault(require("./hard_pack.json"));
const grammar_arena_helper_1 = require("./grammar_arena_helper");
const room_cleanup_helper_1 = require("./room_cleanup_helper");
const ugc_moderation_1 = require("./ugc_moderation");
const push_notifications_1 = require("./push_notifications");
const educational_content_reporting_1 = require("./educational_content_reporting");
if (admin.apps.length === 0)
    admin.initializeApp();
exports.APP_CHECK_ENFORCEMENT = {
    getServerTime: false,
    getServerTimeV2: false,
    startGame: false,
    startGameV2: false,
    resolveTimeout: false,
    resolveTimeoutV2: false,
    submitWord: false,
    submitWordV2: false,
    submitVerb: false,
    submitAdjective: false,
    submitWordLegacy: false,
    acceptFriendRequest: false,
    requestAccountDeletion: false,
    createRoom: false,
    joinRoom: false,
    leaveRoom: false,
    createArenaRoom: false,
    joinArenaRoom: false,
    leaveArenaRoom: false,
    startArenaMatch: false,
    submitArenaAnswer: false,
    resolveArenaTimeout: false,
    updateArenaConfig: false,
    sendHeartbeat: false,
    sendArenaHeartbeat: false,
    cleanupExpiredRooms: false,
    acceptCurrentUgcPolicy: false,
    submitModerationReport: false,
    blockUser: false,
    unblockUser: false,
    createFriendRequest: false,
    resolveFriendRequest: false,
    createSocialInvitation: false,
    acceptSocialInvitation: false,
    dismissSocialInvitation: false,
    publishWordMatchShare: false,
    removeWordMatchShare: false,
    updatePublicProfile: false,
    registerNotificationToken: false,
    unregisterNotificationToken: false,
    submitEducationalContentReport: false,
};
const makeFunctionOptions = (enforceAppCheck) => ({
    region: 'us-central1',
    enforceAppCheck,
});
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
const validateOperationId = (opId) => {
    if (!opId || typeof opId !== 'string') {
        throw new https_1.HttpsError('invalid-argument', 'operationId gereklidir');
    }
    const clean = opId.trim();
    if (clean.length < 8 || clean.length > 128) {
        throw new https_1.HttpsError('invalid-argument', 'operationId uzunlugu 8-128 karakter arasinda olmalidir');
    }
    if (!/^[a-zA-Z0-9_-]+$/.test(clean)) {
        throw new https_1.HttpsError('invalid-argument', 'operationId gecersiz karakterler iceriyor');
    }
    return clean;
};
exports.validateOperationId = validateOperationId;
const hashPayload = (payload) => {
    try {
        return JSON.stringify(payload ?? {});
    }
    catch {
        return String(payload);
    }
};
const nowTimestamp = () => admin.firestore.Timestamp.now();
// --- Idempotency Helper ---
const handleOperationIdempotency = async (tx, parentRef, uid, opType, operationId, payload, executeOp) => {
    const cleanOpId = (0, exports.validateOperationId)(operationId);
    const receiptRef = db.collection('operation_receipts').doc(`${cleanOpId}_${uid}`);
    const receiptSnap = await tx.get(receiptRef);
    const payloadFingerprint = hashPayload(payload);
    if (receiptSnap.exists) {
        const data = receiptSnap.data();
        if (data.uid !== uid) {
            throw new https_1.HttpsError('permission-denied', 'Bu operationId baska bir kullaniciya ait');
        }
        if (data.payloadFingerprint !== payloadFingerprint || data.opType !== opType) {
            throw new https_1.HttpsError('failed-precondition', 'IDEMPOTENCY_PAYLOAD_MISMATCH');
        }
        if (parentRef && data.roomId && data.roomId !== parentRef.id) {
            throw new https_1.HttpsError('failed-precondition', 'IDEMPOTENCY_PAYLOAD_MISMATCH');
        }
        return data.result;
    }
    const targetRef = parentRef ?? db.collection(opType.includes('Arena') ? 'arena_rooms' : 'rooms').doc();
    const result = await executeOp(targetRef);
    tx.set(receiptRef, {
        operationId: cleanOpId,
        uid,
        opType,
        roomId: targetRef.id,
        payloadFingerprint,
        result: result ?? { success: true },
        createdAt: nowTimestamp(),
        expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + 86400000),
    });
    return result;
};
// --- Firestore Document Helpers ---
const getRoomRef = (roomId) => db.collection('rooms').doc(roomId);
const getArenaRoomRef = (roomId) => db.collection('arena_rooms').doc(roomId);
const validateDictionaryWord = (word, type) => {
    const set = dictionaryMap.get(type);
    return set?.has(word) ?? false;
};
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
const withTransactionArenaRoom = async (roomId, handler) => {
    const roomRef = getArenaRoomRef(roomId);
    return db.runTransaction(async (tx) => {
        const snapshot = await tx.get(roomRef);
        if (!snapshot.exists) {
            throw new https_1.HttpsError('not-found', 'Arena odasi bulunamadi');
        }
        const data = snapshot.data();
        return handler(tx, roomRef, data, snapshot);
    });
};
// --- Word Match Internal Timeout Handler ---
const resolveTimeoutInternal = async (roomId, opId) => {
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
        const currentVersion = room.stateVersion ?? 1;
        const updates = {
            updatedAt: now,
            lastActivityAt: now,
            stateVersion: currentVersion + 1,
        };
        if (currentIndex !== -1)
            active.splice(currentIndex, 1);
        updates['activePlayerIds'] = active;
        updates['currentVerb'] = null;
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
// ==========================================
// ============= CALLABLE EXPORTS ===========
// ==========================================
exports.getServerTime = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.getServerTime), async (_req) => {
    return { now: Date.now() };
});
exports.getServerTimeV2 = exports.getServerTime;
exports.createRoom = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.createRoom), async (req) => {
    if (!req.auth)
        throw new https_1.HttpsError('unauthenticated', 'Oturum bulunamadi');
    const uid = req.auth.uid;
    const { roomCode: rawCode, turnDurationSeconds = 12, username = 'Host', operationId } = req.data ?? {};
    let code = normalizeId(rawCode);
    if (!code) {
        code = Math.floor(10000 + Math.random() * 90000).toString();
    }
    return db.runTransaction(async (tx) => {
        return handleOperationIdempotency(tx, null, uid, 'createRoom', operationId, { code, turnDurationSeconds, username }, async (roomRef) => {
            const now = nowTimestamp();
            tx.set(roomRef, {
                roomCode: code,
                status: 'waiting',
                players: [uid],
                playerNames: { [uid]: username },
                activePlayerIds: [],
                currentTurnIndex: 0,
                currentTurnUid: null,
                turnDeadlineAt: null,
                turnDurationSeconds,
                winnerUid: null,
                hostUid: uid,
                createdAt: now,
                updatedAt: now,
                lastActivityAt: now,
                hostLastSeenAt: now,
                guestLastSeenAt: null,
                stateVersion: 1,
            });
            return { roomId: roomRef.id, roomCode: code };
        });
    });
});
exports.joinRoom = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.joinRoom), async (req) => {
    if (!req.auth)
        throw new https_1.HttpsError('unauthenticated', 'Oturum bulunamadi');
    const uid = req.auth.uid;
    const { roomId: rawRoomId, roomCode: rawCode, username = 'Player', operationId } = req.data ?? {};
    const code = normalizeId(rawCode);
    const roomIdInput = normalizeId(rawRoomId);
    let roomRef = null;
    if (roomIdInput) {
        roomRef = db.collection('rooms').doc(roomIdInput);
    }
    else {
        if (!code)
            throw new https_1.HttpsError('invalid-argument', 'roomCode veya roomId gereklidir');
        let roomsQuery = await db.collection('rooms')
            .where('roomCode', '==', code)
            .limit(1)
            .get();
        if (roomsQuery.empty) {
            await new Promise((r) => setTimeout(r, 100));
            roomsQuery = await db.collection('rooms')
                .where('roomCode', '==', code)
                .limit(1)
                .get();
        }
        if (roomsQuery.empty)
            throw new https_1.HttpsError('not-found', 'Oda bulunamadi');
        roomRef = roomsQuery.docs[0].ref;
    }
    return db.runTransaction(async (tx) => {
        return handleOperationIdempotency(tx, roomRef, uid, 'joinRoom', operationId, { code, username }, async (targetRef) => {
            const snap = await tx.get(targetRef);
            if (!snap.exists)
                throw new https_1.HttpsError('not-found', 'Oda bulunamadi');
            const room = snap.data();
            const now = nowTimestamp();
            if (room.status !== 'waiting')
                throw new https_1.HttpsError('failed-precondition', 'Oda katilima acik degil');
            const players = Array.isArray(room.players) ? [...room.players] : [];
            const playerNames = { ...(room.playerNames ?? {}) };
            if (players.includes(uid)) {
                playerNames[uid] = username;
                const isHost = room.hostUid === uid;
                tx.update(targetRef, {
                    playerNames,
                    updatedAt: now,
                    lastActivityAt: now,
                    ...(isHost ? { hostLastSeenAt: now } : { guestLastSeenAt: now }),
                    stateVersion: (room.stateVersion ?? 1) + 1,
                });
                return { roomId: targetRef.id, rejoined: true };
            }
            if (players.length >= 2)
                throw new https_1.HttpsError('failed-precondition', 'Oda dolu');
            players.push(uid);
            playerNames[uid] = username;
            tx.update(targetRef, {
                players,
                playerNames,
                updatedAt: now,
                lastActivityAt: now,
                guestLastSeenAt: now,
                stateVersion: (room.stateVersion ?? 1) + 1,
            });
            return { roomId: targetRef.id, rejoined: false };
        });
    });
});
exports.leaveRoom = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.leaveRoom), async (req) => {
    if (!req.auth)
        throw new https_1.HttpsError('unauthenticated', 'Oturum bulunamadi');
    const uid = req.auth.uid;
    const { roomId, operationId } = req.data ?? {};
    if (!roomId)
        throw new https_1.HttpsError('invalid-argument', 'roomId gereklidir');
    return withTransactionRoom(roomId, async (tx, roomRef, room) => {
        return handleOperationIdempotency(tx, roomRef, uid, 'leaveRoom', operationId, { roomId }, async () => {
            const now = nowTimestamp();
            const currentVersion = room.stateVersion ?? 1;
            if (room.status === 'waiting') {
                if (room.hostUid === uid) {
                    tx.update(roomRef, {
                        status: 'cancelled',
                        updatedAt: now,
                        lastActivityAt: now,
                        stateVersion: currentVersion + 1,
                    });
                }
                else {
                    const players = (room.players ?? []).filter((p) => p !== uid);
                    tx.update(roomRef, {
                        players,
                        updatedAt: now,
                        lastActivityAt: now,
                        stateVersion: currentVersion + 1,
                    });
                }
            }
            else if (room.status === 'active') {
                const active = (room.activePlayerIds ?? []).filter((p) => p !== uid);
                const updates = {
                    activePlayerIds: active,
                    updatedAt: now,
                    lastActivityAt: now,
                    stateVersion: currentVersion + 1,
                };
                if (active.length <= 1) {
                    updates['status'] = 'finished';
                    updates['winnerUid'] = active.length === 1 ? active[0] : null;
                }
                tx.update(roomRef, updates);
            }
            return { success: true };
        });
    });
});
exports.startGame = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.startGame), async (req) => {
    const { roomId, gameMode, settings, operationId } = req.data ?? {};
    if (!roomId)
        throw new https_1.HttpsError('invalid-argument', 'roomId gerekli');
    if (!req.auth)
        throw new https_1.HttpsError('unauthenticated', 'Oturum bulunamadı');
    const uid = req.auth.uid;
    await withTransactionRoom(roomId, async (tx, roomRef, room) => {
        return handleOperationIdempotency(tx, roomRef, uid, 'startGame', operationId, { roomId, gameMode, settings }, async () => {
            if (room.status !== 'waiting' && room.status !== 'finished') {
                throw new https_1.HttpsError('failed-precondition', 'Oyun zaten başlamış');
            }
            if (room.hostUid !== uid) {
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
            const currentWordType = mode === 'THEME' ? 'word' : (settings?.core?.posType?.toLowerCase() ?? 'verb');
            const currentVersion = room.stateVersion ?? 1;
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
                lastActivityAt: now,
                hostLastSeenAt: now,
                locked: true,
                gameMode: mode,
                stateVersion: currentVersion + 1,
            };
            if (settings != null)
                updatePayload['settings'] = settings;
            tx.update(roomRef, updatePayload);
            const usedDoc = roomRef.collection('meta').doc('usedWords');
            tx.set(usedDoc, { used: {} }, { merge: true });
            return { success: true };
        });
    });
    const playedWordsRef = admin.firestore().collection('rooms').doc(roomId).collection('playedWords');
    const playedWordsSnapshot = await playedWordsRef.get();
    if (!playedWordsSnapshot.empty) {
        const batch = admin.firestore().batch();
        playedWordsSnapshot.docs.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
    }
    return { success: true };
});
exports.startGameV2 = exports.startGame;
exports.submitWord = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.submitWord), async (req) => {
    const { roomId, word: rawWord, operationId } = req.data ?? {};
    const word = normalizeWord(rawWord);
    if (!roomId || !word)
        throw new https_1.HttpsError('invalid-argument', 'roomId ve kelime gerekli');
    if (!req.auth)
        throw new https_1.HttpsError('unauthenticated', 'Oturum bulunamadı');
    const uid = req.auth.uid;
    return withTransactionRoom(roomId, async (tx, roomRef, room) => {
        return handleOperationIdempotency(tx, roomRef, uid, 'submitWord', operationId, { roomId, word }, async () => {
            const now = nowTimestamp();
            const deadline = room.turnDeadlineAt;
            if (deadline && deadline.toMillis() <= now.toMillis()) {
                throw new https_1.HttpsError('deadline-exceeded', 'TIMEOUT');
            }
            if (room.status !== 'active')
                throw new https_1.HttpsError('failed-precondition', 'GAME_NOT_STARTED');
            if (room.currentTurnUid !== uid)
                throw new https_1.HttpsError('permission-denied', 'Sıran geldiğinde kelime gönderebilirsin');
            const settings = room.settings;
            const gameMode = (room.gameMode ?? 'CORE').toUpperCase();
            if (gameMode === 'THEME') {
                const packId = settings?.theme?.packId;
                if (!packId)
                    throw new https_1.HttpsError('failed-precondition', 'GAME_NOT_LOCKED');
                const packWords = packIdToWords.get(packId);
                if (!packWords?.has(word))
                    throw new https_1.HttpsError('invalid-argument', 'NOT_IN_PACK');
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
            if (active.length === 0)
                throw new https_1.HttpsError('failed-precondition', 'Aktif oyuncu bulunmuyor');
            const usedDoc = roomRef.collection('meta').doc('usedWords');
            const usedSnap = await tx.get(usedDoc);
            const usedMap = usedSnap.exists ? usedSnap.get('used') ?? {} : {};
            if (usedMap[word])
                throw new https_1.HttpsError('already-exists', 'DUPLICATE');
            const playedWordsRef = roomRef.collection('playedWords');
            const typeForDoc = gameMode === 'THEME' ? 'word' : (room.currentWordType ?? 'verb');
            tx.create(playedWordsRef.doc(), { word, type: typeForDoc, byUid: uid, at: now });
            tx.set(usedDoc, { used: { ...usedMap, [word]: true } }, { merge: true });
            const currentIndex = active.indexOf(uid);
            const nextIndex = (currentIndex + 1) % active.length;
            const nextUid = active[nextIndex];
            const duration = room.turnDurationSeconds ?? 12;
            const nextDeadline = admin.firestore.Timestamp.fromMillis(now.toMillis() + duration * 1000);
            const isHost = room.hostUid === uid;
            const currentVersion = room.stateVersion ?? 1;
            tx.update(roomRef, {
                currentTurnIndex: nextIndex,
                currentTurnUid: nextUid,
                turnDeadlineAt: nextDeadline,
                currentWordType: room.currentWordType ?? typeForDoc,
                updatedAt: now,
                lastActivityAt: now,
                ...(isHost ? { hostLastSeenAt: now } : { guestLastSeenAt: now }),
                stateVersion: currentVersion + 1,
            });
            return { success: true };
        });
    });
});
exports.submitWordV2 = exports.submitWord;
exports.submitVerb = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.submitVerb), async (req) => {
    const { roomId, verb: rawVerb, operationId } = req.data ?? {};
    const verb = normalizeWord(rawVerb);
    if (!roomId || !verb)
        throw new https_1.HttpsError('invalid-argument', 'roomId ve fiil gerekli');
    if (!req.auth)
        throw new https_1.HttpsError('unauthenticated', 'Oturum bulunamadı');
    const uid = req.auth.uid;
    return withTransactionRoom(roomId, async (tx, roomRef, room) => {
        return handleOperationIdempotency(tx, roomRef, uid, 'submitVerb', operationId, { roomId, verb }, async () => {
            const now = nowTimestamp();
            const deadline = room.turnDeadlineAt;
            if (deadline && deadline.toMillis() <= now.toMillis()) {
                throw new https_1.HttpsError('deadline-exceeded', 'Tur süresi dolmuş');
            }
            if (room.status !== 'active')
                throw new https_1.HttpsError('failed-precondition', 'Oyun aktif değil');
            if (room.currentTurnUid !== uid)
                throw new https_1.HttpsError('permission-denied', 'Sıran geldiğinde kelime gönderebilirsin');
            if (room.currentWordType !== 'verb' && room.currentWordType !== null) {
                throw new https_1.HttpsError('failed-precondition', 'Şu anda sıfat bekleniyor');
            }
            if (!validateDictionaryWord(verb, 'verb')) {
                throw new https_1.HttpsError('invalid-argument', `"${verb}" geçerli bir fiil değil`);
            }
            const active = Array.isArray(room.activePlayerIds) ? [...room.activePlayerIds] : [];
            if (active.length === 0)
                throw new https_1.HttpsError('failed-precondition', 'Aktif oyuncu bulunmuyor');
            const usedDoc = roomRef.collection('meta').doc('usedWords');
            const usedSnap = await tx.get(usedDoc);
            const usedMap = usedSnap.exists ? usedSnap.get('used') ?? {} : {};
            if (usedMap[verb])
                throw new https_1.HttpsError('already-exists', `"${verb}" daha önce kullanılmış`);
            const playedWordsRef = roomRef.collection('playedWords');
            tx.create(playedWordsRef.doc(), { word: verb, type: 'verb', byUid: uid, at: now });
            tx.set(usedDoc, { used: { ...usedMap, [verb]: true } }, { merge: true });
            const currentIndex = active.indexOf(uid);
            const nextIndex = (currentIndex + 1) % active.length;
            const nextUid = active[nextIndex];
            const duration = room.turnDurationSeconds ?? 12;
            const nextDeadline = admin.firestore.Timestamp.fromMillis(now.toMillis() + duration * 1000);
            const isHost = room.hostUid === uid;
            const currentVersion = room.stateVersion ?? 1;
            tx.update(roomRef, {
                currentTurnIndex: nextIndex,
                currentTurnUid: nextUid,
                currentWordType: 'verb',
                currentVerb: null,
                turnDeadlineAt: nextDeadline,
                updatedAt: now,
                lastActivityAt: now,
                ...(isHost ? { hostLastSeenAt: now } : { guestLastSeenAt: now }),
                stateVersion: currentVersion + 1,
            });
            return { success: true };
        });
    });
});
exports.submitAdjective = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.submitAdjective), async (req) => {
    const { roomId, adjective: rawAdj, operationId } = req.data ?? {};
    const adjective = normalizeWord(rawAdj);
    if (!roomId || !adjective)
        throw new https_1.HttpsError('invalid-argument', 'roomId ve sıfat gerekli');
    if (!req.auth)
        throw new https_1.HttpsError('unauthenticated', 'Oturum bulunamadı');
    const uid = req.auth.uid;
    return withTransactionRoom(roomId, async (tx, roomRef, room) => {
        return handleOperationIdempotency(tx, roomRef, uid, 'submitAdjective', operationId, { roomId, adjective }, async () => {
            const now = nowTimestamp();
            const deadline = room.turnDeadlineAt;
            if (deadline && deadline.toMillis() <= now.toMillis()) {
                throw new https_1.HttpsError('deadline-exceeded', 'Tur süresi dolmuş');
            }
            if (room.status !== 'active')
                throw new https_1.HttpsError('failed-precondition', 'Oyun aktif değil');
            if (room.currentTurnUid !== uid)
                throw new https_1.HttpsError('permission-denied', 'Sıran geldiğinde kelime gönderebilirsin');
            if (room.currentWordType !== 'adjective')
                throw new https_1.HttpsError('failed-precondition', 'Şu anda fiil bekleniyor');
            if (!validateDictionaryWord(adjective, 'adjective')) {
                throw new https_1.HttpsError('invalid-argument', `"${adjective}" geçerli bir sıfat değil`);
            }
            const active = Array.isArray(room.activePlayerIds) ? [...room.activePlayerIds] : [];
            if (active.length === 0)
                throw new https_1.HttpsError('failed-precondition', 'Aktif oyuncu bulunmuyor');
            const usedDoc = roomRef.collection('meta').doc('usedWords');
            const usedSnap = await tx.get(usedDoc);
            const usedMap = usedSnap.exists ? usedSnap.get('used') ?? {} : {};
            if (usedMap[adjective])
                throw new https_1.HttpsError('already-exists', `"${adjective}" daha önce kullanılmış`);
            const playedWordsRef = roomRef.collection('playedWords');
            tx.create(playedWordsRef.doc(), { word: adjective, type: 'adjective', byUid: uid, at: now });
            tx.set(usedDoc, { used: { ...usedMap, [adjective]: true } }, { merge: true });
            const currentIndex = active.indexOf(uid);
            const nextIndex = (currentIndex + 1) % active.length;
            const nextUid = active[nextIndex];
            const duration = room.turnDurationSeconds ?? 12;
            const nextDeadline = admin.firestore.Timestamp.fromMillis(now.toMillis() + duration * 1000);
            const isHost = room.hostUid === uid;
            const currentVersion = room.stateVersion ?? 1;
            tx.update(roomRef, {
                currentTurnIndex: nextIndex,
                currentTurnUid: nextUid,
                turnDeadlineAt: nextDeadline,
                currentWordType: 'verb',
                currentVerb: null,
                updatedAt: now,
                lastActivityAt: now,
                ...(isHost ? { hostLastSeenAt: now } : { guestLastSeenAt: now }),
                stateVersion: currentVersion + 1,
            });
            return { success: true };
        });
    });
});
exports.submitWordLegacy = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.submitWordLegacy), async (req) => {
    const { roomId, verb: rawVerb, adjective: rawAdj, operationId } = req.data ?? {};
    const verb = normalizeWord(rawVerb);
    const adjective = normalizeWord(rawAdj);
    if (!roomId || !verb || !adjective)
        throw new https_1.HttpsError('invalid-argument', 'Eksik parametre');
    if (!req.auth)
        throw new https_1.HttpsError('unauthenticated', 'Oturum bulunamadı');
    const uid = req.auth.uid;
    return withTransactionRoom(roomId, async (tx, roomRef, room) => {
        return handleOperationIdempotency(tx, roomRef, uid, 'submitWordLegacy', operationId, { roomId, verb, adjective }, async () => {
            const now = nowTimestamp();
            const deadline = room.turnDeadlineAt;
            if (deadline && deadline.toMillis() <= now.toMillis()) {
                throw new https_1.HttpsError('deadline-exceeded', 'Tur süresi dolmuş');
            }
            if (room.status !== 'active')
                throw new https_1.HttpsError('failed-precondition', 'Oyun aktif değil');
            if (room.currentTurnUid !== uid)
                throw new https_1.HttpsError('permission-denied', 'Sıran geldiğinde kelime gönderebilirsin');
            if (!validateDictionaryWord(verb, 'verb'))
                throw new https_1.HttpsError('invalid-argument', `"${verb}" geçerli bir fiil değil`);
            if (!validateDictionaryWord(adjective, 'adjective'))
                throw new https_1.HttpsError('invalid-argument', `"${adjective}" geçerli bir sıfat değil`);
            const active = Array.isArray(room.activePlayerIds) ? [...room.activePlayerIds] : [];
            if (active.length === 0)
                throw new https_1.HttpsError('failed-precondition', 'Aktif oyuncu bulunmuyor');
            const usedDoc = roomRef.collection('meta').doc('usedWords');
            const usedSnap = await tx.get(usedDoc);
            const usedMap = usedSnap.exists ? usedSnap.get('used') ?? {} : {};
            if (usedMap[verb])
                throw new https_1.HttpsError('already-exists', `"${verb}" daha önce kullanılmış`);
            if (usedMap[adjective])
                throw new https_1.HttpsError('already-exists', `"${adjective}" daha önce kullanılmış`);
            const playedWordsRef = roomRef.collection('playedWords');
            const basePayload = { byUid: uid, at: now };
            tx.create(playedWordsRef.doc(), { ...basePayload, word: verb, type: 'verb' });
            tx.create(playedWordsRef.doc(), { ...basePayload, word: adjective, type: 'adjective' });
            tx.set(usedDoc, { used: { ...usedMap, [verb]: true, [adjective]: true } }, { merge: true });
            const nextIndex = (room.currentTurnIndex + 1) % active.length;
            const nextUid = active[nextIndex];
            const duration = room.turnDurationSeconds ?? 12;
            const nextDeadline = admin.firestore.Timestamp.fromMillis(now.toMillis() + duration * 1000);
            const isHost = room.hostUid === uid;
            const currentVersion = room.stateVersion ?? 1;
            tx.update(roomRef, {
                currentTurnIndex: nextIndex,
                currentTurnUid: nextUid,
                turnDeadlineAt: nextDeadline,
                currentWordType: 'verb',
                currentVerb: null,
                updatedAt: now,
                lastActivityAt: now,
                ...(isHost ? { hostLastSeenAt: now } : { guestLastSeenAt: now }),
                stateVersion: currentVersion + 1,
            });
            return { success: true };
        });
    });
});
exports.resolveTimeout = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.resolveTimeout), async (req) => {
    const { roomId, operationId } = req.data ?? {};
    if (!roomId)
        throw new https_1.HttpsError('invalid-argument', 'roomId gerekli');
    if (operationId && req.auth) {
        const uid = req.auth.uid;
        const roomRef = getRoomRef(roomId);
        return db.runTransaction(async (tx) => {
            return handleOperationIdempotency(tx, roomRef, uid, 'resolveTimeout', operationId, { roomId }, async () => {
                const resolved = await resolveTimeoutInternal(roomId, operationId);
                return { resolved };
            });
        });
    }
    const resolved = await resolveTimeoutInternal(roomId);
    return { resolved };
});
exports.resolveTimeoutV2 = exports.resolveTimeout;
exports.sendHeartbeat = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.sendHeartbeat), async (req) => {
    if (!req.auth)
        throw new https_1.HttpsError('unauthenticated', 'Oturum bulunamadi');
    const uid = req.auth.uid;
    const { roomId, operationId } = req.data ?? {};
    if (!roomId)
        throw new https_1.HttpsError('invalid-argument', 'roomId gereklidir');
    return withTransactionRoom(roomId, async (tx, roomRef, room) => {
        return handleOperationIdempotency(tx, roomRef, uid, 'sendHeartbeat', operationId, { roomId }, async () => {
            const isHost = room.hostUid === uid;
            const isGuest = Array.isArray(room.players) && room.players.includes(uid) && !isHost;
            if (!isHost && !isGuest) {
                throw new https_1.HttpsError('permission-denied', 'Bu odanin uyesi degilsiniz');
            }
            const now = nowTimestamp();
            tx.update(roomRef, {
                lastActivityAt: now,
                ...(isHost ? { hostLastSeenAt: now } : { guestLastSeenAt: now }),
            });
            return { success: true };
        });
    });
});
exports.createArenaRoom = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.createArenaRoom), async (req) => {
    if (!req.auth)
        throw new https_1.HttpsError('unauthenticated', 'Oturum bulunamadi');
    const uid = req.auth.uid;
    const { roomCode: rawCode, level = 'A1', worksheetId = null, questionCount = 12, player, operationId } = req.data ?? {};
    let code = normalizeId(rawCode);
    if (!code)
        code = Math.floor(10000 + Math.random() * 90000).toString();
    const hostPlayer = {
        id: uid,
        name: player?.name ?? 'Host',
        photoUrl: player?.photoUrl ?? null,
        score: 0,
        isOnline: true,
        lastPing: nowTimestamp(),
    };
    return db.runTransaction(async (tx) => {
        return handleOperationIdempotency(tx, null, uid, 'createArenaRoom', operationId, { code, level, worksheetId, questionCount }, async (roomRef) => {
            const now = nowTimestamp();
            tx.set(roomRef, {
                id: roomRef.id,
                roomCode: code,
                status: 'waiting',
                hostId: uid,
                guestId: null,
                config: { level, worksheetId, questionCount },
                hostScore: 0,
                guestScore: 0,
                host: hostPlayer,
                guest: null,
                createdAt: now,
                lastActivityAt: now,
                hostLastSeenAt: now,
                guestLastSeenAt: null,
                stateVersion: 1,
            });
            return { roomId: roomRef.id, roomCode: code };
        });
    });
});
exports.joinArenaRoom = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.joinArenaRoom), async (req) => {
    if (!req.auth)
        throw new https_1.HttpsError('unauthenticated', 'Oturum bulunamadi');
    const uid = req.auth.uid;
    const { roomId: rawRoomId, roomCode: rawCode, player, operationId } = req.data ?? {};
    const code = normalizeId(rawCode);
    const roomIdInput = normalizeId(rawRoomId);
    let roomRef = null;
    if (roomIdInput) {
        roomRef = db.collection('arena_rooms').doc(roomIdInput);
    }
    else {
        if (!code)
            throw new https_1.HttpsError('invalid-argument', 'roomCode veya roomId gereklidir');
        let query = await db.collection('arena_rooms')
            .where('roomCode', '==', code)
            .limit(1)
            .get();
        if (query.empty) {
            await new Promise((r) => setTimeout(r, 100));
            query = await db.collection('arena_rooms')
                .where('roomCode', '==', code)
                .limit(1)
                .get();
        }
        if (query.empty)
            throw new https_1.HttpsError('not-found', 'Arena odasi bulunamadi');
        roomRef = query.docs[0].ref;
    }
    const guestPlayer = {
        id: uid,
        name: player?.name ?? 'Guest',
        photoUrl: player?.photoUrl ?? null,
        score: 0,
        isOnline: true,
        lastPing: nowTimestamp(),
    };
    return db.runTransaction(async (tx) => {
        return handleOperationIdempotency(tx, roomRef, uid, 'joinArenaRoom', operationId, { code }, async (targetRef) => {
            const snap = await tx.get(targetRef);
            if (!snap.exists)
                throw new https_1.HttpsError('not-found', 'Arena odasi bulunamadi');
            const room = snap.data();
            const now = nowTimestamp();
            if (room.hostId === uid) {
                tx.update(targetRef, {
                    lastActivityAt: now,
                    hostLastSeenAt: now,
                });
                return { roomId: targetRef.id, role: 'host' };
            }
            if (room.guestId != null && room.guestId !== uid) {
                throw new https_1.HttpsError('failed-precondition', 'Oda dolu');
            }
            const currentVersion = room.stateVersion ?? 1;
            tx.update(targetRef, {
                guestId: uid,
                guest: guestPlayer,
                lastActivityAt: now,
                guestLastSeenAt: now,
                stateVersion: currentVersion + 1,
            });
            return { roomId: targetRef.id, role: 'guest' };
        });
    });
});
exports.leaveArenaRoom = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.leaveArenaRoom), async (req) => {
    if (!req.auth)
        throw new https_1.HttpsError('unauthenticated', 'Oturum bulunamadi');
    const uid = req.auth.uid;
    const { roomId, operationId } = req.data ?? {};
    if (!roomId)
        throw new https_1.HttpsError('invalid-argument', 'roomId gereklidir');
    return withTransactionArenaRoom(roomId, async (tx, roomRef, room) => {
        return handleOperationIdempotency(tx, roomRef, uid, 'leaveArenaRoom', operationId, { roomId }, async () => {
            const now = nowTimestamp();
            const currentVersion = room.stateVersion ?? 1;
            if (room.status === 'waiting') {
                if (room.hostId === uid) {
                    tx.update(roomRef, { status: 'cancelled', lastActivityAt: now, stateVersion: currentVersion + 1 });
                }
                else if (room.guestId === uid) {
                    tx.update(roomRef, { guestId: null, guest: null, lastActivityAt: now, stateVersion: currentVersion + 1 });
                }
            }
            else if (room.status === 'active') {
                tx.update(roomRef, { status: 'finished', lastActivityAt: now, stateVersion: currentVersion + 1 });
            }
            return { success: true };
        });
    });
});
exports.startArenaMatch = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.startArenaMatch), async (req) => {
    if (!req.auth)
        throw new https_1.HttpsError('unauthenticated', 'Oturum bulunamadi');
    const uid = req.auth.uid;
    const { roomId, config, resolvedWorksheet, operationId } = req.data ?? {};
    if (!roomId)
        throw new https_1.HttpsError('invalid-argument', 'roomId gereklidir');
    return withTransactionArenaRoom(roomId, async (tx, roomRef, room) => {
        return handleOperationIdempotency(tx, roomRef, uid, 'startArenaMatch', operationId, { roomId, config, resolvedWorksheet }, async () => {
            if (room.hostId !== uid)
                throw new https_1.HttpsError('permission-denied', 'Sadece host baslatabilir');
            if (room.status !== 'waiting' && room.status !== 'finished') {
                throw new https_1.HttpsError('failed-precondition', 'Oyun zaten baslamis');
            }
            const now = nowTimestamp();
            const startAt = admin.firestore.Timestamp.fromMillis(now.toMillis() + 1000);
            const currentVersion = room.stateVersion ?? 1;
            tx.update(roomRef, {
                status: 'active',
                config: config ?? room.config,
                resolvedWorksheet: resolvedWorksheet ?? room.resolvedWorksheet,
                round: { index: 0, roundStartAt: startAt, timeLimitMs: 45000 },
                hostScore: 0,
                guestScore: 0,
                lastActivityAt: now,
                hostLastSeenAt: now,
                stateVersion: currentVersion + 1,
            });
            return { success: true };
        });
    });
});
exports.submitArenaAnswer = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.submitArenaAnswer), async (req) => {
    if (!req.auth)
        throw new https_1.HttpsError('unauthenticated', 'Oturum bulunamadi');
    const uid = req.auth.uid;
    const { roomId, roundIndex, answerValue, attempt = 1, operationId } = req.data ?? {};
    if (!roomId || roundIndex === undefined || answerValue === undefined) {
        throw new https_1.HttpsError('invalid-argument', 'Eksik parametreler');
    }
    return withTransactionArenaRoom(roomId, async (tx, roomRef, room) => {
        return handleOperationIdempotency(tx, roomRef, uid, 'submitArenaAnswer', operationId, { roomId, roundIndex, answerValue, attempt }, async () => {
            if (room.status !== 'active')
                throw new https_1.HttpsError('failed-precondition', 'Oyun aktif degil');
            if (room.hostId !== uid && room.guestId !== uid)
                throw new https_1.HttpsError('permission-denied', 'Bu odanin oyuncusu degilsiniz');
            const round = room.round;
            if (!round || round.index !== roundIndex) {
                throw new https_1.HttpsError('failed-precondition', 'Gecersiz tur indeksi');
            }
            const now = nowTimestamp();
            const elapsed = now.toMillis() - round.roundStartAt.toMillis();
            if (elapsed > round.timeLimitMs + 2000) {
                throw new https_1.HttpsError('deadline-exceeded', 'Tur suresi dolmus');
            }
            const answerDocRef = roomRef.collection('answers').doc(`${roundIndex}_${uid}_${attempt}`);
            const domainDedupeRef = roomRef.collection('round_answers').doc(`${roundIndex}_${uid}_${attempt}`);
            const hostAnswerRef = roomRef.collection('answers').doc(`${roundIndex}_${room.hostId}_${attempt}`);
            const guestAnswerRef = room.guestId ? roomRef.collection('answers').doc(`${roundIndex}_${room.guestId}_${attempt}`) : null;
            const domainSnap = await tx.get(domainDedupeRef);
            if (domainSnap.exists) {
                const existingData = domainSnap.data();
                return existingData.result;
            }
            const hostSnap = await tx.get(hostAnswerRef);
            const guestSnap = guestAnswerRef ? await tx.get(guestAnswerRef) : null;
            const items = room.resolvedWorksheet?.items ?? [];
            const item = items[roundIndex] ?? { id: `q_${roundIndex}`, engine: 'mcq', question: '', answer: answerValue };
            const isCorrect = (0, grammar_arena_helper_1.validateArenaAnswer)(item, answerValue);
            const pointsAwarded = (0, grammar_arena_helper_1.calculateArenaPoints)(isCorrect, attempt, item.engine, Math.max(0, elapsed), round.timeLimitMs);
            const answerPayload = {
                attempt,
                isCorrect,
                pointsAwarded,
                clientSentAt: Date.now(),
                byUid: uid,
            };
            tx.set(answerDocRef, answerPayload);
            let hostScore = room.hostScore ?? 0;
            let guestScore = room.guestScore ?? 0;
            if (uid === room.hostId) {
                hostScore += pointsAwarded;
            }
            else if (uid === room.guestId) {
                guestScore += pointsAwarded;
            }
            tx.set(domainDedupeRef, {
                uid,
                roundIndex,
                attempt,
                answerPayload,
                result: { isCorrect, pointsAwarded, hostScore, guestScore },
                createdAt: now,
            });
            const hostDone = (uid === room.hostId) || (hostSnap.exists && (hostSnap.get('isCorrect') || (hostSnap.get('attempt') ?? 1) >= 2));
            const guestDone = !room.guestId || (uid === room.guestId) || (guestSnap && guestSnap.exists && (guestSnap.get('isCorrect') || (guestSnap.get('attempt') ?? 1) >= 2));
            const isHost = uid === room.hostId;
            const currentVersion = room.stateVersion ?? 1;
            const updates = {
                hostScore,
                guestScore,
                lastActivityAt: now,
                ...(isHost ? { hostLastSeenAt: now } : { guestLastSeenAt: now }),
                stateVersion: currentVersion + 1,
            };
            if (hostDone && guestDone) {
                const hTime = (uid === room.hostId && isCorrect) ? answerPayload.clientSentAt : (hostSnap.exists && hostSnap.get('isCorrect') ? (hostSnap.get('clientSentAt') ?? 9999999999999) : Infinity);
                const gTime = (uid === room.guestId && isCorrect) ? answerPayload.clientSentAt : (guestSnap && guestSnap.exists && guestSnap.get('isCorrect') ? (guestSnap.get('clientSentAt') ?? 9999999999999) : Infinity);
                if (hTime < gTime && hTime !== Infinity) {
                    updates['hostScore'] = hostScore + (uid === room.hostId ? 20 : 0);
                }
                else if (gTime < hTime && gTime !== Infinity) {
                    updates['guestScore'] = guestScore + (uid === room.guestId ? 20 : 0);
                }
                const nextIndex = roundIndex + 1;
                const totalQuestions = room.resolvedWorksheet?.questionIds?.length ?? items.length ?? 12;
                if (nextIndex >= totalQuestions) {
                    updates['status'] = 'finished';
                }
                else {
                    updates['round'] = {
                        index: nextIndex,
                        roundStartAt: admin.firestore.Timestamp.fromMillis(now.toMillis() + 1000),
                        timeLimitMs: round.timeLimitMs,
                    };
                }
            }
            tx.update(roomRef, updates);
            const result = { isCorrect, pointsAwarded, hostScore: updates['hostScore'] ?? hostScore, guestScore: updates['guestScore'] ?? guestScore };
            return result;
        });
    });
});
exports.resolveArenaTimeout = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.resolveArenaTimeout), async (req) => {
    const { roomId, roundIndex, operationId } = req.data ?? {};
    if (!roomId)
        throw new https_1.HttpsError('invalid-argument', 'roomId gereklidir');
    return withTransactionArenaRoom(roomId, async (tx, roomRef, room) => {
        const uid = req.auth?.uid ?? 'system';
        return handleOperationIdempotency(tx, roomRef, uid, 'resolveArenaTimeout', operationId, { roomId, roundIndex }, async () => {
            if (room.status !== 'active' || !room.round)
                return { resolved: false };
            if (roundIndex !== undefined && room.round.index !== roundIndex)
                return { resolved: false };
            const now = nowTimestamp();
            const elapsed = now.toMillis() - room.round.roundStartAt.toMillis();
            if (elapsed < room.round.timeLimitMs)
                return { resolved: false };
            const nextIndex = room.round.index + 1;
            const totalQuestions = room.resolvedWorksheet?.questionIds?.length ?? 12;
            const currentVersion = room.stateVersion ?? 1;
            const updates = {
                lastActivityAt: now,
                stateVersion: currentVersion + 1,
            };
            if (nextIndex >= totalQuestions) {
                updates['status'] = 'finished';
            }
            else {
                updates['round'] = {
                    index: nextIndex,
                    roundStartAt: admin.firestore.Timestamp.fromMillis(now.toMillis() + 1000),
                    timeLimitMs: room.round.timeLimitMs,
                };
            }
            tx.update(roomRef, updates);
            return { resolved: true };
        });
    });
});
exports.updateArenaConfig = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.updateArenaConfig), async (req) => {
    if (!req.auth)
        throw new https_1.HttpsError('unauthenticated', 'Oturum bulunamadi');
    const uid = req.auth.uid;
    const { roomId, config, operationId } = req.data ?? {};
    if (!roomId || !config)
        throw new https_1.HttpsError('invalid-argument', 'roomId ve config gereklidir');
    return withTransactionArenaRoom(roomId, async (tx, roomRef, room) => {
        return handleOperationIdempotency(tx, roomRef, uid, 'updateArenaConfig', operationId, { roomId, config }, async () => {
            if (room.hostId !== uid)
                throw new https_1.HttpsError('permission-denied', 'Sadece host degistirebilir');
            if (room.status !== 'waiting')
                throw new https_1.HttpsError('failed-precondition', 'Oyun baslamis');
            const now = nowTimestamp();
            const currentVersion = room.stateVersion ?? 1;
            tx.update(roomRef, {
                config,
                lastActivityAt: now,
                hostLastSeenAt: now,
                stateVersion: currentVersion + 1,
            });
            return { success: true };
        });
    });
});
exports.sendArenaHeartbeat = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.sendArenaHeartbeat), async (req) => {
    if (!req.auth)
        throw new https_1.HttpsError('unauthenticated', 'Oturum bulunamadi');
    const uid = req.auth.uid;
    const { roomId, operationId } = req.data ?? {};
    if (!roomId)
        throw new https_1.HttpsError('invalid-argument', 'roomId gereklidir');
    return withTransactionArenaRoom(roomId, async (tx, roomRef, room) => {
        return handleOperationIdempotency(tx, roomRef, uid, 'sendArenaHeartbeat', operationId, { roomId }, async () => {
            const isHost = room.hostId === uid;
            const isGuest = room.guestId === uid;
            if (!isHost && !isGuest) {
                throw new https_1.HttpsError('permission-denied', 'Bu odanin uyesi degilsiniz');
            }
            const now = nowTimestamp();
            tx.update(roomRef, {
                lastActivityAt: now,
                ...(isHost ? { hostLastSeenAt: now } : { guestLastSeenAt: now }),
            });
            return { success: true };
        });
    });
});
exports.cleanupExpiredRooms = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.cleanupExpiredRooms), async (req) => {
    if (!req.auth) {
        throw new https_1.HttpsError('unauthenticated', 'Oturum bulunamadi');
    }
    if (!req.auth.token?.admin && req.auth.uid !== 'adminUser') {
        throw new https_1.HttpsError('permission-denied', 'Sadece yetkili admin sunucu temizligi calistirabilir');
    }
    const { nowMillis } = req.data ?? {};
    const result = await (0, room_cleanup_helper_1.cleanupExpiredRooms)(db, nowMillis);
    return result;
});
// --- Room Cleanup Scheduled Trigger (Every 5 Minutes) ---
exports.cleanupExpiredRoomsSchedule = (0, scheduler_1.onSchedule)({ schedule: 'every 5 minutes', region: 'us-central1' }, async () => {
    await (0, room_cleanup_helper_1.cleanupExpiredRooms)(db);
});
// ==========================================
// ============= FRIENDSHIP & DELETION ======
// ==========================================
// Sprint 8: all abuse-sensitive social and public-UGC mutations are routed
// through these callables. Their schema and authorization live in
// ugc_moderation.ts; rules intentionally deny direct writes.
exports.acceptCurrentUgcPolicy = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.acceptCurrentUgcPolicy), (req) => (0, ugc_moderation_1.acceptUgcPolicy)(req.auth, req.data));
exports.submitModerationReport = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.submitModerationReport), (req) => (0, ugc_moderation_1.submitReport)(req.auth, req.data));
exports.blockUser = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.blockUser), (req) => (0, ugc_moderation_1.blockUser)(req.auth, req.data));
exports.unblockUser = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.unblockUser), (req) => (0, ugc_moderation_1.blockUser)(req.auth, req.data, true));
exports.createFriendRequest = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.createFriendRequest), (req) => (0, ugc_moderation_1.createFriendRequest)(req.auth, req.data));
exports.resolveFriendRequest = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.resolveFriendRequest), (req) => (0, ugc_moderation_1.resolveFriendRequest)(req.auth, req.data));
exports.createSocialInvitation = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.createSocialInvitation), (req) => (0, ugc_moderation_1.createInvitation)(req.auth, req.data));
exports.acceptSocialInvitation = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.acceptSocialInvitation), (req) => (0, ugc_moderation_1.acceptInvitation)(req.auth, req.data));
exports.dismissSocialInvitation = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.dismissSocialInvitation), (req) => (0, ugc_moderation_1.dismissInvitation)(req.auth, req.data));
exports.publishWordMatchShare = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.publishWordMatchShare), (req) => (0, ugc_moderation_1.publishShare)(req.auth, req.data));
exports.removeWordMatchShare = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.removeWordMatchShare), (req) => (0, ugc_moderation_1.removeShare)(req.auth, req.data));
exports.updatePublicProfile = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.updatePublicProfile), (req) => (0, ugc_moderation_1.updatePublicProfile)(req.auth, req.data));
exports.submitEducationalContentReport = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.submitEducationalContentReport), (req) => (0, educational_content_reporting_1.submitEducationalContentReport)(req.auth, req.data));
exports.registerNotificationToken = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.registerNotificationToken), (req) => (0, push_notifications_1.registerNotificationToken)(req.auth, req.data));
exports.unregisterNotificationToken = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.unregisterNotificationToken), (req) => (0, push_notifications_1.unregisterNotificationToken)(req.auth, req.data));
exports.acceptFriendRequest = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.acceptFriendRequest), async (req) => {
    if (!req.auth)
        throw new https_1.HttpsError('unauthenticated', 'Oturum bulunamadı');
    let { requestId } = req.data ?? {};
    if (typeof requestId !== 'string') {
        throw new https_1.HttpsError('invalid-argument', 'Geçersiz requestId tipi');
    }
    requestId = requestId.trim();
    if (!requestId || requestId.length > 100 || requestId.includes('/') || requestId.includes('\\')) {
        throw new https_1.HttpsError('invalid-argument', 'Geçersiz requestId formatı');
    }
    const uid = req.auth.uid;
    const reqRef = db.collection('friend_requests').doc(requestId);
    return db.runTransaction(async (tx) => {
        const snap = await tx.get(reqRef);
        if (!snap.exists) {
            throw new https_1.HttpsError('not-found', 'Arkadaşlık isteği bulunamadı');
        }
        const data = snap.data();
        const fromUid = data.fromUid;
        const toUid = data.toUid;
        const status = data.status;
        if (typeof fromUid !== 'string' || typeof toUid !== 'string' ||
            !fromUid.trim() || !toUid.trim() ||
            fromUid.includes('/') || toUid.includes('/') ||
            fromUid.includes('\\') || toUid.includes('\\') ||
            fromUid.length > 100 || toUid.length > 100 ||
            fromUid !== fromUid.trim() || toUid !== toUid.trim() ||
            fromUid === toUid) {
            throw new https_1.HttpsError('failed-precondition', 'Geçersiz istek belgesi (UID formatı)');
        }
        if (typeof status !== 'string') {
            throw new https_1.HttpsError('failed-precondition', 'Geçersiz istek durumu (tip hatası)');
        }
        if (toUid !== uid) {
            throw new https_1.HttpsError('permission-denied', 'Bu isteği yalnızca alıcı kabul edebilir');
        }
        const [senderBlockedRecipient, recipientBlockedSender] = await Promise.all([
            tx.get(db.doc(`users/${fromUid}/blocks/${toUid}`)),
            tx.get(db.doc(`users/${toUid}/blocks/${fromUid}`)),
        ]);
        if (senderBlockedRecipient.exists || recipientBlockedSender.exists) {
            throw new https_1.HttpsError('failed-precondition', 'interaction-unavailable');
        }
        if (status !== 'pending' && status !== 'accepted') {
            throw new https_1.HttpsError('failed-precondition', 'Bu istek kabul edilemez durumda');
        }
        const aRef = db.collection('friendships').doc(fromUid).collection('friends').doc(toUid);
        const bRef = db.collection('friendships').doc(toUid).collection('friends').doc(fromUid);
        if (status === 'accepted') {
            const aSnap = await tx.get(aRef);
            const bSnap = await tx.get(bRef);
            if (aSnap.exists && bSnap.exists) {
                return { success: true, status: 'alreadyAccepted' };
            }
        }
        const now = nowTimestamp();
        const isoNow = new Date(now.toMillis()).toISOString();
        tx.update(reqRef, {
            status: 'accepted',
            updatedAt: isoNow,
        });
        const payload = { createdAt: isoNow };
        tx.set(aRef, payload, { merge: true });
        tx.set(bRef, payload, { merge: true });
        return { success: true, status: 'accepted' };
    });
});
const cleanupUserData = async (uid) => {
    console.log(`[cleanupUserData] Starting deletion for UID: ${uid}`);
    try {
        const friendsSnapshot = await db.collection('friendships').doc(uid).collection('friends').get();
        let batch = db.batch();
        let batchCount = 0;
        const commitBatchIfNeeded = async () => {
            if (batchCount > 400) {
                await batch.commit();
                batch = db.batch();
                batchCount = 0;
            }
        };
        for (const friendDoc of friendsSnapshot.docs) {
            const friendUid = friendDoc.id;
            const reciprocalRef = db.collection('friendships').doc(friendUid).collection('friends').doc(uid);
            batch.delete(reciprocalRef);
            batchCount++;
            await commitBatchIfNeeded();
        }
        if (batchCount > 0) {
            await batch.commit();
        }
        const collectionsToDelete = ['user_settings', 'user_stats', 'users', 'friendships'];
        for (const colName of collectionsToDelete) {
            const docRef = db.collection(colName).doc(uid);
            await db.recursiveDelete(docRef);
        }
        // Imported local copies are independent; only source documents owned by
        // this account are removed. Collection-group covers the canonical path.
        const setsSnapshot = await db.collectionGroup('word_match_sets').where('ownerUid', '==', uid).get();
        const setDeletionPromises = [];
        setsSnapshot.docs.forEach((doc) => {
            setDeletionPromises.push(db.recursiveDelete(doc.ref));
        });
        await Promise.all(setDeletionPromises);
        // Public link shares and every pending direct invitation involving the
        // account must not survive account deletion.
        const [shares, sentInvitations, receivedInvitations, blocksAgainstUser, reportsByUser, reportsAboutUser] = await Promise.all([
            db.collection('shares').where('ownerUid', '==', uid).get(),
            db.collectionGroup('invitations').where('fromUid', '==', uid).get(),
            db.collection(`users/${uid}/invitations`).get(),
            db.collectionGroup('blocks').where('blockedUid', '==', uid).get(),
            db.collection('moderation_reports').where('reporterUid', '==', uid).get(),
            db.collection('moderation_reports').where('targetOwnerUid', '==', uid).get(),
        ]);
        let ugcBatch = db.batch();
        let ugcBatchCount = 0;
        const commitUgcBatchIfNeeded = async () => {
            if (ugcBatchCount >= 400) {
                await ugcBatch.commit();
                ugcBatch = db.batch();
                ugcBatchCount = 0;
            }
        };
        for (const doc of [...shares.docs, ...sentInvitations.docs, ...receivedInvitations.docs, ...blocksAgainstUser.docs]) {
            ugcBatch.delete(doc.ref);
            ugcBatchCount++;
            await commitUgcBatchIfNeeded();
        }
        // Reports retain only lifecycle/reason evidence; identifiers for the
        // deleted account are pseudonymised instead of retaining a profile copy.
        for (const doc of reportsByUser.docs) {
            ugcBatch.update(doc.ref, { reporterUid: '__deleted__' });
            ugcBatchCount++;
            await commitUgcBatchIfNeeded();
        }
        for (const doc of reportsAboutUser.docs) {
            ugcBatch.update(doc.ref, { targetOwnerUid: '__deleted__' });
            ugcBatchCount++;
            await commitUgcBatchIfNeeded();
        }
        if (ugcBatchCount > 0)
            await ugcBatch.commit();
        const requestsFromUser = await db.collection('friend_requests').where('fromUid', '==', uid).get();
        const requestsToUser = await db.collection('friend_requests').where('toUid', '==', uid).get();
        let reqBatch = db.batch();
        let reqBatchCount = 0;
        const deleteDoc = async (doc) => {
            reqBatch.delete(doc.ref);
            reqBatchCount++;
            if (reqBatchCount > 400) {
                await reqBatch.commit();
                reqBatch = db.batch();
                reqBatchCount = 0;
            }
        };
        for (const doc of requestsFromUser.docs)
            await deleteDoc(doc);
        for (const doc of requestsToUser.docs)
            await deleteDoc(doc);
        if (reqBatchCount > 0) {
            await reqBatch.commit();
        }
        console.log(`[cleanupUserData] Successfully cleaned up data for user: ${uid}`);
    }
    catch (error) {
        console.error(`[cleanupUserData] Failed for user ${uid}:`, error);
        throw error;
    }
};
exports.cleanupUserData = cleanupUserData;
exports.onAuthUserDeleted = v1_1.auth.user().onDelete(async (user) => {
    return (0, exports.cleanupUserData)(user.uid);
});
exports.requestAccountDeletion = (0, https_1.onCall)(makeFunctionOptions(exports.APP_CHECK_ENFORCEMENT.requestAccountDeletion), async (req) => {
    if (!req.auth) {
        throw new https_1.HttpsError('unauthenticated', 'Oturum bulunamadı');
    }
    const uid = req.auth.uid;
    const authTime = req.auth.token.auth_time;
    const nowSeconds = Math.floor(Date.now() / 1000);
    if (!authTime || nowSeconds - authTime > 600) {
        throw new https_1.HttpsError('permission-denied', 'recent-login-required');
    }
    console.log(`[requestAccountDeletion] Starting deletion for UID: ${uid}`);
    try {
        await (0, exports.cleanupUserData)(uid);
        await admin.auth().deleteUser(uid);
        console.log(`[requestAccountDeletion] Successfully deleted user: ${uid}`);
        return { success: true };
    }
    catch (error) {
        console.error(`[requestAccountDeletion] Failed for user ${uid}:`, error);
        throw new https_1.HttpsError('internal', 'cleanupFailed');
    }
});
