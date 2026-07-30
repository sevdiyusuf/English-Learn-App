import 'dart:io';

import 'src/educational_content_registry.dart';

void main(List<String> arguments) {
  final root =
      arguments.length == 2 && arguments.first == '--root'
          ? Directory(arguments.last)
          : Directory.current;
  final result = validateRegistry(root);
  if (!result.isValid) {
    stderr.writeln(
      'Educational content validation failed '
      '(${result.errors.length} error(s)):',
    );
    for (final error in result.errors) {
      stderr.writeln('- $error');
    }
    exitCode = 1;
    return;
  }
  stdout.writeln(
    'Educational content validation passed: '
    '${result.datasetCount} datasets, ${result.itemCount} stable content IDs.',
  );
}
