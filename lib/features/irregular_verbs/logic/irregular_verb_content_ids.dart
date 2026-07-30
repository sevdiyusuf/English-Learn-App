import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Returns a map from base_form (V1) → contentId for the irregular verbs
/// dataset, loaded from the educational content registry asset.
///
/// Returns an empty map if the registry cannot be read (offline / asset not
/// found), which is safe — callers fall back to a dataset-level contentId.
final irregularVerbContentIdMapProvider = FutureProvider<Map<String, String>>((
  ref,
) async {
  try {
    final raw = await rootBundle.loadString(
      'assets/educational_content_registry.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final datasets = json['datasets'] as List<dynamic>? ?? [];

    for (final ds in datasets) {
      final path = (ds as Map<String, dynamic>)['path'] as String? ?? '';
      // Match both 'irregular_verbs.json' and the BOM-prefixed variant
      if (!path.contains('rregular_verbs')) continue;

      final items = (ds['items'] as List<dynamic>?) ?? [];
      final result = <String, String>{};
      for (final item in items) {
        final m = item as Map<String, dynamic>;
        final anchor = m['anchor'] as String? ?? '';
        final contentId = m['contentId'] as String? ?? '';
        // anchor format: "base_form:arise"
        if (anchor.startsWith('base_form:') && contentId.isNotEmpty) {
          final baseForm = anchor.substring('base_form:'.length);
          result[baseForm] = contentId;
        }
      }
      return result;
    }
    return {};
  } catch (_) {
    return {};
  }
});
