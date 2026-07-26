import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_logger.dart';
import '../../../core/utils/storage_service.dart';
import '../../../core/repositories/user_stats_repo.dart';
import '../../friends/data/friends_repo.dart';
import '../../friends/logic/friends_controller.dart';
import '../../sync/sync_providers.dart';
import '../../../core/errors/app_failure.dart';
import '../../word_match/data/word_match_providers.dart';
import '../data/auth_repo.dart';
import '../models/app_user.dart';

class AuthController extends StateNotifier<AsyncValue<AppUser?>> {
  AuthController(this._ref) : super(const AsyncValue<AppUser?>.loading()) {
    _init();
  }

  final Ref _ref;
  StreamSubscription<AppUser?>? _authSubscription;

  AuthRepository get _repo => _ref.read(authRepositoryProvider);

  Future<void> _init() async {
    state = const AsyncValue.loading();

    _authSubscription?.cancel();
    _authSubscription = _repo.watchAuthUser().listen(
      (user) {
        state = AsyncValue.data(user);
        if (user != null) {
          unawaited(_ref.read(userStatsRepoProvider).updateLoginStreak(user));

          if (!user.isAnonymous && !user.isGuestMode) {
            unawaited(_runPostSignInTasks(user));
          }
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        ErrorLogger.instance.logError(
          error,
          stackTrace: stackTrace,
          context: 'AuthController._init',
        );
        state = AsyncValue.error(error, stackTrace);
      },
    );

    // Ensure anonymous guest is signed in on startup
    try {
      await ensureAnonymousGuestSignedIn();
    } catch (err, stack) {
      ErrorLogger.instance.logError(
        err,
        stackTrace: stack,
        context: 'AuthController._init - ensureAnonymousGuestSignedIn',
      );
      state = AsyncValue.error(err, stack);
    }
  }

  /// Ensure anonymous guest is signed in (for immediate play)
  Future<AppUser> ensureAnonymousGuestSignedIn() async {
    try {
      final user = await _repo.ensureAnonymousGuestSignedIn();
      state = AsyncValue.data(user);
      return user;
    } catch (err, stack) {
      ErrorLogger.instance.logError(
        err,
        stackTrace: stack,
        context: 'AuthController.ensureAnonymousGuestSignedIn',
      );
      state = AsyncValue.error(err, stack);
      rethrow;
    }
  }

  /// Continue as guest (alias for ensureAnonymousGuestSignedIn)
  Future<void> continueAsGuest() async {
    await ensureAnonymousGuestSignedIn();
  }

  /// Sign in with Google (For login only)
  Future<void> signInWithGoogle() async {
    try {
      final user = await _repo.signInWithGoogle();
      state = AsyncValue.data(user);
      unawaited(_runPostSignInTasks(user));
    } catch (err, stack) {
      ErrorLogger.instance.logError(
        err,
        stackTrace: stack,
        context: 'AuthController.signInWithGoogle',
      );
      rethrow;
    }
  }

  /// Sign in with Apple (For login only)
  Future<void> signInWithApple() async {
    try {
      final user = await _repo.signInWithApple();
      state = AsyncValue.data(user);
      unawaited(_runPostSignInTasks(user));
    } catch (err, stack) {
      ErrorLogger.instance.logError(
        err,
        stackTrace: stack,
        context: 'AuthController.signInWithApple',
      );
      rethrow;
    }
  }

  /// Link Google Account to current user
  Future<void> linkGoogleAccount() async {
    try {
      final user = await _repo.linkGoogleAccount();
      state = AsyncValue.data(user);
      // Wait, is it a post sign in task? If they were guest, they are now registered.
      if (!user.isAnonymous && !user.isGuestMode) {
        unawaited(_runPostSignInTasks(user));
      }
    } catch (err, stack) {
      ErrorLogger.instance.logError(
        err,
        stackTrace: stack,
        context: 'AuthController.linkGoogleAccount',
      );
      rethrow;
    }
  }

  /// Link Apple Account to current user
  Future<void> linkAppleAccount() async {
    try {
      final user = await _repo.linkAppleAccount();
      state = AsyncValue.data(user);
      if (!user.isAnonymous && !user.isGuestMode) {
        unawaited(_runPostSignInTasks(user));
      }
    } catch (err, stack) {
      ErrorLogger.instance.logError(
        err,
        stackTrace: stack,
        context: 'AuthController.linkAppleAccount',
      );
      rethrow;
    }
  }

  /// Register with email and password
  Future<void> registerWithEmail({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      // Don't set loading state - keep current state to avoid triggering AppStartupGate error
      final user = await _repo.registerWithEmail(
        email: email,
        password: password,
        name: name,
      );
      state = AsyncValue.data(user);

      // Update Friends Repo if name is provided
      if (name != null && name.isNotEmpty) {
        final friendsRepo = _ref.read(friendsRepositoryProvider);
        await friendsRepo.updateUserProfile(uid: user.uid, displayName: name);
        _ref.invalidate(friendsControllerProvider);
      }

      unawaited(_runPostSignInTasks(user));
    } catch (err, stack) {
      ErrorLogger.instance.logError(
        err,
        stackTrace: stack,
        context: 'AuthController.registerWithEmail',
      );
      // Don't set error state - keep current state and just rethrow
      // This prevents AppStartupGate from showing error screen
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Don't set loading state - keep current state to avoid triggering AppStartupGate error
      final user = await _repo.signInWithEmail(
        email: email,
        password: password,
      );
      state = AsyncValue.data(user);
      unawaited(_runPostSignInTasks(user));
    } catch (err, stack) {
      ErrorLogger.instance.logError(
        err,
        stackTrace: stack,
        context: 'AuthController.signInWithEmail',
      );
      // Don't set error state - keep current state and just rethrow
      // This prevents AppStartupGate from showing error screen
      rethrow;
    }
  }

  /// Reauthenticate with Google
  Future<void> reauthenticateWithGoogle() async {
    try {
      await _repo.reauthenticateWithGoogle();
    } catch (err, stack) {
      ErrorLogger.instance.logError(
        err,
        stackTrace: stack,
        context: 'AuthController.reauthenticateWithGoogle',
      );
      rethrow;
    }
  }

  /// Reauthenticate with Apple
  Future<void> reauthenticateWithApple() async {
    try {
      await _repo.reauthenticateWithApple();
    } catch (err, stack) {
      ErrorLogger.instance.logError(
        err,
        stackTrace: stack,
        context: 'AuthController.reauthenticateWithApple',
      );
      rethrow;
    }
  }

  /// Reauthenticate with Password
  Future<void> reauthenticateWithPassword(String password) async {
    try {
      await _repo.reauthenticateWithPassword(password);
    } catch (err, stack) {
      ErrorLogger.instance.logError(
        err,
        stackTrace: stack,
        context: 'AuthController.reauthenticateWithPassword',
      );
      rethrow;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _repo.sendPasswordResetEmail(email);
    } catch (err, stack) {
      ErrorLogger.instance.logError(
        err,
        stackTrace: stack,
        context: 'AuthController.resetPassword',
      );
      rethrow;
    }
  }

  /// Update display name
  Future<void> updateDisplayName(String name) async {
    try {
      final currentUser = state.value;
      if (currentUser == null) return;

      // Update in Auth (Firebase)
      await _repo.updateDisplayName(name);

      // Update in Friends Repo (Firestore Users)
      final friendsRepo = _ref.read(friendsRepositoryProvider);
      await friendsRepo.updateUserProfile(
        uid: currentUser.uid,
        displayName: name,
      );

      // Invalidate FriendsController to force reload of profile
      _ref.invalidate(friendsControllerProvider);

      // Force refresh auth state
      final updatedUser = await _repo.getCurrentUser();
      state = AsyncValue.data(updatedUser);
    } catch (err, stack) {
      ErrorLogger.instance.logError(
        err,
        stackTrace: stack,
        context: 'AuthController.updateDisplayName',
      );
      rethrow;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      // 1. Invalidate session/sync early
      try {
        await _ref
            .read(syncCoordinatorProvider.future)
            .then((c) => c.onUserLogout());
      } catch (e, stack) {
        ErrorLogger.instance.logError(
          e,
          stackTrace: stack,
          context: 'AuthController.signOut - onUserLogout',
        );
      }

      // 2. Sign out from Firebase
      await _repo.signOut();

      // 3. Clear local storage
      await StorageService.clearAll();

      // 4. Clear memory state
      _clearUserSessionState();
      state = const AsyncValue.data(null);

      // 5. Enter guest mode
      await ensureAnonymousGuestSignedIn();
    } catch (err, stack) {
      ErrorLogger.instance.logError(
        err,
        stackTrace: stack,
        context: 'AuthController.signOut',
      );
      rethrow;
    }
  }

  /// Delete account and data
  Future<void> deleteAccountAndData({String? password}) async {
    try {
      final currentUser = state.value;
      state = const AsyncValue.loading();

      if (currentUser == null || currentUser.isAnonymous) {
        throw AppFailure.auth(message: 'Silinecek hesap bulunamadı');
      }

      // 1. Reauthentication based on provider
      try {
        if (currentUser.providerId == 'google.com') {
          await _repo.reauthenticateWithGoogle();
        } else if (currentUser.providerId == 'apple.com') {
          await _repo.reauthenticateWithApple();
        } else if (currentUser.providerId == 'password') {
          if (password == null || password.isEmpty) {
            throw AppFailure.auth(message: 'Şifre gereklidir');
          }
          await _repo.reauthenticateWithPassword(password);
        }
      } catch (e) {
        throw AppFailure.auth(
          message: 'Kimlik doğrulama başarısız oldu. İşlem iptal edildi.',
        );
      }

      // 2. Stop sync first
      try {
        await _ref
            .read(syncCoordinatorProvider.future)
            .then((c) => c.onUserLogout());
      } catch (e, stack) {
        ErrorLogger.instance.logError(
          e,
          stackTrace: stack,
          context: 'AuthController.deleteAccountAndData - onUserLogout',
        );
      }

      final uid = currentUser.uid;

      // 3. Delete account (Cloud Function)
      await _repo.deleteAccountAndData();

      // 4. Clear local outbox and word sets for this user
      try {
        await _ref.read(wordMatchRepoProvider.future).then((repo) async {
          await repo.clearUserData(uid);
        });

        await _ref.read(outboxRepositoryProvider.future).then((repo) async {
          await repo.clearUserData(uid);
        });
      } catch (e) {
        ErrorLogger.instance.logWarning(
          'Failed to clear Isar User Data: ',
          context: 'AuthController.deleteAccountAndData',
        );
      }

      await StorageService.clearAll();
      _clearUserSessionState();

      // 5. After deletion, ensure guest mode is active
      await ensureAnonymousGuestSignedIn();
    } catch (err, stack) {
      ErrorLogger.instance.logError(
        err,
        stackTrace: stack,
        context: 'AuthController.deleteAccountAndData',
      );
      state = AsyncValue.error(err, stack);
      rethrow;
    }
  }

  void _clearUserSessionState() {
    // userStatsControllerProvider automatically updates reactively when auth state changes
  }

  /// Get current user (for backward compatibility)
  Future<AppUser?> getCurrentUser() async {
    return await _repo.getCurrentUser();
  }

  /// Check if user is in guest mode
  bool get isGuest {
    final user = state.value;
    return user?.isGuestMode == true;
  }

  /// Check if user is logged in (not anonymous)
  bool get isLoggedIn {
    final user = state.value;
    return user != null && !user.isAnonymous;
  }

  /// Run post sign-in tasks that depend on a stable, non-anonymous user.
  ///
  /// Currently:
  /// - Phase 0: migrate local Word Match sets (Isar / prefs / localStorage)
  ///   into `users/{uid}/sets` in Firestore.
  Future<void> _runPostSignInTasks(AppUser user) async {
    if (user.isAnonymous || user.isGuestMode) {
      // Guest/anonymous: nothing to migrate to cloud.
      return;
    }
    try {
      final syncCoordinator = await _ref.read(syncCoordinatorProvider.future);
      // Run bootstrap in the background so auth flow isn't blocked.
      syncCoordinator.onUserLogin(user);
    } catch (err, stack) {
      // Never break auth flows because of migration problems.
      ErrorLogger.instance.logError(
        err,
        stackTrace: stack,
        context: 'AuthController._runPostSignInTasks',
      );
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AppUser?>>((ref) {
      return AuthController(ref);
    });
