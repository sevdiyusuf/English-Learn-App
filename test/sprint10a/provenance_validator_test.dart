import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/provenance_validator.dart';

void main() {
  group('production provenance repository', () {
    test('current production manifest and dependency inventory pass', () {
      expect(validateProvenanceRepository(Directory.current), isEmpty);
    });
  });

  group('provenance validator failures', () {
    late Directory fixture;

    setUp(() {
      fixture = Directory.systemTemp.createTempSync('yunoo_provenance_');
      _writeFixture(fixture);
    });

    tearDown(() => fixture.deleteSync(recursive: true));

    test('unsupported schema version fails', () {
      _mutateManifest(fixture, (manifest) => manifest['schemaVersion'] = 99);
      expect(_errors(fixture), contains(contains('Unsupported content')));
    });

    test('duplicate stable IDs fail', () {
      _mutateManifest(fixture, (manifest) {
        final records = manifest['records'] as List;
        records.add(Map<String, dynamic>.from(records.first as Map));
      });
      expect(_errors(fixture), contains(contains('Duplicate record ID')));
    });

    test('missing material fails', () {
      File('${fixture.path}/assets/item.txt').deleteSync();
      expect(_errors(fixture), contains(contains('missing material')));
    });

    test('unsafe escaping path fails', () {
      _mutateRecord(
        fixture,
        (record) =>
            record['scopes'] = [
              {'path': '../secret.txt', 'kind': 'file'},
            ],
      );
      expect(_errors(fixture), contains(contains('unsafe path')));
    });

    test('uncovered packaged material fails', () {
      File('${fixture.path}/assets/second.txt').writeAsStringSync('second');
      _write(
        fixture,
        'pubspec.yaml',
        _pubspecWithAssets(['assets/item.txt', 'assets/second.txt']),
      );
      expect(_errors(fixture), contains(contains('no manifest coverage')));
    });

    test('orphaned manifest entry fails', () {
      File('${fixture.path}/assets/orphan.txt').writeAsStringSync('orphan');
      _mutateManifest(fixture, (manifest) {
        (manifest['records'] as List).add(
          _validRecord(id: 'orphan', path: 'assets/orphan.txt'),
        );
      });
      expect(_errors(fixture), contains(contains('orphaned')));
    });

    test('conflicting coverage fails', () {
      _mutateManifest(fixture, (manifest) {
        (manifest['records'] as List).add(
          _validRecord(id: 'duplicate-coverage', path: 'assets/item.txt'),
        );
      });
      expect(_errors(fixture), contains(contains('Conflicting coverage')));
    });

    test('contradictory project rights fail', () {
      _mutateRecord(
        fixture,
        (record) => record['rightsBasis'] = 'third_party_license',
      );
      expect(_errors(fixture), contains(contains('contradictory')));
    });

    test('required attribution without text fails', () {
      _mutateRecord(fixture, (record) {
        record['attributionRequired'] = true;
        record.remove('attributionText');
      });
      expect(_errors(fixture), contains(contains('requires attribution text')));
    });

    test('unresolved origin or status fails', () {
      _mutateRecord(fixture, (record) {
        record['originCategory'] = 'unknown';
        record['verificationStatus'] = 'check later';
      });
      final errors = _errors(fixture).join('\n');
      expect(errors, contains('unresolved/unsupported originCategory'));
      expect(errors, contains('not verified'));
    });

    test('third-party material without license basis fails', () {
      _mutateRecord(fixture, (record) {
        record['originCategory'] = 'third_party_licensed';
        record['rightsBasis'] = 'project_owned';
        record['sourceUrl'] = 'https://example.test/source';
      });
      final errors = _errors(fixture).join('\n');
      expect(errors, contains('third-party rightsBasis'));
      expect(errors, contains('without a verified license'));
    });

    test('AI-assisted project original needs no fabricated source URL', () {
      expect(_errors(fixture), isEmpty);
    });

    test('dependency inventory must match resolved lock set', () {
      final file = File('${fixture.path}/licenses/dependency_licenses.json');
      final inventory =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      (inventory['packages'] as List).first['version'] = '9.9.9';
      file.writeAsStringSync(jsonEncode(inventory));
      expect(
        _errors(fixture),
        contains(contains('does not match pubspec.lock')),
      );
    });
  });
}

List<String> _errors(Directory fixture) =>
    validateProvenanceRepository(fixture);

void _writeFixture(Directory root) {
  _write(root, 'assets/item.txt', 'project material');
  _write(root, 'pubspec.yaml', _pubspecWithAssets(['assets/item.txt']));
  _write(root, 'pubspec.lock', '''
packages:
  sample:
    dependency: "direct main"
    description:
      name: sample
      url: "https://pub.dev"
    source: hosted
    version: "1.0.0"
sdks:
  dart: ">=3.0.0 <4.0.0"
''');
  _write(
    root,
    'licenses/content_provenance.json',
    jsonEncode({
      'schemaVersion': 1,
      'records': [_validRecord()],
    }),
  );
  _write(
    root,
    'licenses/dependency_licenses.json',
    jsonEncode({
      'schemaVersion': 1,
      'packages': [
        {
          'name': 'sample',
          'version': '1.0.0',
          'dependency': 'direct main',
          'source': 'hosted',
          'licenseIdentifier': 'MIT',
          'licenseStatus': 'verified',
          'licenseEvidence': 'LICENSE',
        },
      ],
    }),
  );
  Directory('${root.path}/lib').createSync(recursive: true);
}

Map<String, dynamic> _validRecord({
  String id = 'project-content',
  String path = 'assets/item.txt',
}) => {
  'id': id,
  'scopes': [
    {'path': path, 'kind': 'file'},
  ],
  'materialType': 'educational_dataset',
  'description': 'AI-assisted project material',
  'usage': 'Production learning flow',
  'originCategory': 'ai_assisted_project_original',
  'creatorProvider': 'Project owner with mixed/unspecified AI assistance',
  'rightsBasis': 'project_owned',
  'attributionRequired': false,
  'verificationStatus': 'verified',
};

void _mutateRecord(
  Directory fixture,
  void Function(Map<String, dynamic> record) mutation,
) {
  _mutateManifest(
    fixture,
    (manifest) =>
        mutation((manifest['records'] as List).first as Map<String, dynamic>),
  );
}

void _mutateManifest(
  Directory fixture,
  void Function(Map<String, dynamic> manifest) mutation,
) {
  final file = File('${fixture.path}/licenses/content_provenance.json');
  final manifest = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  mutation(manifest);
  file.writeAsStringSync(jsonEncode(manifest));
}

String _pubspecWithAssets(List<String> assets) => '''
name: fixture
environment:
  sdk: ^3.7.0
flutter:
  assets:
${assets.map((asset) => '    - $asset').join('\n')}
''';

void _write(Directory root, String relative, String contents) {
  final file = File('${root.path}/$relative');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
}
