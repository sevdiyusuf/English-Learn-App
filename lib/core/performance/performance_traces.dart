/// Fixed dictionary of custom performance trace names.
class PerformanceTraces {
  PerformanceTraces._();

  static const String appBootstrap = 'app_bootstrap';
  static const String lessonLoad = 'lesson_load';
  static const String worksheetLoad = 'worksheet_load';
  static const String syncCycle = 'sync_cycle';

  /// Complete list of valid custom trace names.
  static const Set<String> validTraces = {
    appBootstrap,
    lessonLoad,
    worksheetLoad,
    syncCycle,
  };
}

/// Low-cardinality categorical parameter keys and controlled vocabularies for performance traces.
class PerformanceParams {
  PerformanceParams._();

  static const String contentType = 'content_type';
  static const String contentLevel = 'content_level';
  static const String operation = 'operation';
  static const String stage = 'stage';
  static const String sourceType = 'source_type';
  static const String resultCategory = 'result_category';
  static const String isGuest = 'is_guest';

  /// Set of explicitly allowed low-cardinality attribute keys.
  static const Set<String> allowlist = {
    contentType,
    contentLevel,
    operation,
    stage,
    sourceType,
    resultCategory,
    isGuest,
  };

  /// Controlled vocabularies for each allowed attribute key.
  /// Any value not present in the specified vocabulary for a key will be strictly rejected.
  static const Map<String, Set<String>> controlledVocabularies = {
    contentType: {
      'grammar_lesson',
      'worksheet',
      'dictionary',
      'word_set',
      'audio',
    },
    contentLevel: {'A1', 'A2', 'B1', 'B2', 'C1', 'C2', 'all'},
    operation: {
      'sync_bootstrap',
      'sync_push',
      'sync_pull',
      'cache_load',
      'remote_fetch',
    },
    stage: {'bootstrap', 'initialization', 'background_load', 'completion'},
    sourceType: {'local_cache', 'firestore_remote', 'bundle_asset'},
    resultCategory: {'success', 'error', 'timeout', 'cancelled'},
    isGuest: {'true', 'false'},
  };

  /// Set of forbidden high-cardinality / PII / free-text keys.
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
    'set_id',
    'arbitrary_user_input',
  };
}
