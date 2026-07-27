/// Sprint 10C — Educational Content Error Reporting
///
/// This service wraps the `submitEducationalContentReport` Cloud Function.
/// All errors are swallowed after extraction so that reporting failures are
/// **never** surfaced to the learning flow.  Callers receive a typed
/// [ContentReportResult] and decide whether to show a snackbar.
library;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';

// ── Public API ───────────────────────────────────────────────────────────────

/// The six categories the Cloud Function accepts (mirrors server enum exactly).
enum ContentReportCategory {
  typo,
  incorrectAnswer,
  unclearExplanation,
  audioIssue,
  wrongLevelOrCategory,
  other;

  /// Wire value sent to the Cloud Function.
  String get value {
    switch (this) {
      case ContentReportCategory.typo:
        return 'typo';
      case ContentReportCategory.incorrectAnswer:
        return 'incorrect_answer';
      case ContentReportCategory.unclearExplanation:
        return 'unclear_explanation';
      case ContentReportCategory.audioIssue:
        return 'audio_issue';
      case ContentReportCategory.wrongLevelOrCategory:
        return 'wrong_level_or_category';
      case ContentReportCategory.other:
        return 'other';
    }
  }
}

/// Result returned by [ContentReportService.submit].
enum ContentReportResult {
  /// The Function accepted the report.
  success,

  /// The user has not signed in — they need to log in first.
  unauthenticated,

  /// The user has already submitted this report recently (cooldown).
  alreadyReported,

  /// Any other transient or network failure.
  failure,
}

// ── Service ──────────────────────────────────────────────────────────────────

class ContentReportService {
  ContentReportService(this._functions, this._auth);

  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  /// Submit an educational content report.
  ///
  /// This method is **non-blocking**: it never throws.  Callers should
  /// inspect the returned [ContentReportResult] to choose a snackbar message.
  Future<ContentReportResult> submit({
    required String contentId,
    required int contentVersion,
    required String contentType,
    required ContentReportCategory category,
    String comment = '',
  }) async {
    // Guard: user must be signed in — do NOT silently authenticate guests.
    if (_auth.currentUser == null) {
      return ContentReportResult.unauthenticated;
    }

    try {
      await _functions.httpsCallable('submitEducationalContentReport').call({
        'contentId': contentId,
        'contentVersion': contentVersion,
        'contentType': contentType,
        'category': category.value,
        if (comment.trim().isNotEmpty) 'comment': comment.trim(),
      });
      return ContentReportResult.success;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'already-exists') {
        return ContentReportResult.alreadyReported;
      }
      if (e.code == 'unauthenticated') {
        return ContentReportResult.unauthenticated;
      }
      return ContentReportResult.failure;
    } catch (_) {
      return ContentReportResult.failure;
    }
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final contentReportServiceProvider = Provider<ContentReportService>((ref) {
  return ContentReportService(
    ref.watch(firebaseFunctionsProvider),
    ref.watch(firebaseAuthProvider),
  );
});
