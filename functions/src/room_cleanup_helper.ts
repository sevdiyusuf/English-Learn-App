// --- src/room_cleanup_helper.ts ---
import * as admin from 'firebase-admin';

export const WAITING_ROOM_EXPIRY_MS = 10 * 60 * 1000; // 10 minutes
export const ACTIVE_ROOM_ABANDONED_MS = 5 * 60 * 1000; // 5 minutes
export const FINISHED_ROOM_RETENTION_MS = 24 * 60 * 60 * 1000; // 24 hours

export type CleanupResult = {
    processedCount: number;
    cancelledWaitingCount: number;
    abandonedActiveCount: number;
    deletedFinishedCount: number;
    errorsCount: number;
};

export type BeforeCandidateTransactionHook = (
    docId: string,
    collectionName: string,
    candidateStatus: 'waiting' | 'active' | 'finished',
) => Promise<void>;

export const cleanupExpiredRooms = async (
    db: admin.firestore.Firestore,
    nowMillis?: number,
    beforeCandidateTransaction?: BeforeCandidateTransactionHook,
): Promise<CleanupResult> => {
    const now = nowMillis ? admin.firestore.Timestamp.fromMillis(nowMillis) : admin.firestore.Timestamp.now();
    const nowMs = now.toMillis();

    const result: CleanupResult = {
        processedCount: 0,
        cancelledWaitingCount: 0,
        abandonedActiveCount: 0,
        deletedFinishedCount: 0,
        errorsCount: 0,
    };

    const collections = ['rooms', 'arena_rooms'];

    for (const colName of collections) {
        const colRef = db.collection(colName);

        // 1. Process Waiting Rooms
        try {
            const waitingSnap = await colRef
                .where('status', '==', 'waiting')
                .limit(50)
                .get();

            for (const doc of waitingSnap.docs) {
                result.processedCount++;
                const data = doc.data();
                const lastActivity = (data.lastActivityAt as admin.firestore.Timestamp) ?? (data.createdAt as admin.firestore.Timestamp) ?? null;
                const activityMs = lastActivity ? lastActivity.toMillis() : 0;

                if (activityMs > 0 && nowMs - activityMs >= WAITING_ROOM_EXPIRY_MS) {
                    if (beforeCandidateTransaction) {
                        await beforeCandidateTransaction(doc.id, colName, 'waiting');
                    }
                    try {
                        const mutated = await db.runTransaction(async (tx) => {
                            const freshSnap = await tx.get(doc.ref);
                            if (!freshSnap.exists) return false;
                            const freshData = freshSnap.data()!;
                            if (freshData.status !== 'waiting') return false;

                            const freshActivity = (freshData.lastActivityAt as admin.firestore.Timestamp) ?? (freshData.createdAt as admin.firestore.Timestamp) ?? null;
                            if (freshActivity && nowMs - freshActivity.toMillis() < WAITING_ROOM_EXPIRY_MS) {
                                return false;
                            }

                            const version = (freshData.stateVersion ?? 1) + 1;
                            tx.update(doc.ref, {
                                status: 'cancelled',
                                updatedAt: now,
                                stateVersion: version,
                            });
                            return true;
                        });
                        if (mutated) {
                            result.cancelledWaitingCount++;
                        }
                    } catch (e) {
                        result.errorsCount++;
                    }
                }
            }
        } catch (e) {
            result.errorsCount++;
        }

        // 2. Process Active Rooms (Abandoned)
        try {
            const activeSnap = await colRef
                .where('status', '==', 'active')
                .limit(50)
                .get();

            for (const doc of activeSnap.docs) {
                result.processedCount++;
                const data = doc.data();
                const lastActivity = (data.lastActivityAt as admin.firestore.Timestamp) ?? (data.updatedAt as admin.firestore.Timestamp) ?? null;
                const activityMs = lastActivity ? lastActivity.toMillis() : 0;

                if (activityMs > 0 && nowMs - activityMs >= ACTIVE_ROOM_ABANDONED_MS) {
                    if (beforeCandidateTransaction) {
                        await beforeCandidateTransaction(doc.id, colName, 'active');
                    }
                    try {
                        const mutated = await db.runTransaction(async (tx) => {
                            const freshSnap = await tx.get(doc.ref);
                            if (!freshSnap.exists) return false;
                            const freshData = freshSnap.data()!;
                            if (freshData.status !== 'active') return false;

                            const freshActivity = (freshData.lastActivityAt as admin.firestore.Timestamp) ?? (freshData.updatedAt as admin.firestore.Timestamp) ?? null;
                            if (freshActivity && nowMs - freshActivity.toMillis() < ACTIVE_ROOM_ABANDONED_MS) {
                                return false;
                            }

                            const version = (freshData.stateVersion ?? 1) + 1;
                            tx.update(doc.ref, {
                                status: 'finished',
                                winnerUid: null,
                                updatedAt: now,
                                stateVersion: version,
                            });
                            return true;
                        });
                        if (mutated) {
                            result.abandonedActiveCount++;
                        }
                    } catch (e) {
                        result.errorsCount++;
                    }
                }
            }
        } catch (e) {
            result.errorsCount++;
        }

        // 3. Process Finished/Cancelled Rooms (Retention Expiry -> Safe Soft/Hard Deletion)
        try {
            const finishedSnap = await colRef
                .where('status', 'in', ['finished', 'cancelled'])
                .limit(50)
                .get();

            for (const doc of finishedSnap.docs) {
                result.processedCount++;
                const data = doc.data();
                const updatedAt = (data.updatedAt as admin.firestore.Timestamp) ?? (data.createdAt as admin.firestore.Timestamp) ?? null;
                const updatedMs = updatedAt ? updatedAt.toMillis() : 0;

                if (updatedMs > 0 && nowMs - updatedMs >= FINISHED_ROOM_RETENTION_MS) {
                    if (beforeCandidateTransaction) {
                        await beforeCandidateTransaction(doc.id, colName, 'finished');
                    }
                    try {
                        await db.recursiveDelete(doc.ref);
                        result.deletedFinishedCount++;
                    } catch (e) {
                        result.errorsCount++;
                    }
                }
            }
        } catch (e) {
            result.errorsCount++;
        }
    }

    return result;
};
