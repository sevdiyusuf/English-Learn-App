import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yunoo/app/di.dart';
import 'package:yunoo/core/utils/operation_id.dart';
import '../models/arena_models.dart';

final arenaMatchRepoProvider = Provider(
  (ref) => ArenaMatchRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseFunctionsProvider),
  ),
);

class ArenaMatchRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  ArenaMatchRepository(this._firestore, this._functions);

  CollectionReference<Map<String, dynamic>> _answersRef(String roomId) =>
      _firestore.collection('arena_rooms').doc(roomId).collection('answers');

  Future<void> submitAnswer({
    required String roomId,
    required String playerId,
    required int roundIndex,
    required dynamic answerValue,
    int attempt = 1,
    String? operationId,
  }) async {
    final opId = operationId ?? generateOperationId();
    try {
      final callable = _functions.httpsCallable('submitArenaAnswer');
      await callable.call({
        'roomId': roomId,
        'roundIndex': roundIndex,
        'answerValue': answerValue,
        'attempt': attempt,
        'operationId': opId,
      });
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Error submitting arena answer via callable: $e\n$st');
      }
      rethrow;
    }
  }

  Stream<Map<String, ArenaAnswer>> watchRoundAnswers(
    String roomId,
    int roundIndex,
  ) {
    return _answersRef(roomId).snapshots().map((snapshot) {
      final Map<String, ArenaAnswer> answers = {};
      for (var doc in snapshot.docs) {
        if (doc.id.startsWith('${roundIndex}_')) {
          final parts = doc.id.split('_');
          if (parts.length >= 2) {
            final playerId = parts.sublist(1).join('_');
            try {
              answers[playerId] = ArenaAnswer.fromJson(doc.data());
            } catch (e) {
              if (kDebugMode) {
                debugPrint('Error parsing ArenaAnswer: $e');
              }
            }
          }
        }
      }
      return answers;
    });
  }
}
