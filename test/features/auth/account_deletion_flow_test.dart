import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yunoo/core/errors/app_failure.dart';
import 'package:yunoo/features/auth/logic/auth_controller.dart';
import 'package:yunoo/features/auth/models/app_user.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:yunoo/app/di.dart';
import 'package:yunoo/features/sync/data/outbox_repository.dart';
import 'package:yunoo/features/word_match/data/word_match_repo_interface.dart';
import 'package:yunoo/features/sync/services/sync_coordinator.dart';
import 'package:yunoo/features/sync/sync_providers.dart';
import 'package:yunoo/features/word_match/data/word_match_providers.dart';
import 'package:yunoo/core/repositories/user_stats_repo.dart';
import 'package:yunoo/core/repositories/user_settings_repo.dart';

class FakeHttpsCallableResult<T> implements HttpsCallableResult<T> {
  FakeHttpsCallableResult(this.data);
  @override
  final T data;
}

class FakeHttpsCallable extends Fake implements HttpsCallable {
  int callCount = 0;
  bool shouldThrow = false;
  String? mockErrorCode;

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    callCount++;
    if (shouldThrow) {
      throw FirebaseFunctionsException(
        message: 'error',
        code: mockErrorCode ?? 'internal',
      );
    }
    return FakeHttpsCallableResult<T>({} as T);
  }
}

class FakeFirebaseFunctions extends Fake implements FirebaseFunctions {
  final FakeHttpsCallable callable = FakeHttpsCallable();
  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) {
    if (name == 'requestAccountDeletion') return callable;
    return FakeHttpsCallable();
  }
}

class FakeUserInfo extends Fake implements firebase_auth.UserInfo {
  @override
  final String providerId = 'password';
}

class FakeUserMetadata extends Fake implements firebase_auth.UserMetadata {
  @override
  final DateTime? creationTime = DateTime.now();
  @override
  final DateTime? lastSignInTime = DateTime.now();
}

class FakeUser extends Fake implements firebase_auth.User {
  @override
  final List<firebase_auth.UserInfo> providerData = [FakeUserInfo()];
  @override
  bool isAnonymous = false;
  @override
  final String? email = 'test@test.com';
  @override
  final String? displayName = 'Test User';
  @override
  final String? photoURL = null;
  @override
  final firebase_auth.UserMetadata metadata = FakeUserMetadata();
  @override
  final String uid = 'user123';

  bool reauthThrows = false;

  @override
  Future<firebase_auth.UserCredential> reauthenticateWithCredential(
    firebase_auth.AuthCredential credential,
  ) async {
    if (reauthThrows) {
      throw firebase_auth.FirebaseAuthException(code: 'wrong-password');
    }
    return FakeUserCredential();
  }
}

class FakeUserCredential extends Fake implements firebase_auth.UserCredential {
  @override
  final firebase_auth.User? user = FakeUser();
}

class FakeFirebaseAuth extends Fake implements firebase_auth.FirebaseAuth {
  FakeUser? _currentUser = FakeUser();
  final Stream<firebase_auth.User?> _stream = Stream.value(FakeUser());

  @override
  Stream<firebase_auth.User?> authStateChanges() => _stream;

  @override
  firebase_auth.User? get currentUser => _currentUser;

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  @override
  Future<firebase_auth.UserCredential> signInAnonymously() async {
    _currentUser =
        FakeUser()
          ..isAnonymous = true
          ..providerData.clear();
    return FakeUserCredential();
  }
}

class FakeSyncCoordinator extends Fake implements SyncCoordinator {
  @override
  Future<void> onUserLogin(AppUser user) async {}

  int onUserLogoutCount = 0;
  @override
  Future<void> onUserLogout() async {
    onUserLogoutCount++;
  }
}

class FakeWordMatchRepo extends Fake implements WordMatchRepoInterface {
  List<String> clearedUids = [];
  @override
  Future<void> clearUserData(String uid) async {
    clearedUids.add(uid);
  }
}

class FakeOutboxRepository extends Fake implements OutboxRepository {
  List<String> clearedUids = [];
  @override
  Future<void> clearUserData(String uid) async {
    clearedUids.add(uid);
  }
}

class FakeUserStatsRepo extends Fake implements UserStatsRepo {
  @override
  Future<void> updateLoginStreak(AppUser user) async {}

  Stream<void> get userStatsStream => const Stream.empty();
}

class FakeUserSettingsRepo extends Fake implements UserSettingsRepo {
  Stream<void> get userSettingsStream => const Stream.empty();
}

void main() {
  late ProviderContainer container;
  late FakeFirebaseAuth fakeAuth;
  late FakeFirebaseFunctions fakeFunctions;
  late FakeSyncCoordinator fakeSync;
  late FakeWordMatchRepo fakeWordMatch;
  late FakeOutboxRepository fakeOutbox;

  setUp(() {
    fakeAuth = FakeFirebaseAuth();
    fakeFunctions = FakeFirebaseFunctions();
    fakeSync = FakeSyncCoordinator();
    fakeWordMatch = FakeWordMatchRepo();
    fakeOutbox = FakeOutboxRepository();

    container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(fakeAuth),
        firebaseFunctionsProvider.overrideWithValue(fakeFunctions),
        syncCoordinatorProvider.overrideWith((ref) => fakeSync),
        wordMatchRepoProvider.overrideWith((ref) => fakeWordMatch),
        userStatsRepoProvider.overrideWith((ref) => FakeUserStatsRepo()),
        userSettingsRepoProvider.overrideWith((ref) => FakeUserSettingsRepo()),
        outboxRepositoryProvider.overrideWith((ref) => fakeOutbox),
      ],
    );
  });

  group('Sprint 5C Account Deletion Tests', () {
    test('reauth failure blocks deletion entirely', () async {
      // we need to set state of authController to a registered user first
      final controller = container.read(authControllerProvider.notifier);
      // Wait for initialization
      await Future.delayed(Duration.zero);
      // override user state to be password

      while (controller.state.value?.providerId != 'password') {
        await Future.delayed(const Duration(milliseconds: 10));
      }

      fakeAuth._currentUser!.reauthThrows = true; // force error

      expect(
        () => controller.deleteAccountAndData(password: 'wrong_pass'),
        throwsA(isA<AppFailure>()),
      );

      // Verification: callable never called, sync never stopped
      expect(fakeFunctions.callable.callCount, 0);
      expect(fakeSync.onUserLogoutCount, 0);
      expect(fakeWordMatch.clearedUids.isEmpty, true);
    });

    test('callable failure keeps local data intact', () async {
      final controller = container.read(authControllerProvider.notifier);
      await Future.delayed(Duration.zero);

      while (controller.state.value?.providerId != 'password') {
        await Future.delayed(const Duration(milliseconds: 10));
      }

      fakeFunctions.callable.shouldThrow = true;
      fakeFunctions.callable.mockErrorCode =
          'permission-denied'; // simulates recent-login error

      expect(
        () => controller.deleteAccountAndData(password: 'correct_pass'),
        throwsA(isA<AppFailure>()),
      );

      // Wait a tick for async exception to bubble
      await Future.delayed(Duration.zero);

      expect(fakeFunctions.callable.callCount, 1);
      expect(fakeWordMatch.clearedUids.isEmpty, true);
    });

    test(
      'success calls sync stop, callable, local cleanup and signout',
      () async {
        final controller = container.read(authControllerProvider.notifier);
        await Future.delayed(Duration.zero);

        while (controller.state.value?.providerId != 'password') {
          await Future.delayed(const Duration(milliseconds: 10));
        }

        await controller.deleteAccountAndData(password: 'correct_pass');

        expect(fakeFunctions.callable.callCount, 1);
        expect(fakeSync.onUserLogoutCount, 1);
        expect(fakeWordMatch.clearedUids, contains('user123'));
        expect(fakeOutbox.clearedUids, contains('user123'));
        expect(fakeAuth.currentUser!.isAnonymous, isTrue);
      },
    );
  });
}
