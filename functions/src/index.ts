// --- src/index.ts (V2 uyumlu) ---
import * as admin from 'firebase-admin';
// v1 import'u kaldırıyoruz:
// import * as functions from 'firebase-functions';
import { onCall, HttpsError } from 'firebase-functions/v2/https';

import dictionary from './dictionary.json';
import easyPack from './easy_pack.json';
import mediumPack from './medium_pack.json';
import hardPack from './hard_pack.json';

admin.initializeApp();

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
    activePlayerIds: string[];
    currentTurnIndex: number;
    currentTurnUid?: string | null;
    turnDeadlineAt?: FirebaseFirestore.Timestamp | null;
    turnDurationSeconds: number;
    currentWordType?: string | null; // 'verb' or 'adjective' etc.
    currentVerb?: string | null;
    winnerUid?: string | null;
    hostUid: string;
    gameMode?: string | null; // 'THEME' | 'CORE'
    locked?: boolean;
    settings?: { theme?: { difficulty: string; packId: string; packTitle: string }; core?: { posType: string } } | null;
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

const getRoomRef = (roomId: string) => db.collection('rooms').doc(roomId);

const nowTimestamp = () => admin.firestore.Timestamp.now();

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

const resolveTimeoutInternal = async (roomId: string): Promise<boolean> => {
    return withTransactionRoom(roomId, async (tx, roomRef, room) => {
        const deadline = room.turnDeadlineAt;
        if (!deadline) return false;

        const now = nowTimestamp();
        if (deadline.toMillis() > now.toMillis()) return false;

        const active = Array.isArray(room.activePlayerIds) ? [...room.activePlayerIds] : [];
        const currentUid = room.currentTurnUid ?? null;
        const currentIndex = currentUid ? active.indexOf(currentUid) : -1;

        const updates: FirebaseFirestore.UpdateData<FirebaseFirestore.DocumentData> = {
            updatedAt: now,
        };

        // Remove player who timed out
        if (currentIndex !== -1) active.splice(currentIndex, 1);
        updates['activePlayerIds'] = active;
        updates['currentVerb'] = null;

        // Word Battle: THEME/CORE use single type per game; legacy verb/adjective alternate
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
            // After removing the timed-out player, the next player is at the same index
            // (or 0 if we were at the end)
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

// --------- Callable V2 (yeni isimlerle) ---------

export const getServerTime = onCall({ region: 'us-central1' }, async (_req) => {
    return { now: Date.now() };
});

// Alias for backward compatibility
export const getServerTimeV2 = getServerTime;

type StartGameInput = {
    roomId?: string;
    gameMode?: string; // 'THEME' | 'CORE'
    settings?: { theme?: { difficulty: string; packId: string; packTitle: string }; core?: { posType: string } };
};

export const startGame = onCall({ region: 'us-central1' }, async (req) => {
    const { roomId, gameMode, settings } = (req.data as StartGameInput) ?? {};
    if (!roomId) throw new HttpsError('invalid-argument', 'roomId gerekli');
    if (!req.auth) throw new HttpsError('unauthenticated', 'Oturum bulunamadı');

    await withTransactionRoom(roomId, async (tx, roomRef, room) => {
        if (room.status !== 'waiting' && room.status !== 'finished') {
            throw new HttpsError('failed-precondition', 'Oyun zaten başlamış');
        }
        if (room.hostUid !== req.auth!.uid) {
            throw new HttpsError('permission-denied', 'Sadece host oyunu başlatabilir');
        }

        const players = Array.isArray(room.players) ? [...room.players] : [];
        if (players.length < 2) {
            throw new HttpsError(
                'failed-precondition',
                'Oyunu başlatmak için en az iki oyuncu gerekir',
            );
        }

        const now = nowTimestamp();
        const active = Array.from(new Set(players));
        const randomIndex = Math.floor(Math.random() * active.length);
        const nextUid = active[randomIndex];
        const duration = room.turnDurationSeconds ?? 12;
        const deadline = admin.firestore.Timestamp.fromMillis(
            now.toMillis() + duration * 1000,
        );

        const mode = (gameMode ?? 'CORE').toUpperCase();
        const currentWordType = mode === 'THEME'
            ? 'word'
            : (settings?.core?.posType?.toLowerCase() ?? 'verb');

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
export const startGameV2 = startGame;

type ResolveTimeoutInput = { roomId?: string };

export const resolveTimeout = onCall({ region: 'us-central1' }, async (req) => {
    const { roomId } = (req.data as ResolveTimeoutInput) ?? {};
    if (!roomId) throw new HttpsError('invalid-argument', 'roomId gerekli');
    const resolved = await resolveTimeoutInternal(roomId);
    return { resolved };
});

// Alias for backward compatibility
export const resolveTimeoutV2 = resolveTimeout;

// Unified word submission for THEME and CORE modes (single word per turn)
type SubmitWordInput = { roomId?: string; word?: string };

export const submitWord = onCall({ region: 'us-central1' }, async (req) => {
    const { roomId, word: rawWord } = (req.data as SubmitWordInput) ?? {};
    const word = normalizeWord(rawWord);

    if (!roomId || !word) {
        throw new HttpsError('invalid-argument', 'roomId ve kelime gerekli');
    }
    if (!req.auth) {
        throw new HttpsError('unauthenticated', 'Oturum bulunamadı');
    }

    await withTransactionRoom(roomId, async (tx, roomRef, room) => {
        const now = nowTimestamp();
        const deadline = room.turnDeadlineAt;
        if (deadline && deadline.toMillis() <= now.toMillis()) {
            throw new HttpsError('deadline-exceeded', 'TIMEOUT');
        }
        if (room.status !== 'active') {
            throw new HttpsError('failed-precondition', 'GAME_NOT_STARTED');
        }
        if (room.currentTurnUid !== req.auth!.uid) {
            throw new HttpsError('permission-denied', 'Sıran geldiğinde kelime gönderebilirsin');
        }

        const settings = room.settings;
        const gameMode = (room.gameMode ?? 'CORE').toUpperCase();

        if (gameMode === 'THEME') {
            const packId = settings?.theme?.packId;
            if (!packId) {
                throw new HttpsError('failed-precondition', 'GAME_NOT_LOCKED');
            }
            const packWords = packIdToWords.get(packId);
            if (!packWords?.has(word)) {
                throw new HttpsError('invalid-argument', 'NOT_IN_PACK');
            }
        } else {
            const posType = settings?.core?.posType ?? 'verb';
            if (!validateDictionaryWord(word, posType)) {
                let inAnyType = false;
                for (const set of dictionaryMap.values()) {
                    if (set.has(word)) {
                        inAnyType = true;
                        break;
                    }
                }
                throw new HttpsError(
                    'invalid-argument',
                    inAnyType ? 'WRONG_TYPE' : 'NOT_IN_DICTIONARY',
                );
            }
        }

        const active = Array.isArray(room.activePlayerIds) ? [...room.activePlayerIds] : [];
        if (active.length === 0) {
            throw new HttpsError('failed-precondition', 'Aktif oyuncu bulunmuyor');
        }

        const usedDoc = roomRef.collection('meta').doc('usedWords');
        const usedSnap = await tx.get(usedDoc);
        const usedMap = usedSnap.exists
            ? (usedSnap.get('used') as Record<string, boolean> | undefined) ?? {}
            : {};
        if (usedMap[word]) {
            throw new HttpsError('already-exists', 'DUPLICATE');
        }

        const playedWordsRef = roomRef.collection('playedWords');
        const typeForDoc = gameMode === 'THEME' ? 'word' : (room.currentWordType ?? 'verb');
        tx.create(playedWordsRef.doc(), {
            word,
            type: typeForDoc,
            byUid: req.auth!.uid,
            at: now,
        });

        tx.set(
            usedDoc,
            { used: { ...usedMap, [word]: true } },
            { merge: true },
        );

        const currentIndex = active.indexOf(req.auth!.uid);
        const nextIndex = (currentIndex + 1) % active.length;
        const nextUid = active[nextIndex];
        const duration = room.turnDurationSeconds ?? 12;
        const nextDeadline = admin.firestore.Timestamp.fromMillis(
            now.toMillis() + duration * 1000,
        );

        tx.update(roomRef, {
            currentTurnIndex: nextIndex,
            currentTurnUid: nextUid,
            turnDeadlineAt: nextDeadline,
            currentWordType: room.currentWordType ?? typeForDoc,
            updatedAt: now,
        });
    });
});

// Two-phase word submission: verb first, then adjective (legacy CORE verb+adjective alternating)
type SubmitVerbInput = { roomId?: string; verb?: string };
type SubmitAdjectiveInput = { roomId?: string; adjective?: string };

const validateDictionaryWord = (word: string, type: string) => {
    const set = dictionaryMap.get(type);
    return set?.has(word) ?? false;
};

// Submit verb - player submits verb, then turn switches to next player for adjective
export const submitVerb = onCall({ region: 'us-central1' }, async (req) => {
    const { roomId, verb: rawVerb } = (req.data as SubmitVerbInput) ?? {};
    const verb = normalizeWord(rawVerb);

    if (!roomId || !verb) {
        throw new HttpsError('invalid-argument', 'roomId ve fiil gerekli');
    }
    if (!req.auth) {
        throw new HttpsError('unauthenticated', 'Oturum bulunamadı');
    }

    await withTransactionRoom(roomId, async (tx, roomRef, room) => {
        // Check deadline FIRST - before any other checks to reject expired turns immediately
        const now = nowTimestamp();
        const deadline = room.turnDeadlineAt;
        if (deadline && deadline.toMillis() <= now.toMillis()) {
            throw new HttpsError('deadline-exceeded', 'Tur süresi dolmuş');
        }

        if (room.status !== 'active') {
            throw new HttpsError('failed-precondition', 'Oyun aktif değil');
        }

        if (room.currentTurnUid !== req.auth!.uid) {
            throw new HttpsError(
                'permission-denied',
                'Sıran geldiğinde kelime gönderebilirsin',
            );
        }

        // Check if we're waiting for verb
        if (room.currentWordType !== 'verb' && room.currentWordType !== null) {
            throw new HttpsError('failed-precondition', 'Şu anda sıfat bekleniyor');
        }

        // Validate word (fast check)
        if (!validateDictionaryWord(verb, 'verb')) {
            throw new HttpsError('invalid-argument', `"${verb}" geçerli bir fiil değil`);
        }

        const active = Array.isArray(room.activePlayerIds) ? [...room.activePlayerIds] : [];
        if (active.length === 0) {
            throw new HttpsError('failed-precondition', 'Aktif oyuncu bulunmuyor');
        }

        const usedDoc = roomRef.collection('meta').doc('usedWords');
        const usedSnap = await tx.get(usedDoc);
        const usedMap = usedSnap.exists
            ? (usedSnap.get('used') as Record<string, boolean> | undefined) ?? {}
            : {};

        if (usedMap[verb]) {
            throw new HttpsError('already-exists', `"${verb}" daha önce kullanılmış`);
        }

        // Add verb to playedWords
        const playedWordsRef = roomRef.collection('playedWords');
        tx.create(playedWordsRef.doc(), {
            word: verb,
            type: 'verb',
            byUid: req.auth!.uid,
            at: now,
        });

        // Mark word as used
        tx.set(
            usedDoc,
            {
                used: {
                    ...usedMap,
                    [verb]: true,
                },
            },
            { merge: true },
        );

        // Switch to next player for verb (ensure single word turn)
        const currentIndex = active.indexOf(req.auth!.uid);
        const nextIndex = (currentIndex + 1) % active.length;
        const nextUid = active[nextIndex];
        const duration = room.turnDurationSeconds ?? 12;
        const nextDeadline = admin.firestore.Timestamp.fromMillis(
            now.toMillis() + duration * 1000,
        );

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
export const submitAdjective = onCall({ region: 'us-central1' }, async (req) => {
    const { roomId, adjective: rawAdj } = (req.data as SubmitAdjectiveInput) ?? {};
    const adjective = normalizeWord(rawAdj);

    if (!roomId || !adjective) {
        throw new HttpsError('invalid-argument', 'roomId ve sıfat gerekli');
    }
    if (!req.auth) {
        throw new HttpsError('unauthenticated', 'Oturum bulunamadı');
    }

    await withTransactionRoom(roomId, async (tx, roomRef, room) => {
        // Check deadline FIRST - before any other checks to reject expired turns immediately
        const now = nowTimestamp();
        const deadline = room.turnDeadlineAt;
        if (deadline && deadline.toMillis() <= now.toMillis()) {
            throw new HttpsError('deadline-exceeded', 'Tur süresi dolmuş');
        }

        if (room.status !== 'active') {
            throw new HttpsError('failed-precondition', 'Oyun aktif değil');
        }

        if (room.currentTurnUid !== req.auth!.uid) {
            throw new HttpsError(
                'permission-denied',
                'Sıran geldiğinde kelime gönderebilirsin',
            );
        }

        // Check if we're waiting for adjective
        if (room.currentWordType !== 'adjective') {
            throw new HttpsError('failed-precondition', 'Şu anda fiil bekleniyor');
        }

        // Validate word (fast check)
        if (!validateDictionaryWord(adjective, 'adjective')) {
            throw new HttpsError('invalid-argument', `"${adjective}" geçerli bir sıfat değil`);
        }

        const active = Array.isArray(room.activePlayerIds) ? [...room.activePlayerIds] : [];
        if (active.length === 0) {
            throw new HttpsError('failed-precondition', 'Aktif oyuncu bulunmuyor');
        }

        const usedDoc = roomRef.collection('meta').doc('usedWords');
        const usedSnap = await tx.get(usedDoc);
        const usedMap = usedSnap.exists
            ? (usedSnap.get('used') as Record<string, boolean> | undefined) ?? {}
            : {};

        if (usedMap[adjective]) {
            throw new HttpsError('already-exists', `"${adjective}" daha önce kullanılmış`);
        }

        // Add adjective to playedWords
        const playedWordsRef = roomRef.collection('playedWords');
        tx.create(playedWordsRef.doc(), {
            word: adjective,
            type: 'adjective',
            byUid: req.auth!.uid,
            at: now,
        });

        // Mark word as used
        tx.set(
            usedDoc,
            {
                used: {
                    ...usedMap,
                    [adjective]: true,
                },
            },
            { merge: true },
        );

        // Switch to next player for verb
        const currentIndex = active.indexOf(req.auth!.uid);
        const nextIndex = (currentIndex + 1) % active.length;
        const nextUid = active[nextIndex];
        const duration = room.turnDurationSeconds ?? 12;
        const nextDeadline = admin.firestore.Timestamp.fromMillis(
            now.toMillis() + duration * 1000,
        );

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

// Legacy submitWord function (verb+adjective at once) - backward compatibility only
type SubmitWordLegacyInput = { roomId?: string; verb?: string; adjective?: string };

export const submitWordLegacy = onCall({ region: 'us-central1' }, async (req) => {
    // Deprecated - use submitWord (THEME/CORE) or submitVerb+submitAdjective (legacy)
    // It's kept for backward compatibility only
    // New code should use submitVerb + submitAdjective separately
    const { roomId, verb: rawVerb, adjective: rawAdj } = (req.data as SubmitWordLegacyInput) ?? {};
    const verb = normalizeWord(rawVerb);
    const adjective = normalizeWord(rawAdj);

    if (!roomId || !verb || !adjective) {
        throw new HttpsError('invalid-argument', 'Eksik parametre');
    }
    if (!req.auth) {
        throw new HttpsError('unauthenticated', 'Oturum bulunamadı');
    }

    // Legacy: submit both at once (old behavior)
    // This doesn't use the two-phase timing system
    const timedOut = await resolveTimeoutInternal(roomId);
    if (timedOut) {
        throw new HttpsError('deadline-exceeded', 'Tur süresi dolmuş');
    }

    await withTransactionRoom(roomId, async (tx, roomRef, room) => {
        if (room.status !== 'active') {
            throw new HttpsError('failed-precondition', 'Oyun aktif değil');
        }

        if (room.currentTurnUid !== req.auth!.uid) {
            throw new HttpsError(
                'permission-denied',
                'Sıran geldiğinde kelime gönderebilirsin',
            );
        }

        if (!validateDictionaryWord(verb, 'verb')) {
            throw new HttpsError('invalid-argument', `"${verb}" geçerli bir fiil değil`);
        }
        if (!validateDictionaryWord(adjective, 'adjective')) {
            throw new HttpsError('invalid-argument', `"${adjective}" geçerli bir sıfat değil`);
        }

        const now = nowTimestamp();
        const deadline = room.turnDeadlineAt;
        if (deadline && deadline.toMillis() < now.toMillis()) {
            throw new HttpsError('deadline-exceeded', 'Tur süresi dolmuş');
        }

        const active = Array.isArray(room.activePlayerIds) ? [...room.activePlayerIds] : [];
        if (active.length === 0) {
            throw new HttpsError('failed-precondition', 'Aktif oyuncu bulunmuyor');
        }

        const usedDoc = roomRef.collection('meta').doc('usedWords');
        const usedSnap = await tx.get(usedDoc);
        const usedMap = usedSnap.exists
            ? (usedSnap.get('used') as Record<string, boolean> | undefined) ?? {}
            : {};

        if (usedMap[verb]) {
            throw new HttpsError('already-exists', `"${verb}" daha önce kullanılmış`);
        }
        if (usedMap[adjective]) {
            throw new HttpsError('already-exists', `"${adjective}" daha önce kullanılmış`);
        }

        const playedWordsRef = roomRef.collection('playedWords');
        const basePayload = {
            byUid: req.auth!.uid,
            at: now,
        };
        tx.create(playedWordsRef.doc(), { ...basePayload, word: verb, type: 'verb' });
        tx.create(playedWordsRef.doc(), { ...basePayload, word: adjective, type: 'adjective' });

        tx.set(
            usedDoc,
            {
                used: {
                    ...usedMap,
                    [verb]: true,
                    [adjective]: true,
                },
            },
            { merge: true },
        );

        const nextIndex = (room.currentTurnIndex + 1) % active.length;
        const nextUid = active[nextIndex];
        const duration = room.turnDurationSeconds ?? 12;
        const nextDeadline = admin.firestore.Timestamp.fromMillis(
            now.toMillis() + duration * 1000,
        );

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
export const submitWordV2 = submitWord;
