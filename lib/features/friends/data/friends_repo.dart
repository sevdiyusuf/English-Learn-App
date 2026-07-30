import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../auth/models/app_user.dart';
import '../models/friend_models.dart';

/// Firestore-based friends & friend-requests repository.
class FriendsRepository {
  FriendsRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _friendRequestsRef =>
      _firestore.collection('friend_requests');

  CollectionReference<Map<String, dynamic>> _friendshipsRef(String uid) =>
      _firestore.collection('friendships').doc(uid).collection('friends');

  /// Ensure a minimal user profile exists in `users/{uid}` with a stable userCode.
  Future<UserProfile> ensureUserProfile(AppUser user) async {
    final docRef = _usersRef.doc(user.uid);
    final snap = await docRef.get();
    if (snap.exists && snap.data() != null) {
      final data = snap.data()!;
      final profile = UserProfile.fromJson(_normalizeUserDoc(data, user.uid));
      return profile;
    }

    final now = DateTime.now().toUtc();
    final generatedCode = _generateUserCode(user.uid);
    final data = <String, dynamic>{
      'uid': user.uid,
      'displayName': user.displayName ?? 'Guest',
      'photoUrl': user.photoUrl,
      'userCode': generatedCode,
      'createdAt': now.toIso8601String(),
    };
    await docRef.set(data, SetOptions(merge: true));
    return UserProfile.fromJson(_normalizeUserDoc(data, user.uid));
  }

  /// Update user profile data
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? photoUrl,
  }) async {
    final data = <String, dynamic>{};
    if (displayName != null) data['displayName'] = displayName;
    if (photoUrl != null) data['photoUrl'] = photoUrl;

    if (data.isNotEmpty) {
      try {
        await _functions.httpsCallable('updatePublicProfile').call(data);
      } on FirebaseFunctionsException catch (error) {
        throw StateError(_safeSocialError(error.code));
      }
    }
  }

  /// Try to find a user by their userCode (case-insensitive).
  Future<UserProfile?> findUserByCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return null;

    final snap =
        await _usersRef.where('userCode', isEqualTo: normalized).limit(1).get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return UserProfile.fromJson(_normalizeUserDoc(doc.data(), doc.id));
  }

  /// Send a friend request from [fromUser] to a user identified by [targetCode].
  Future<void> sendFriendRequest({
    required AppUser fromUser,
    required String targetCode,
  }) async {
    try {
      await _functions.httpsCallable('createFriendRequest').call({
        'targetCode': targetCode,
      });
    } on FirebaseFunctionsException catch (error) {
      throw StateError(_safeSocialError(error.code));
    }
  }

  /// Watch incoming friend requests for the given user.
  Stream<List<FriendRequest>> watchIncomingRequests(AppUser user) {
    return _friendRequestsRef
        .where('toUid', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          final requests =
              snapshot.docs.map((doc) {
                final data = doc.data();
                return FriendRequest.fromJson(
                  _normalizeRequestDoc(doc.id, data),
                );
              }).toList();

          // Client-side sorting to avoid composite index requirement
          requests.sort((a, b) {
            final tA = a.createdAt ?? DateTime(0);
            final tB = b.createdAt ?? DateTime(0);
            return tB.compareTo(tA); // Descending
          });

          return requests;
        });
  }

  /// Watch friend list for the given user.
  Stream<List<UserProfile>> watchFriends(AppUser user) {
    return _friendshipsRef(user.uid).snapshots().asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) return <UserProfile>[];

      final friendIds = snapshot.docs.map((d) => d.id).toList(growable: false);
      final chunks = <List<String>>[];
      const chunkSize = 10;
      for (var i = 0; i < friendIds.length; i += chunkSize) {
        chunks.add(
          friendIds.sublist(
            i,
            i + chunkSize > friendIds.length ? friendIds.length : i + chunkSize,
          ),
        );
      }

      final friends = <UserProfile>[];
      for (final chunk in chunks) {
        final snap =
            await _usersRef
                .where('uid', whereIn: chunk)
                .limit(chunk.length)
                .get();
        for (final doc in snap.docs) {
          friends.add(
            UserProfile.fromJson(_normalizeUserDoc(doc.data(), doc.id)),
          );
        }
      }
      return friends;
    });
  }

  /// Accept a friend request (creates friendship both ways).
  Future<void> acceptRequest(FriendRequest request, AppUser currentUser) async {
    if (request.toUid != currentUser.uid) {
      throw StateError('Bu isteği yalnızca alıcı kabul edebilir');
    }

    // Verify current user is authenticated
    if (currentUser.uid.isEmpty) {
      throw StateError('Kullanıcı kimlik doğrulaması gerekli');
    }

    try {
      final callable = _functions.httpsCallable('acceptFriendRequest');
      await callable.call({'requestId': request.id});
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Accept Request Functions Error:');
      debugPrint('  Code: ${e.code}');
      debugPrint('  Message: ${e.message}');
      throw StateError(_safeSocialError(e.code));
    } catch (e) {
      debugPrint('Accept Request Error: $e');
      throw StateError('İşlem şu anda kullanılamıyor. Lütfen tekrar deneyin.');
    }
  }

  /// Reject or cancel a friend request.
  Future<void> rejectRequest(FriendRequest request, AppUser currentUser) async {
    if (request.toUid != currentUser.uid &&
        request.fromUid != currentUser.uid) {
      throw StateError('Bu isteği yalnızca gönderen veya alıcı reddedebilir');
    }
    final newStatus =
        request.fromUid == currentUser.uid ? 'cancelled' : 'rejected';
    try {
      await _functions.httpsCallable('resolveFriendRequest').call({
        'requestId': request.id,
        'action': newStatus == 'cancelled' ? 'cancel' : 'reject',
      });
    } on FirebaseFunctionsException catch (error) {
      throw StateError(_safeSocialError(error.code));
    }
  }

  String _safeSocialError(String code) {
    if (code == 'resource-exhausted') {
      return 'Çok sık işlem yapıldı. Lütfen biraz sonra tekrar deneyin.';
    }
    return 'Bu etkileşim şu anda kullanılamıyor.';
  }

  Map<String, dynamic> _normalizeUserDoc(
    Map<String, dynamic> data,
    String uid,
  ) {
    final result = Map<String, dynamic>.from(data);
    result['uid'] = uid;

    final createdAt = data['createdAt'];
    if (createdAt is Timestamp) {
      result['createdAt'] = createdAt.toDate().toIso8601String();
    } else if (createdAt is String) {
      // keep as is
    } else {
      result['createdAt'] = null;
    }

    // Normalize userCode to uppercase
    if (result['userCode'] is String) {
      result['userCode'] = (result['userCode'] as String).trim().toUpperCase();
    }
    return result;
  }

  Map<String, dynamic> _normalizeRequestDoc(
    String id,
    Map<String, dynamic> data,
  ) {
    final result = Map<String, dynamic>.from(data);
    result['id'] = id;

    String statusStr = (data['status'] as String?) ?? 'pending';
    statusStr = statusStr.toLowerCase();
    FriendRequestStatus status;
    switch (statusStr) {
      case 'accepted':
        status = FriendRequestStatus.accepted;
        break;
      case 'rejected':
        status = FriendRequestStatus.rejected;
        break;
      default:
        status = FriendRequestStatus.pending;
    }
    result['status'] = status.name;

    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    final createdAt = parseDate(data['createdAt']);
    final updatedAt = parseDate(data['updatedAt']);
    result['createdAt'] = createdAt?.toIso8601String();
    result['updatedAt'] = updatedAt?.toIso8601String();

    return result;
  }

  String _generateUserCode(String uid) {
    // Simple deterministic short code: 6 chars from uid + random suffix
    final base = uid.replaceAll('-', '').toUpperCase();
    final prefix =
        base.length >= 4 ? base.substring(0, 4) : base.padRight(4, 'X');
    final rand = Random.secure().nextInt(9000) + 1000;
    return '$prefix$rand';
  }
}

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final functions = ref.watch(firebaseFunctionsProvider);
  return FriendsRepository(firestore, functions);
});
