// --- src/index.ts (Sprint 7B Server-Authoritative Core & Lifecycle) ---
import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { auth as authV1 } from 'firebase-functions/v1';

import dictionary from './dictionary.json';
import easyPack from './easy_pack.json';
import mediumPack from './medium_pack.json';
import hardPack from './hard_pack.json';
import {
    WorksheetItem,
    validateArenaAnswer,
    calculateArenaPoints,
} from './grammar_arena_helper';
import { cleanupExpiredRooms as runCleanupCore } from './room_cleanup_helper';
import {
    acceptInvitation as acceptModeratedInvitation,
    acceptUgcPolicy,
    blockUser as changeBlockedUser,
    createFriendRequest as createModeratedFriendRequest,
    resolveFriendRequest as resolveModeratedFriendRequest,
    createInvitation as createModeratedInvitation,
    dismissInvitation as dismissModeratedInvitation,
    publishShare,
    removeShare,
    submitReport,
    updatePublicProfile as updateModeratedPublicProfile,
} from './ugc_moderation';
import {
    registerNotificationToken as registerPushToken,
    unregisterNotificationToken as unregisterPushToken,
} from './push_notifications';
import { submitEducationalContentReport as submitEduReport } from './educational_content_reporting';

if (admin.apps.length === 0) {
    if (!process.env.FIRESTORE_EMULATOR_HOST && (process.env.FUNCTIONS_EMULATOR || process.env.NODE_ENV === 'test')) {
        process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
    }
    admin.initializeApp({
        projectId: process.env.GCLOUD_PROJECT || process.env.FIREBASE_PROJECT || 'demo-tamamm',
    });
}

export const APP_CHECK_ENFORCEMENT = {
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
} as const;

const makeFunctionOptions = (enforceAppCheck: boolean) => ({
    region: 'us-central1' as const,
    enforceAppCheck,
});

type PackJson = { level: string; packs: Array<{ id: string; title: string; words: string[] }> };
const allPacks: PackJson[] = [easyPack as PackJson, mediumPack as PackJson, hardPack as PackJson];
const packIdToWords = new Map<string, Set<string>>();
for (const packFile of allPacks) {
    for (const pack of packFile.packs ?? []) {
        const words = new Set<string>();
        for (const w of pack.words ?? []) {
            words.add(String(w).toLowerCase());
        }
        packIdToWords.set(pack.id, words);
    }
}

type RoomData = {
    status: string;
    players: string[];
    playerNames?: Record<string, string>;
    activePlayerIds: string[];
    currentTurnIndex: number;
    currentTurnUid?: string | null;
    turnDeadlineAt?: FirebaseFirestore.Timestamp | null;
    turnDurationSeconds: number;
    currentWordType?: string | null;
    currentVerb?: string | null;
    winnerUid?: string | null;
    hostUid: string;
    gameMode?: string | null;
    locked?: boolean;
    stateVersion?: number;
    lastActivityAt?: FirebaseFirestore.Timestamp | null;
    hostLastSeenAt?: FirebaseFirestore.Timestamp | null;
    guestLastSeenAt?: FirebaseFirestore.Timestamp | null;
    settings?: { theme?: { difficulty: string; packId: string; packTitle: string }; core?: { posType: string } } | null;
};

type ArenaRoomData = {
    id: string;
    roomCode: string;
    status: string;
    hostId: string;
    guestId?: string | null;
    config: { level: string; worksheetId?: string | null; questionCount: number };
    resolvedWorksheet?: {
        worksheetId: string;
        seed: number;
        questionIds: string[];
        items?: WorksheetItem[];
    } | null;
    round?: { index: number; roundStartAt: FirebaseFirestore.Timestamp; timeLimitMs: number } | null;
    hostScore: number;
    guestScore: number;
    host?: any;
    guest?: any;
    createdAt?: FirebaseFirestore.Timestamp | null;
    stateVersion?: number;
    lastActivityAt?: FirebaseFirestore.Timestamp | null;
    hostLastSeenAt?: FirebaseFirestore.Timestamp | null;
    guestLastSeenAt?: FirebaseFirestore.Timestamp | null;
};

const db = admin.firestore();

type DictionaryEntry = { word: string; type: string };
const dictionaryEntries = dictionary as DictionaryEntry[];

const dictionaryMap = new Map<string, Set<string>>();
for (const entry of dictionaryEntries) {
    const type = entry.type.toLowerCase();
    const word = entry.word.toLowerCase();
    const set = dictionaryMap.get(type) ?? new Set<string>();
    set.add(word);
    dictionaryMap.set(type, set);
}

const normalizeWord = (word: unknown): string => {
    if (typeof word !== 'string') return '';
    return word.trim().toLowerCase();
};

const normalizeId = (value: unknown): string => {
    if (typeof value !== 'string') return '';
    return value.trim();
};

export const validateOperationId = (opId: unknown): string => {
    if (!opId || typeof opId !== 'string') {
        throw new HttpsError('invalid-argument', 'operationId gereklidir');
    }
    const clean = opId.trim();
    if (clean.length < 8 || clean.length > 128) {
        throw new HttpsError('invalid-argument', 'operationId uzunlugu 8-128 karakter arasinda olmalidir');
    }
    if (!/^[a-zA-Z0-9_-]+$/.test(clean)) {
        throw new HttpsError('invalid-argument', 'operationId gecersiz karakterler iceriyor');
    }
    return clean;
};

const hashPayload = (payload: any): string => {
    try {
        return JSON.stringify(payload ?? {});
    } catch {
        return String(payload);
    }
};

const nowTimestamp = () => admin.firestore.Timestamp.now();

// --- Idempotency Helper ---
const handleOperationIdempotency = async <T>(
    tx: FirebaseFirestore.Transaction,
    parentRef: FirebaseFirestore.DocumentReference | null,
    uid: string,
    opType: string,
    operationId: string | undefined,
    payload: any,
    executeOp: (targetRef: FirebaseFirestore.DocumentReference) => Promise<T>,
): Promise<T> => {
    const cleanOpId = validateOperationId(operationId);
    const receiptRef = db.collection('operation_receipts').doc(`${cleanOpId}_${uid}`);
    const receiptSnap = await tx.get(receiptRef);
    const payloadFingerprint = hashPayload(payload);

    if (receiptSnap.exists) {
        const data = receiptSnap.data()!;
        if (data.uid !== uid) {
            throw new HttpsError('permission-denied', 'Bu operationId baska bir kullaniciya ait');
        }
        if (data.payloadFingerprint !== payloadFingerprint || data.opType !== opType) {
            throw new HttpsError('failed-precondition', 'IDEMPOTENCY_PAYLOAD_MISMATCH');
        }
        if (parentRef && data.roomId && data.roomId !== parentRef.id) {
            throw new HttpsError('failed-precondition', 'IDEMPOTENCY_PAYLOAD_MISMATCH');
        }
        return data.result as T;
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
const getRoomRef = (roomId: string) => db.collection('rooms').doc(roomId);
const getArenaRoomRef = (roomId: string) => db.collection('arena_rooms').doc(roomId);

const validateDictionaryWord = (word: string, type: string) => {
    const set = dictionaryMap.get(type);
    return set?.has(word) ?? false;
};

const withTransactionRoom = async <T>(
    roomId: string,
    handler: (
        tx: FirebaseFirestore.Transaction,
        roomRef: FirebaseFirestore.DocumentReference<admin.firestore.DocumentData>,
        room: RoomData,
        snapshot: FirebaseFirestore.DocumentSnapshot<admin.firestore.DocumentData>,
    ) => Promise<T>,
) => {
    const roomRef = getRoomRef(roomId);
    return db.runTransaction(async (tx) => {
        const snapshot = await tx.get(roomRef);
        if (!snapshot.exists) {
            throw new HttpsError('not-found', 'Oda bulunamadı');
        }
        const data = snapshot.data() as RoomData;
        return handler(tx, roomRef, data, snapshot);
    });
};

const withTransactionArenaRoom = async <T>(
    roomId: string,
    handler: (
        tx: FirebaseFirestore.Transaction,
        roomRef: FirebaseFirestore.DocumentReference<admin.firestore.DocumentData>,
        room: ArenaRoomData,
        snapshot: FirebaseFirestore.DocumentSnapshot<admin.firestore.DocumentData>,
    ) => Promise<T>,
) => {
    const roomRef = getArenaRoomRef(roomId);
    return db.runTransaction(async (tx) => {
        const snapshot = await tx.get(roomRef);
        if (!snapshot.exists) {
            throw new HttpsError('not-found', 'Arena odasi bulunamadi');
        }
        const data = snapshot.data() as ArenaRoomData;
        return handler(tx, roomRef, data, snapshot);
    });
};

// --- Word Match Internal Timeout Handler ---
const resolveTimeoutInternal = async (roomId: string, opId?: string): Promise<boolean> => {
    return withTransactionRoom(roomId, async (tx, roomRef, room) => {
        const deadline = room.turnDeadlineAt;
        if (!deadline) return false;

        const now = nowTimestamp();
        if (deadline.toMillis() > now.toMillis()) return false;

        const active = Array.isArray(room.activePlayerIds) ? [...room.activePlayerIds] : [];
        const currentUid = room.currentTurnUid ?? null;
        const currentIndex = currentUid ? active.indexOf(currentUid) : -1;

        const currentVersion = room.stateVersion ?? 1;
        const updates: FirebaseFirestore.UpdateData<FirebaseFirestore.DocumentData> = {
            updatedAt: now,
            lastActivityAt: now,
            stateVersion: currentVersion + 1,
        };

        if (currentIndex !== -1) active.splice(currentIndex, 1);
        updates['activePlayerIds'] = active;
        updates['currentVerb'] = null;

        const gameMode = (room as RoomData).gameMode;
        if (gameMode === 'THEME' || gameMode === 'CORE') {
            updates['currentWordType'] = room.currentWordType ?? 'word';
        } else if (room.currentWordType === 'verb') {
            updates['currentWordType'] = 'adjective';
        } else if (room.currentWordType === 'adjective') {
            updates['currentWordType'] = 'verb';
        } else {
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
        } else {
            const nextIndex = currentIndex < active.length ? currentIndex : 0;
            const nextUid = active[nextIndex];
            const duration = room.turnDurationSeconds ?? 12;
            const nextDeadline = admin.firestore.Timestamp.fromMillis(
                now.toMillis() + duration * 1000,
            );
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

export const getServerTime = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.getServerTime), async (_req) => {
    return { now: Date.now() };
});
export const getServerTimeV2 = getServerTime;

// --- Word Match: Create Room ---
type CreateRoomInput = {
    roomCode?: string;
    turnDurationSeconds?: number;
    username?: string;
    operationId?: string;
};

export const createRoom = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.createRoom), async (req) => {
    if (!req.auth) throw new HttpsError('unauthenticated', 'Oturum bulunamadi');
    const uid = req.auth.uid;
    const { roomCode: rawCode, turnDurationSeconds = 12, username = 'Host', operationId } = (req.data as CreateRoomInput) ?? {};

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

// --- Word Match: Join Room ---
type JoinRoomInput = {
    roomId?: string;
    roomCode?: string;
    username?: string;
    operationId?: string;
};

export const joinRoom = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.joinRoom), async (req) => {
    if (!req.auth) throw new HttpsError('unauthenticated', 'Oturum bulunamadi');
    const uid = req.auth.uid;
    const { roomId: rawRoomId, roomCode: rawCode, username = 'Player', operationId } = (req.data as JoinRoomInput) ?? {};
    const code = normalizeId(rawCode);
    const roomIdInput = normalizeId(rawRoomId);

    let roomRef: FirebaseFirestore.DocumentReference | null = null;
    if (roomIdInput) {
        roomRef = db.collection('rooms').doc(roomIdInput);
    } else {
        if (!code) throw new HttpsError('invalid-argument', 'roomCode veya roomId gereklidir');
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

        if (roomsQuery.empty) throw new HttpsError('not-found', 'Oda bulunamadi');
        roomRef = roomsQuery.docs[0].ref;
    }

    return db.runTransaction(async (tx) => {
        return handleOperationIdempotency(tx, roomRef!, uid, 'joinRoom', operationId, { code, username }, async (targetRef) => {
            const snap = await tx.get(targetRef);
            if (!snap.exists) throw new HttpsError('not-found', 'Oda bulunamadi');
            const room = snap.data() as RoomData;
            const now = nowTimestamp();

            if (room.status !== 'waiting') throw new HttpsError('failed-precondition', 'Oda katilima acik degil');

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

            if (players.length >= 2) throw new HttpsError('failed-precondition', 'Oda dolu');

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

// --- Word Match: Leave Room ---
type LeaveRoomInput = {
    roomId?: string;
    operationId?: string;
};

export const leaveRoom = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.leaveRoom), async (req) => {
    if (!req.auth) throw new HttpsError('unauthenticated', 'Oturum bulunamadi');
    const uid = req.auth.uid;
    const { roomId, operationId } = (req.data as LeaveRoomInput) ?? {};
    if (!roomId) throw new HttpsError('invalid-argument', 'roomId gereklidir');

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
                } else {
                    const players = (room.players ?? []).filter((p) => p !== uid);
                    tx.update(roomRef, {
                        players,
                        updatedAt: now,
                        lastActivityAt: now,
                        stateVersion: currentVersion + 1,
                    });
                }
            } else if (room.status === 'active') {
                const active = (room.activePlayerIds ?? []).filter((p) => p !== uid);
                const updates: FirebaseFirestore.UpdateData<FirebaseFirestore.DocumentData> = {
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

// --- Word Match: Start Game ---
type StartGameInput = {
    roomId?: string;
    gameMode?: string;
    settings?: { theme?: { difficulty: string; packId: string; packTitle: string }; core?: { posType: string } };
    operationId?: string;
};

export const startGame = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.startGame), async (req) => {
    const { roomId, gameMode, settings, operationId } = (req.data as StartGameInput) ?? {};
    if (!roomId) throw new HttpsError('invalid-argument', 'roomId gerekli');
    if (!req.auth) throw new HttpsError('unauthenticated', 'Oturum bulunamadı');
    const uid = req.auth.uid;

    await withTransactionRoom(roomId, async (tx, roomRef, room) => {
        return handleOperationIdempotency(tx, roomRef, uid, 'startGame', operationId, { roomId, gameMode, settings }, async () => {
            if (room.status !== 'waiting' && room.status !== 'finished') {
                throw new HttpsError('failed-precondition', 'Oyun zaten başlamış');
            }
            if (room.hostUid !== uid) {
                throw new HttpsError('permission-denied', 'Sadece host oyunu başlatabilir');
            }

            const players = Array.isArray(room.players) ? [...room.players] : [];
            if (players.length < 2) {
                throw new HttpsError('failed-precondition', 'Oyunu başlatmak için en az iki oyuncu gerekir');
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
            const updatePayload: FirebaseFirestore.UpdateData<FirebaseFirestore.DocumentData> = {
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
            if (settings != null) updatePayload['settings'] = settings;

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
export const startGameV2 = startGame;

// --- Word Match: Submit Word ---
type SubmitWordInput = { roomId?: string; word?: string; operationId?: string };

export const submitWord = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.submitWord), async (req) => {
    const { roomId, word: rawWord, operationId } = (req.data as SubmitWordInput) ?? {};
    const word = normalizeWord(rawWord);

    if (!roomId || !word) throw new HttpsError('invalid-argument', 'roomId ve kelime gerekli');
    if (!req.auth) throw new HttpsError('unauthenticated', 'Oturum bulunamadı');
    const uid = req.auth.uid;

    return withTransactionRoom(roomId, async (tx, roomRef, room) => {
        return handleOperationIdempotency(tx, roomRef, uid, 'submitWord', operationId, { roomId, word }, async () => {
            const now = nowTimestamp();
            const deadline = room.turnDeadlineAt;
            if (deadline && deadline.toMillis() <= now.toMillis()) {
                throw new HttpsError('deadline-exceeded', 'TIMEOUT');
            }
            if (room.status !== 'active') throw new HttpsError('failed-precondition', 'GAME_NOT_STARTED');
            if (room.currentTurnUid !== uid) throw new HttpsError('permission-denied', 'Sıran geldiğinde kelime gönderebilirsin');

            const settings = room.settings;
            const gameMode = (room.gameMode ?? 'CORE').toUpperCase();

            if (gameMode === 'THEME') {
                const packId = settings?.theme?.packId;
                if (!packId) throw new HttpsError('failed-precondition', 'GAME_NOT_LOCKED');
                const packWords = packIdToWords.get(packId);
                if (!packWords?.has(word)) throw new HttpsError('invalid-argument', 'NOT_IN_PACK');
            } else {
                const posType = settings?.core?.posType ?? 'verb';
                if (!validateDictionaryWord(word, posType)) {
                    let inAnyType = false;
                    for (const set of dictionaryMap.values()) {
                        if (set.has(word)) { inAnyType = true; break; }
                    }
                    throw new HttpsError('invalid-argument', inAnyType ? 'WRONG_TYPE' : 'NOT_IN_DICTIONARY');
                }
            }

            const active = Array.isArray(room.activePlayerIds) ? [...room.activePlayerIds] : [];
            if (active.length === 0) throw new HttpsError('failed-precondition', 'Aktif oyuncu bulunmuyor');

            const usedDoc = roomRef.collection('meta').doc('usedWords');
            const usedSnap = await tx.get(usedDoc);
            const usedMap = usedSnap.exists ? (usedSnap.get('used') as Record<string, boolean> | undefined) ?? {} : {};
            if (usedMap[word]) throw new HttpsError('already-exists', 'DUPLICATE');

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
export const submitWordV2 = submitWord;

// --- Word Match: Submit Verb ---
type SubmitVerbInput = { roomId?: string; verb?: string; operationId?: string };

export const submitVerb = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.submitVerb), async (req) => {
    const { roomId, verb: rawVerb, operationId } = (req.data as SubmitVerbInput) ?? {};
    const verb = normalizeWord(rawVerb);

    if (!roomId || !verb) throw new HttpsError('invalid-argument', 'roomId ve fiil gerekli');
    if (!req.auth) throw new HttpsError('unauthenticated', 'Oturum bulunamadı');
    const uid = req.auth.uid;

    return withTransactionRoom(roomId, async (tx, roomRef, room) => {
        return handleOperationIdempotency(tx, roomRef, uid, 'submitVerb', operationId, { roomId, verb }, async () => {
            const now = nowTimestamp();
            const deadline = room.turnDeadlineAt;
            if (deadline && deadline.toMillis() <= now.toMillis()) {
                throw new HttpsError('deadline-exceeded', 'Tur süresi dolmuş');
            }
            if (room.status !== 'active') throw new HttpsError('failed-precondition', 'Oyun aktif değil');
            if (room.currentTurnUid !== uid) throw new HttpsError('permission-denied', 'Sıran geldiğinde kelime gönderebilirsin');
            if (room.currentWordType !== 'verb' && room.currentWordType !== null) {
                throw new HttpsError('failed-precondition', 'Şu anda sıfat bekleniyor');
            }

            if (!validateDictionaryWord(verb, 'verb')) {
                throw new HttpsError('invalid-argument', `"${verb}" geçerli bir fiil değil`);
            }

            const active = Array.isArray(room.activePlayerIds) ? [...room.activePlayerIds] : [];
            if (active.length === 0) throw new HttpsError('failed-precondition', 'Aktif oyuncu bulunmuyor');

            const usedDoc = roomRef.collection('meta').doc('usedWords');
            const usedSnap = await tx.get(usedDoc);
            const usedMap = usedSnap.exists ? (usedSnap.get('used') as Record<string, boolean> | undefined) ?? {} : {};

            if (usedMap[verb]) throw new HttpsError('already-exists', `"${verb}" daha önce kullanılmış`);

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

// --- Word Match: Submit Adjective ---
type SubmitAdjectiveInput = { roomId?: string; adjective?: string; operationId?: string };

export const submitAdjective = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.submitAdjective), async (req) => {
    const { roomId, adjective: rawAdj, operationId } = (req.data as SubmitAdjectiveInput) ?? {};
    const adjective = normalizeWord(rawAdj);

    if (!roomId || !adjective) throw new HttpsError('invalid-argument', 'roomId ve sıfat gerekli');
    if (!req.auth) throw new HttpsError('unauthenticated', 'Oturum bulunamadı');
    const uid = req.auth.uid;

    return withTransactionRoom(roomId, async (tx, roomRef, room) => {
        return handleOperationIdempotency(tx, roomRef, uid, 'submitAdjective', operationId, { roomId, adjective }, async () => {
            const now = nowTimestamp();
            const deadline = room.turnDeadlineAt;
            if (deadline && deadline.toMillis() <= now.toMillis()) {
                throw new HttpsError('deadline-exceeded', 'Tur süresi dolmuş');
            }
            if (room.status !== 'active') throw new HttpsError('failed-precondition', 'Oyun aktif değil');
            if (room.currentTurnUid !== uid) throw new HttpsError('permission-denied', 'Sıran geldiğinde kelime gönderebilirsin');
            if (room.currentWordType !== 'adjective') throw new HttpsError('failed-precondition', 'Şu anda fiil bekleniyor');

            if (!validateDictionaryWord(adjective, 'adjective')) {
                throw new HttpsError('invalid-argument', `"${adjective}" geçerli bir sıfat değil`);
            }

            const active = Array.isArray(room.activePlayerIds) ? [...room.activePlayerIds] : [];
            if (active.length === 0) throw new HttpsError('failed-precondition', 'Aktif oyuncu bulunmuyor');

            const usedDoc = roomRef.collection('meta').doc('usedWords');
            const usedSnap = await tx.get(usedDoc);
            const usedMap = usedSnap.exists ? (usedSnap.get('used') as Record<string, boolean> | undefined) ?? {} : {};

            if (usedMap[adjective]) throw new HttpsError('already-exists', `"${adjective}" daha önce kullanılmış`);

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

// --- Word Match: Submit Legacy ---
type SubmitWordLegacyInput = { roomId?: string; verb?: string; adjective?: string; operationId?: string };

export const submitWordLegacy = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.submitWordLegacy), async (req) => {
    const { roomId, verb: rawVerb, adjective: rawAdj, operationId } = (req.data as SubmitWordLegacyInput) ?? {};
    const verb = normalizeWord(rawVerb);
    const adjective = normalizeWord(rawAdj);

    if (!roomId || !verb || !adjective) throw new HttpsError('invalid-argument', 'Eksik parametre');
    if (!req.auth) throw new HttpsError('unauthenticated', 'Oturum bulunamadı');
    const uid = req.auth.uid;

    return withTransactionRoom(roomId, async (tx, roomRef, room) => {
        return handleOperationIdempotency(tx, roomRef, uid, 'submitWordLegacy', operationId, { roomId, verb, adjective }, async () => {
            const now = nowTimestamp();
            const deadline = room.turnDeadlineAt;
            if (deadline && deadline.toMillis() <= now.toMillis()) {
                throw new HttpsError('deadline-exceeded', 'Tur süresi dolmuş');
            }
            if (room.status !== 'active') throw new HttpsError('failed-precondition', 'Oyun aktif değil');
            if (room.currentTurnUid !== uid) throw new HttpsError('permission-denied', 'Sıran geldiğinde kelime gönderebilirsin');

            if (!validateDictionaryWord(verb, 'verb')) throw new HttpsError('invalid-argument', `"${verb}" geçerli bir fiil değil`);
            if (!validateDictionaryWord(adjective, 'adjective')) throw new HttpsError('invalid-argument', `"${adjective}" geçerli bir sıfat değil`);

            const active = Array.isArray(room.activePlayerIds) ? [...room.activePlayerIds] : [];
            if (active.length === 0) throw new HttpsError('failed-precondition', 'Aktif oyuncu bulunmuyor');

            const usedDoc = roomRef.collection('meta').doc('usedWords');
            const usedSnap = await tx.get(usedDoc);
            const usedMap = usedSnap.exists ? (usedSnap.get('used') as Record<string, boolean> | undefined) ?? {} : {};

            if (usedMap[verb]) throw new HttpsError('already-exists', `"${verb}" daha önce kullanılmış`);
            if (usedMap[adjective]) throw new HttpsError('already-exists', `"${adjective}" daha önce kullanılmış`);

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

// --- Word Match: Resolve Timeout ---
type ResolveTimeoutInput = { roomId?: string; operationId?: string };

export const resolveTimeout = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.resolveTimeout), async (req) => {
    const { roomId, operationId } = (req.data as ResolveTimeoutInput) ?? {};
    if (!roomId) throw new HttpsError('invalid-argument', 'roomId gerekli');

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
export const resolveTimeoutV2 = resolveTimeout;

// --- Word Match: Send Heartbeat ---
type SendHeartbeatInput = { roomId?: string; operationId?: string };

export const sendHeartbeat = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.sendHeartbeat), async (req) => {
    if (!req.auth) throw new HttpsError('unauthenticated', 'Oturum bulunamadi');
    const uid = req.auth.uid;
    const { roomId, operationId } = (req.data as SendHeartbeatInput) ?? {};
    if (!roomId) throw new HttpsError('invalid-argument', 'roomId gereklidir');

    return withTransactionRoom(roomId, async (tx, roomRef, room) => {
        return handleOperationIdempotency(tx, roomRef, uid, 'sendHeartbeat', operationId, { roomId }, async () => {
            const isHost = room.hostUid === uid;
            const isGuest = Array.isArray(room.players) && room.players.includes(uid) && !isHost;

            if (!isHost && !isGuest) {
                throw new HttpsError('permission-denied', 'Bu odanin uyesi degilsiniz');
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

// ==========================================
// =========== GRAMMAR ARENA CALLABLES ======
// ==========================================

// --- Grammar Arena: Create Room ---
type CreateArenaRoomInput = {
    roomCode?: string;
    level?: string;
    worksheetId?: string;
    questionCount?: number;
    player?: any;
    operationId?: string;
};

export const createArenaRoom = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.createArenaRoom), async (req) => {
    if (!req.auth) throw new HttpsError('unauthenticated', 'Oturum bulunamadi');
    const uid = req.auth.uid;
    const { roomCode: rawCode, level = 'A1', worksheetId = null, questionCount = 12, player, operationId } = (req.data as CreateArenaRoomInput) ?? {};

    let code = normalizeId(rawCode);
    if (!code) code = Math.floor(10000 + Math.random() * 90000).toString();

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

// --- Grammar Arena: Join Room ---
type JoinArenaRoomInput = {
    roomId?: string;
    roomCode?: string;
    player?: any;
    operationId?: string;
};

export const joinArenaRoom = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.joinArenaRoom), async (req) => {
    if (!req.auth) throw new HttpsError('unauthenticated', 'Oturum bulunamadi');
    const uid = req.auth.uid;
    const { roomId: rawRoomId, roomCode: rawCode, player, operationId } = (req.data as JoinArenaRoomInput) ?? {};
    const code = normalizeId(rawCode);
    const roomIdInput = normalizeId(rawRoomId);

    let roomRef: FirebaseFirestore.DocumentReference | null = null;
    if (roomIdInput) {
        roomRef = db.collection('arena_rooms').doc(roomIdInput);
    } else {
        if (!code) throw new HttpsError('invalid-argument', 'roomCode veya roomId gereklidir');
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

        if (query.empty) throw new HttpsError('not-found', 'Arena odasi bulunamadi');
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
        return handleOperationIdempotency(tx, roomRef!, uid, 'joinArenaRoom', operationId, { code }, async (targetRef) => {
            const snap = await tx.get(targetRef);
            if (!snap.exists) throw new HttpsError('not-found', 'Arena odasi bulunamadi');
            const room = snap.data() as ArenaRoomData;
            const now = nowTimestamp();

            if (room.hostId === uid) {
                tx.update(targetRef, {
                    lastActivityAt: now,
                    hostLastSeenAt: now,
                });
                return { roomId: targetRef.id, role: 'host' };
            }

            if (room.guestId != null && room.guestId !== uid) {
                throw new HttpsError('failed-precondition', 'Oda dolu');
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

// --- Grammar Arena: Leave Room ---
type LeaveArenaRoomInput = {
    roomId?: string;
    operationId?: string;
};

export const leaveArenaRoom = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.leaveArenaRoom), async (req) => {
    if (!req.auth) throw new HttpsError('unauthenticated', 'Oturum bulunamadi');
    const uid = req.auth.uid;
    const { roomId, operationId } = (req.data as LeaveArenaRoomInput) ?? {};
    if (!roomId) throw new HttpsError('invalid-argument', 'roomId gereklidir');

    return withTransactionArenaRoom(roomId, async (tx, roomRef, room) => {
        return handleOperationIdempotency(tx, roomRef, uid, 'leaveArenaRoom', operationId, { roomId }, async () => {
            const now = nowTimestamp();
            const currentVersion = room.stateVersion ?? 1;
            if (room.status === 'waiting') {
                if (room.hostId === uid) {
                    tx.update(roomRef, { status: 'cancelled', lastActivityAt: now, stateVersion: currentVersion + 1 });
                } else if (room.guestId === uid) {
                    tx.update(roomRef, { guestId: null, guest: null, lastActivityAt: now, stateVersion: currentVersion + 1 });
                }
            } else if (room.status === 'active') {
                tx.update(roomRef, { status: 'finished', lastActivityAt: now, stateVersion: currentVersion + 1 });
            }
            return { success: true };
        });
    });
});

// --- Grammar Arena: Start Match ---
type StartArenaMatchInput = {
    roomId?: string;
    config?: any;
    resolvedWorksheet?: any;
    operationId?: string;
};

export const startArenaMatch = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.startArenaMatch), async (req) => {
    if (!req.auth) throw new HttpsError('unauthenticated', 'Oturum bulunamadi');
    const uid = req.auth.uid;
    const { roomId, config, resolvedWorksheet, operationId } = (req.data as StartArenaMatchInput) ?? {};
    if (!roomId) throw new HttpsError('invalid-argument', 'roomId gereklidir');

    return withTransactionArenaRoom(roomId, async (tx, roomRef, room) => {
        return handleOperationIdempotency(tx, roomRef, uid, 'startArenaMatch', operationId, { roomId, config, resolvedWorksheet }, async () => {
            if (room.hostId !== uid) throw new HttpsError('permission-denied', 'Sadece host baslatabilir');
            if (room.status !== 'waiting' && room.status !== 'finished') {
                throw new HttpsError('failed-precondition', 'Oyun zaten baslamis');
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

// --- Grammar Arena: Submit Answer ---
type SubmitArenaAnswerInput = {
    roomId?: string;
    roundIndex?: number;
    answerValue?: any;
    attempt?: number;
    operationId?: string;
};

export const submitArenaAnswer = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.submitArenaAnswer), async (req) => {
    if (!req.auth) throw new HttpsError('unauthenticated', 'Oturum bulunamadi');
    const uid = req.auth.uid;
    const { roomId, roundIndex, answerValue, attempt = 1, operationId } = (req.data as SubmitArenaAnswerInput) ?? {};

    if (!roomId || roundIndex === undefined || answerValue === undefined) {
        throw new HttpsError('invalid-argument', 'Eksik parametreler');
    }

    return withTransactionArenaRoom(roomId, async (tx, roomRef, room) => {
        return handleOperationIdempotency(tx, roomRef, uid, 'submitArenaAnswer', operationId, { roomId, roundIndex, answerValue, attempt }, async () => {
            if (room.status !== 'active') throw new HttpsError('failed-precondition', 'Oyun aktif degil');
            if (room.hostId !== uid && room.guestId !== uid) throw new HttpsError('permission-denied', 'Bu odanin oyuncusu degilsiniz');

            const round = room.round;
            if (!round || round.index !== roundIndex) {
                throw new HttpsError('failed-precondition', 'Gecersiz tur indeksi');
            }

            const now = nowTimestamp();
            const elapsed = now.toMillis() - round.roundStartAt.toMillis();
            if (elapsed > round.timeLimitMs + 2000) {
                throw new HttpsError('deadline-exceeded', 'Tur suresi dolmus');
            }

            const answerDocRef = roomRef.collection('answers').doc(`${roundIndex}_${uid}_${attempt}`);
            const domainDedupeRef = roomRef.collection('round_answers').doc(`${roundIndex}_${uid}_${attempt}`);
            const hostAnswerRef = roomRef.collection('answers').doc(`${roundIndex}_${room.hostId}_${attempt}`);
            const guestAnswerRef = room.guestId ? roomRef.collection('answers').doc(`${roundIndex}_${room.guestId}_${attempt}`) : null;

            const domainSnap = await tx.get(domainDedupeRef);
            if (domainSnap.exists) {
                const existingData = domainSnap.data()!;
                return existingData.result;
            }

            const hostSnap = await tx.get(hostAnswerRef);
            const guestSnap = guestAnswerRef ? await tx.get(guestAnswerRef) : null;

            const items = room.resolvedWorksheet?.items ?? [];
            const item = items[roundIndex] ?? { id: `q_${roundIndex}`, engine: 'mcq', question: '', answer: answerValue };

            const isCorrect = validateArenaAnswer(item, answerValue);
            const pointsAwarded = calculateArenaPoints(isCorrect, attempt, item.engine, Math.max(0, elapsed), round.timeLimitMs);

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
            } else if (uid === room.guestId) {
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
            const updates: FirebaseFirestore.UpdateData<FirebaseFirestore.DocumentData> = {
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
                } else if (gTime < hTime && gTime !== Infinity) {
                    updates['guestScore'] = guestScore + (uid === room.guestId ? 20 : 0);
                }

                const nextIndex = roundIndex + 1;
                const totalQuestions = room.resolvedWorksheet?.questionIds?.length ?? items.length ?? 12;
                if (nextIndex >= totalQuestions) {
                    updates['status'] = 'finished';
                } else {
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

// --- Grammar Arena: Resolve Timeout ---
type ResolveArenaTimeoutInput = { roomId?: string; roundIndex?: number; operationId?: string };

export const resolveArenaTimeout = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.resolveArenaTimeout), async (req) => {
    const { roomId, roundIndex, operationId } = (req.data as ResolveArenaTimeoutInput) ?? {};
    if (!roomId) throw new HttpsError('invalid-argument', 'roomId gereklidir');

    return withTransactionArenaRoom(roomId, async (tx, roomRef, room) => {
        const uid = req.auth?.uid ?? 'system';
        return handleOperationIdempotency(tx, roomRef, uid, 'resolveArenaTimeout', operationId, { roomId, roundIndex }, async () => {
            if (room.status !== 'active' || !room.round) return { resolved: false };
            if (roundIndex !== undefined && room.round.index !== roundIndex) return { resolved: false };

            const now = nowTimestamp();
            const elapsed = now.toMillis() - room.round.roundStartAt.toMillis();
            if (elapsed < room.round.timeLimitMs) return { resolved: false };

            const nextIndex = room.round.index + 1;
            const totalQuestions = room.resolvedWorksheet?.questionIds?.length ?? 12;
            const currentVersion = room.stateVersion ?? 1;

            const updates: FirebaseFirestore.UpdateData<FirebaseFirestore.DocumentData> = {
                lastActivityAt: now,
                stateVersion: currentVersion + 1,
            };

            if (nextIndex >= totalQuestions) {
                updates['status'] = 'finished';
            } else {
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

// --- Grammar Arena: Update Config ---
type UpdateArenaConfigInput = { roomId?: string; config?: any; operationId?: string };

export const updateArenaConfig = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.updateArenaConfig), async (req) => {
    if (!req.auth) throw new HttpsError('unauthenticated', 'Oturum bulunamadi');
    const uid = req.auth.uid;
    const { roomId, config, operationId } = (req.data as UpdateArenaConfigInput) ?? {};
    if (!roomId || !config) throw new HttpsError('invalid-argument', 'roomId ve config gereklidir');

    return withTransactionArenaRoom(roomId, async (tx, roomRef, room) => {
        return handleOperationIdempotency(tx, roomRef, uid, 'updateArenaConfig', operationId, { roomId, config }, async () => {
            if (room.hostId !== uid) throw new HttpsError('permission-denied', 'Sadece host degistirebilir');
            if (room.status !== 'waiting') throw new HttpsError('failed-precondition', 'Oyun baslamis');

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

// --- Grammar Arena: Send Heartbeat ---
type SendArenaHeartbeatInput = { roomId?: string; operationId?: string };

export const sendArenaHeartbeat = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.sendArenaHeartbeat), async (req) => {
    if (!req.auth) throw new HttpsError('unauthenticated', 'Oturum bulunamadi');
    const uid = req.auth.uid;
    const { roomId, operationId } = (req.data as SendArenaHeartbeatInput) ?? {};
    if (!roomId) throw new HttpsError('invalid-argument', 'roomId gereklidir');

    return withTransactionArenaRoom(roomId, async (tx, roomRef, room) => {
        return handleOperationIdempotency(tx, roomRef, uid, 'sendArenaHeartbeat', operationId, { roomId }, async () => {
            const isHost = room.hostId === uid;
            const isGuest = room.guestId === uid;

            if (!isHost && !isGuest) {
                throw new HttpsError('permission-denied', 'Bu odanin uyesi degilsiniz');
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

// --- Room Cleanup Callable (Manual/Test Trigger) ---
type CleanupExpiredRoomsInput = { nowMillis?: number };

export const cleanupExpiredRooms = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.cleanupExpiredRooms), async (req) => {
    if (!req.auth) {
        throw new HttpsError('unauthenticated', 'Oturum bulunamadi');
    }
    if (!req.auth.token?.admin && req.auth.uid !== 'adminUser') {
        throw new HttpsError('permission-denied', 'Sadece yetkili admin sunucu temizligi calistirabilir');
    }
    const { nowMillis } = (req.data as CleanupExpiredRoomsInput) ?? {};
    const result = await runCleanupCore(db, nowMillis);
    return result;
});

// --- Room Cleanup Scheduled Trigger (Every 5 Minutes) ---
export const cleanupExpiredRoomsSchedule = onSchedule(
    { schedule: 'every 5 minutes', region: 'us-central1' },
    async () => {
        await runCleanupCore(db);
    }
);

// ==========================================
// ============= FRIENDSHIP & DELETION ======
// ==========================================

// Sprint 8: all abuse-sensitive social and public-UGC mutations are routed
// through these callables. Their schema and authorization live in
// ugc_moderation.ts; rules intentionally deny direct writes.
export const acceptCurrentUgcPolicy = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.acceptCurrentUgcPolicy),
    (req) => acceptUgcPolicy(req.auth, req.data));
export const submitModerationReport = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.submitModerationReport),
    (req) => submitReport(req.auth, req.data));
export const blockUser = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.blockUser),
    (req) => changeBlockedUser(req.auth, req.data));
export const unblockUser = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.unblockUser),
    (req) => changeBlockedUser(req.auth, req.data, true));
export const createFriendRequest = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.createFriendRequest),
    (req) => createModeratedFriendRequest(req.auth, req.data));
export const resolveFriendRequest = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.resolveFriendRequest),
    (req) => resolveModeratedFriendRequest(req.auth, req.data));
export const createSocialInvitation = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.createSocialInvitation),
    (req) => createModeratedInvitation(req.auth, req.data));
export const acceptSocialInvitation = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.acceptSocialInvitation),
    (req) => acceptModeratedInvitation(req.auth, req.data));
export const dismissSocialInvitation = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.dismissSocialInvitation),
    (req) => dismissModeratedInvitation(req.auth, req.data));
export const publishWordMatchShare = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.publishWordMatchShare),
    (req) => publishShare(req.auth, req.data));
export const removeWordMatchShare = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.removeWordMatchShare),
    (req) => removeShare(req.auth, req.data));
export const updatePublicProfile = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.updatePublicProfile),
    (req) => updateModeratedPublicProfile(req.auth, req.data));
export const submitEducationalContentReport = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.submitEducationalContentReport),
    (req) => submitEduReport(req.auth, req.data));
export const registerNotificationToken = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.registerNotificationToken),
    (req) => registerPushToken(req.auth, req.data));
export const unregisterNotificationToken = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.unregisterNotificationToken),
    (req) => unregisterPushToken(req.auth, req.data));

type AcceptFriendRequestInput = { requestId?: string };

export const acceptFriendRequest = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.acceptFriendRequest), async (req) => {
    if (!req.auth) throw new HttpsError('unauthenticated', 'Oturum bulunamadı');

    let { requestId } = (req.data as AcceptFriendRequestInput) ?? {};
    if (typeof requestId !== 'string') {
        throw new HttpsError('invalid-argument', 'Geçersiz requestId tipi');
    }
    requestId = requestId.trim();
    if (!requestId || requestId.length > 100 || requestId.includes('/') || requestId.includes('\\')) {
        throw new HttpsError('invalid-argument', 'Geçersiz requestId formatı');
    }

    const uid = req.auth.uid;
    const reqRef = db.collection('friend_requests').doc(requestId);

    return db.runTransaction(async (tx) => {
        const snap = await tx.get(reqRef);
        if (!snap.exists) {
            throw new HttpsError('not-found', 'Arkadaşlık isteği bulunamadı');
        }

        const data = snap.data()!;
        const fromUid = data.fromUid;
        const toUid = data.toUid;
        const status = data.status;

        if (
            typeof fromUid !== 'string' || typeof toUid !== 'string' ||
            !fromUid.trim() || !toUid.trim() ||
            fromUid.includes('/') || toUid.includes('/') ||
            fromUid.includes('\\') || toUid.includes('\\') ||
            fromUid.length > 100 || toUid.length > 100 ||
            fromUid !== fromUid.trim() || toUid !== toUid.trim() ||
            fromUid === toUid
        ) {
            throw new HttpsError('failed-precondition', 'Geçersiz istek belgesi (UID formatı)');
        }

        if (typeof status !== 'string') {
            throw new HttpsError('failed-precondition', 'Geçersiz istek durumu (tip hatası)');
        }

        if (toUid !== uid) {
            throw new HttpsError('permission-denied', 'Bu isteği yalnızca alıcı kabul edebilir');
        }

        const [senderBlockedRecipient, recipientBlockedSender] = await Promise.all([
            tx.get(db.doc(`users/${fromUid}/blocks/${toUid}`)),
            tx.get(db.doc(`users/${toUid}/blocks/${fromUid}`)),
        ]);
        if (senderBlockedRecipient.exists || recipientBlockedSender.exists) {
            throw new HttpsError('failed-precondition', 'interaction-unavailable');
        }

        if (status !== 'pending' && status !== 'accepted') {
            throw new HttpsError('failed-precondition', 'Bu istek kabul edilemez durumda');
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

export const cleanupUserData = async (uid: string) => {
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
        const setDeletionPromises: Promise<void>[] = [];
        setsSnapshot.docs.forEach((doc) => {
            setDeletionPromises.push(db.recursiveDelete(doc.ref));
        });
        await Promise.all(setDeletionPromises);

        // Public link shares and every pending direct invitation involving the
        // account must not survive account deletion.
        const [shares, sentInvitations, receivedInvitations, blocksAgainstUser,
            reportsByUser, reportsAboutUser] = await Promise.all([
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
            if (ugcBatchCount >= 400) { await ugcBatch.commit(); ugcBatch = db.batch(); ugcBatchCount = 0; }
        };
        for (const doc of [...shares.docs, ...sentInvitations.docs, ...receivedInvitations.docs, ...blocksAgainstUser.docs]) {
            ugcBatch.delete(doc.ref); ugcBatchCount++; await commitUgcBatchIfNeeded();
        }
        // Reports retain only lifecycle/reason evidence; identifiers for the
        // deleted account are pseudonymised instead of retaining a profile copy.
        for (const doc of reportsByUser.docs) {
            ugcBatch.update(doc.ref, { reporterUid: '__deleted__' }); ugcBatchCount++; await commitUgcBatchIfNeeded();
        }
        for (const doc of reportsAboutUser.docs) {
            ugcBatch.update(doc.ref, { targetOwnerUid: '__deleted__' }); ugcBatchCount++; await commitUgcBatchIfNeeded();
        }
        if (ugcBatchCount > 0) await ugcBatch.commit();

        const requestsFromUser = await db.collection('friend_requests').where('fromUid', '==', uid).get();
        const requestsToUser = await db.collection('friend_requests').where('toUid', '==', uid).get();

        let reqBatch = db.batch();
        let reqBatchCount = 0;
        const deleteDoc = async (doc: FirebaseFirestore.DocumentSnapshot) => {
            reqBatch.delete(doc.ref);
            reqBatchCount++;
            if (reqBatchCount > 400) {
                await reqBatch.commit();
                reqBatch = db.batch();
                reqBatchCount = 0;
            }
        };
        for (const doc of requestsFromUser.docs) await deleteDoc(doc);
        for (const doc of requestsToUser.docs) await deleteDoc(doc);

        if (reqBatchCount > 0) {
            await reqBatch.commit();
        }
        console.log(`[cleanupUserData] Successfully cleaned up data for user: ${uid}`);
    } catch (error) {
        console.error(`[cleanupUserData] Failed for user ${uid}:`, error);
        throw error;
    }
};

export const onAuthUserDeleted = authV1.user().onDelete(async (user) => {
    return cleanupUserData(user.uid);
});

export const requestAccountDeletion = onCall(makeFunctionOptions(APP_CHECK_ENFORCEMENT.requestAccountDeletion), async (req) => {
    if (!req.auth) {
        throw new HttpsError('unauthenticated', 'Oturum bulunamadı');
    }

    const uid = req.auth.uid;
    const authTime = req.auth.token.auth_time;
    const nowSeconds = Math.floor(Date.now() / 1000);
    if (!authTime || nowSeconds - authTime > 600) {
        throw new HttpsError('permission-denied', 'recent-login-required');
    }

    console.log(`[requestAccountDeletion] Starting deletion for UID: ${uid}`);

    try {
        await cleanupUserData(uid);
        await admin.auth().deleteUser(uid);
        console.log(`[requestAccountDeletion] Successfully deleted user: ${uid}`);
        return { success: true };
    } catch (error) {
        console.error(`[requestAccountDeletion] Failed for user ${uid}:`, error);
        throw new HttpsError('internal', 'cleanupFailed');
    }
});
