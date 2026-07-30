import 'package:flutter_test/flutter_test.dart';
import 'package:yunoo/core/notifications/incoming_destination.dart';
import 'package:yunoo/core/notifications/incoming_route_coordinator.dart';
import 'package:yunoo/features/auth/models/app_user.dart';
import 'package:yunoo/features/profile_settings/models/user_settings.dart';

void main() {
  const invitation = IncomingDestination.multiplayerInvitation('invite_1');

  test('invitation waits for authenticated current onboarding state', () {
    expect(isIncomingDestinationReady(invitation, null, null), isFalse);
    expect(
      isIncomingDestinationReady(
        invitation,
        const AppUser(uid: 'guest', isAnonymous: true, isGuestMode: true),
        const UserSettings(onboardingCompletedVersion: 1),
      ),
      isFalse,
    );
    expect(
      isIncomingDestinationReady(
        invitation,
        const AppUser(uid: 'user-a'),
        const UserSettings(onboardingCompletedVersion: 0),
      ),
      isFalse,
    );
    expect(
      isIncomingDestinationReady(
        invitation,
        const AppUser(uid: 'user-a'),
        const UserSettings(
          onboardingCompletedVersion:
              LearningProfileValues.currentOnboardingVersion,
        ),
      ),
      isTrue,
    );
  });

  test(
    'public home/share destinations do not bypass or depend on account gate',
    () {
      expect(
        isIncomingDestinationReady(
          const IncomingDestination.home(),
          null,
          null,
        ),
        isTrue,
      );
      expect(
        isIncomingDestinationReady(
          const IncomingDestination.publicShare('share_1'),
          null,
          null,
        ),
        isTrue,
      );
    },
  );

  test('duplicate notification and link delivery claims one navigation', () {
    final tracker = IncomingDestinationDeduplicator();
    const fromNotification = IncomingDestination.multiplayerInvitation(
      'invite_same',
    );
    const fromLink = IncomingDestination.multiplayerInvitation('invite_same');

    expect(tracker.claim(fromNotification), isTrue);
    expect(tracker.claim(fromLink), isFalse);
  });
}
