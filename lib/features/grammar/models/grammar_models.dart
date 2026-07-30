import '../../training/models/training_models.dart';

class LessonIndex {
  final List<String> levels;
  final Map<String, List<LessonEntry>> lessonsByLevel;

  LessonIndex({required this.levels, required this.lessonsByLevel});

  factory LessonIndex.fromJson(Map<String, dynamic> json) {
    final levels = List<String>.from(json['levels'] ?? []);
    final lessonsJson = json['lessons'] as Map<String, dynamic>? ?? {};

    final lessonsByLevel = <String, List<LessonEntry>>{};
    for (var level in levels) {
      final list = lessonsJson[level] as List<dynamic>? ?? [];
      lessonsByLevel[level] =
          list
              .map((e) => LessonEntry.fromJson(e as Map<String, dynamic>))
              .toList();
    }

    return LessonIndex(levels: levels, lessonsByLevel: lessonsByLevel);
  }
}

class LessonEntry {
  final String lessonId;
  final String title;
  final String path;
  final List<String> topicTags;
  final String? trainWorksheetId;

  LessonEntry({
    required this.lessonId,
    required this.title,
    required this.path,
    required this.topicTags,
    this.trainWorksheetId,
  });

  factory LessonEntry.fromJson(Map<String, dynamic> json) {
    return LessonEntry(
      lessonId: json['lesson_id'] as String,
      title: json['title'] as String,
      path: json['path'] as String,
      topicTags: List<String>.from(json['topic_tags'] ?? []),
      trainWorksheetId: json['train_worksheet_id'] as String?,
    );
  }
}

class LessonDoc {
  final String schemaVersion;
  final String level;
  final String lessonId;
  final String title;
  final List<String> topicTags;
  final MicroLesson microLesson;
  final StoryMode storyMode;
  final String? trainWorksheetId;

  LessonDoc({
    required this.schemaVersion,
    required this.level,
    required this.lessonId,
    required this.title,
    required this.topicTags,
    required this.microLesson,
    required this.storyMode,
    this.trainWorksheetId,
  });

  factory LessonDoc.fromJson(Map<String, dynamic> json) {
    return LessonDoc(
      schemaVersion: json['schema_version'] as String? ?? '1.0',
      level: json['level'] as String? ?? '',
      lessonId: json['lesson_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      topicTags: List<String>.from(json['topic_tags'] ?? []),
      microLesson: MicroLesson.fromJson(
        json['micro_lesson'] as Map<String, dynamic>? ?? {},
      ),
      storyMode: StoryMode.fromJson(
        json['story_mode'] as Map<String, dynamic>? ?? {},
      ),
      trainWorksheetId:
          (json['train_link'] as Map<String, dynamic>?)?['worksheet_id']
              as String?,
    );
  }
}

class MicroLesson {
  final List<LessonCard> cards;

  MicroLesson({required this.cards});

  factory MicroLesson.fromJson(Map<String, dynamic> json) {
    final cardsList = json['cards'] as List<dynamic>? ?? [];
    return MicroLesson(
      cards:
          cardsList
              .map((e) => LessonCard.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}

enum LessonCardType {
  goal,
  rule,
  tip,
  commonMistake,
  examples,
  formula,
  checkpoint,
  unknown;

  static LessonCardType fromString(String value) {
    final normalized = value.toLowerCase().replaceAll('_', '');
    return LessonCardType.values.firstWhere(
      (e) => e.name.toLowerCase() == normalized,
      orElse: () => LessonCardType.unknown,
    );
  }
}

class LessonCard {
  final String id;
  final LessonCardType type;
  final String? title;
  final List<String> bullets;
  final List<String> formula;
  final List<String> examples;
  final WorksheetItem? checkpoint;

  LessonCard({
    required this.id,
    required this.type,
    this.title,
    this.bullets = const [],
    this.formula = const [],
    this.examples = const [],
    this.checkpoint,
  });

  factory LessonCard.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? '';
    final type = LessonCardType.fromString(typeStr);

    return LessonCard(
      id: json['id'] as String? ?? '',
      type: type,
      title: json['title'] as String?,
      bullets: List<String>.from(json['bullets'] ?? []),
      formula: List<String>.from(json['formula'] ?? []),
      examples: List<String>.from(json['examples'] ?? []),
      checkpoint:
          type == LessonCardType.checkpoint
              ? WorksheetItem.fromJson(json)
              : null,
    );
  }
}

class StoryMode {
  final bool enabled;
  final String title;
  final List<String> introBullets;
  final List<WorksheetItem> items;
  final List<String> recapBullets;

  StoryMode({
    required this.enabled,
    required this.title,
    required this.introBullets,
    required this.items,
    required this.recapBullets,
  });

  factory StoryMode.fromJson(Map<String, dynamic> json) {
    return StoryMode(
      enabled: json['enabled'] as bool? ?? false,
      title: json['title'] as String? ?? '',
      introBullets: List<String>.from(json['intro_bullets'] ?? []),
      items:
          (json['items'] as List<dynamic>? ?? [])
              .map((e) => WorksheetItem.fromJson(e as Map<String, dynamic>))
              .toList(),
      recapBullets: List<String>.from(json['recap_bullets'] ?? []),
    );
  }
}
