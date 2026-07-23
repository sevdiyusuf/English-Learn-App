enum EngineType {
  mcq,
  fill,
  tap,
  order,
  transform,
  errorSpotting,
  matching,
  unknown;

  static EngineType fromString(String value) {
    final normalized = value.trim().toLowerCase().replaceAll('_', '');
    return EngineType.values.firstWhere(
      (e) => e.name.toLowerCase() == normalized,
      orElse: () => EngineType.unknown,
    );
  }
}

class WorksheetMetadata {
  final String worksheetId;
  final String title;
  final String path;
  final List<String> tags;
  final String level; // Added to store level context
  final int? bestScore;

  WorksheetMetadata({
    required this.worksheetId,
    required this.title,
    required this.path,
    required this.tags,
    required this.level,
    this.bestScore,
  });

  factory WorksheetMetadata.fromJson(
    Map<String, dynamic> json,
    String level, {
    int? bestScore,
  }) {
    return WorksheetMetadata(
      worksheetId: json['worksheet_id'] as String,
      title: json['title'] as String,
      path: json['path'] as String,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      level: level,
      bestScore: bestScore,
    );
  }
}

class Worksheet {
  final String schemaVersion;
  final String level;
  final String worksheetId;
  final String title;
  final List<String> topicTags;
  final List<String> subskills;
  final int difficulty;
  final List<WorksheetItem> items;

  Worksheet({
    required this.schemaVersion,
    required this.level,
    required this.worksheetId,
    required this.title,
    required this.topicTags,
    required this.subskills,
    required this.difficulty,
    required this.items,
  });

  factory Worksheet.fromJson(Map<String, dynamic> json) {
    return Worksheet(
      schemaVersion: json['schema_version'] as String? ?? '1.0',
      level: json['level'] as String? ?? '',
      worksheetId: json['worksheet_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      topicTags:
          (json['topic_tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      subskills:
          (json['subskills'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      difficulty: json['difficulty'] as int? ?? 1,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => WorksheetItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class TransformStep {
  final String type;
  final String label;
  final List<String> options;
  final String answer;

  TransformStep({
    required this.type,
    required this.label,
    required this.options,
    required this.answer,
  });

  factory TransformStep.fromJson(Map<String, dynamic> json) {
    return TransformStep(
      type: json['type'] as String? ?? '',
      label: json['label'] as String? ?? '',
      options:
          (json['options'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      answer: json['answer'] as String? ?? '',
    );
  }
}

class WorksheetItem {
  final String id;
  final EngineType engine;
  final String prompt;
  final dynamic answer; // Can be String or List<String> depending on engine
  final String? hint;
  final String? translation;
  final List<String> bank; // For tap/order
  final List<String> options; // For mcq (if not in bank)
  final List<TransformStep> steps; // For transform
  final Map<String, dynamic> raw; // Keep raw data just in case

  WorksheetItem({
    required this.id,
    required this.engine,
    required this.prompt,
    required this.answer,
    this.hint,
    this.translation,
    required this.bank,
    required this.options,
    required this.steps,
    required this.raw,
  });

  factory WorksheetItem.fromJson(Map<String, dynamic> json) {
    return WorksheetItem(
      id: json['id'] as String? ?? '',
      engine: EngineType.fromString(json['engine'] as String? ?? ''),
      prompt: json['prompt'] as String? ?? '',
      answer:
          json['answer'] ??
          json['final_answer'] ??
          json['answer_tokens'], // Fallback chain
      hint: json['hint'] as String?,
      translation: (json['translation_tr'] ?? json['translation']) as String?,
      bank:
          ((json['bank'] ?? json['tokens']) as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      options:
          (json['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      steps:
          (json['steps'] as List<dynamic>?)
              ?.map((e) => TransformStep.fromJson(e))
              .toList() ??
          [],
      raw: json,
    );
  }
}
