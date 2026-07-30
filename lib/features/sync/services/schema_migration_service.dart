import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../../../core/errors/app_failure.dart';
import '../models/local_schema_metadata.dart';
import '../../word_match/models/word_pair.dart';
import '../../word_match/models/word_set.dart';

typedef MigrationStepHandler = Future<void> Function(Isar isar);

/// Service responsible for managing local Isar schema versioning and data migrations.
class SchemaMigrationService {
  SchemaMigrationService({
    this.targetSchemaVersion = kCurrentLocalSchemaVersion,
    this.customStepHandlers,
  });

  /// Current target local schema version
  static const int kCurrentLocalSchemaVersion = 2;

  final int targetSchemaVersion;
  final Map<int, MigrationStepHandler>? customStepHandlers;

  /// Runs local schema migrations on the provided [isar] instance.
  /// Sequential, idempotent, and non-destructive.
  Future<void> runMigrations(Isar isar) async {
    try {
      final appliedVersions = await isar.localSchemaMetadatas.where().findAll();

      final currentVersionRecord =
          appliedVersions.isNotEmpty
              ? appliedVersions
                  .where((m) => m.isSuccessful)
                  .fold<int>(0, (max, m) => m.version > max ? m.version : max)
              : 0;

      if (currentVersionRecord >= targetSchemaVersion) {
        debugPrint(
          'Local schema migration: Database already up to date (Version $currentVersionRecord)',
        );
        return;
      }

      // Check if fresh install or upgrade
      final isFreshInstall =
          currentVersionRecord == 0 && await _isDatabaseFresh(isar);

      if (isFreshInstall) {
        debugPrint(
          'Local schema migration: Fresh install detected. Setting schema version $targetSchemaVersion',
        );
        await isar.writeTxn(() async {
          final metadata =
              LocalSchemaMetadata()
                ..version = targetSchemaVersion
                ..appliedAt = DateTime.now()
                ..isSuccessful = true
                ..description =
                    'Initial schema version setup for fresh install';
          await isar.localSchemaMetadatas.put(metadata);
        });
        return;
      }

      // Upgrade steps loop
      for (
        var version = currentVersionRecord + 1;
        version <= targetSchemaVersion;
        version++
      ) {
        debugPrint('Local schema migration: Running step for version $version');
        await _applyMigrationStep(isar, version);
      }
    } catch (e, stack) {
      if (e is AppFailure) rethrow;
      debugPrint('Error during local schema migration: $e\n$stack');
      throw AppFailure.database(
        message: 'Yerel şema migrasyonu sırasında hata oluştu: $e',
        originalError: e,
      );
    }
  }

  Future<bool> _isDatabaseFresh(Isar isar) async {
    try {
      final wordSetsCount = await isar.wordSets.count();
      final wordPairsCount = await isar.wordPairs.count();
      return wordSetsCount == 0 && wordPairsCount == 0;
    } catch (_) {
      return false;
    }
  }

  Future<void> _applyMigrationStep(Isar isar, int targetVersion) async {
    if (customStepHandlers != null &&
        customStepHandlers!.containsKey(targetVersion)) {
      await customStepHandlers![targetVersion]!(isar);
      await isar.writeTxn(() async {
        final metadata =
            LocalSchemaMetadata()
              ..version = targetVersion
              ..appliedAt = DateTime.now()
              ..isSuccessful = true
              ..description = 'Custom migration step $targetVersion';
        await isar.localSchemaMetadatas.put(metadata);
      });
      return;
    }

    // Only write version metadata AFTER the step logic completes successfully
    if (targetVersion == 1) {
      // Step 1: Ensure outbox and metadata collections are active and any initial backfill is done
      await isar.writeTxn(() async {
        final metadata =
            LocalSchemaMetadata()
              ..version = 1
              ..appliedAt = DateTime.now()
              ..isSuccessful = true
              ..description =
                  'Schema version 1: Initial Outbox and Sync metadata schema';
        await isar.localSchemaMetadatas.put(metadata);
      });
    } else if (targetVersion == 2) {
      // Step 2: Initialize SyncCheckpoint schema for incremental pull tracking
      await isar.writeTxn(() async {
        final metadata =
            LocalSchemaMetadata()
              ..version = 2
              ..appliedAt = DateTime.now()
              ..isSuccessful = true
              ..description =
                  'Schema version 2: SyncCheckpoint collection for paginated pull tracking';
        await isar.localSchemaMetadatas.put(metadata);
      });
    }
  }
}
