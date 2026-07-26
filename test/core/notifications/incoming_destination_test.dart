import 'package:flutter_test/flutter_test.dart';
import 'package:yunoo/core/notifications/incoming_destination.dart';

void main() {
  group('FCM and deep-link destination parser', () {
    test('both sources resolve to the same invitation destination', () {
      final fromMessage = IncomingDestinationParser.fromMessageData({
        'type': 'multiplayer_invitation',
        'version': '1',
        'invitationId': 'invite_ABC-123',
      });
      final fromLink = IncomingDestinationParser.fromUri(
        Uri.parse('yunoo://invite/invite_ABC-123?ignored=true'),
      );

      expect(fromMessage, isA<MultiplayerInvitationDestination>());
      expect(fromLink, isA<MultiplayerInvitationDestination>());
      expect(fromMessage!.deduplicationKey, fromLink!.deduplicationKey);
    });

    test('supports only allowlisted home and public share destinations', () {
      expect(
        IncomingDestinationParser.fromUri(Uri.parse('yunoo://home')),
        isA<HomeDestination>(),
      );
      expect(
        IncomingDestinationParser.fromUri(
          Uri.parse('yunoo://share/public_set_1'),
        ),
        isA<PublicShareDestination>(),
      );
    });

    test('rejects unsupported versions, types, schemes, hosts and routes', () {
      expect(
        IncomingDestinationParser.fromMessageData({
          'type': 'multiplayer_invitation',
          'version': '2',
          'invitationId': 'invite_1',
        }),
        isNull,
      );
      expect(
        IncomingDestinationParser.fromMessageData({
          'type': '/room/admin',
          'version': '1',
          'invitationId': 'invite_1',
        }),
        isNull,
      );
      expect(
        IncomingDestinationParser.fromUri(
          Uri.parse('https://example.com/invite/invite_1'),
        ),
        isNull,
      );
      expect(
        IncomingDestinationParser.fromUri(Uri.parse('yunoo://arbitrary/route')),
        isNull,
      );
    });

    test('rejects missing, malformed and oversized identifiers', () {
      for (final value in <Object?>[
        null,
        '',
        ' leading',
        'contains/slash',
        List.filled(129, 'x').join(),
      ]) {
        expect(
          IncomingDestinationParser.fromMessageData({
            'type': 'multiplayer_invitation',
            'version': '1',
            'invitationId': value,
          }),
          isNull,
        );
      }
      expect(
        IncomingDestinationParser.fromUri(Uri.parse('yunoo://invite')),
        isNull,
      );
    });

    test('unknown message fields cannot expand the allowlist', () {
      expect(
        IncomingDestinationParser.fromMessageData({
          'type': 'multiplayer_invitation',
          'version': '1',
          'invitationId': 'invite_1',
          'route': '/admin',
          'role': 'host',
          'ownerUid': 'attacker',
          'a': '1',
          'b': '2',
          'c': '3',
          'd': '4',
          'e': '5',
        }),
        isNull,
      );
    });
  });
}
