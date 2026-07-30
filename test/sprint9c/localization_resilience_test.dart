import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'English and Turkish ARB keys and placeholder metadata stay in parity',
    () {
      final en = _readArb('lib/l10n/app_en.arb');
      final tr = _readArb('lib/l10n/app_tr.arb');
      final enKeys = en.keys.where((key) => !key.startsWith('@@')).toSet();
      final trKeys = tr.keys.where((key) => !key.startsWith('@@')).toSet();

      expect(trKeys.difference(enKeys), isEmpty);
      expect(enKeys.difference(trKeys), isEmpty);
      for (final key in enKeys.where((key) => key.startsWith('@'))) {
        expect(
          tr[key],
          en[key],
          reason: 'Placeholder metadata differs for $key',
        );
      }
    },
  );

  test('Sprint 9C Turkish source contains localized accessibility labels', () {
    final tr = _readArb('lib/l10n/app_tr.arb');
    expect(tr['navigationHome'], 'Ana sayfa');
    expect(tr['yourTurn'], 'Sıra sende');
    expect(tr['closeAction'], 'Kapat');
    expect(tr['emailAddress'], 'E-posta adresi');
    expect(tr['learningGoalGrammar'], isNot('grammar_practice'));
  });
}

Map<String, Object?> _readArb(String path) {
  return jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
}
