import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/arena_models.dart';

final arenaMatchRepoProvider = Provider(
  (ref) => ArenaMatchRepository(FirebaseFirestore.instance),
);

class ArenaMatchRepository {
  final FirebaseFirestore _firestore;

  ArenaMatchRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _answersRef(String roomId) =>
      _firestore.collection('arena_rooms').doc(roomId).collection('answers');

  Future<void> submitAnswer({
    required String roomId,
    required String playerId,
    required int roundIndex,
    required ArenaAnswer answer,
  }) async {
    final docId = '${roundIndex}_$playerId';
    await _answersRef(roomId).doc(docId).set(answer.toJson());
  }

  Stream<Map<String, ArenaAnswer>> watchRoundAnswers(
    String roomId,
    int roundIndex,
  ) {
    // Returns map of playerId -> Answer
    return _answersRef(roomId).snapshots().map((snapshot) {
      final Map<String, ArenaAnswer> answers = {};
      for (var doc in snapshot.docs) {
        if (doc.id.startsWith('${roundIndex}_')) {
          final parts = doc.id.split('_');
          if (parts.length >= 2) {
            final playerId = parts
                .sublist(1)
                .join('_'); // Handle if playerId has underscores?
            // Ideally we shouldn't use underscores in IDs or use a different separator.
            // Requirement says `{roundIndex}_{playerId}`.
            // Let's assume playerId is safe or just match carefully.
            answers[playerId] = ArenaAnswer.fromJson(doc.data());
          }
        }
      }
      return answers;
    });
  }
}
