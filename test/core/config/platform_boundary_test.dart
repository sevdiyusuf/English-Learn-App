import 'package:flutter_test/flutter_test.dart';
import 'package:yunoo/app/isar_initializer_stub.dart' as initializer_stub;
import 'package:yunoo/features/sync/services/sync_coordinator.dart';
import 'package:yunoo/features/sync/sync_providers_web.dart' as sync_web;
import 'package:yunoo/features/word_match/data/word_match_repo_web.dart';
import 'package:yunoo/features/word_match/models/word_pair.dart';
import 'package:yunoo/features/word_match/models/word_set.dart';

void main() {
  group('Web Platform Boundary Tests', () {
    test('1. initIsarStoreOnStartup stub completes without throwing', () async {
      await expectLater(initializer_stub.initIsarStoreOnStartup(), completes);
    });

    test('2. WordSet and WordPair models instantiate cleanly', () {
      final set =
          WordSet()
            ..id = 1
            ..name = 'Test Set'
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();

      final pair =
          WordPair()
            ..id = 10
            ..setId = 1
            ..english = 'apple'
            ..turkish = 'elma';

      expect(set.name, equals('Test Set'));
      expect(pair.english, equals('apple'));
      expect(pair.turkish, equals('elma'));
    });

    test(
      '3. WebSyncCoordinator implements SyncCoordinator interface as non-blocking stub',
      () async {
        final coordinator = sync_web.WebSyncCoordinator();

        expect(coordinator.status, equals(SyncStatus.upToDate));
        await expectLater(coordinator.onUserLogout(), completes);
        await expectLater(coordinator.triggerSync(), completes);
      },
    );

    test('4. WordMatchRepoWeb operates without Isar database instance', () {
      final repo = WordMatchRepoWeb(activeOwnerUid: 'test_web_user');
      expect(repo.activeOwnerUid, equals('test_web_user'));
    });
  });
}
