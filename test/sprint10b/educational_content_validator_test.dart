import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/educational_content_registry.dart';

void main() {
  group('production educational content', () {
    test('all production datasets validate', () {
      final result = validateRegistry(Directory.current);

      expect(result.errors, isEmpty);
      expect(result.datasetCount, greaterThan(100));
      expect(result.itemCount, greaterThan(7000));
    });
  });

  group('educational registry validation', () {
    late Directory root;
    late Map<String, dynamic> registry;

    setUp(() {
      root = Directory.systemTemp.createTempSync('content_validator_');
      _writeFixture(root, {
        'level': 'A1',
        'items': [
          {
            'id': 'q1',
            'engine': 'mcq',
            'prompt': 'Prompt',
            'options': ['a', 'b'],
            'answer': 0,
          },
        ],
      });
      registry = generateRegistry(root);
      _writeRegistry(root, registry);
    });

    tearDown(() => root.deleteSync(recursive: true));

    test('supported versions and generated IDs pass', () {
      expect(validateRegistry(root).errors, isEmpty);
    });

    test('unsupported schema version fails', () {
      registry['schemaVersion'] = 99;
      expect(_validate(root, registry), contains(contains('schemaVersion')));
    });

    test('missing schema version fails', () {
      registry.remove('schemaVersion');
      expect(_validate(root, registry), contains(contains('schemaVersion')));
    });

    test('invalid content version fails', () {
      registry['contentVersion'] = 0;
      expect(_validate(root, registry), contains(contains('contentVersion')));
    });

    test('missing contentId fails', () {
      _firstItem(registry).remove('contentId');
      expect(_validate(root, registry), contains(contains('contentId')));
    });

    test('malformed contentId fails', () {
      _firstItem(registry)['contentId'] = 'display text / 1';
      expect(_validate(root, registry), contains(contains('contentId')));
    });

    test('duplicate IDs fail globally', () {
      final first = Map<String, dynamic>.from(_firstItem(registry));
      (registry['datasets'] as List).first['items'].add(first);
      expect(
        _validate(root, registry),
        contains(contains('duplicate contentId')),
      );
    });

    test('missing required runtime text fails', () {
      _writeFixture(root, {
        'items': [
          {
            'id': 'q1',
            'engine': 'mcq',
            'prompt': '',
            'options': ['a'],
            'answer': 0,
          },
        ],
      });
      expect(
        _validate(root, generateRegistry(root)),
        contains(contains('prompt')),
      );
    });

    test('wrong field type fails safely', () {
      _writeFixture(root, {
        'items': [
          {
            'id': 'q1',
            'engine': 'mcq',
            'prompt': 4,
            'options': ['a'],
            'answer': 0,
          },
        ],
      });
      expect(
        _validate(root, generateRegistry(root)),
        contains(contains('prompt')),
      );
    });

    test('unsupported engine enum fails', () {
      _writeFixture(root, {
        'items': [
          {'id': 'q1', 'engine': 'surprise', 'prompt': 'Prompt'},
        ],
      });
      expect(
        _validate(root, generateRegistry(root)),
        contains(contains('engine')),
      );
    });

    test('invalid answer index fails', () {
      _writeFixture(root, {
        'items': [
          {
            'id': 'q1',
            'engine': 'mcq',
            'prompt': 'Prompt',
            'options': ['a'],
            'answer': 2,
          },
        ],
      });
      expect(
        _validate(root, generateRegistry(root)),
        contains(contains('answer index')),
      );
    });

    test('dangling pointer fails', () {
      _firstItem(registry)['pointer'] = '/items/99';
      expect(_validate(root, registry), contains(contains('dangling')));
    });

    test('dangling content reference fails', () {
      _writeFixture(root, {
        'items': [
          {
            'lesson_id': 'A1-TEST',
            'title': 'Test',
            'path': 'assets/missing.json',
          },
        ],
      });
      expect(
        _validate(root, generateRegistry(root)),
        contains(contains('dangling asset reference')),
      );
    });

    test('malformed JSON fails with file context', () {
      File('${root.path}/assets/sample.json').writeAsStringSync('{');
      final errors = _validate(root, registry);
      expect(errors, contains(contains('assets/sample.json: malformed JSON')));
    });

    test('reordering preserves existing IDs', () {
      _writeFixture(root, {
        'words': [
          {'word': 'alpha'},
          {'word': 'beta'},
        ],
      });
      final before = generateRegistry(root);
      final beforeByAnchor = _idsByAnchor(before);
      _writeFixture(root, {
        'words': [
          {'word': 'beta'},
          {'word': 'alpha'},
        ],
      });

      final after = generateRegistry(root, previousRegistry: before);

      expect(_idsByAnchor(after), beforeByAnchor);
      expect(_validate(root, after), isEmpty);
    });

    test('existing IDs survive a generator rerun', () {
      final before = _firstItem(registry)['contentId'];
      final after = generateRegistry(root, previousRegistry: registry);
      expect(_firstItem(after)['contentId'], before);
    });

    test('unregistered production dataset fails coverage', () {
      (registry['datasets'] as List).clear();
      expect(_validate(root, registry), contains(contains('not registered')));
    });

    test('validation does not judge the linguistic answer', () {
      _writeFixture(root, {
        'items': [
          {
            'id': 'q1',
            'engine': 'mcq',
            'prompt': 'Choose',
            'options': ['arbitrary', 'values'],
            'answer': 0,
          },
        ],
      });
      expect(_validate(root, generateRegistry(root)), isEmpty);
    });

    test('command returns non-zero for invalid production content', () async {
      registry['schemaVersion'] = 99;
      _writeRegistry(root, registry);

      final result = await Process.run(_dartExecutable(), [
        File('tool/educational_content_validator.dart').absolute.path,
        '--root',
        root.path,
      ]);

      expect(result.exitCode, 1);
      expect(result.stderr, contains('validation failed'));
    });
  });
}

void _writeFixture(Directory root, Object json) {
  Directory('${root.path}/assets').createSync(recursive: true);
  Directory('${root.path}/licenses').createSync(recursive: true);
  File('${root.path}/assets/sample.json').writeAsStringSync(jsonEncode(json));
  File('${root.path}/licenses/content_provenance.json').writeAsStringSync(
    jsonEncode({
      'schemaVersion': 1,
      'records': [
        {
          'id': 'educational-core-datasets',
          'scopes': [
            {'path': 'assets/sample.json', 'kind': 'file'},
          ],
        },
      ],
    }),
  );
}

void _writeRegistry(Directory root, Map<String, dynamic> registry) {
  File(
    '${root.path}/assets/educational_content_registry.json',
  ).writeAsStringSync(jsonEncode(registry));
}

List<String> _validate(Directory root, Map<String, dynamic> registry) {
  _writeRegistry(root, registry);
  return validateRegistry(root).errors;
}

Map<String, dynamic> _firstItem(Map<String, dynamic> registry) =>
    (((registry['datasets'] as List).first as Map<String, dynamic>)['items']
                as List)
            .first
        as Map<String, dynamic>;

Map<String, String> _idsByAnchor(Map<String, dynamic> registry) {
  final items =
      ((registry['datasets'] as List).first as Map<String, dynamic>)['items']
          as List;
  return {
    for (final item in items.cast<Map<String, dynamic>>())
      item['anchor'] as String: item['contentId'] as String,
  };
}

String _dartExecutable() {
  var directory = File(Platform.resolvedExecutable).parent;
  while (directory.parent.path != directory.path) {
    final candidate = File('${directory.path}/bin/dart.bat');
    if (candidate.existsSync()) return candidate.path;
    directory = directory.parent;
  }
  throw StateError('Flutter SDK Dart executable was not found');
}
