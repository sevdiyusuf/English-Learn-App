import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yunoo/core/notifications/push_messaging_gateway.dart';
import 'package:yunoo/core/notifications/push_registration_manager.dart';

class _Result<T> implements HttpsCallableResult<T> {
  _Result(this.data);
  @override
  final T data;
}

class _Callable extends Fake implements HttpsCallable {
  _Callable(this.name, this.owner);
  final String name;
  final _Functions owner;

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    owner.calls.add((name, Map<String, dynamic>.from(parameters as Map)));
    if (owner.failNext) {
      owner.failNext = false;
      throw FirebaseFunctionsException(code: 'unavailable', message: 'failed');
    }
    return _Result<T>(<String, dynamic>{} as T);
  }
}

class _Functions extends Fake implements FirebaseFunctions {
  final List<(String, Map<String, dynamic>)> calls = [];
  bool failNext = false;

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) =>
      _Callable(name, this);
}

class _Gateway implements PushMessagingGateway {
  final foreground = StreamController<PushMessage>.broadcast();
  final opened = StreamController<PushMessage>.broadcast();
  final refresh = StreamController<String>.broadcast();
  String? token = 'token_1234567890123456';
  int permissionRequests = 0;
  int deleteCount = 0;

  @override
  Stream<PushMessage> get foregroundMessages => foreground.stream;
  @override
  Stream<PushMessage> get openedMessages => opened.stream;
  @override
  Stream<String> get tokenRefreshes => refresh.stream;
  @override
  Future<PushAuthorizationStatus> authorizationStatus() async =>
      PushAuthorizationStatus.notDetermined;
  @override
  Future<void> deleteToken() async => deleteCount++;
  @override
  Future<PushMessage?> getInitialMessage() async => null;
  @override
  Future<String?> getToken() async => token;
  @override
  Future<PushAuthorizationStatus> requestPermission() async {
    permissionRequests++;
    return PushAuthorizationStatus.granted;
  }
}

void main() {
  test(
    'registration never requests permission and deduplicates same token',
    () async {
      final gateway = _Gateway();
      final functions = _Functions();
      final manager = PushRegistrationManager(gateway, functions);

      expect(await manager.register(uid: 'user-a', locale: 'tr'), isTrue);
      expect(await manager.register(uid: 'user-a', locale: 'tr'), isTrue);

      expect(gateway.permissionRequests, 0);
      expect(
        functions.calls.where((call) => call.$1 == 'registerNotificationToken'),
        hasLength(1),
      );
      expect(functions.calls.single.$2['locale'], 'tr');
    },
  );

  test(
    'refresh registration, unregister and account switch remain scoped',
    () async {
      final gateway = _Gateway();
      final functions = _Functions();
      final manager = PushRegistrationManager(gateway, functions);
      await manager.register(uid: 'user-a', locale: 'en');
      await manager.registerToken(
        uid: 'user-a',
        token: 'refreshed_1234567890123456',
        locale: 'en',
      );
      gateway.token = 'refreshed_1234567890123456';
      await manager.unregisterCurrent();
      gateway.token = 'account_b_1234567890123456';
      await manager.register(uid: 'user-b', locale: 'en');

      expect(functions.calls.map((call) => call.$1), [
        'registerNotificationToken',
        'registerNotificationToken',
        'unregisterNotificationToken',
        'registerNotificationToken',
      ]);
      expect(gateway.deleteCount, 1);
    },
  );

  test(
    'failed registration remains retryable and null token is graceful',
    () async {
      final gateway = _Gateway();
      final functions = _Functions()..failNext = true;
      final manager = PushRegistrationManager(gateway, functions);

      await expectLater(
        manager.register(uid: 'user-a', locale: 'en'),
        throwsA(isA<FirebaseFunctionsException>()),
      );
      expect(await manager.register(uid: 'user-a', locale: 'en'), isTrue);

      gateway.token = null;
      manager.clearLocalRegistration();
      expect(await manager.register(uid: 'user-a', locale: 'en'), isFalse);
    },
  );
}
