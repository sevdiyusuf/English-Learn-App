import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_invitation.dart';

class InvitationRepository {
  InvitationRepository(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _userInvitations(String uid) =>
      _firestore.collection('users').doc(uid).collection('invitations');

  Future<void> sendInvitation({
    required String fromUid,
    required String fromName,
    required String toUid,
    required String roomId,
    required String gameType,
  }) async {
    final now = DateTime.now().toUtc();
    await _userInvitations(toUid).add({
      'fromUid': fromUid,
      'fromName': fromName,
      'toUid': toUid,
      'roomId': roomId,
      'gameType': gameType,
      'status': 'pending',
      'createdAt': now.toIso8601String(),
    });
  }

  Stream<List<GameInvitation>> watchInvitations(String uid) {
    return _userInvitations(uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return GameInvitation.fromJson(data);
      }).toList();
    });
  }

  Future<void> deleteInvitation(String uid, String invitationId) async {
    await _userInvitations(uid).doc(invitationId).delete();
  }
}

final invitationRepositoryProvider = Provider<InvitationRepository>((ref) {
  return InvitationRepository(FirebaseFirestore.instance);
});
