import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../features/auth/models/app_user.dart';
import '../../features/user_stats/models/user_stats.dart';
import '../utils/error_logger.dart';

/// Repository for managing user statistics
class UserStatsRepo {
  UserStatsRepo(this._firestore);

  final FirebaseFirestore _firestore;

  /// Watch user stats (stream)
  Stream<UserStats> watchUserStats(AppUser user) {
    if (user.isGuestMode || user.isAnonymous) {
      // For guests, return default stats (no persistence)
      return Stream.value(const UserStats());
    }

    return _firestore.collection('user_stats').doc(user.uid).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists || snapshot.data() == null) {
        return const UserStats();
      }
      try {
        // Convert Firestore Timestamp to DateTime and normalize types
        final rawData = snapshot.data()!;
        final data = Map<String, dynamic>.from(rawData);

        // Normalize integer fields
        data['totalLearnedWords'] = _normalizeInt(
          data['totalLearnedWords'] ?? 0,
        );
        data['totalSessions'] = _normalizeInt(data['totalSessions'] ?? 0);
        data['totalScore'] = _normalizeInt(data['totalScore'] ?? 0);
        data['currentStreakDays'] = _normalizeInt(
          data['currentStreakDays'] ?? 0,
        );
        data['bestStreakDays'] = _normalizeInt(data['bestStreakDays'] ?? 0);

        // Convert Timestamp to ISO 8601 String for generated fromJson code
        // TimestampConverter can handle multiple types, but String is safest
        if (data['lastActivityDate'] != null) {
          DateTime? dateTime;
          if (data['lastActivityDate'] is Timestamp) {
            dateTime = (data['lastActivityDate'] as Timestamp).toDate();
          } else if (data['lastActivityDate'] is DateTime) {
            dateTime = data['lastActivityDate'] as DateTime;
          } else if (data['lastActivityDate'] is String) {
            // Already a String, keep it
            dateTime = DateTime.tryParse(data['lastActivityDate'] as String);
          }
          if (dateTime != null) {
            data['lastActivityDate'] = dateTime.toIso8601String();
          } else {
            data.remove('lastActivityDate');
          }
        }

        // Normalize modeStats map - normalize integers, let generated code parse
        if (data['modeStats'] != null && data['modeStats'] is Map) {
          final rawModeStats = data['modeStats'] as Map;
          final normalizedModeStats = <String, dynamic>{};
          for (final entry in rawModeStats.entries) {
            if (entry.value is Map) {
              final modeData = Map<String, dynamic>.from(entry.value as Map);
              // Normalize integer fields - generated code will parse this
              normalizedModeStats[entry.key.toString()] = {
                'sessions': _normalizeInt(modeData['sessions'] ?? 0),
                'correctAnswers': _normalizeInt(
                  modeData['correctAnswers'] ?? 0,
                ),
                'wrongAnswers': _normalizeInt(modeData['wrongAnswers'] ?? 0),
                'totalQuestions': _normalizeInt(
                  modeData['totalQuestions'] ?? 0,
                ),
                'totalMinutes': _normalizeInt(modeData['totalMinutes'] ?? 0),
              };
            }
          }
          data['modeStats'] = normalizedModeStats;
        }

        // Convert last30Days list - date must be ISO 8601 String for generated code
        if (data['last30Days'] != null && data['last30Days'] is List) {
          final daysList =
              (data['last30Days'] as List).map((day) {
                if (day is Map) {
                  final dayMap = Map<String, dynamic>.from(day);
                  // Convert date to ISO 8601 String
                  if (dayMap['date'] != null) {
                    DateTime? dateTime;
                    if (dayMap['date'] is Timestamp) {
                      dateTime = (dayMap['date'] as Timestamp).toDate();
                    } else if (dayMap['date'] is DateTime) {
                      dateTime = dayMap['date'] as DateTime;
                    } else if (dayMap['date'] is String) {
                      // Already a String, try to parse to validate
                      dateTime = DateTime.tryParse(dayMap['date'] as String);
                    }
                    if (dateTime != null) {
                      dayMap['date'] = dateTime.toIso8601String();
                    } else {
                      // Invalid date, remove this entry or use current date
                      dayMap['date'] = DateTime.now().toIso8601String();
                    }
                  }
                  dayMap['practicedWords'] = _normalizeInt(
                    dayMap['practicedWords'] ?? 0,
                  );
                  dayMap['minutes'] = _normalizeInt(dayMap['minutes'] ?? 0);
                  return dayMap;
                }
                return day;
              }).toList();
          data['last30Days'] = daysList;
        }

        // Normalize hardestWords list
        if (data['hardestWords'] != null && data['hardestWords'] is List) {
          data['hardestWords'] =
              (data['hardestWords'] as List).whereType<String>().toList();
        } else {
          // If hardestWords is not in document, use empty list
          // (will be populated by getHardestWords when needed)
          data['hardestWords'] = <String>[];
        }

        return UserStats.fromJson(data);
      } catch (e) {
        ErrorLogger.instance.logError(e, context: 'watchUserStats');
        return const UserStats();
      }
    });
  }

  /// Get user stats once (non-streaming)
  Future<UserStats> getUserStats(AppUser user) async {
    if (user.isGuestMode || user.isAnonymous) {
      return const UserStats();
    }

    try {
      final doc = await _firestore.collection('user_stats').doc(user.uid).get();
      if (!doc.exists || doc.data() == null) {
        return const UserStats();
      }
      // Convert Firestore Timestamp to DateTime and normalize types
      final rawData = doc.data()!;
      final data = Map<String, dynamic>.from(rawData);

      // Normalize integer fields
      data['totalLearnedWords'] = _normalizeInt(data['totalLearnedWords'] ?? 0);
      data['totalSessions'] = _normalizeInt(data['totalSessions'] ?? 0);
      data['totalScore'] = _normalizeInt(data['totalScore'] ?? 0);
      data['currentStreakDays'] = _normalizeInt(data['currentStreakDays'] ?? 0);
      data['bestStreakDays'] = _normalizeInt(data['bestStreakDays'] ?? 0);

      // Convert Timestamp to ISO 8601 String for generated fromJson code
      // TimestampConverter can handle multiple types, but String is safest
      if (data['lastActivityDate'] != null) {
        DateTime? dateTime;
        if (data['lastActivityDate'] is Timestamp) {
          dateTime = (data['lastActivityDate'] as Timestamp).toDate();
        } else if (data['lastActivityDate'] is DateTime) {
          dateTime = data['lastActivityDate'] as DateTime;
        } else if (data['lastActivityDate'] is String) {
          // Already a String, keep it
          dateTime = DateTime.tryParse(data['lastActivityDate'] as String);
        }
        if (dateTime != null) {
          data['lastActivityDate'] = dateTime.toIso8601String();
        } else {
          data.remove('lastActivityDate');
        }
      }

      // Normalize modeStats map - normalize integers, let generated code parse
      if (data['modeStats'] != null && data['modeStats'] is Map) {
        final rawModeStats = data['modeStats'] as Map;
        final normalizedModeStats = <String, dynamic>{};
        for (final entry in rawModeStats.entries) {
          if (entry.value is Map) {
            final modeData = Map<String, dynamic>.from(entry.value as Map);
            // Normalize integer fields - generated code will parse this
            normalizedModeStats[entry.key.toString()] = {
              'sessions': _normalizeInt(modeData['sessions'] ?? 0),
              'correctAnswers': _normalizeInt(modeData['correctAnswers'] ?? 0),
              'wrongAnswers': _normalizeInt(modeData['wrongAnswers'] ?? 0),
              'totalQuestions': _normalizeInt(modeData['totalQuestions'] ?? 0),
              'totalMinutes': _normalizeInt(modeData['totalMinutes'] ?? 0),
            };
          }
        }
        data['modeStats'] = normalizedModeStats;
      }

      // Convert last30Days list - date must be ISO 8601 String for generated code
      if (data['last30Days'] != null && data['last30Days'] is List) {
        final daysList =
            (data['last30Days'] as List).map((day) {
              if (day is Map) {
                final dayMap = Map<String, dynamic>.from(day);
                // Convert date to ISO 8601 String
                if (dayMap['date'] != null) {
                  DateTime? dateTime;
                  if (dayMap['date'] is Timestamp) {
                    dateTime = (dayMap['date'] as Timestamp).toDate();
                  } else if (dayMap['date'] is DateTime) {
                    dateTime = dayMap['date'] as DateTime;
                  } else if (dayMap['date'] is String) {
                    // Already a String, try to parse to validate
                    dateTime = DateTime.tryParse(dayMap['date'] as String);
                  }
                  if (dateTime != null) {
                    dayMap['date'] = dateTime.toIso8601String();
                  } else {
                    // Invalid date, remove this entry or use current date
                    dayMap['date'] = DateTime.now().toIso8601String();
                  }
                }
                dayMap['practicedWords'] = _normalizeInt(
                  dayMap['practicedWords'] ?? 0,
                );
                dayMap['minutes'] = _normalizeInt(dayMap['minutes'] ?? 0);
                return dayMap;
              }
              return day;
            }).toList();
        data['last30Days'] = daysList;
      }

      // Normalize hardestWords list
      List<String> hardestWordsList = <String>[];
      if (data['hardestWords'] != null && data['hardestWords'] is List) {
        hardestWordsList =
            (data['hardestWords'] as List).whereType<String>().toList();
      }

      // Always fetch latest hardest words from trap_words subcollection
      try {
        final hardestWordsData = await getHardestWords(user, limit: 10);
        hardestWordsList =
            hardestWordsData
                .map((w) => w['word'] as String)
                .whereType<String>()
                .toList();
      } catch (e) {
        // If fetching fails, keep existing list or use empty
        ErrorLogger.instance.logError(
          e,
          context: 'getUserStats (hardestWords)',
        );
      }

      data['hardestWords'] = hardestWordsList;
      return UserStats.fromJson(data);
    } catch (e) {
      ErrorLogger.instance.logError(e, context: 'getUserStats');
      return const UserStats();
    }
  }

  /// Update streak on app startup (login)
  Future<void> updateLoginStreak(AppUser user) async {
    if (user.isGuestMode || user.isAnonymous) return;

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final currentStats = await getUserStats(user);
      final lastActivityDate = currentStats.lastActivityDate;
      final lastActivityDay =
          lastActivityDate != null
              ? DateTime(
                lastActivityDate.year,
                lastActivityDate.month,
                lastActivityDate.day,
              )
              : null;

      int newStreak = 1;
      bool shouldUpdate = false;

      if (lastActivityDay != null) {
        final daysDiff = today.difference(lastActivityDay).inDays;
        if (daysDiff == 0) {
          // Zaten bugün girilmiş
          newStreak = currentStats.currentStreakDays;
          if (newStreak == 0) {
            newStreak = 1;
            shouldUpdate = true;
          }
        } else if (daysDiff == 1) {
          // Dün girilmiş, seriyi artır
          newStreak = currentStats.currentStreakDays + 1;
          shouldUpdate = true;
        } else {
          // 1 günden fazla olmuş, seriyi sıfırla (1 yap)
          newStreak = 1;
          shouldUpdate = true;
        }
      } else {
        // İlk giriş
        shouldUpdate = true;
      }

      if (shouldUpdate) {
        final bestStreak =
            newStreak > currentStats.bestStreakDays
                ? newStreak
                : currentStats.bestStreakDays;

        await _firestore.collection('user_stats').doc(user.uid).set({
          'currentStreakDays': newStreak,
          'bestStreakDays': bestStreak,
          'lastActivityDate': Timestamp.fromDate(now.toUtc()),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      ErrorLogger.instance.logError(e, context: 'updateLoginStreak');
    }
  }

  /// Record a game session
  Future<void> recordSession({
    required AppUser user,
    required String modeId,
    required int practicedWords,
    required int correctAnswers,
    required int wrongAnswers,
    required Duration duration,
    int score = 0, // Oyun puanı (opsiyonel)
  }) async {
    if (user.isGuestMode || user.isAnonymous) {
      // Guests don't persist stats
      return;
    }

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final minutes = duration.inMinutes;

      // Get current stats to calculate streak
      final currentStats = await getUserStats(user);
      final lastActivityDate = currentStats.lastActivityDate;
      final lastActivityDay =
          lastActivityDate != null
              ? DateTime(
                lastActivityDate.year,
                lastActivityDate.month,
                lastActivityDate.day,
              )
              : null;

      // Calculate streak
      int newStreak = 1;
      if (lastActivityDay != null) {
        final daysDiff = today.difference(lastActivityDay).inDays;
        if (daysDiff == 0) {
          // Same day, keep current streak
          newStreak = currentStats.currentStreakDays;
        } else if (daysDiff == 1) {
          // Yesterday, increment streak
          newStreak = currentStats.currentStreakDays + 1;
        }
        // else: more than 1 day, reset to 1
      }

      final bestStreak =
          newStreak > currentStats.bestStreakDays
              ? newStreak
              : currentStats.bestStreakDays;

      // Update today's activity
      final todayActivity = currentStats.last30Days.firstWhere((day) {
        final dayDate = DateTime(day.date.year, day.date.month, day.date.day);
        return dayDate == today;
      }, orElse: () => DailyActivityPoint(date: today));

      final updatedTodayActivity = todayActivity.copyWith(
        practicedWords: todayActivity.practicedWords + practicedWords,
        minutes: todayActivity.minutes + minutes,
      );

      // Update last30Days list (keep only last 30 days)
      final updatedLast30Days = [
        ...currentStats.last30Days.where((day) {
          final dayDate = DateTime(day.date.year, day.date.month, day.date.day);
          return dayDate != today;
        }),
        updatedTodayActivity,
      ]..sort((a, b) => b.date.compareTo(a.date));

      // Keep only last 30 days
      if (updatedLast30Days.length > 30) {
        updatedLast30Days.removeRange(30, updatedLast30Days.length);
      }

      // Prepare Firestore update
      final updateData = <String, dynamic>{
        'totalSessions': FieldValue.increment(1),
        'totalLearnedWords': FieldValue.increment(practicedWords),
        if (score > 0) 'totalScore': FieldValue.increment(score),
        'currentStreakDays': newStreak,
        'bestStreakDays': bestStreak,
        'lastActivityDate': Timestamp.fromDate(now.toUtc()),
        'modeStats.$modeId.sessions': FieldValue.increment(1),
        'modeStats.$modeId.correctAnswers': FieldValue.increment(
          correctAnswers,
        ),
        'modeStats.$modeId.wrongAnswers': FieldValue.increment(wrongAnswers),
        'modeStats.$modeId.totalQuestions': FieldValue.increment(
          correctAnswers + wrongAnswers,
        ),
        'modeStats.$modeId.totalMinutes': FieldValue.increment(minutes),
        'last30Days':
            updatedLast30Days
                .map(
                  (day) => {
                    'date': Timestamp.fromDate(day.date.toUtc()),
                    'practicedWords': day.practicedWords,
                    'minutes': day.minutes,
                  },
                )
                .toList(),
      };

      await _firestore
          .collection('user_stats')
          .doc(user.uid)
          .set(updateData, SetOptions(merge: true));
    } catch (e) {
      ErrorLogger.instance.logError(e, context: 'recordSession');
      // Don't rethrow - stats recording shouldn't break the game
    }
  }

  /// Record a word result (for hardest words tracking)
  Future<void> recordWordResult({
    required AppUser user,
    required String modeId,
    required String word,
    required bool isCorrect,
  }) async {
    if (user.isGuestMode || user.isAnonymous) {
      return;
    }

    try {
      final wordDocRef = _firestore
          .collection('user_stats')
          .doc(user.uid)
          .collection('trap_words')
          .doc(word.toLowerCase());

      if (isCorrect) {
        await wordDocRef.set({
          'word': word.toLowerCase(),
          'correctCount': FieldValue.increment(1),
          'lastSeenAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        await wordDocRef.set({
          'word': word.toLowerCase(),
          'wrongCount': FieldValue.increment(1),
          'lastSeenAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // Periodically update hardestWords list (every 10 wrong answers)
      // For now, we'll do this on-demand when viewing stats
    } catch (e) {
      ErrorLogger.instance.logError(e, context: 'recordWordResult');
      // Don't rethrow
    }
  }

  /// Reset all stats for a user
  Future<void> resetAllStats(AppUser user) async {
    if (user.isGuestMode || user.isAnonymous) {
      return;
    }

    try {
      // Delete main stats document
      await _firestore.collection('user_stats').doc(user.uid).delete();

      // Delete trap_words subcollection
      // Note: Firestore doesn't support recursive delete in client SDK
      // For now, we'll delete the main doc. Subcollection will be cleaned up
      // by a Cloud Function or on next access
      // TODO: Implement Cloud Function deleteUserStats(uid) for complete cleanup

      final trapWordsRef = _firestore
          .collection('user_stats')
          .doc(user.uid)
          .collection('trap_words');

      // Delete in batches (Firestore limit is 500 per batch)
      final batch = _firestore.batch();
      int count = 0;

      await trapWordsRef.get().then((snapshot) {
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
          count++;
          if (count >= 500) {
            batch.commit();
            count = 0;
          }
        }
        if (count > 0) {
          batch.commit();
        }
      });
    } catch (e) {
      ErrorLogger.instance.logError(e, context: 'resetAllStats');
      rethrow;
    }
  }

  /// Get hardest words (top N by wrongCount - correctCount)
  Future<List<Map<String, dynamic>>> getHardestWords(
    AppUser user, {
    int limit = 10,
  }) async {
    if (user.isGuestMode || user.isAnonymous) {
      return [];
    }

    try {
      final trapWordsRef = _firestore
          .collection('user_stats')
          .doc(user.uid)
          .collection('trap_words');

      final snapshot = await trapWordsRef.get();
      final words = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final correctCount = (data['correctCount'] as int?) ?? 0;
        final wrongCount = (data['wrongCount'] as int?) ?? 0;
        final difficulty = wrongCount - correctCount;

        if (difficulty > 0) {
          words.add({
            'word': data['word'] ?? doc.id,
            'wrongCount': wrongCount,
            'correctCount': correctCount,
            'difficulty': difficulty,
          });
        }
      }

      // Sort by difficulty (descending) and take top N
      words.sort(
        (a, b) => (b['difficulty'] as int).compareTo(a['difficulty'] as int),
      );
      return words.take(limit).toList();
    } catch (e) {
      ErrorLogger.instance.logError(e, context: 'getHardestWords');
      return [];
    }
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
}

/// Provider for UserStatsRepo
final userStatsRepoProvider = Provider<UserStatsRepo>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return UserStatsRepo(firestore);
});
