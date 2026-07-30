import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A entry containing dataset path and item anchor.
class EducationalItemKey {
  final String path;
  final String anchor;

  const EducationalItemKey(this.path, this.anchor);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EducationalItemKey &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          anchor == other.anchor;

  @override
  int get hashCode => path.hashCode ^ anchor.hashCode;
}

/// Loads `assets/educational_content_registry.json` and exposes a lookup map
/// from `(path, anchor)` to stable `contentId`.
final educationalContentRegistryProvider =
    FutureProvider<Map<EducationalItemKey, String>>((ref) async {
      try {
        final raw = await rootBundle.loadString(
          'assets/educational_content_registry.json',
        );
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final datasets = json['datasets'] as List<dynamic>? ?? [];

        final result = <EducationalItemKey, String>{};
        for (final ds in datasets) {
          final map = ds as Map<String, dynamic>;
          final path = map['path'] as String? ?? '';
          final items = (map['items'] as List<dynamic>?) ?? [];

          for (final item in items) {
            final itemMap = item as Map<String, dynamic>;
            final anchor = itemMap['anchor'] as String? ?? '';
            final contentId = itemMap['contentId'] as String? ?? '';
            if (path.isNotEmpty && anchor.isNotEmpty && contentId.isNotEmpty) {
              result[EducationalItemKey(path, anchor)] = contentId;
            }
          }
        }
        return result;
      } catch (_) {
        return {};
      }
    });
