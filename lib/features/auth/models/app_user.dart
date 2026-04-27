import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';

/// Unified user model used across solo and multiplayer features
@freezed
class AppUser with _$AppUser {
  const AppUser._();

  const factory AppUser({
    required String uid,
    String? displayName,
    String? email,
    String? photoUrl,
    @Default(false) bool isAnonymous,
    @Default(false) bool isGuestMode,
    String? providerId,
  }) = _AppUser;

  /// Factory to create AppUser from Firebase User
  factory AppUser.fromFirebaseUser(firebase_auth.User user) {
    // Determine provider ID from user's provider data
    String? providerId;
    if (user.providerData.isNotEmpty) {
      // Get the first non-anonymous provider
      final provider = user.providerData.firstWhere(
        (p) => p.providerId != 'firebase',
        orElse: () => user.providerData.first,
      );
      providerId = provider.providerId;
    } else {
      providerId = user.isAnonymous ? 'anonymous' : null;
    }

    // Determine if user is in guest mode
    // Guest mode = anonymous user without any linked providers
    final hasLinkedProviders = user.providerData.any(
      (p) => p.providerId != 'firebase',
    );
    final isGuestMode = user.isAnonymous && !hasLinkedProviders;

    return AppUser(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
      isAnonymous: user.isAnonymous,
      isGuestMode: isGuestMode,
      providerId: providerId,
    );
  }
}
