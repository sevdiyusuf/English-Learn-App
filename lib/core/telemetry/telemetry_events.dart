/// Fixed event dictionary for analytics logging.
class TelemetryEvents {
  TelemetryEvents._();

  static const String onboardingCompleted = 'onboarding_completed';
  static const String lessonStarted = 'lesson_started';
  static const String lessonCompleted = 'lesson_completed';
  static const String multiplayerMatchStarted = 'multiplayer_match_started';
  static const String multiplayerMatchCompleted = 'multiplayer_match_completed';
  static const String contentReportSubmitted = 'content_report_submitted';
}

/// Allowed low-cardinality analytics & error parameter keys.
class TelemetryParams {
  TelemetryParams._();

  static const String feature = 'feature';
  static const String operation = 'operation';
  static const String stage = 'stage';
  static const String contentType = 'content_type';
  static const String contentLevel = 'content_level';
  static const String matchMode = 'match_mode';
  static const String resultCategory = 'result_category';
  static const String retryCount = 'retry_count';
  static const String isGuest = 'is_guest';
  static const String level = 'level';
  static const String goal = 'goal';
  static const String reason = 'reason';
  static const String errorCode = 'error_code';

  /// Complete list of explicitly allowed metadata keys (low-cardinality categorical data only).
  static const Set<String> allowlist = {
    feature,
    operation,
    stage,
    contentType,
    contentLevel,
    matchMode,
    resultCategory,
    retryCount,
    isGuest,
    level,
    goal,
    reason,
    errorCode,
  };

  /// Set of explicitly forbidden sensitive/high-cardinality keys.
  static const Set<String> forbiddenKeys = {
    'email',
    'password',
    'token',
    'auth_token',
    'app_check_token',
    'fcm_token',
    'uid',
    'user_id',
    'display_name',
    'displayname',
    'answer',
    'message',
    'body',
    'title',
    'details',
    'user_text',
    'text',
    'room_id',
    'lesson_id',
  };
}
