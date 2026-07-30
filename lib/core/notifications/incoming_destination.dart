sealed class IncomingDestination {
  const IncomingDestination();

  const factory IncomingDestination.home() = HomeDestination;
  const factory IncomingDestination.publicShare(String shareId) =
      PublicShareDestination;
  const factory IncomingDestination.multiplayerInvitation(String invitationId) =
      MultiplayerInvitationDestination;

  String get deduplicationKey => switch (this) {
    HomeDestination() => 'home',
    PublicShareDestination(:final shareId) => 'share:$shareId',
    MultiplayerInvitationDestination(:final invitationId) =>
      'invitation:$invitationId',
  };
}

final class HomeDestination extends IncomingDestination {
  const HomeDestination();
}

final class PublicShareDestination extends IncomingDestination {
  const PublicShareDestination(this.shareId);
  final String shareId;
}

final class MultiplayerInvitationDestination extends IncomingDestination {
  const MultiplayerInvitationDestination(this.invitationId);
  final String invitationId;
}

abstract final class IncomingDestinationParser {
  static const payloadVersion = '1';
  static final RegExp _identifier = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

  static IncomingDestination? fromMessageData(Map<String, dynamic> data) {
    if (data.length > 8 ||
        data['type'] != 'multiplayer_invitation' ||
        data['version'] != payloadVersion) {
      return null;
    }
    final invitationId = _validatedIdentifier(data['invitationId']);
    return invitationId == null
        ? null
        : IncomingDestination.multiplayerInvitation(invitationId);
  }

  static IncomingDestination? fromUri(Uri uri) {
    if (uri.toString().length > 512 || uri.scheme != 'yunoo') return null;
    if (uri.userInfo.isNotEmpty || uri.hasPort) return null;
    final segments =
        uri.pathSegments.where((value) => value.isNotEmpty).toList();

    if (uri.host == 'home' && segments.isEmpty) {
      return const IncomingDestination.home();
    }
    if (segments.length != 1) return null;
    final identifier = _validatedIdentifier(segments.single);
    if (identifier == null) return null;
    return switch (uri.host) {
      'invite' => IncomingDestination.multiplayerInvitation(identifier),
      'share' => IncomingDestination.publicShare(identifier),
      _ => null,
    };
  }

  static String? _validatedIdentifier(Object? value) {
    if (value is! String || value != value.trim()) return null;
    return _identifier.hasMatch(value) ? value : null;
  }
}
