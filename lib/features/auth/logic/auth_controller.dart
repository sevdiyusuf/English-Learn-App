import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_logger.dart';
import '../../../core/repositories/user_stats_repo.dart';
import '../../friends/data/friends_repo.dart';
import '../../friends/logic/friends_controller.dart';
import '../../word_match/data/word_match_migration_service.dart';
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

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      // Don't set loading state - keep current state to avoid triggering AppStartupGate error
      final user = await _repo.signInWithGoogle();
      state = AsyncValue.data(user);
      // Post sign-in hooks (Phase 0: migrate local Word Match sets)
      unawaited(_runPostSignInTasks(user));
    } catch (err, stack) {
      ErrorLogger.instance.logError(
        err,
        stackTrace: stack,
        context: 'AuthController.signInWithGoogle',
      );
      // Don't set error state - keep current state and just rethrow
      // This prevents AppStartupGate from showing error screen
      rethrow;
    }
  }

  /// Sign in with Apple (iOS/macOS only)
  Future<void> signInWithApple() async {
    try {
      // Don't set loading state - keep current state to avoid triggering AppStartupGate error
      final user = await _repo.signInWithApple();
      state = AsyncValue.data(user);
      unawaited(_runPostSignInTasks(user));
    } catch (err, stack) {
      ErrorLogger.instance.logError(
        err,
        stackTrace: stack,
        context: 'AuthController.signInWithApple',
      );
      // Don't set error state - keep current state and just rethrow
      // This prevents AppStartupGate from showing error screen
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
      await _repo.signOut();
      // After sign out, ensure guest mode is active
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
  Future<void> deleteAccountAndData() async {
    try {
      state = const AsyncValue.loading();
      await _repo.deleteAccountAndData();
      // After deletion, ensure guest mode is active
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
      final migrationService = await _ref.read(
        wordMatchMigrationServiceProvider.future,
      );
      await migrationService.migrateLocalSetsForUser(user);
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
