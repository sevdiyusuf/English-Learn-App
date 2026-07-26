import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yunoo/core/errors/app_failure.dart';
import 'package:yunoo/features/auth/data/auth_repo.dart';
import 'package:yunoo/features/auth/services/social_auth_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:yunoo/app/di.dart';

class FakeSocialAuthService implements SocialAuthService {
  @override
  bool get isWeb => false;

  @override
  Future<firebase_auth.OAuthCredential?> getGoogleCredential() async {
    return firebase_auth.GoogleAuthProvider.credential(
      accessToken: 'fake_access',
      idToken: 'fake_id',
    );
  }

  @override
  Future<firebase_auth.OAuthCredential?> getAppleCredential() async {
    return firebase_auth.OAuthProvider(
      'apple.com',
    ).credential(accessToken: 'fake_apple_access', idToken: 'fake_apple_id');
  }
}

class FakeUser implements firebase_auth.User {
  @override
  final String uid = 'test-uid';

  @override
  bool get isAnonymous => false;

  @override
  String? get email => 'test@test.com';

  @override
  List<firebase_auth.UserInfo> get providerData => [];

  @override
  String? get displayName => 'Test User';

  @override
  String? get photoURL => null;

  bool reauthCalled = false;
  bool reauthShouldThrow = false;

  @override
  Future<firebase_auth.UserCredential> reauthenticateWithCredential(
    firebase_auth.AuthCredential credential,
  ) async {
    if (reauthShouldThrow) {
      throw firebase_auth.FirebaseAuthException(code: 'wrong-password');
    }
    reauthCalled = true;
    return FakeUserCredential(this);
  }

  @override
  Future<firebase_auth.UserCredential> reauthenticateWithPopup(
    firebase_auth.AuthProvider provider,
  ) async {
    if (reauthShouldThrow) {
      throw firebase_auth.FirebaseAuthException(code: 'invalid-credential');
    }
    reauthCalled = true;
    return FakeUserCredential(this);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUserCredential implements firebase_auth.UserCredential {
  FakeUserCredential(this.user);
  @override
  final firebase_auth.User? user;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFirebaseAuth implements firebase_auth.FirebaseAuth {
  FakeUser? _currentUser;

  void setCurrentUser(FakeUser user) {
    _currentUser = user;
  }

  @override
  firebase_auth.User? get currentUser => _currentUser;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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

void main() {
  late ProviderContainer container;
  late FakeFirebaseAuth fakeAuth;
  late FakeSocialAuthService fakeSocialAuth;

  setUp(() {
    fakeAuth = FakeFirebaseAuth();
    fakeSocialAuth = FakeSocialAuthService();
    container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(fakeAuth),
        socialAuthServiceProvider.overrideWithValue(fakeSocialAuth),
        firebaseFunctionsProvider.overrideWithValue(FakeFirebaseFunctions()),
      ],
    );
  });

  group('AuthRepository Reauthentication Tests', () {
    test('reauthenticateWithGoogle reauthenticates successfully', () async {
      final repo = container.read(authRepositoryProvider);
      final fakeUser = FakeUser();
      fakeAuth.setCurrentUser(fakeUser);

      await repo.reauthenticateWithGoogle();
      expect(fakeUser.reauthCalled, true);
    });

    test('reauthenticateWithGoogle throws AppFailure on error', () async {
      final repo = container.read(authRepositoryProvider);
      final fakeUser = FakeUser();
      fakeUser.reauthShouldThrow = true;
      fakeAuth.setCurrentUser(fakeUser);

      expect(() => repo.reauthenticateWithGoogle(), throwsA(isA<AppFailure>()));
    });

    test('reauthenticateWithPassword reauthenticates successfully', () async {
      final repo = container.read(authRepositoryProvider);
      final fakeUser = FakeUser();
      fakeAuth.setCurrentUser(fakeUser);

      await repo.reauthenticateWithPassword('correct_password');
      expect(fakeUser.reauthCalled, true);
    });

    test(
      'reauthenticateWithPassword throws AppFailure on wrong password',
      () async {
        final repo = container.read(authRepositoryProvider);
        final fakeUser = FakeUser();
        fakeUser.reauthShouldThrow = true;
        fakeAuth.setCurrentUser(fakeUser);

        expect(
          () => repo.reauthenticateWithPassword('wrong_password'),
          throwsA(
            isA<AppAuthFailure>().having(
              (e) => e.reason,
              'reason',
              AuthFailureReason.wrongPassword,
            ),
          ),
        );
      },
    );
  });
}
