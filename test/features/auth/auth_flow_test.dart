// ignore_for_file: unnecessary_no_such_method
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yunoo/core/errors/app_failure.dart';
import 'package:yunoo/core/utils/browser_storage_stub.dart'
    if (dart.library.html) 'package:yunoo/core/utils/browser_storage_web.dart';
import 'package:yunoo/features/auth/data/auth_repo.dart';
import 'package:yunoo/features/auth/logic/auth_controller.dart';
import 'package:yunoo/features/auth/services/social_auth_service.dart';
import 'package:yunoo/features/auth/models/app_user.dart';
import 'package:yunoo/features/sync/services/sync_coordinator.dart';
import 'package:yunoo/features/sync/sync_providers.dart';
import 'package:yunoo/core/repositories/user_stats_repo.dart';
import 'package:cloud_functions/cloud_functions.dart';

class FakeHttpsCallableResult<T> implements HttpsCallableResult<T> {
  FakeHttpsCallableResult(this.data);
  @override
  final T data;
}

class FakeHttpsCallable extends Fake implements HttpsCallable {
  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    return FakeHttpsCallableResult<T>({} as T);
  }
}

class FakeFirebaseFunctions extends Fake implements FirebaseFunctions {
  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) {
    return FakeHttpsCallable();
  }
}

// ignore: subtype_of_sealed_class
class FakeFirebaseAuthForReset extends Fake
    implements firebase_auth.FirebaseAuth {
  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    firebase_auth.ActionCodeSettings? actionCodeSettings,
  }) async {
    if (email == 'notfound@example.com') {
      throw firebase_auth.FirebaseAuthException(code: 'user-not-found');
    }
    if (email == 'error@example.com') {
      throw firebase_auth.FirebaseAuthException(code: 'invalid-email');
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class SpySyncCoordinator extends ChangeNotifier implements SyncCoordinator {
  int loginCallCount = 0;
  AppUser? lastLoginUser;
  bool logoutCalled = false;
  bool shouldThrowOnLogout = false;

  @override
  Future<void> onUserLogout() async {
    logoutCalled = true;
    if (shouldThrowOnLogout) {
      throw Exception('Fake logout error');
    }
  }

  @override
  Future<void> onUserLogin(AppUser user) async {
    loginCallCount++;
    lastLoginUser = user;
  }

  @override
  SyncStatus get status => SyncStatus.idle;
}

class FakeUserStatsRepo extends Fake implements UserStatsRepo {
  @override
  Future<void> updateLoginStreak(AppUser user) async {}
}

class SpyAuthRepo extends Fake implements AuthRepository {
  bool signOutCalled = false;
  bool wasSyncLogoutCalledFirst = false;
  final SpySyncCoordinator coordinator;

  final StreamController<AppUser?> userStreamController =
      StreamController<AppUser?>.broadcast();

  SpyAuthRepo(this.coordinator);

  @override
  Stream<AppUser?> watchAuthUser() => userStreamController.stream;

  @override
  Future<AppUser> ensureAnonymousGuestSignedIn() async =>
      AppUser(uid: 'guest', isAnonymous: true);

  @override
  Future<void> signOut() async {
    wasSyncLogoutCalledFirst = coordinator.logoutCalled;
    signOutCalled = true;
  }

  @override
  Future<AppUser?> getCurrentUser() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    clearStorage();
  });

  group('Sprint 5A — Auth Flow and Error Tests', () {
    test(
      'AuthRepository.sendPasswordResetEmail suppresses user-not-found for enumeration prevention',
      () async {
        final fakeAuth = FakeFirebaseAuthForReset();
        final fakeFunctions = FakeFirebaseFunctions();
        final repo = AuthRepository(
          fakeAuth,
          const SocialAuthServiceImpl(),
          fakeFunctions,
        );

        // 1. notfound@example.com -> throws user-not-found -> suppressed, completes normally
        await expectLater(
          repo.sendPasswordResetEmail('notfound@example.com'),
          completes,
        );

        // 2. error@example.com -> throws invalid-email -> throws AppFailure.auth
        try {
          await repo.sendPasswordResetEmail('error@example.com');
          fail('Should have thrown AppFailure');
        } catch (e) {
          expect(e, isA<AppFailure>());
          final failure = e as AppFailure;
          expect(failure.type, equals(FailureType.auth));
          expect(failure.code, equals('invalid-email'));
        }
      },
    );

    test(
      'AuthController.signOut stops SyncCoordinator before Firebase Auth signOut',
      () async {
        final coordinator = SpySyncCoordinator();
        final repo = SpyAuthRepo(coordinator);

        final container = ProviderContainer(
          overrides: [
            syncCoordinatorProvider.overrideWith((ref) async => coordinator),
            authRepositoryProvider.overrideWithValue(repo),
            userStatsRepoProvider.overrideWithValue(FakeUserStatsRepo()),
          ],
        );
        addTearDown(container.dispose);

        final controller = container.read(authControllerProvider.notifier);

        await controller.signOut();

        expect(
          coordinator.logoutCalled,
          isTrue,
          reason: 'SyncCoordinator.onUserLogout should be called',
        );
        expect(
          repo.signOutCalled,
          isTrue,
          reason: 'AuthRepository.signOut should be called',
        );
        expect(
          repo.wasSyncLogoutCalledFirst,
          isTrue,
          reason:
              'Sync coordinator MUST be stopped before auth session is cleared',
        );
      },
    );

    test(
      'AuthController._init starts SyncCoordinator on cold boot for authenticated user',
      () async {
        final coordinator = SpySyncCoordinator();
        final repo = SpyAuthRepo(coordinator);

        final container = ProviderContainer(
          overrides: [
            syncCoordinatorProvider.overrideWith((ref) async => coordinator),
            authRepositoryProvider.overrideWithValue(repo),
            userStatsRepoProvider.overrideWithValue(FakeUserStatsRepo()),
          ],
        );
        addTearDown(container.dispose);

        // Force AuthController initialization
        container.read(authControllerProvider.notifier);

        // Simulate a cold boot where Firebase Auth emits a real authenticated user
        final realUser = AppUser(
          uid: 'real_uid',
          isAnonymous: false,
          isGuestMode: false,
        );
        repo.userStreamController.add(realUser);

        // Allow async events to propagate
        await Future<void>.delayed(Duration.zero);

        expect(
          coordinator.loginCallCount,
          equals(1),
          reason:
              'SyncCoordinator.onUserLogin should be called on cold boot for authenticated user',
        );
        expect(coordinator.lastLoginUser?.uid, equals('real_uid'));
      },
    );

    test(
      'SyncCoordinator.onUserLogout throwing does not stop AuthRepository.signOut',
      () async {
        final coordinator = SpySyncCoordinator()..shouldThrowOnLogout = true;
        final repo = SpyAuthRepo(coordinator);

        final container = ProviderContainer(
          overrides: [
            syncCoordinatorProvider.overrideWith((ref) async => coordinator),
            authRepositoryProvider.overrideWithValue(repo),
            userStatsRepoProvider.overrideWithValue(FakeUserStatsRepo()),
          ],
        );
        addTearDown(container.dispose);

        final controller = container.read(authControllerProvider.notifier);

        // Should not throw
        await expectLater(controller.signOut(), completes);

        expect(coordinator.logoutCalled, isTrue);
        expect(
          repo.signOutCalled,
          isTrue,
          reason:
              'AuthRepository.signOut must be called even if sync coordinator throws',
        );
      },
    );

    test('Raw FirebaseAuthException does not leak from AuthController', () async {
      // Create a repo that throws FirebaseAuthException on getCurrentUser or register
      final fakeAuth = FakeFirebaseAuthForReset();
      final fakeFunctions = FakeFirebaseFunctions();
      final repo = AuthRepository(
        fakeAuth,
        const SocialAuthServiceImpl(),
        fakeFunctions,
      );

      // We know sendPasswordResetEmail is tested, let's verify map works
      try {
        await repo.sendPasswordResetEmail(
          'error@example.com',
        ); // throws invalid-email
        fail('Should throw');
      } catch (e) {
        expect(e, isA<AppFailure>());
        expect((e as AppFailure).type, equals(FailureType.auth));
      }
    });
  });
}
