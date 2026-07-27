import 'dart:convert';
import 'dart:io';

const int educationalSchemaVersion = 1;
const int educationalContentVersion = 1;
const String educationalRegistryPath =
    'assets/educational_content_registry.json';

final RegExp contentIdPattern = RegExp(r'^edu\.[a-z0-9][a-z0-9._-]*$');

class ContentValidationResult {
  const ContentValidationResult(this.errors, this.datasetCount, this.itemCount);

  final List<String> errors;
  final int datasetCount;
  final int itemCount;

  bool get isValid => errors.isEmpty;
}

List<String> productionEducationalPaths(Directory root) {
  final provenanceFile = File(
    '${root.path}${Platform.pathSeparator}licenses'
    '${Platform.pathSeparator}content_provenance.json',
  );
  final provenance =
      jsonDecode(provenanceFile.readAsStringSync()) as Map<String, dynamic>;
  final records = provenance['records'] as List<dynamic>;
  final record = records.cast<Map<String, dynamic>>().singleWhere(
    (entry) => entry['id'] == 'educational-core-datasets',
  );
  final paths = <String>{};
  for (final scope
      in (record['scopes'] as List<dynamic>).cast<Map<String, dynamic>>()) {
    final relative = scope['path'] as String;
    final entity = FileSystemEntity.typeSync(
      '${root.path}${Platform.pathSeparator}'
      '${relative.replaceAll('/', Platform.pathSeparator)}',
    );
    if (scope['kind'] == 'file' && entity == FileSystemEntityType.file) {
      paths.add(relative);
    } else if (scope['kind'] == 'directory' &&
        entity == FileSystemEntityType.directory) {
      final directory = Directory(
        '${root.path}${Platform.pathSeparator}'
        '${relative.replaceAll('/', Platform.pathSeparator)}',
      );
      for (final file
          in directory.listSync(recursive: true).whereType<File>()) {
        if (!file.path.toLowerCase().endsWith('.json')) continue;
        paths.add(
          file.path
              .substring(root.path.length + 1)
              .replaceAll(Platform.pathSeparator, '/'),
        );
      }
    }
  }
  return paths.toList()..sort();
}

Map<String, dynamic> generateRegistry(
  Directory root, {
  Map<String, dynamic>? previousRegistry,
}) {
  final previousByLocation = <String, String>{};
  final previousByAnchor = <String, String>{};
  final ambiguousPreviousAnchors = <String>{};
  var nextNumber = 1;
  if (previousRegistry != null) {
    for (final dataset
        in (previousRegistry['datasets'] as List<dynamic>? ?? const <dynamic>[])
            .cast<Map<String, dynamic>>()) {
      final path = dataset['path'] as String;
      for (final item
          in (dataset['items'] as List<dynamic>).cast<Map<String, dynamic>>()) {
        final id = item['contentId'] as String;
        previousByLocation['$path#${item['pointer']}'] = id;
        final anchor = item['anchor'];
        if (anchor is String && anchor.isNotEmpty) {
          final key = '$path#$anchor';
          if (previousByAnchor.containsKey(key)) {
            previousByAnchor.remove(key);
            ambiguousPreviousAnchors.add(key);
          } else if (!ambiguousPreviousAnchors.contains(key)) {
            previousByAnchor[key] = id;
          }
        }
        final match = RegExp(r'\.(\d+)$').firstMatch(id);
        if (match != null) {
          final value = int.parse(match.group(1)!);
          if (value >= nextNumber) nextNumber = value + 1;
        }
      }
    }
  }

  final datasets = <Map<String, dynamic>>[];
  for (final path in productionEducationalPaths(root)) {
    final file = File(
      '${root.path}${Platform.pathSeparator}'
      '${path.replaceAll('/', Platform.pathSeparator)}',
    );
    final decoded = jsonDecode(file.readAsStringSync());
    final candidates = <_Candidate>[];
    _collectCandidates(decoded, '', candidates);
    final anchorCounts = <String, int>{};
    for (final candidate in candidates) {
      anchorCounts.update(
        candidate.anchor,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    final items = <Map<String, dynamic>>[];
    for (final candidate in candidates) {
      final location = '$path#${candidate.pointer}';
      final anchorKey = '$path#${candidate.anchor}';
      final stableAnchorId =
          anchorCounts[candidate.anchor] == 1
              ? previousByAnchor[anchorKey]
              : null;
      final id =
          stableAnchorId ??
          previousByLocation[location] ??
          'edu.item.${nextNumber.toString().padLeft(6, '0')}';
      if (!previousByLocation.containsKey(location) && stableAnchorId == null) {
        nextNumber++;
      }
      items.add({
        'contentId': id,
        'pointer': candidate.pointer,
        'kind': candidate.kind,
        'anchor': candidate.anchor,
      });
    }
    datasets.add({
      'path': path,
      'schemaVersion': educationalSchemaVersion,
      'contentVersion': educationalContentVersion,
      'items': items,
    });
  }
  return {
    'schemaVersion': educationalSchemaVersion,
    'contentVersion': educationalContentVersion,
    'idPolicy': 'stable_repository_mapping_v1',
    'datasets': datasets,
  };
}

ContentValidationResult validateRegistry(
  Directory root, {
  Map<String, dynamic>? registryOverride,
}) {
  final errors = <String>[];
  Map<String, dynamic> registry;
  try {
    registry =
        registryOverride ??
        jsonDecode(
              File(
                '${root.path}${Platform.pathSeparator}'
                '${educationalRegistryPath.replaceAll('/', Platform.pathSeparator)}',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
  } on Object catch (error) {
    return ContentValidationResult(
      ['registry: malformed JSON or structure ($error)'],
      0,
      0,
    );
  }

  if (registry['schemaVersion'] != educationalSchemaVersion) {
    errors.add(
      'registry: unsupported schemaVersion ${registry['schemaVersion']}',
    );
  }
  final releaseVersion = registry['contentVersion'];
  if (releaseVersion is! int || releaseVersion < 1) {
    errors.add('registry: contentVersion must be a positive integer');
  }

  final expected = productionEducationalPaths(root).toSet();
  final seenPaths = <String>{};
  final seenIds = <String>{};
  var itemCount = 0;
  final datasets = registry['datasets'];
  if (datasets is! List) {
    errors.add('registry: datasets must be a list');
    return ContentValidationResult(errors, 0, 0);
  }

  for (final rawDataset in datasets) {
    if (rawDataset is! Map<String, dynamic>) {
      errors.add('registry: dataset entry must be an object');
      continue;
    }
    final path = rawDataset['path'];
    if (path is! String || path.isEmpty || path.contains('..')) {
      errors.add('registry: dataset has an unsafe or empty path');
      continue;
    }
    if (!seenPaths.add(path)) errors.add('$path: duplicate dataset record');
    if (rawDataset['schemaVersion'] != educationalSchemaVersion) {
      errors.add('$path: unsupported or missing schemaVersion');
    }
    final version = rawDataset['contentVersion'];
    if (version is! int || version < 1) {
      errors.add('$path: contentVersion must be a positive integer');
    }
    final file = File(
      '${root.path}${Platform.pathSeparator}'
      '${path.replaceAll('/', Platform.pathSeparator)}',
    );
    if (!file.existsSync()) {
      errors.add('$path: dataset file is missing');
      continue;
    }
    dynamic decoded;
    try {
      decoded = jsonDecode(file.readAsStringSync());
    } on Object {
      errors.add('$path: malformed JSON');
      continue;
    }
    final actual = <_Candidate>[];
    _collectCandidates(decoded, '', actual);
    final actualPointers = actual.map((entry) => entry.pointer).toSet();
    final actualByPointer = {
      for (final candidate in actual) candidate.pointer: candidate,
    };
    final coveredPointers = <String>{};
    final items = rawDataset['items'];
    if (items is! List) {
      errors.add('$path: items must be a list');
      continue;
    }
    for (final rawItem in items) {
      itemCount++;
      if (rawItem is! Map<String, dynamic>) {
        errors.add('$path: item record must be an object');
        continue;
      }
      final id = rawItem['contentId'];
      final pointer = rawItem['pointer'];
      if (id is! String || !contentIdPattern.hasMatch(id)) {
        errors.add('$path: malformed or missing contentId at $pointer');
      } else if (!seenIds.add(id)) {
        errors.add('$path: duplicate contentId $id');
      }
      if (pointer is! String || !actualPointers.contains(pointer)) {
        errors.add('$path: dangling item pointer $pointer');
      } else if (!coveredPointers.add(pointer)) {
        errors.add('$path: duplicate item pointer $pointer');
      } else if (rawItem['anchor'] != actualByPointer[pointer]!.anchor) {
        errors.add('$path: item anchor does not match content at $pointer');
      }
    }
    for (final missing in actualPointers.difference(coveredPointers)) {
      errors.add('$path: reportable item is missing contentId at $missing');
    }
    _validateStructuralContent(root, path, decoded, errors);
  }

  for (final path in expected.difference(seenPaths)) {
    errors.add('$path: production educational dataset is not registered');
  }
  for (final path in seenPaths.difference(expected)) {
    errors.add('$path: registry entry is not a production educational dataset');
  }
  return ContentValidationResult(errors, seenPaths.length, itemCount);
}

void _collectCandidates(
  dynamic value,
  String pointer,
  List<_Candidate> output,
) {
  if (value is List) {
    for (var index = 0; index < value.length; index++) {
      final childPointer = '$pointer/$index';
      final child = value[index];
      if (child is String && _isIndependentWordPointer(pointer)) {
        output.add(_Candidate(childPointer, 'word', 'word:${child.trim()}'));
      } else {
        _collectCandidates(child, childPointer, output);
      }
    }
    return;
  }
  if (value is! Map<String, dynamic>) return;

  if (_isReportableObject(value, pointer)) {
    output.add(
      _Candidate(
        pointer.isEmpty ? '/' : pointer,
        _kindFor(value),
        _anchorFor(value, pointer),
      ),
    );
  }
  for (final entry in value.entries) {
    _collectCandidates(
      entry.value,
      '$pointer/${_escapePointer(entry.key)}',
      output,
    );
  }
}

bool _isIndependentWordPointer(String pointer) {
  return pointer.endsWith('/words');
}

bool _isReportableObject(Map<String, dynamic> value, String pointer) {
  if (value.containsKey('prompt') ||
      value.containsKey('base_form') ||
      value.containsKey('word') ||
      (value.containsKey('en') && value.containsKey('tr')) ||
      (value.containsKey('english') && value.containsKey('turkish'))) {
    return true;
  }
  if (value.containsKey('id') &&
      (value.containsKey('title') || value.containsKey('type'))) {
    return true;
  }
  if (value.containsKey('worksheet_id') || value.containsKey('lesson_id')) {
    return true;
  }
  return false;
}

String _kindFor(Map<String, dynamic> value) {
  if (value.containsKey('prompt')) return 'exercise';
  if (value.containsKey('base_form')) return 'irregular_verb';
  if (value.containsKey('word')) return 'word';
  if (value.containsKey('worksheet_id')) return 'worksheet';
  if (value.containsKey('lesson_id')) return 'lesson';
  if (value.containsKey('en') || value.containsKey('english')) {
    return 'word_pair';
  }
  if (value.containsKey('type')) return 'lesson_card';
  return 'content_unit';
}

String _anchorFor(Map<String, dynamic> value, String pointer) {
  for (final key in const [
    'contentId',
    'worksheet_id',
    'lesson_id',
    'id',
    'base_form',
    'word',
  ]) {
    final candidate = value[key];
    if (candidate is String && candidate.trim().isNotEmpty) {
      return '$key:${candidate.trim()}';
    }
  }
  final en = value['en'] ?? value['english'];
  final tr = value['tr'] ?? value['turkish'];
  if (en is String && tr is String) return 'pair:${en.trim()}|${tr.trim()}';
  final prompt = value['prompt'];
  if (prompt is String) return 'prompt:${prompt.trim()}';
  return 'legacy-pointer:$pointer';
}

void _validateStructuralContent(
  Directory root,
  String path,
  dynamic decoded,
  List<String> errors,
) {
  void walk(dynamic value, String pointer) {
    if (value is List) {
      for (var i = 0; i < value.length; i++) {
        walk(value[i], '$pointer/$i');
      }
      return;
    }
    if (value is! Map<String, dynamic>) return;
    if (value.containsKey('prompt')) {
      final prompt = value['prompt'];
      if (prompt is! String || prompt.trim().isEmpty) {
        errors.add('$path$pointer: prompt must be a non-empty string');
      }
      final engine = value['engine'];
      const engines = {
        'mcq',
        'fill',
        'tap',
        'order',
        'transform',
        'error_spotting',
        'matching',
      };
      if (engine is! String || !engines.contains(engine)) {
        errors.add('$path$pointer: unsupported exercise engine');
      }
      if (engine == 'mcq') {
        final options = value['options'];
        final answer = value['answer'];
        if (options is! List || options.isEmpty) {
          errors.add('$path$pointer: mcq options must be a non-empty list');
        } else if (answer is int && (answer < 0 || answer >= options.length)) {
          errors.add('$path$pointer: answer index is outside options');
        }
      }
    }
    if (value.containsKey('word') &&
        (value['word'] is! String ||
            (value['word'] as String).trim().isEmpty)) {
      errors.add('$path$pointer: word must be a non-empty string');
    }
    for (final pair in const [('en', 'tr'), ('english', 'turkish')]) {
      if (value.containsKey(pair.$1) || value.containsKey(pair.$2)) {
        if (value[pair.$1] is! String ||
            (value[pair.$1] as String).trim().isEmpty ||
            value[pair.$2] is! String ||
            (value[pair.$2] as String).trim().isEmpty) {
          errors.add(
            '$path$pointer: ${pair.$1}/${pair.$2} must be non-empty strings',
          );
        }
      }
    }
    if (value.containsKey('base_form')) {
      for (final key in const ['base_form', 'v2', 'v3', 'meaning_tr']) {
        if (value[key] is! String || (value[key] as String).trim().isEmpty) {
          errors.add('$path$pointer: $key must be a non-empty string');
        }
      }
    }
    final level = value['level'];
    const supportedLevels = {'A1', 'A2', 'B1', 'B2', 'easy', 'medium', 'hard'};
    if (level is String && !supportedLevels.contains(level)) {
      errors.add('$path$pointer: unsupported level $level');
    }
    final referencedPath = value['path'];
    if (referencedPath is String && referencedPath.startsWith('assets/')) {
      final referencedFile = File(
        '${root.path}${Platform.pathSeparator}'
        '${referencedPath.replaceAll('/', Platform.pathSeparator)}',
      );
      if (!referencedFile.existsSync()) {
        errors.add('$path$pointer: dangling asset reference $referencedPath');
      }
    }
    for (final entry in value.entries) {
      walk(entry.value, '$pointer/${_escapePointer(entry.key)}');
    }
  }

  walk(decoded, '');
}

String _escapePointer(String value) =>
    value.replaceAll('~', '~0').replaceAll('/', '~1');

class _Candidate {
  const _Candidate(this.pointer, this.kind, this.anchor);

  final String pointer;
  final String kind;
  final String anchor;
}
