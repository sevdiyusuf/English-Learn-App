import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';

const ugcTermsVersion = '2026-07-26';
const ugcGuidelinesVersion = '2026-07-26';

class ModerationClient {
  ModerationClient(this._functions, this._firestore);
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  Future<bool> hasCurrentAcceptance(String uid) async {
    final data = await _firestore.doc('users/$uid/ugc_acceptance/current').get();
    return data.data()?['termsVersion'] == ugcTermsVersion &&
        data.data()?['guidelinesVersion'] == ugcGuidelinesVersion;
  }

  Future<void> acceptPolicies() => _call('acceptCurrentUgcPolicy', {
    'termsVersion': ugcTermsVersion,
    'guidelinesVersion': ugcGuidelinesVersion,
    'accepted': true,
  });

  Future<void> report({required String type, required String targetId, required String reason, String details = ''}) =>
      _call('submitModerationReport', {'targetType': type, 'targetId': targetId, 'reason': reason, 'details': details});
  Future<void> block(String targetUid) => _call('blockUser', {'targetUid': targetUid});
  Future<void> unblock(String targetUid) => _call('unblockUser', {'targetUid': targetUid});
  Stream<List<String>> watchBlocked() => _firestore.collection('users').doc(_uid!).collection('blocks').snapshots().map((s) => s.docs.map((d) => d.id).toList());
  String? _uid;
  void setUid(String uid) => _uid = uid;

  Future<void> _call(String name, Map<String, dynamic> data) async {
    await _functions.httpsCallable(name).call(data);
  }
}

final moderationClientProvider = Provider<ModerationClient>((ref) => ModerationClient(
  ref.watch(firebaseFunctionsProvider), ref.watch(firestoreProvider),
));

String moderationErrorKey(Object error) {
  if (error is FirebaseFunctionsException) {
    if (error.code == 'resource-exhausted') return 'rateLimited';
    if (error.code == 'failed-precondition' || error.code == 'permission-denied') return 'interactionUnavailable';
  }
  return 'errorGeneric';
}
