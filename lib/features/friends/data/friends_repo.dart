import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../auth/models/app_user.dart';
import '../models/friend_models.dart';

/// Firestore-based friends & friend-requests repository.
class FriendsRepository {
  FriendsRepository(this._firestore);

  final FirebaseFirestore _firestore;

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
    final docRef = _usersRef.doc(uid);
    final data = <String, dynamic>{};
    if (displayName != null) data['displayName'] = displayName;
    if (photoUrl != null) data['photoUrl'] = photoUrl;

    if (data.isNotEmpty) {
      await docRef.update(data);
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
    final profile = await ensureUserProfile(fromUser);
    final target = await findUserByCode(targetCode);
    if (target == null) {
      throw StateError('Bu koda sahip kullanıcı bulunamadı');
    }
    if (target.uid == fromUser.uid) {
      throw StateError('Kendinize arkadaşlık isteği gönderemezsiniz');
    }

    // Check existing friendship
    final existingFriend =
        await _friendshipsRef(fromUser.uid).doc(target.uid).get();
    if (existingFriend.exists) {
      throw StateError('Bu kullanıcı zaten arkadaş listenizde');
    }

    // Check existing pending request
    final pendingSnap =
        await _friendRequestsRef
            .where('fromUid', isEqualTo: fromUser.uid)
            .where('toUid', isEqualTo: target.uid)
            .where('status', isEqualTo: 'pending')
            .limit(1)
            .get();
    if (pendingSnap.docs.isNotEmpty) {
      throw StateError('Bu kullanıcıya zaten bekleyen bir isteğiniz var');
    }

    final now = DateTime.now().toUtc();
    await _friendRequestsRef.add({
      'fromUid': fromUser.uid,
      'toUid': target.uid,
      'status': 'pending',
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'fromDisplayName': profile.displayName,
      'fromUserCode': profile.userCode,
    });
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

    final now = DateTime.now().toUtc();
    final reqRef = _friendRequestsRef.doc(request.id);
    final batch = _firestore.batch();

    // Update request status
    batch.update(reqRef, {
      'status': 'accepted',
      'updatedAt': now.toIso8601String(),
    });

    // Create friendships in both directions
    // Path 1: /friendships/{fromUid}/friends/{toUid}
    //   - userId = fromUid, friendUid = toUid (currentUser)
    //   - Rule should pass: request.auth.uid == toUid == friendUid ✓
    final aRef = _friendshipsRef(request.fromUid).doc(request.toUid);

    // Path 2: /friendships/{toUid}/friends/{fromUid}
    //   - userId = toUid (currentUser), friendUid = fromUid
    //   - Rule should pass: request.auth.uid == toUid == userId ✓
    final bRef = _friendshipsRef(request.toUid).doc(request.fromUid);

    final payload = {'createdAt': now.toIso8601String()};

    // Use set with merge to ensure we don't overwrite if somehow exists (idempotent)
    batch.set(aRef, payload, SetOptions(merge: true));
    batch.set(bRef, payload, SetOptions(merge: true));

    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      // Log detailed error for debugging
      print('Accept Request Firebase Error:');
      print('  Code: ${e.code}');
      print('  Message: ${e.message}');
      print('  Current User UID: ${currentUser.uid}');
      print('  From UID: ${request.fromUid}');
      print('  To UID: ${request.toUid}');
      print(
        '  Path 1: /friendships/${request.fromUid}/friends/${request.toUid}',
      );
      print(
        '  Path 2: /friendships/${request.toUid}/friends/${request.fromUid}',
      );

      // Provide more specific error message
      if (e.code == 'permission-denied') {
        throw StateError(
          'İstek kabul edilirken izin hatası oluştu. '
          'Lütfen tekrar giriş yapmayı deneyin. '
          'Hata: ${e.message}',
        );
      }
      rethrow;
    } catch (e) {
      // Log detailed error for debugging
      print('Accept Request Error: $e');
      // Rethrow so UI knows it failed
      throw StateError('İstek kabul edilirken hata oluştu: $e');
    }
  }

  /// Reject or cancel a friend request.
  Future<void> rejectRequest(FriendRequest request, AppUser currentUser) async {
    if (request.toUid != currentUser.uid &&
        request.fromUid != currentUser.uid) {
      throw StateError('Bu isteği yalnızca gönderen veya alıcı reddedebilir');
    }
    final now = DateTime.now().toUtc();
    await _friendRequestsRef.doc(request.id).update({
      'status': 'rejected',
      'updatedAt': now.toIso8601String(),
    });
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
  return FriendsRepository(firestore);
});
