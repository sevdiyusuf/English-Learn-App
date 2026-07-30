import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yunoo/core/errors/app_failure.dart';
import 'package:yunoo/features/auth/data/auth_repo.dart';
import 'package:yunoo/features/auth/services/social_auth_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:yunoo/app/di.dart';

class FakeSocialAuthService implements SocialAuthService {
  bool shouldCancel = false;
  bool isWebEnvironment = false;

  @override
  bool get isWeb => isWebEnvironment;

  @override
  Future<firebase_auth.OAuthCredential?> getGoogleCredential() async {
    if (shouldCancel) return null;
    return firebase_auth.GoogleAuthProvider.credential(
      accessToken: 'fake_access',
      idToken: 'fake_id',
    );
  }

  @override
  Future<firebase_auth.OAuthCredential?> getAppleCredential() async {
    if (shouldCancel) return null;
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

  bool linkCalled = false;
  firebase_auth.AuthCredential? linkedCredential;
  bool linkShouldThrowCollision = false;

  @override
  Future<firebase_auth.UserCredential> linkWithCredential(
    firebase_auth.AuthCredential credential,
  ) async {
    if (linkShouldThrowCollision) {
      throw firebase_auth.FirebaseAuthException(
        code: 'credential-already-in-use',
      );
    }
    linkCalled = true;
    linkedCredential = credential;
    return FakeUserCredential(this);
  }

  @override
  Future<firebase_auth.UserCredential> linkWithPopup(
    firebase_auth.AuthProvider provider,
  ) async {
    linkCalled = true;
    return FakeUserCredential(this);
  }

  @override
  Future<firebase_auth.UserCredential> reauthenticateWithCredential(
    firebase_auth.AuthCredential credential,
  ) async {
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
  bool signInCalled = false;
  bool popupCalled = false;

  void setCurrentUser(FakeUser user) {
    _currentUser = user;
  }

  @override
  firebase_auth.User? get currentUser => _currentUser;

  @override
  Future<firebase_auth.UserCredential> signInWithCredential(
    firebase_auth.AuthCredential credential,
  ) async {
    signInCalled = true;
    return FakeUserCredential(FakeUser());
  }

  @override
  Future<firebase_auth.UserCredential> signInWithPopup(
    firebase_auth.AuthProvider provider,
  ) async {
    popupCalled = true;
    return FakeUserCredential(FakeUser());
  }

  @override
  Stream<firebase_auth.User?> authStateChanges() => Stream.value(_currentUser);

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

  group('AuthRepository Social Flow Tests', () {
    test('signInWithGoogle throws cancel error if user cancels', () async {
      final repo = container.read(authRepositoryProvider);
      fakeSocialAuth.shouldCancel = true;

      expect(
        () => repo.signInWithGoogle(),
        throwsA(
          isA<AppFailure>().having(
            (e) => e.message,
            'message',
            contains('iptal'),
          ),
        ),
      );
    });

    test('signInWithGoogle signs in if credential is provided', () async {
      final repo = container.read(authRepositoryProvider);

      final user = await repo.signInWithGoogle();
      expect(user.uid, 'test-uid');
      expect(fakeAuth.signInCalled, true);
    });

    test(
      'linkGoogleAccount bubbles credential-already-in-use exception',
      () async {
        final repo = container.read(authRepositoryProvider);
        final fakeUser = FakeUser();
        fakeUser.linkShouldThrowCollision = true;
        fakeAuth.setCurrentUser(fakeUser);

        expect(
          () => repo.linkGoogleAccount(),
          throwsA(
            isA<AppAuthFailure>().having(
              (e) => e.reason,
              'reason',
              AuthFailureReason.collision,
            ),
          ),
        );
      },
    );

    test('linkGoogleAccount links successfully', () async {
      final repo = container.read(authRepositoryProvider);
      final fakeUser = FakeUser();
      fakeAuth.setCurrentUser(fakeUser);

      final user = await repo.linkGoogleAccount();
      expect(fakeUser.linkCalled, true);
      expect(fakeUser.linkedCredential, isNotNull);
      expect(user.uid, 'test-uid');
    });
  });
}
