import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yunoo/core/repositories/user_settings_repo.dart';
import 'package:yunoo/features/auth/models/app_user.dart';
import 'package:yunoo/features/profile_settings/models/user_settings.dart';

class _MemoryLocalStore implements UserSettingsLocalStore {
  final Map<String, Object> values = {};

  @override
  Future<bool?> readBool(String key) async => values[key] as bool?;

  @override
  Future<String?> readString(String key) async => values[key] as String?;

  @override
  Future<void> writeBool(String key, bool value) async {
    values[key] = value;
  }

  @override
  Future<void> writeString(String key, String value) async {
    values[key] = value;
  }
}

class _MemoryRemoteStore implements UserSettingsRemoteStore {
  final Map<String, Map<String, dynamic>> values = {};
  final Map<String, StreamController<Map<String, dynamic>?>> _controllers = {};
  int saveCount = 0;
  bool failNextSave = false;

  @override
  Future<Map<String, dynamic>?> load(String uid) async {
    final value = values[uid];
    return value == null ? null : Map<String, dynamic>.from(value);
  }

  @override
  Future<void> save(String uid, Map<String, dynamic> settings) async {
    saveCount++;
    if (failNextSave) {
      failNextSave = false;
      throw StateError('simulated write failure');
    }
    values[uid] = {...?values[uid], ...settings};
    _controllers[uid]?.add(Map<String, dynamic>.from(values[uid]!));
  }

  @override
  Stream<Map<String, dynamic>?> watch(String uid) {
    final controller = _controllers.putIfAbsent(
      uid,
      StreamController<Map<String, dynamic>?>.broadcast,
    );
    return controller.stream;
  }

  Future<void> dispose() async {
    for (final controller in _controllers.values) {
      await controller.close();
    }
  }
}

const _anonymousA = AppUser(
  uid: 'anonymous-a',
  isAnonymous: true,
  isGuestMode: true,
);
const _anonymousB = AppUser(
  uid: 'anonymous-b',
  isAnonymous: true,
  isGuestMode: true,
);
const _authenticatedA = AppUser(uid: 'account-a');
const _authenticatedB = AppUser(uid: 'account-b');

UserSettings _profile({
  String? level,
  String? goal,
  String step = LearningProfileValues.onboardingIntro,
  int version = 0,
}) => UserSettings(
  cefrLevel: level,
  learningGoal: goal,
  onboardingStep: step,
  onboardingCompletedVersion: version,
);

void main() {
  late _MemoryLocalStore local;
  late _MemoryRemoteStore remote;
  late UserSettingsRepo repository;

  setUp(() {
    local = _MemoryLocalStore();
    remote = _MemoryRemoteStore();
    repository = UserSettingsRepo.withStores(
      remoteStore: remote,
      localStore: local,
    );
  });

  tearDown(() async {
    repository.dispose();
    await remote.dispose();
  });

  group('UID isolation', () {
    test(
      'anonymous UIDs persist independently across repository recreation',
      () async {
        await repository.saveSettings(
          _anonymousA,
          _profile(level: 'A2', goal: 'word_practice'),
        );
        await repository.saveSettings(
          _anonymousB,
          _profile(level: 'C1', goal: 'multiplayer'),
        );

        repository.dispose();
        repository = UserSettingsRepo.withStores(
          remoteStore: remote,
          localStore: local,
        );

        expect(
          (await repository.loadSettingsOnce(_anonymousA)).cefrLevel,
          'A2',
        );
        expect(
          (await repository.loadSettingsOnce(_anonymousB)).learningGoal,
          'multiplayer',
        );
      },
    );

    test(
      'authenticated account switching and sign-out do not leak values',
      () async {
        await repository.saveSettings(
          _authenticatedA,
          _profile(level: 'B1', goal: 'grammar_practice'),
        );
        await repository.saveSettings(
          _authenticatedB,
          _profile(level: 'C2', goal: 'mini_games'),
        );

        expect(
          (await repository.loadSettingsOnce(_authenticatedA)).learningGoal,
          'grammar_practice',
        );
        expect(
          (await repository.loadSettingsOnce(_anonymousA)).cefrLevel,
          isNull,
        );
        expect(
          (await repository.loadSettingsOnce(_authenticatedB)).learningGoal,
          'mini_games',
        );
      },
    );

    test('mobile anonymous settings survive repository recreation', () async {
      SharedPreferences.setMockInitialValues({});
      repository.dispose();
      repository = UserSettingsRepo.withStores(
        remoteStore: remote,
        localStore: PlatformUserSettingsLocalStore(),
      );
      await repository.saveSettings(
        _anonymousA,
        _profile(level: 'A2', goal: 'word_practice'),
      );

      repository.dispose();
      repository = UserSettingsRepo.withStores(
        remoteStore: remote,
        localStore: PlatformUserSettingsLocalStore(),
      );

      final restored = await repository.loadSettingsOnce(_anonymousA);
      expect(restored.cefrLevel, 'A2');
      expect(restored.learningGoal, 'word_practice');
    });
  });

  group('anonymous-to-authenticated migration', () {
    test(
      'authenticated explicit values win and guest fills only defaults',
      () async {
        await repository.saveSettings(
          _anonymousA,
          _profile(
            level: 'A2',
            goal: 'multiplayer',
            step: LearningProfileValues.onboardingReview,
            version: 1,
          ),
        );
        remote.values[_anonymousA.uid] =
            _profile(
              level: 'B2',
              step: LearningProfileValues.onboardingLevel,
            ).toJson();

        final merged = await repository.loadSettingsOnce(
          const AppUser(uid: 'anonymous-a'),
        );

        expect(merged.cefrLevel, 'B2');
        expect(merged.learningGoal, 'multiplayer');
        expect(merged.onboardingCompletedVersion, 1);
        expect(merged.onboardingStep, LearningProfileValues.onboardingLevel);
      },
    );

    test(
      'guest defaults never replace explicit authenticated choices',
      () async {
        await repository.saveSettings(_anonymousA, const UserSettings());
        remote.values[_anonymousA.uid] =
            _profile(
              level: 'C1',
              goal: 'grammar_practice',
              step: LearningProfileValues.onboardingGoal,
            ).toJson();

        final merged = await repository.loadSettingsOnce(
          const AppUser(uid: 'anonymous-a'),
        );

        expect(merged.cefrLevel, 'C1');
        expect(merged.learningGoal, 'grammar_practice');
        expect(merged.onboardingStep, LearningProfileValues.onboardingGoal);
      },
    );

    test('completed authenticated onboarding is never downgraded', () {
      final merged = UserSettingsRepo.mergeLearningProfiles(
        _profile(
          level: 'B1',
          goal: 'word_practice',
          step: LearningProfileValues.onboardingReview,
          version: 2,
        ),
        _profile(
          level: 'C2',
          goal: 'multiplayer',
          step: LearningProfileValues.onboardingIntro,
        ),
      );

      expect(merged.onboardingCompletedVersion, 2);
      expect(merged.onboardingStep, LearningProfileValues.onboardingReview);
      expect(merged.cefrLevel, 'B1');
      expect(merged.learningGoal, 'word_practice');
    });

    test('successful merge is idempotent', () async {
      await repository.saveSettings(
        _anonymousA,
        _profile(level: 'A1', goal: 'mini_games'),
      );

      final linked = const AppUser(uid: 'anonymous-a');
      final first = await repository.loadSettingsOnce(linked);
      final savesAfterFirstMerge = remote.saveCount;
      final second = await repository.loadSettingsOnce(linked);

      expect(first.cefrLevel, 'A1');
      expect(second.cefrLevel, first.cefrLevel);
      expect(second.learningGoal, first.learningGoal);
      expect(
        second.onboardingCompletedVersion,
        first.onboardingCompletedVersion,
      );
      expect(remote.saveCount, savesAfterFirstMerge);
      expect(local.values['user_settings_guest_migrated_anonymous-a'], isTrue);
    });

    test(
      'failed merge stays retryable and never writes migration marker',
      () async {
        await repository.saveSettings(
          _anonymousA,
          _profile(level: 'A1', goal: 'word_practice'),
        );
        remote.failNextSave = true;
        const linked = AppUser(uid: 'anonymous-a');

        final failed = await repository.loadSettingsOnce(linked);
        expect(failed, const UserSettings());
        expect(
          local.values['user_settings_guest_migrated_anonymous-a'],
          isNot(true),
        );

        final retried = await repository.loadSettingsOnce(linked);
        expect(retried.cefrLevel, 'A1');
        expect(retried.learningGoal, 'word_practice');
        expect(
          local.values['user_settings_guest_migrated_anonymous-a'],
          isTrue,
        );
      },
    );

    test(
      'linked anonymous UID without remote document follows merge path',
      () async {
        await repository.saveSettings(
          _anonymousA,
          _profile(
            level: 'B2',
            goal: 'multiplayer',
            step: LearningProfileValues.onboardingReview,
          ),
        );

        final loaded = await repository.loadSettingsOnce(
          const AppUser(uid: 'anonymous-a'),
        );

        expect(loaded.cefrLevel, 'B2');
        expect(loaded.learningGoal, 'multiplayer');
        expect(remote.values, contains(_anonymousA.uid));
      },
    );
  });
}
