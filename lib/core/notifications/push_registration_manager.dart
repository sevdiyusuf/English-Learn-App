import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import 'push_messaging_gateway.dart';

class PushRegistrationManager {
  PushRegistrationManager(this._gateway, this._functions);

  final PushMessagingGateway _gateway;
  final FirebaseFunctions _functions;
  String? _registeredUid;
  String? _registeredToken;
  String? _registeredLocale;

  Future<bool> register({required String uid, required String locale}) async {
    final token = await _gateway.getToken();
    if (token == null || token.isEmpty) return false;
    return registerToken(uid: uid, token: token, locale: locale);
  }

  Future<bool> registerToken({
    required String uid,
    required String token,
    required String locale,
  }) async {
    if (_registeredUid == uid &&
        _registeredToken == token &&
        _registeredLocale == locale) {
      return true;
    }
    await _functions.httpsCallable('registerNotificationToken').call({
      'token': token,
      'platform': _platform,
      'locale': locale == 'tr' ? 'tr' : 'en',
    });
    _registeredUid = uid;
    _registeredToken = token;
    _registeredLocale = locale;
    return true;
  }

  Future<void> unregisterCurrent() async {
    final token = _registeredToken ?? await _gateway.getToken();
    if (token != null && token.isNotEmpty) {
      await _functions.httpsCallable('unregisterNotificationToken').call({
        'token': token,
      });
    }
    await _gateway.deleteToken();
    _registeredUid = null;
    _registeredToken = null;
    _registeredLocale = null;
  }

  void clearLocalRegistration() {
    _registeredUid = null;
    _registeredToken = null;
    _registeredLocale = null;
  }

  String get _platform {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }
}

final pushMessagingGatewayProvider = Provider<PushMessagingGateway>((ref) {
  return FirebasePushMessagingGateway(FirebaseMessaging.instance);
});

final pushRegistrationManagerProvider = Provider<PushRegistrationManager>((
  ref,
) {
  return PushRegistrationManager(
    ref.watch(pushMessagingGatewayProvider),
    ref.watch(firebaseFunctionsProvider),
  );
});
