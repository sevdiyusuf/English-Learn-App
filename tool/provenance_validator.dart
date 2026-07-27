import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

const supportedManifestSchemaVersion = 1;
const _unresolvedWords = <String>[
  'todo',
  'unknown',
  'check later',
  'assumed',
  'probably free',
  'source needed',
];

Future<void> main(List<String> arguments) async {
  final root = Directory.current;
  if (arguments.contains('--generate-dependencies')) {
    final errors = await generateDependencyInventory(root);
    if (errors.isNotEmpty) {
      stderr.writeln(errors.join('\n'));
      exitCode = 1;
      return;
    }
    stdout.writeln('Generated licenses/dependency_licenses.json.');
  }

  final errors = validateProvenanceRepository(root);
  if (errors.isNotEmpty) {
    stderr.writeln('Provenance validation failed (${errors.length}):');
    for (final error in errors) {
      stderr.writeln('- $error');
    }
    exitCode = 1;
    return;
  }

  final manifest =
      jsonDecode(
            File(
              '${root.path}/licenses/content_provenance.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final dependencies =
      jsonDecode(
            File(
              '${root.path}/licenses/dependency_licenses.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  stdout.writeln(
    'Provenance validation passed: '
    '${(manifest['records'] as List).length} content records, '
    '${(dependencies['packages'] as List).length} resolved packages.',
  );
}

List<String> validateProvenanceRepository(
  Directory root, {
  String manifestPath = 'licenses/content_provenance.json',
  String dependencyInventoryPath = 'licenses/dependency_licenses.json',
  String pubspecPath = 'pubspec.yaml',
  String lockPath = 'pubspec.lock',
}) {
  final errors = <String>[];
  final manifestFile = File('${root.path}/$manifestPath');
  final dependencyFile = File('${root.path}/$dependencyInventoryPath');
  final pubspecFile = File('${root.path}/$pubspecPath');
  final lockFile = File('${root.path}/$lockPath');

  for (final file in [manifestFile, dependencyFile, pubspecFile, lockFile]) {
    if (!file.existsSync()) {
      errors.add(
        'Required inventory source is missing: ${_relative(root, file)}',
      );
    }
  }
  if (errors.isNotEmpty) return errors;

  Map<String, dynamic> manifest;
  Map<String, dynamic> dependencies;
  YamlMap pubspec;
  YamlMap lock;
  try {
    manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    dependencies =
        jsonDecode(dependencyFile.readAsStringSync()) as Map<String, dynamic>;
    pubspec = loadYaml(pubspecFile.readAsStringSync()) as YamlMap;
    lock = loadYaml(lockFile.readAsStringSync()) as YamlMap;
  } catch (error) {
    return ['Malformed manifest or authoritative YAML source: $error'];
  }

  if (manifest['schemaVersion'] != supportedManifestSchemaVersion) {
    errors.add(
      'Unsupported content manifest schemaVersion: ${manifest['schemaVersion']}',
    );
  }
  if (dependencies['schemaVersion'] != 1) {
    errors.add(
      'Unsupported dependency inventory schemaVersion: '
      '${dependencies['schemaVersion']}',
    );
  }

  final records = manifest['records'];
  if (records is! List || records.isEmpty) {
    errors.add('Manifest records must be a non-empty list.');
    return errors;
  }

  final ids = <String>{};
  final coveredFiles = <String, String>{};
  for (final raw in records) {
    if (raw is! Map<String, dynamic>) {
      errors.add('Every manifest record must be an object.');
      continue;
    }
    final id = raw['id'];
    if (id is! String || id.trim().isEmpty) {
      errors.add('A manifest record has an empty stable ID.');
      continue;
    }
    if (!ids.add(id)) errors.add('Duplicate record ID: $id');
    _validateRecordFields(raw, id, errors);

    final scopes = raw['scopes'];
    if (scopes is! List || scopes.isEmpty) {
      errors.add('$id has no controlled scopes.');
      continue;
    }
    for (final rawScope in scopes) {
      if (rawScope is! Map<String, dynamic>) {
        errors.add('$id contains a malformed scope.');
        continue;
      }
      final path = rawScope['path'];
      final kind = rawScope['kind'];
      if (path is! String || !_isSafeRelativePath(path)) {
        errors.add('$id contains an unsafe path: $path');
        continue;
      }
      if (kind != 'file' && kind != 'directory') {
        errors.add('$id has unsupported scope kind: $kind');
        continue;
      }
      final target = FileSystemEntity.typeSync('${root.path}/$path');
      if (target == FileSystemEntityType.notFound) {
        errors.add('$id points to missing material: $path');
        continue;
      }
      final files =
          kind == 'file'
              ? [File('${root.path}/$path')]
              : Directory('${root.path}/$path')
                  .listSync(recursive: true, followLinks: false)
                  .whereType<File>()
                  .toList();
      if (files.isEmpty) {
        errors.add('$id scope contains no files: $path');
      }
      for (final file in files) {
        final relative = _relative(root, file);
        final previous = coveredFiles[relative];
        if (previous != null && previous != id) {
          errors.add(
            'Conflicting coverage for $relative by $previous and $id.',
          );
        } else {
          coveredFiles[relative] = id;
        }
      }
    }
  }

  final expected = <String>{};
  _collectPubspecAssets(root, pubspec, expected, errors);
  _collectProductionDirectory(root, 'web', expected);
  _collectProductionDirectory(root, 'android/app/src/main/res', expected);
  for (final path
      in expected.difference(coveredFiles.keys.toSet()).toList()..sort()) {
    errors.add('Production material has no manifest coverage: $path');
  }
  for (final path
      in coveredFiles.keys.toSet().difference(expected).toList()..sort()) {
    errors.add('Manifest entry is orphaned from production packaging: $path');
  }

  _validateDartAssetReferences(root, expected, errors);
  _validateDependencies(lock, dependencies, errors);
  return errors;
}

void _validateRecordFields(
  Map<String, dynamic> record,
  String id,
  List<String> errors,
) {
  const origins = {
    'project_original',
    'ai_assisted_project_original',
    'third_party_licensed',
    'flutter_platform_provided',
    'generated_from_project_source',
  };
  const requiredText = [
    'materialType',
    'description',
    'usage',
    'originCategory',
    'rightsBasis',
    'verificationStatus',
  ];
  for (final field in requiredText) {
    final value = record[field];
    if (value is! String || value.trim().isEmpty) {
      errors.add('$id has an empty required field: $field');
    }
  }
  if (!origins.contains(record['originCategory'])) {
    errors.add('$id has unresolved/unsupported originCategory.');
  }
  if (record['verificationStatus'] != 'verified') {
    errors.add('$id is not verified.');
  }
  final encoded = jsonEncode(record).toLowerCase();
  for (final word in _unresolvedWords) {
    if (encoded.contains(word)) {
      errors.add('$id contains unresolved placeholder text: $word');
    }
  }
  final thirdParty =
      record['originCategory'] == 'third_party_licensed' ||
      record['originCategory'] == 'flutter_platform_provided';
  if (thirdParty) {
    if (record['rightsBasis'] != 'third_party_license') {
      errors.add('$id has contradictory third-party rightsBasis.');
    }
    if (record['licenseIdentifier'] is! String ||
        (record['licenseIdentifier'] as String).isEmpty) {
      errors.add('$id is third-party material without a verified license.');
    }
    final source = record['sourceUrl'];
    if (source is! String || !_isHttpUrl(source)) {
      errors.add('$id requires a valid verified sourceUrl.');
    }
  } else if (record['rightsBasis'] == 'third_party_license') {
    errors.add('$id has contradictory project origin and third-party rights.');
  }
  if (record['attributionRequired'] is! bool) {
    errors.add('$id must declare attributionRequired.');
  } else if (record['attributionRequired'] == true &&
      (record['attributionText'] is! String ||
          (record['attributionText'] as String).trim().isEmpty)) {
    errors.add('$id requires attribution text.');
  }
  final source = record['sourceUrl'];
  if (source != null && (source is! String || !_isHttpUrl(source))) {
    errors.add('$id contains an invalid sourceUrl.');
  }
}

void _collectPubspecAssets(
  Directory root,
  YamlMap pubspec,
  Set<String> expected,
  List<String> errors,
) {
  final flutter = pubspec['flutter'];
  final assets = flutter is YamlMap ? flutter['assets'] : null;
  if (assets is! YamlList) {
    errors.add('pubspec.yaml has no authoritative flutter.assets list.');
    return;
  }
  for (final value in assets) {
    if (value is! String || !_isSafeRelativePath(value)) {
      errors.add('pubspec.yaml contains an unsafe asset path: $value');
      continue;
    }
    final normalized = value
        .replaceAll('\\', '/')
        .replaceAll(RegExp(r'/$'), '');
    final type = FileSystemEntity.typeSync('${root.path}/$normalized');
    if (type == FileSystemEntityType.notFound) {
      errors.add('Packaged asset is missing: $normalized');
    } else if (type == FileSystemEntityType.file) {
      expected.add(normalized);
    } else if (type == FileSystemEntityType.directory) {
      _collectProductionDirectory(root, normalized, expected);
    }
  }

  final launcher = pubspec['flutter_launcher_icons'];
  if (launcher is YamlMap) {
    for (final key in ['image_path', 'adaptive_icon_foreground']) {
      final value = launcher[key];
      if (value is String) {
        if (!_isSafeRelativePath(value) ||
            !File('${root.path}/$value').existsSync()) {
          errors.add('Launcher source is missing or unsafe: $value');
        }
      }
    }
  }
}

void _collectProductionDirectory(
  Directory root,
  String path,
  Set<String> output,
) {
  final directory = Directory('${root.path}/$path');
  if (!directory.existsSync()) return;
  for (final file
      in directory
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()) {
    output.add(_relative(root, file));
  }
}

void _validateDartAssetReferences(
  Directory root,
  Set<String> expected,
  List<String> errors,
) {
  final lib = Directory('${root.path}/lib');
  final pattern = RegExp(r'''['"](assets/[^'"]+)['"]''');
  for (final file
      in lib.listSync(recursive: true, followLinks: false).whereType<File>()) {
    if (!file.path.endsWith('.dart')) continue;
    for (final match in pattern.allMatches(file.readAsStringSync())) {
      final reference = match.group(1)!;
      if (reference.contains(r'$')) {
        final prefix = reference.substring(0, reference.indexOf(r'$'));
        if (!expected.any((path) => path.startsWith(prefix))) {
          errors.add('Dynamic asset prefix is not packaged: $reference');
        }
      } else if (reference.endsWith('/') &&
          expected.any((path) => path.startsWith(reference))) {
        continue;
      } else if (!expected.contains(reference)) {
        errors.add('Referenced production asset is not packaged: $reference');
      }
    }
  }
}

void _validateDependencies(
  YamlMap lock,
  Map<String, dynamic> inventory,
  List<String> errors,
) {
  final packages = lock['packages'];
  final rows = inventory['packages'];
  if (packages is! YamlMap || rows is! List) {
    errors.add('Dependency inventory or pubspec.lock packages are malformed.');
    return;
  }
  final expected = <String, String>{};
  for (final entry in packages.entries) {
    final data = entry.value as YamlMap;
    expected[entry.key as String] =
        '${data['version']}|${data['dependency']}|${data['source']}';
  }
  final actual = <String, String>{};
  for (final raw in rows) {
    if (raw is! Map<String, dynamic>) {
      errors.add('Dependency inventory contains a malformed row.');
      continue;
    }
    final name = raw['name'];
    if (name is! String || actual.containsKey(name)) {
      errors.add(
        'Dependency inventory has an empty or duplicate package: $name',
      );
      continue;
    }
    actual[name] = '${raw['version']}|${raw['dependency']}|${raw['source']}';
    if (raw['licenseStatus'] != 'verified' ||
        raw['licenseIdentifier'] is! String ||
        (raw['licenseIdentifier'] as String).isEmpty) {
      errors.add('$name has no verified distributed license metadata.');
    }
  }
  for (final name in expected.keys.toSet().difference(actual.keys.toSet())) {
    errors.add('Resolved dependency is missing from inventory: $name');
  }
  for (final name in actual.keys.toSet().difference(expected.keys.toSet())) {
    errors.add('Dependency inventory contains stale package: $name');
  }
  for (final name in expected.keys.toSet().intersection(actual.keys.toSet())) {
    if (expected[name] != actual[name]) {
      errors.add('Dependency inventory does not match pubspec.lock: $name');
    }
  }
}

Future<List<String>> generateDependencyInventory(Directory root) async {
  final errors = <String>[];
  final lock =
      loadYaml(File('${root.path}/pubspec.lock').readAsStringSync()) as YamlMap;
  final config =
      jsonDecode(
            File(
              '${root.path}/.dart_tool/package_config.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final packageRoots = <String, String>{};
  for (final raw in config['packages'] as List) {
    final row = raw as Map<String, dynamic>;
    final uri = Uri.parse(row['rootUri'] as String);
    if (uri.scheme == 'file') {
      packageRoots[row['name'] as String] = uri.toFilePath();
    }
  }

  final packages = <Map<String, dynamic>>[];
  for (final entry in (lock['packages'] as YamlMap).entries) {
    final name = entry.key as String;
    final data = entry.value as YamlMap;
    final rootPath = packageRoots[name];
    File? licenseFile;
    if (rootPath != null) {
      licenseFile = _findDistributedLicense(Directory(rootPath));
    }
    if (licenseFile == null && data['source'] == 'sdk' && rootPath != null) {
      licenseFile = _findParentLicense(Directory(rootPath));
    }
    if (licenseFile == null) {
      errors.add('$name ${data['version']} has no distributed LICENSE/NOTICE.');
      continue;
    }
    final licenseId = _classifyLicense(licenseFile.readAsStringSync());
    if (licenseId == null) {
      errors.add(
        '$name ${data['version']} has unclassified license metadata at '
        '${licenseFile.path}.',
      );
      continue;
    }
    packages.add({
      'name': name,
      'version': data['version'],
      'dependency': data['dependency'],
      'source': data['source'],
      'licenseIdentifier': licenseId,
      'licenseStatus': 'verified',
      'licenseEvidence': licenseFile.uri.pathSegments.last,
    });
  }
  if (errors.isNotEmpty) return errors;
  packages.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
  final output = {
    'schemaVersion': 1,
    'generatedFrom': 'pubspec.lock and distributed local package metadata',
    'packages': packages,
  };
  final encoder = const JsonEncoder.withIndent('  ');
  File('${root.path}/licenses/dependency_licenses.json')
    ..createSync(recursive: true)
    ..writeAsStringSync('${encoder.convert(output)}\n');
  return [];
}

File? _findDistributedLicense(Directory directory) {
  if (!directory.existsSync()) return null;
  for (final name in [
    'LICENSE',
    'LICENSE.md',
    'LICENSE.txt',
    'COPYING',
    'NOTICE',
  ]) {
    final file = File('${directory.path}/$name');
    if (file.existsSync()) return file;
  }
  return null;
}

File? _findParentLicense(Directory directory) {
  var current = directory;
  for (var i = 0; i < 6; i++) {
    final license = _findDistributedLicense(current);
    if (license != null) return license;
    current = current.parent;
  }
  return null;
}

String? _classifyLicense(String text) {
  final lower = text.toLowerCase();
  if (lower.contains('mozilla public license version 2.0')) return 'MPL-2.0';
  if (lower.contains('apache license') && lower.contains('version 2.0')) {
    return 'Apache-2.0';
  }
  if (lower.contains('permission is hereby granted, free of charge')) {
    return 'MIT';
  }
  if (lower.contains('redistribution and use in source and binary forms')) {
    return lower.contains('neither the name') ? 'BSD-3-Clause' : 'BSD-2-Clause';
  }
  if (lower.contains(
    'permission to use, copy, modify, and/or distribute this software',
  )) {
    return 'ISC';
  }
  if (lower.contains("this software is provided 'as-is'") ||
      lower.contains('this software is provided "as-is"')) {
    return 'Zlib';
  }
  return null;
}

bool _isSafeRelativePath(String path) {
  if (path.trim().isEmpty ||
      path.contains('\\') ||
      path.startsWith('/') ||
      RegExp(r'^[A-Za-z]:').hasMatch(path)) {
    return false;
  }
  final segments = path.split('/');
  return !segments.contains('..') && !segments.contains('.');
}

bool _isHttpUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null &&
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host.isNotEmpty;
}

String _relative(Directory root, FileSystemEntity entity) {
  final base = root.absolute.path.replaceAll('\\', '/');
  final full = entity.absolute.path.replaceAll('\\', '/');
  return full.substring(base.length + 1);
}
