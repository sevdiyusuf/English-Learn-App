import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repo.dart';

class AuthController extends StateNotifier<AsyncValue<User?>> {
  AuthController(this._ref) : super(const AsyncValue<User?>.loading()) {
    _init();
  }

  final Ref _ref;
  StreamSubscription<User?>? _authSubscription;

  AuthRepository get _repo => _ref.read(authRepositoryProvider);

  Future<void> _init() async {
    state = const AsyncValue.loading();

    _authSubscription?.cancel();
    _authSubscription = _repo.authStateChanges().listen(
      (user) {
        state = AsyncValue.data(user);
      },
      onError: (Object error, StackTrace stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      },
    );

    final current = _repo.currentUser;
    if (current != null) {
      state = AsyncValue.data(current);
      return;
    }

    try {
      final credential = await _repo.signInAnonymously();
      final user = credential.user;
      if (user != null) {
        state = AsyncValue.data(user);
      } else {
        // This should never happen, but handle it safely for iOS Safari
        state = AsyncValue.error(
          Exception('Sign in succeeded but user is null'),
          StackTrace.current,
        );
      }
    } on Object catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<User?> ensureSignedIn() async {
    final value = state.value;
    if (value != null) {
      return value;
    }
    try {
      final credential = await _repo.signInAnonymously();
      final user = credential.user;
      if (user != null) {
        state = AsyncValue.data(user);
        return user;
      } else {
        // This should never happen, but handle it safely for iOS Safari
        final error = Exception('Sign in succeeded but user is null');
        state = AsyncValue.error(error, StackTrace.current);
        throw error;
      }
    } on Object catch (err, stack) {
      state = AsyncValue.error(err, stack);
      rethrow;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<User?>>((ref) {
      return AuthController(ref);
    });
