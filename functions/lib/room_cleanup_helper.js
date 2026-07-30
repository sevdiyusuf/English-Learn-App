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
exports.cleanupExpiredRooms = exports.FINISHED_ROOM_RETENTION_MS = exports.ACTIVE_ROOM_ABANDONED_MS = exports.WAITING_ROOM_EXPIRY_MS = void 0;
// --- src/room_cleanup_helper.ts ---
const admin = __importStar(require("firebase-admin"));
exports.WAITING_ROOM_EXPIRY_MS = 10 * 60 * 1000; // 10 minutes
exports.ACTIVE_ROOM_ABANDONED_MS = 5 * 60 * 1000; // 5 minutes
exports.FINISHED_ROOM_RETENTION_MS = 24 * 60 * 60 * 1000; // 24 hours
const cleanupExpiredRooms = async (db, nowMillis, beforeCandidateTransaction) => {
    const now = nowMillis ? admin.firestore.Timestamp.fromMillis(nowMillis) : admin.firestore.Timestamp.now();
    const nowMs = now.toMillis();
    const result = {
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
                const lastActivity = data.lastActivityAt ?? data.createdAt ?? null;
                const activityMs = lastActivity ? lastActivity.toMillis() : 0;
                if (activityMs > 0 && nowMs - activityMs >= exports.WAITING_ROOM_EXPIRY_MS) {
                    if (beforeCandidateTransaction) {
                        await beforeCandidateTransaction(doc.id, colName, 'waiting');
                    }
                    try {
                        const mutated = await db.runTransaction(async (tx) => {
                            const freshSnap = await tx.get(doc.ref);
                            if (!freshSnap.exists)
                                return false;
                            const freshData = freshSnap.data();
                            if (freshData.status !== 'waiting')
                                return false;
                            const freshActivity = freshData.lastActivityAt ?? freshData.createdAt ?? null;
                            if (freshActivity && nowMs - freshActivity.toMillis() < exports.WAITING_ROOM_EXPIRY_MS) {
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
                    }
                    catch (e) {
                        result.errorsCount++;
                    }
                }
            }
        }
        catch (e) {
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
                const lastActivity = data.lastActivityAt ?? data.updatedAt ?? null;
                const activityMs = lastActivity ? lastActivity.toMillis() : 0;
                if (activityMs > 0 && nowMs - activityMs >= exports.ACTIVE_ROOM_ABANDONED_MS) {
                    if (beforeCandidateTransaction) {
                        await beforeCandidateTransaction(doc.id, colName, 'active');
                    }
                    try {
                        const mutated = await db.runTransaction(async (tx) => {
                            const freshSnap = await tx.get(doc.ref);
                            if (!freshSnap.exists)
                                return false;
                            const freshData = freshSnap.data();
                            if (freshData.status !== 'active')
                                return false;
                            const freshActivity = freshData.lastActivityAt ?? freshData.updatedAt ?? null;
                            if (freshActivity && nowMs - freshActivity.toMillis() < exports.ACTIVE_ROOM_ABANDONED_MS) {
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
                    }
                    catch (e) {
                        result.errorsCount++;
                    }
                }
            }
        }
        catch (e) {
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
                const updatedAt = data.updatedAt ?? data.createdAt ?? null;
                const updatedMs = updatedAt ? updatedAt.toMillis() : 0;
                if (updatedMs > 0 && nowMs - updatedMs >= exports.FINISHED_ROOM_RETENTION_MS) {
                    if (beforeCandidateTransaction) {
                        await beforeCandidateTransaction(doc.id, colName, 'finished');
                    }
                    try {
                        await db.recursiveDelete(doc.ref);
                        result.deletedFinishedCount++;
                    }
                    catch (e) {
                        result.errorsCount++;
                    }
                }
            }
        }
        catch (e) {
            result.errorsCount++;
        }
    }
    return result;
};
exports.cleanupExpiredRooms = cleanupExpiredRooms;
