import 'dart:convert';
import 'dart:io';

import 'src/educational_content_registry.dart';

void main() {
  final root = Directory.current;
  final output = File(
    '${root.path}${Platform.pathSeparator}'
    '${educationalRegistryPath.replaceAll('/', Platform.pathSeparator)}',
  );
  Map<String, dynamic>? previous;
  if (output.existsSync()) {
    previous = jsonDecode(output.readAsStringSync()) as Map<String, dynamic>;
  }
  final registry = generateRegistry(root, previousRegistry: previous);
  output.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(registry)}\n',
  );
  final datasets = registry['datasets'] as List<dynamic>;
  final itemCount = datasets.cast<Map<String, dynamic>>().fold<int>(
    0,
    (sum, item) => sum + (item['items'] as List).length,
  );
  stdout.writeln(
    'Generated $educationalRegistryPath: '
    '${datasets.length} datasets, $itemCount stable content IDs.',
  );
}
