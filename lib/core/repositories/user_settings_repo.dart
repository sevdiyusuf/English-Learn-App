import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/di.dart';
import '../../features/auth/models/app_user.dart';
import '../../features/profile_settings/models/user_settings.dart';
import '../utils/browser_storage_stub.dart'
    if (dart.library.html) '../utils/browser_storage_web.dart';
import '../utils/error_logger.dart';

abstract interface class UserSettingsRemoteStore {
  Stream<Map<String, dynamic>?> watch(String uid);

  Future<Map<String, dynamic>?> load(String uid);

  Future<void> save(String uid, Map<String, dynamic> values);
}

class FirestoreUserSettingsStore implements UserSettingsRemoteStore {
  FirestoreUserSettingsStore(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _document(String uid) =>
      _firestore.collection('user_settings').doc(uid);

  @override
  Stream<Map<String, dynamic>?> watch(String uid) =>
      _document(uid).snapshots().map((snapshot) => snapshot.data());

  @override
  Future<Map<String, dynamic>?> load(String uid) async =>
      (await _document(uid).get()).data();

  @override
  Future<void> save(String uid, Map<String, dynamic> values) =>
      _document(uid).set(values, SetOptions(merge: true));
}

abstract interface class UserSettingsLocalStore {
  Future<String?> readString(String key);

  Future<void> writeString(String key, String value);

  Future<bool?> readBool(String key);

  Future<void> writeBool(String key, bool value);
}

class PlatformUserSettingsLocalStore implements UserSettingsLocalStore {
  @override
  Future<String?> readString(String key) async {
    if (kIsWeb) return getItem(key);
    return (await SharedPreferences.getInstance()).getString(key);
  }

  @override
  Future<void> writeString(String key, String value) async {
    if (kIsWeb) {
      setItem(key, value);
      return;
    }
    await (await SharedPreferences.getInstance()).setString(key, value);
  }

  @override
  Future<bool?> readBool(String key) async {
    if (kIsWeb) return getItem(key) == 'true';
    return (await SharedPreferences.getInstance()).getBool(key);
  }

  @override
  Future<void> writeBool(String key, bool value) async {
    if (kIsWeb) {
      setItem(key, value.toString());
      return;
    }
    await (await SharedPreferences.getInstance()).setBool(key, value);
  }
}

/// Repository for managing user settings
/// Handles both Firestore (signed-in users) and local storage (guests)
class UserSettingsRepo {
  UserSettingsRepo(
    FirebaseFirestore firestore, {
    UserSettingsLocalStore? localStore,
  }) : this.withStores(
         remoteStore: FirestoreUserSettingsStore(firestore),
         localStore: localStore ?? PlatformUserSettingsLocalStore(),
       );

  @visibleForTesting
  UserSettingsRepo.withStores({
    required UserSettingsRemoteStore remoteStore,
    required UserSettingsLocalStore localStore,
  }) : _remoteStore = remoteStore,
       _localStore = localStore;

  final UserSettingsRemoteStore _remoteStore;
  final UserSettingsLocalStore _localStore;
  static const String _storageKeyGuestPrefix = 'user_settings_guest_';
  static const String _storageKeyGuestMigratedPrefix =
      'user_settings_guest_migrated_';

  String _guestStorageKey(String uid) => '$_storageKeyGuestPrefix$uid';
  String _guestMigrationKey(String uid) =>
      '$_storageKeyGuestMigratedPrefix$uid';

  /// Watch settings for a user (stream)
  Stream<UserSettings> watchSettings(AppUser user) {
    if (user.isGuestMode || user.isAnonymous) {
      // For guests, use a stream controller that updates on save
      final controller = StreamController<UserSettings>.broadcast();
      _loadGuestSettings(user.uid)
          .then((settings) {
            if (!controller.isClosed) {
              controller.add(settings);
            }
          })
          .catchError((e) {
            if (!controller.isClosed) {
              controller.addError(e);
            }
          });

      // Store controller for updates
      _guestControllers[user.uid] = controller;
      return controller.stream;
    } else {
      // For signed-in users, use Firestore stream
      return _remoteStore.watch(user.uid).map((rawData) {
        if (rawData == null) {
          return const UserSettings();
        }
        try {
          // Convert Firestore Timestamp to DateTime and normalize types
          final data = Map<String, dynamic>.from(rawData);

          // Convert Timestamps or String dates - MUST be done before fromJson
          // Generated code expects String (ISO 8601) for DateTime fields
          final createdAt = _normalizeDateTime(data['createdAt']);
          final updatedAt = _normalizeDateTime(data['updatedAt']);

          // Convert to ISO 8601 String for generated fromJson code
          if (createdAt != null) {
            data['createdAt'] = createdAt.toIso8601String();
          } else {
            data.remove('createdAt');
          }

          if (updatedAt != null) {
            data['updatedAt'] = updatedAt.toIso8601String();
          } else {
            data.remove('updatedAt');
          }

          // Normalize boolean fields (Firestore sometimes returns as String)
          if (data.containsKey('soundEnabled')) {
            data['soundEnabled'] = _normalizeBool(data['soundEnabled']);
          }
          if (data.containsKey('vibrationEnabled')) {
            data['vibrationEnabled'] = _normalizeBool(data['vibrationEnabled']);
          }
          if (data.containsKey('remindersEnabled')) {
            data['remindersEnabled'] = _normalizeBool(data['remindersEnabled']);
          }

          // Normalize int fields
          if (data.containsKey('dailyGoalValue')) {
            data['dailyGoalValue'] = _normalizeInt(data['dailyGoalValue']);
          }

          // Now safe to call fromJson
          return normalizeLearningProfile(UserSettings.fromJson(data));
        } catch (e) {
          ErrorLogger.instance.logError(e, context: 'watchSettings');
          // On permission error, fall back to default settings
          if (e.toString().contains('permission-denied')) {
            return const UserSettings();
          }
          return const UserSettings();
        }
      });
    }
  }

  /// Load settings once (non-streaming)
  Future<UserSettings> loadSettingsOnce(AppUser user) async {
    if (user.isGuestMode || user.isAnonymous) {
      return _loadGuestSettings(user.uid);
    } else {
      try {
        final stored = await _remoteStore.load(user.uid);
        // A newly linked anonymous account may not have a settings document
        // yet. It still needs the one-time UID-scoped guest merge below.
        final data =
            stored == null
                ? <String, dynamic>{}
                : Map<String, dynamic>.from(stored);

        // Convert Timestamps or String dates - MUST be done before fromJson
        // Generated code expects String (ISO 8601) for DateTime fields
        final createdAt = _normalizeDateTime(data['createdAt']);
        final updatedAt = _normalizeDateTime(data['updatedAt']);

        // Convert to ISO 8601 String for generated fromJson code
        if (createdAt != null) {
          data['createdAt'] = createdAt.toIso8601String();
        } else {
          data.remove('createdAt');
        }

        if (updatedAt != null) {
          data['updatedAt'] = updatedAt.toIso8601String();
        } else {
          data.remove('updatedAt');
        }

        // Normalize boolean fields (Firestore sometimes returns as String)
        if (data.containsKey('soundEnabled')) {
          data['soundEnabled'] = _normalizeBool(data['soundEnabled']);
        }
        if (data.containsKey('vibrationEnabled')) {
          data['vibrationEnabled'] = _normalizeBool(data['vibrationEnabled']);
        }
        if (data.containsKey('remindersEnabled')) {
          data['remindersEnabled'] = _normalizeBool(data['remindersEnabled']);
        }

        // Normalize int fields
        if (data.containsKey('dailyGoalValue')) {
          data['dailyGoalValue'] = _normalizeInt(data['dailyGoalValue']);
        }

        // Now safe to call fromJson
        final authenticated = normalizeLearningProfile(
          UserSettings.fromJson(data),
        );
        return await _mergeGuestSettingsIfNeeded(user, authenticated);
      } catch (e) {
        ErrorLogger.instance.logError(e, context: 'loadSettingsOnce');
        // On permission error, fall back to guest settings
        if (e.toString().contains('permission-denied')) {
          return _loadGuestSettings(user.uid);
        }
        return const UserSettings();
      }
    }
  }

  /// Save settings for a user
  Future<void> saveSettings(AppUser user, UserSettings settings) async {
    final now = DateTime.now();
    // Note: copyWith will be available after build_runner
    final updatedSettings = settings.copyWith(
      updatedAt: now,
      createdAt: settings.createdAt ?? now,
    );

    if (user.isGuestMode || user.isAnonymous) {
      // Save to local storage
      try {
        final json = updatedSettings.toJson();
        for (final field in const ['createdAt', 'updatedAt']) {
          final value = json[field];
          if (value is Timestamp) {
            json[field] = value.toDate().toUtc().toIso8601String();
          } else if (value is DateTime) {
            json[field] = value.toUtc().toIso8601String();
          }
        }
        final jsonString = jsonEncode(json);
        await _writeGuestJson(user.uid, jsonString);
        // Update stream if exists
        _guestControllers[user.uid]?.add(updatedSettings);
      } catch (e) {
        ErrorLogger.instance.logError(e, context: 'saveSettings (guest)');
        rethrow;
      }
    } else {
      // Save to Firestore
      try {
        final json = updatedSettings.toJson();
        // Convert DateTime (which may be String from toJson) to Timestamp for Firestore
        if (json['createdAt'] != null) {
          DateTime? dateTime;
          if (json['createdAt'] is DateTime) {
            dateTime = json['createdAt'] as DateTime;
          } else if (json['createdAt'] is String) {
            dateTime = DateTime.parse(json['createdAt'] as String);
          } else if (json['createdAt'] is Timestamp) {
            // Already a Timestamp, use as is
            dateTime = (json['createdAt'] as Timestamp).toDate();
          }
          if (dateTime != null) {
            json['createdAt'] = Timestamp.fromDate(dateTime.toUtc());
          }
        }
        if (json['updatedAt'] != null) {
          DateTime? dateTime;
          if (json['updatedAt'] is DateTime) {
            dateTime = json['updatedAt'] as DateTime;
          } else if (json['updatedAt'] is String) {
            dateTime = DateTime.parse(json['updatedAt'] as String);
          } else if (json['updatedAt'] is Timestamp) {
            // Already a Timestamp, use as is
            dateTime = (json['updatedAt'] as Timestamp).toDate();
          }
          if (dateTime != null) {
            json['updatedAt'] = Timestamp.fromDate(dateTime.toUtc());
          }
        }

        await _remoteStore.save(user.uid, json);
      } catch (e) {
        ErrorLogger.instance.logError(e, context: 'saveSettings (firestore)');
        rethrow;
      }
    }
  }

  /// Reset local settings (for guests)
  Future<void> resetLocalSettings() async {
    try {
      // Guest settings are intentionally scoped to a Firebase anonymous UID.
      // There is no global settings key to expose across guest sessions.
      // Clear all guest controllers
      for (final controller in _guestControllers.values) {
        controller.add(const UserSettings());
      }
    } catch (e) {
      ErrorLogger.instance.logError(e, context: 'resetLocalSettings');
    }
  }

  // Private helpers
  final Map<String, StreamController<UserSettings>> _guestControllers = {};

  /// Normalize boolean values from Firestore (handles String, bool, int)
  bool _normalizeBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value != 0;
    return false;
  }

  /// Normalize int values from Firestore (handles String, int, double)
  int _normalizeInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  /// Normalize DateTime values from Firestore (handles Timestamp, String, DateTime)
  /// Returns null if value cannot be converted to DateTime
  DateTime? _normalizeDateTime(dynamic value) {
    if (value == null) return null;

    // Already a DateTime
    if (value is DateTime) return value;

    // Firestore Timestamp
    if (value is Timestamp) {
      try {
        return value.toDate();
      } catch (e) {
        ErrorLogger.instance.logError(
          e,
          context: '_normalizeDateTime (Timestamp)',
        );
        return null;
      }
    }

    // String - try multiple formats
    if (value is String) {
      if (value.isEmpty) return null;

      // Try ISO 8601 format first (most common)
      try {
        return DateTime.parse(value);
      } catch (_) {
        // If ISO parsing fails, try milliseconds since epoch
        final milliseconds = int.tryParse(value);
        if (milliseconds != null && milliseconds > 0) {
          try {
            return DateTime.fromMillisecondsSinceEpoch(milliseconds);
          } catch (e) {
            ErrorLogger.instance.logError(
              e,
              context: '_normalizeDateTime (String milliseconds)',
            );
            return null;
          }
        }

        // Last resort: try to extract date from string
        ErrorLogger.instance.logError(
          StateError('Cannot parse DateTime string: $value'),
          context: '_normalizeDateTime (String)',
        );
        return null;
      }
    }

    // Handle Firestore Timestamp map format (for web/localStorage)
    if (value is Map) {
      try {
        // Try _seconds format first
        final seconds = value['_seconds'];
        if (seconds != null) {
          final secondsInt =
              seconds is int
                  ? seconds
                  : (seconds is String ? int.tryParse(seconds) : null);
          if (secondsInt != null) {
            final nanoseconds = value['_nanoseconds'] as int? ?? 0;
            return DateTime.fromMillisecondsSinceEpoch(
              secondsInt * 1000 + (nanoseconds ~/ 1000000),
            );
          }
        }

        // Try direct timestamp value
        final timestamp = value['timestamp'];
        if (timestamp != null) {
          return _normalizeDateTime(timestamp);
        }
      } catch (e) {
        ErrorLogger.instance.logError(e, context: '_normalizeDateTime (Map)');
        return null;
      }
    }

    // Unknown type - log and return null
    ErrorLogger.instance.logError(
      StateError('Unknown DateTime type: ${value.runtimeType}'),
      context: '_normalizeDateTime',
    );
    return null;
  }

  @visibleForTesting
  static UserSettings normalizeLearningProfile(UserSettings settings) {
    final validLevel =
        settings.cefrLevel != null &&
        LearningProfileValues.cefrLevels.contains(settings.cefrLevel);
    final validGoal =
        settings.learningGoal != null &&
        LearningProfileValues.learningGoals.contains(settings.learningGoal);
    final validStep = LearningProfileValues.isValidStep(
      settings.onboardingStep,
    );
    return settings.copyWith(
      onboardingCompletedVersion:
          settings.onboardingCompletedVersion < 0
              ? 0
              : settings.onboardingCompletedVersion,
      onboardingStep:
          validStep
              ? settings.onboardingStep
              : LearningProfileValues.onboardingIntro,
      cefrLevel: validLevel ? settings.cefrLevel : null,
      learningGoal: validGoal ? settings.learningGoal : null,
    );
  }

  Future<UserSettings> _loadGuestSettings(String uid) async {
    try {
      final jsonString = await _localStore.readString(_guestStorageKey(uid));
      if (jsonString == null || jsonString.isEmpty) {
        return const UserSettings();
      }
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      if (kIsWeb) {
        // Convert Timestamps or String dates - MUST be done before fromJson
        // Generated code expects String (ISO 8601) for DateTime fields
        final createdAt = _normalizeDateTime(json['createdAt']);
        final updatedAt = _normalizeDateTime(json['updatedAt']);

        // Convert to ISO 8601 String for generated fromJson code
        if (createdAt != null) {
          json['createdAt'] = createdAt.toIso8601String();
        } else {
          json.remove('createdAt');
        }

        if (updatedAt != null) {
          json['updatedAt'] = updatedAt.toIso8601String();
        } else {
          json.remove('updatedAt');
        }

        // Normalize boolean fields
        if (json.containsKey('soundEnabled')) {
          json['soundEnabled'] = _normalizeBool(json['soundEnabled']);
        }
        if (json.containsKey('vibrationEnabled')) {
          json['vibrationEnabled'] = _normalizeBool(json['vibrationEnabled']);
        }
        if (json.containsKey('remindersEnabled')) {
          json['remindersEnabled'] = _normalizeBool(json['remindersEnabled']);
        }

        // Normalize int fields
        if (json.containsKey('dailyGoalValue')) {
          json['dailyGoalValue'] = _normalizeInt(json['dailyGoalValue']);
        }

        // Now safe to call fromJson
        return normalizeLearningProfile(UserSettings.fromJson(json));
      } else {
        return normalizeLearningProfile(UserSettings.fromJson(json));
      }
    } catch (e) {
      ErrorLogger.instance.logError(e, context: '_loadGuestSettings');
      return const UserSettings();
    }
  }

  Future<void> _writeGuestJson(String uid, String jsonString) async {
    await _localStore.writeString(_guestStorageKey(uid), jsonString);
  }

  /// Merges the anonymous session identified by the same Firebase UID after it
  /// is linked to a permanent account. It is safe to call repeatedly.
  Future<UserSettings> _mergeGuestSettingsIfNeeded(
    AppUser user,
    UserSettings authenticated,
  ) async {
    if (user.isAnonymous || user.isGuestMode) return authenticated;
    final migrated = await _isGuestMigrated(user.uid);
    if (migrated) return authenticated;
    final guest = await _loadGuestSettings(user.uid);
    final merged = mergeLearningProfiles(authenticated, guest);
    if (merged == authenticated) {
      await _markGuestMigrated(user.uid);
      return authenticated;
    }
    await saveSettings(user, merged);
    await _markGuestMigrated(user.uid);
    return merged;
  }

  @visibleForTesting
  static UserSettings mergeLearningProfiles(
    UserSettings authenticated,
    UserSettings guest,
  ) {
    final authenticatedComplete =
        authenticated.onboardingCompletedVersion >=
        LearningProfileValues.currentOnboardingVersion;
    final guestHasProgress =
        guest.onboardingStep != LearningProfileValues.onboardingIntro;
    final completedVersion =
        authenticated.onboardingCompletedVersion >=
                guest.onboardingCompletedVersion
            ? authenticated.onboardingCompletedVersion
            : guest.onboardingCompletedVersion;
    return authenticated.copyWith(
      cefrLevel: authenticated.cefrLevel ?? guest.cefrLevel,
      learningGoal: authenticated.learningGoal ?? guest.learningGoal,
      onboardingStep:
          authenticatedComplete
              ? authenticated.onboardingStep
              : (authenticated.onboardingStep ==
                          LearningProfileValues.onboardingIntro &&
                      guestHasProgress
                  ? guest.onboardingStep
                  : authenticated.onboardingStep),
      onboardingCompletedVersion: completedVersion,
    );
  }

  Future<bool> _isGuestMigrated(String uid) async {
    return await _localStore.readBool(_guestMigrationKey(uid)) ?? false;
  }

  Future<void> _markGuestMigrated(String uid) async {
    await _localStore.writeBool(_guestMigrationKey(uid), true);
  }

  void dispose() {
    for (final controller in _guestControllers.values) {
      controller.close();
    }
    _guestControllers.clear();
  }
}

/// Provider for UserSettingsRepo
final userSettingsRepoProvider = Provider<UserSettingsRepo>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return UserSettingsRepo(firestore);
});
