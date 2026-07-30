import 'package:flutter_test/flutter_test.dart';
import 'package:yunoo/core/notifications/incoming_destination.dart';
import 'package:yunoo/features/irregular_verbs/models/irregular_verb.dart';
import 'package:yunoo/features/user_stats/models/user_stats.dart';

void main() {
  group('Domain Models & Utility Contracts', () {
    test('IrregularVerb pattern and patternDescription computation', () {
      const aaa = IrregularVerb(
        v1: 'cut',
        v2: 'cut',
        v3: 'cut',
        meaningTr: 'kesmek',
      );
      expect(aaa.pattern, 'AAA');
      expect(aaa.patternDescription, 'Tüm formlar aynı');

      const abb = IrregularVerb(
        v1: 'buy',
        v2: 'bought',
        v3: 'bought',
        meaningTr: 'satın almak',
      );
      expect(abb.pattern, 'ABB');
      expect(abb.patternDescription, 'V2 ve V3 aynı');

      const aba = IrregularVerb(
        v1: 'run',
        v2: 'ran',
        v3: 'run',
        meaningTr: 'koşmak',
      );
      expect(aba.pattern, 'ABA');
      expect(aba.patternDescription, 'V1 ve V3 aynı');

      const abc = IrregularVerb(
        v1: 'go',
        v2: 'went',
        v3: 'gone',
        meaningTr: 'gitmek',
      );
      expect(abc.pattern, 'ABC');
      expect(abc.patternDescription, 'Tüm formlar farklı');
    });

    test('UserStats serialization and immutability defaults', () {
      const defaultStats = UserStats();
      expect(defaultStats.totalLearnedWords, 0);
      expect(defaultStats.totalSessions, 0);
      expect(defaultStats.totalScore, 0);

      const customStats = UserStats(
        totalLearnedWords: 150,
        totalSessions: 5,
        totalScore: 450,
      );

      final json = customStats.toJson();
      expect(json['totalLearnedWords'], 150);
      expect(json['totalSessions'], 5);
      expect(json['totalScore'], 450);

      final restored = UserStats.fromJson(json);
      expect(restored.totalLearnedWords, 150);
      expect(restored.totalSessions, 5);
      expect(restored.totalScore, 450);
    });

    test('IncomingDestination parsing for deep link data', () {
      const validInvitationData = {
        'type': 'multiplayer_invitation',
        'version': '1',
        'invitationId': 'inv-12345678',
      };
      final dest = IncomingDestinationParser.fromMessageData(
        validInvitationData,
      );
      expect(dest, isNotNull);
      expect(dest?.deduplicationKey, 'invitation:inv-12345678');

      const invalidData = {'type': 'unknown'};
      final invalidDest = IncomingDestinationParser.fromMessageData(
        invalidData,
      );
      expect(invalidDest, isNull);
    });
  });
}
