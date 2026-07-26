import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../../features/auth/logic/auth_controller.dart';
import '../../features/auth/models/app_user.dart';
import '../../features/friends/logic/invitation_controller.dart';
import '../../features/profile_settings/logic/user_settings_controller.dart';
import '../../features/profile_settings/models/user_settings.dart';
import 'incoming_destination.dart';
import 'push_messaging_gateway.dart';
import 'push_registration_manager.dart';

bool isIncomingDestinationReady(
  IncomingDestination destination,
  AppUser? user,
  UserSettings? settings,
) {
  if (destination is! MultiplayerInvitationDestination) return true;
  return user != null &&
      !user.isAnonymous &&
      !user.isGuestMode &&
      settings != null &&
      settings.onboardingCompletedVersion >=
          LearningProfileValues.currentOnboardingVersion;
}

class IncomingDestinationDeduplicator {
  final Set<String> _seen = {};

  bool claim(IncomingDestination destination) =>
      _seen.add(destination.deduplicationKey);
}

abstract interface class ExternalLinkGateway {
  Stream<Uri> get links;
  Future<Uri?> getInitialLink();
}

class AppLinksGateway implements ExternalLinkGateway {
  AppLinksGateway(this._links);
  final AppLinks _links;

  @override
  Stream<Uri> get links => _links.uriLinkStream;

  @override
  Future<Uri?> getInitialLink() => _links.getInitialLink();
}

class IncomingRouteState {
  const IncomingRouteState({
    this.pending,
    this.foregroundInvitation,
    this.invitationUnavailable = false,
  });

  final IncomingDestination? pending;
  final MultiplayerInvitationDestination? foregroundInvitation;
  final bool invitationUnavailable;

  IncomingRouteState copyWith({
    IncomingDestination? pending,
    bool clearPending = false,
    MultiplayerInvitationDestination? foregroundInvitation,
    bool clearForeground = false,
    bool? invitationUnavailable,
  }) => IncomingRouteState(
    pending: clearPending ? null : (pending ?? this.pending),
    foregroundInvitation:
        clearForeground
            ? null
            : (foregroundInvitation ?? this.foregroundInvitation),
    invitationUnavailable: invitationUnavailable ?? this.invitationUnavailable,
  );
}

class IncomingRouteCoordinator extends StateNotifier<IncomingRouteState> {
  IncomingRouteCoordinator(this._ref) : super(const IncomingRouteState()) {
    _openedSubscription = _push.openedMessages.listen(
      (message) => _receiveMessage(message, foreground: false),
    );
    _foregroundSubscription = _push.foregroundMessages.listen(
      (message) => _receiveMessage(message, foreground: true),
    );
    _linkSubscription = _links.links.listen(receiveUri);
    _ref.listen(authControllerProvider, (_, __) => _resumePending());
    _ref.listen(userSettingsControllerProvider, (_, __) => _resumePending());
    unawaited(_loadInitialEvents());
  }

  final Ref _ref;
  final IncomingDestinationDeduplicator _deduplicator =
      IncomingDestinationDeduplicator();
  StreamSubscription<PushMessage>? _openedSubscription;
  StreamSubscription<PushMessage>? _foregroundSubscription;
  StreamSubscription<Uri>? _linkSubscription;
  bool _handling = false;

  PushMessagingGateway get _push => _ref.read(pushMessagingGatewayProvider);
  ExternalLinkGateway get _links => _ref.read(externalLinkGatewayProvider);

  Future<void> _loadInitialEvents() async {
    try {
      final message = await _push.getInitialMessage();
      if (!mounted) return;
      if (message != null) await _receiveMessage(message, foreground: false);
    } catch (_) {
      // Push initialization must never block normal app startup.
    }
    try {
      final uri = await _links.getInitialLink();
      if (!mounted) return;
      if (uri != null) await receiveUri(uri);
    } catch (_) {
      // Platform-link initialization is non-fatal.
    }
  }

  Future<void> _receiveMessage(
    PushMessage message, {
    required bool foreground,
  }) async {
    if (!mounted) return;
    final destination = IncomingDestinationParser.fromMessageData(message.data);
    if (destination == null) return;
    if (foreground && destination is MultiplayerInvitationDestination) {
      if (!_deduplicator.claim(destination)) return;
      state = state.copyWith(foregroundInvitation: destination);
      return;
    }
    await receive(destination);
  }

  Future<void> receiveUri(Uri uri) async {
    if (!mounted) return;
    final destination = IncomingDestinationParser.fromUri(uri);
    if (destination != null) await receive(destination);
  }

  Future<void> receive(IncomingDestination destination) async {
    if (!mounted) return;
    if (!_deduplicator.claim(destination)) return;
    if (!_readyFor(destination)) {
      state = state.copyWith(pending: destination);
      return;
    }
    await _handle(destination);
  }

  Future<void> openForegroundInvitation() async {
    if (!mounted) return;
    final destination = state.foregroundInvitation;
    if (destination == null) return;
    state = state.copyWith(clearForeground: true);
    if (!_readyFor(destination)) {
      state = state.copyWith(pending: destination);
      return;
    }
    await _handle(destination);
  }

  void dismissForegroundInvitation() {
    if (!mounted) return;
    state = state.copyWith(clearForeground: true);
  }

  bool _readyFor(IncomingDestination destination) {
    final user = _ref.read(authControllerProvider).valueOrNull;
    final settings = _ref.read(userSettingsControllerProvider).valueOrNull;
    return isIncomingDestinationReady(destination, user, settings);
  }

  Future<void> _resumePending() async {
    if (!mounted) return;
    final pending = state.pending;
    if (pending == null || !_readyFor(pending)) return;
    state = state.copyWith(clearPending: true);
    await _handle(pending);
  }

  Future<void> _handle(IncomingDestination destination) async {
    if (!mounted) return;
    if (_handling) {
      state = state.copyWith(pending: destination);
      return;
    }
    _handling = true;
    try {
      switch (destination) {
        case HomeDestination():
          _ref.read(appRouterProvider).go('/');
        case PublicShareDestination(:final shareId):
          _ref.read(appRouterProvider).go('/s/$shareId');
        case MultiplayerInvitationDestination(:final invitationId):
          final handled = await _ref
              .read(invitationControllerProvider.notifier)
              .acceptInvitationById(invitationId);
          if (!mounted) return;
          if (!handled) {
            state = state.copyWith(invitationUnavailable: true);
          }
      }
    } finally {
      _handling = false;
      if (mounted) {
        final queued = state.pending;
        if (queued != null && _readyFor(queued)) {
          state = state.copyWith(clearPending: true);
          unawaited(_handle(queued));
        }
      }
    }
  }

  void clearUnavailable() {
    if (!mounted) return;
    state = state.copyWith(invitationUnavailable: false);
  }

  @override
  void dispose() {
    _openedSubscription?.cancel();
    _foregroundSubscription?.cancel();
    _linkSubscription?.cancel();
    super.dispose();
  }
}

final externalLinkGatewayProvider = Provider<ExternalLinkGateway>((ref) {
  return AppLinksGateway(AppLinks());
});

final incomingRouteCoordinatorProvider =
    StateNotifierProvider<IncomingRouteCoordinator, IncomingRouteState>((ref) {
      return IncomingRouteCoordinator(ref);
    });
