import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/utils/operation_id.dart';
import '../models/played_word.dart';
import '../models/room.dart';

class GameRepository {
  GameRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _roomsRef =>
      _firestore.collection('rooms');

  Stream<List<PlayedWord>> watchPlayedWords(String roomId) {
    return _roomsRef
        .doc(roomId)
        .collection('playedWords')
        .orderBy('at', descending: false)
        .snapshots()
        .map((snapshot) {
          final words = snapshot.docs
              .map((doc) {
                try {
                  final data = doc.data();
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
                  if (kDebugMode) {
                    debugPrint('Error parsing PlayedWord from Firestore: $e');
                  }
                  return null;
                }
              })
              .whereType<PlayedWord>()
              .toList(growable: false);
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
    String? operationId,
  }) async {
    final opId = operationId ?? generateOperationId();
    try {
      final callable = _functions.httpsCallable('submitWord');
      await callable.call({
        'roomId': roomId,
        'word': word,
        'operationId': opId,
      });
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        debugPrint(
          'Firebase Functions Error [submitWord]: ${e.code} - ${e.message}',
        );
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
    String? operationId,
  }) async {
    final opId = operationId ?? generateOperationId();
    try {
      final callable = _functions.httpsCallable('submitVerb');
      await callable.call({
        'roomId': roomId,
        'verb': verb,
        'operationId': opId,
      });
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        debugPrint(
          'Firebase Functions Error [submitVerb]: ${e.code} - ${e.message}',
        );
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
    String? operationId,
  }) async {
    final opId = operationId ?? generateOperationId();
    try {
      final callable = _functions.httpsCallable('submitAdjective');
      await callable.call({
        'roomId': roomId,
        'adjective': adjective,
        'operationId': opId,
      });
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        debugPrint(
          'Firebase Functions Error [submitAdjective]: ${e.code} - ${e.message}',
        );
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected Error [submitAdjective]: $e');
      }
      rethrow;
    }
  }

  Future<void> submitLegacyTurn({
    required String roomId,
    required String verb,
    required String adjective,
    String? operationId,
  }) async {
    final opId = operationId ?? generateOperationId();
    final callable = _functions.httpsCallable('submitWordLegacy');
    await callable.call({
      'roomId': roomId,
      'verb': verb,
      'adjective': adjective,
      'operationId': opId,
    });
  }

  Future<void> resolveTimeout({
    required String roomId,
    String? operationId,
  }) async {
    final opId = operationId ?? generateOperationId();
    final callable = _functions.httpsCallable('resolveTimeout');
    await callable.call({'roomId': roomId, 'operationId': opId});
  }
}

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final functions = ref.watch(firebaseFunctionsProvider);
  return GameRepository(firestore, functions);
});
