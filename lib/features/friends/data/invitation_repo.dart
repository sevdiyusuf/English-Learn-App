import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_invitation.dart';

class InvitationRepository {
  InvitationRepository(this._firestore, this._functions);
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> _userInvitations(String uid) =>
      _firestore.collection('users').doc(uid).collection('invitations');

  Future<void> sendInvitation({
    required String fromUid,
    required String fromName,
    required String toUid,
    required String roomId,
    required String gameType,
  }) async {
    await _functions.httpsCallable('createSocialInvitation').call({
      'toUid': toUid,
      'roomId': roomId,
      'gameType': gameType,
    });
  }

  Stream<List<GameInvitation>> watchInvitations(String uid) {
    return _userInvitations(
      uid,
    ).where('status', isEqualTo: 'pending').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return GameInvitation.fromJson(data);
      }).toList();
    });
  }

  Future<void> deleteInvitation(String uid, String invitationId) async {
    await _functions
        .httpsCallable('dismissSocialInvitation')
        .call({'invitationId': invitationId});
  }

  Future<Map<String, dynamic>> acceptInvitation(String invitationId) async {
    final result = await _functions
        .httpsCallable('acceptSocialInvitation')
        .call<Map<String, dynamic>>({'invitationId': invitationId});
    return result.data;
  }
}

final invitationRepositoryProvider = Provider<InvitationRepository>((ref) {
  return InvitationRepository(
    FirebaseFirestore.instance,
    FirebaseFunctions.instance,
  );
});
