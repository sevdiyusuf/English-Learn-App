import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../models/played_word.dart';
import '../models/room.dart';

class GameRepository {
  GameRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _roomsRef =>
      _firestore.collection('rooms');

  Stream<List<PlayedWord>> watchPlayedWords(String roomId) {
    if (kDebugMode) {
      debugPrint('GameRepository: Watching playedWords for roomId: $roomId');
    }
    return _roomsRef
        .doc(roomId)
        .collection('playedWords')
        .orderBy('at', descending: false)
        .snapshots()
        .map((snapshot) {
          if (kDebugMode) {
            debugPrint(
              'GameRepository: Received ${snapshot.docs.length} playedWords documents',
            );
          }
          final words = snapshot.docs
              .map((doc) {
                try {
                  final data = doc.data();
                  if (kDebugMode) {
                    debugPrint(
                      'GameRepository: Parsing word: ${data['word']} (${data['type']})',
                    );
                  }
                  // Convert Firestore Timestamp to DateTime for 'at' field
                  final processedData = Map<String, dynamic>.from(data);
                  if (data['at'] is Timestamp) {
                    processedData['at'] =
                        (data['at'] as Timestamp).toDate().toIso8601String();
                  } else if (data['at'] is DateTime) {
                    processedData['at'] =
                        (data['at'] as DateTime).toIso8601String();
                  }
                  return PlayedWord.fromJson(processedData);
                } catch (e) {
                  // Log error but don't crash - return null for this document
                  if (kDebugMode) {
                    debugPrint('Error parsing PlayedWord from Firestore: $e');
                    debugPrint('Document data: ${doc.data()}');
                  }
                  return null;
                }
              })
              .whereType<PlayedWord>()
              .toList(growable: false);
          if (kDebugMode) {
            debugPrint(
              'GameRepository: Successfully parsed ${words.length} playedWords',
            );
          }
          return words;
        });
  }

  Stream<Map<String, bool>> watchUsedWords(String roomId) {
    final docRef = _roomsRef.doc(roomId).collection('meta').doc('usedWords');
    return docRef.snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        return <String, bool>{};
      }
      final used = data['used'];
      if (used is Map<String, dynamic>) {
        return used.map((key, value) => MapEntry(key, value as bool? ?? true));
      }
      return <String, bool>{};
    });
  }

  Stream<Room?> watchRoom(String roomId) {
    return _roomsRef.doc(roomId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return Room.fromFirestore(snapshot);
    });
  }

  /// Unified submit for THEME and CORE modes (single word per turn).
  Future<void> submitWord({
    required String roomId,
    required String word,
  }) async {
    try {
      final callable = _functions.httpsCallable('submitWord');
      await callable.call({'roomId': roomId, 'word': word});
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase Functions Error [submitWord]: ${e.code} - ${e.message}');
        debugPrint('Details: ${e.details}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected Error [submitWord]: $e');
      }
      rethrow;
    }
  }

  Future<void> submitVerb({
    required String roomId,
    required String verb,
  }) async {
    try {
      final callable = _functions.httpsCallable('submitVerb');
      await callable.call({'roomId': roomId, 'verb': verb});
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase Functions Error [submitVerb]: ${e.code} - ${e.message}');
        debugPrint('Details: ${e.details}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected Error [submitVerb]: $e');
      }
      rethrow;
    }
  }

  Future<void> submitAdjective({
    required String roomId,
    required String adjective,
  }) async {
    try {
      final callable = _functions.httpsCallable('submitAdjective');
      await callable.call({'roomId': roomId, 'adjective': adjective});
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase Functions Error [submitAdjective]: ${e.code} - ${e.message}');
        debugPrint('Details: ${e.details}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected Error [submitAdjective]: $e');
      }
      rethrow;
    }
  }

  // Legacy method - keeps backward compatibility
  Future<void> submitLegacyTurn({
    required String roomId,
    required String verb,
    required String adjective,
  }) async {
    final callable = _functions.httpsCallable('submitWord');
    await callable.call({
      'roomId': roomId,
      'verb': verb,
      'adjective': adjective,
    });
  }

  Future<void> resolveTimeout({required String roomId}) async {
    final callable = _functions.httpsCallable('resolveTimeout');
    await callable.call({'roomId': roomId});
  }
}

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final functions = ref.watch(firebaseFunctionsProvider);
  return GameRepository(firestore, functions);
});
