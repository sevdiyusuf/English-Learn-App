import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/logic/auth_controller.dart';
import '../../features/profile_settings/logic/user_settings_controller.dart';
import 'push_messaging_gateway.dart';
import 'push_registration_manager.dart';

enum PushPreferenceResult { enabled, denied, unavailable }

class PushNotificationState {
  const PushNotificationState({
    this.authorization = PushAuthorizationStatus.notDetermined,
    this.busy = false,
    this.error = false,
  });

  final PushAuthorizationStatus authorization;
  final bool busy;
  final bool error;

  PushNotificationState copyWith({
    PushAuthorizationStatus? authorization,
    bool? busy,
    bool? error,
  }) => PushNotificationState(
    authorization: authorization ?? this.authorization,
    busy: busy ?? this.busy,
    error: error ?? this.error,
  );
}

class PushNotificationController extends StateNotifier<PushNotificationState> {
  PushNotificationController(this._ref) : super(const PushNotificationState()) {
    _tokenSubscription = _gateway.tokenRefreshes.listen(_handleTokenRefresh);
    _ref.listen(authControllerProvider, (_, __) => _syncWithoutPrompt());
    _ref.listen(
      userSettingsControllerProvider,
      (_, __) => _syncWithoutPrompt(),
    );
    unawaited(_syncWithoutPrompt());
  }

  final Ref _ref;
  StreamSubscription<String>? _tokenSubscription;

  PushMessagingGateway get _gateway => _ref.read(pushMessagingGatewayProvider);
  PushRegistrationManager get _registrations =>
      _ref.read(pushRegistrationManagerProvider);

  Future<PushPreferenceResult> enable() async {
    if (state.busy) return PushPreferenceResult.unavailable;
    state = state.copyWith(busy: true, error: false);
    try {
      final authorization = await _gateway.requestPermission();
      state = state.copyWith(authorization: authorization);
      if (authorization != PushAuthorizationStatus.granted &&
          authorization != PushAuthorizationStatus.provisional) {
        return PushPreferenceResult.denied;
      }
      final user = _ref.read(authControllerProvider).valueOrNull;
      if (user == null || user.isAnonymous || user.isGuestMode) {
        return PushPreferenceResult.unavailable;
      }
      final locale =
          _ref.read(userSettingsControllerProvider).valueOrNull?.languageCode ??
          'en';
      final registered = await _registrations.register(
        uid: user.uid,
        locale: locale,
      );
      if (!registered) throw StateError('notification-token-unavailable');
      try {
        await _ref
            .read(userSettingsControllerProvider.notifier)
            .updateMultiplayerNotifications(true);
      } catch (_) {
        await _registrations.unregisterCurrent();
        rethrow;
      }
      return PushPreferenceResult.enabled;
    } catch (_) {
      state = state.copyWith(error: true);
      return PushPreferenceResult.unavailable;
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  Future<void> disable() async {
    if (state.busy) return;
    state = state.copyWith(busy: true, error: false);
    try {
      await _registrations.unregisterCurrent();
      await _ref
          .read(userSettingsControllerProvider.notifier)
          .updateMultiplayerNotifications(false);
    } catch (_) {
      state = state.copyWith(error: true);
      rethrow;
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  Future<void> _syncWithoutPrompt() async {
    final user = _ref.read(authControllerProvider).valueOrNull;
    final settings = _ref.read(userSettingsControllerProvider).valueOrNull;
    if (user == null ||
        user.isAnonymous ||
        user.isGuestMode ||
        settings == null ||
        !settings.multiplayerNotificationsEnabled) {
      return;
    }
    try {
      final authorization = await _gateway.authorizationStatus();
      if (authorization != PushAuthorizationStatus.granted &&
          authorization != PushAuthorizationStatus.provisional) {
        state = state.copyWith(authorization: authorization);
        return;
      }
      state = state.copyWith(authorization: authorization);
      await _registrations.register(
        uid: user.uid,
        locale: settings.languageCode,
      );
    } catch (_) {
      state = state.copyWith(error: true);
    }
  }

  Future<void> _handleTokenRefresh(String token) async {
    final user = _ref.read(authControllerProvider).valueOrNull;
    final settings = _ref.read(userSettingsControllerProvider).valueOrNull;
    if (user == null ||
        user.isAnonymous ||
        user.isGuestMode ||
        settings == null ||
        !settings.multiplayerNotificationsEnabled ||
        token.isEmpty) {
      return;
    }
    try {
      await _registrations.registerToken(
        uid: user.uid,
        token: token,
        locale: settings.languageCode,
      );
    } catch (_) {
      state = state.copyWith(error: true);
    }
  }

  @override
  void dispose() {
    _tokenSubscription?.cancel();
    super.dispose();
  }
}

final pushNotificationControllerProvider =
    StateNotifierProvider<PushNotificationController, PushNotificationState>((
      ref,
    ) {
      return PushNotificationController(ref);
    });
