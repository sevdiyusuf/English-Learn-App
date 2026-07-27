import 'package:flutter/foundation.dart';

@immutable
class ContentProgressReference {
  const ContentProgressReference({
    required this.ownerScope,
    this.contentId,
    this.legacyKey,
  });

  final String ownerScope;
  final String? contentId;
  final String? legacyKey;

  factory ContentProgressReference.fromJson(Map<String, Object?> json) {
    String? nonEmpty(Object? value) {
      if (value is! String || value.trim().isEmpty) return null;
      return value.trim();
    }

    return ContentProgressReference(
      ownerScope: nonEmpty(json['ownerScope']) ?? 'unscoped',
      contentId: nonEmpty(json['contentId']),
      legacyKey: nonEmpty(json['legacyKey']),
    );
  }

  Map<String, Object?> toJson() => {
    'ownerScope': ownerScope,
    if (contentId != null) 'contentId': contentId,
    if (legacyKey != null) 'legacyKey': legacyKey,
  };

  ContentProgressReference resolveLegacy(Map<String, String> legacyMapping) {
    if (contentId != null || legacyKey == null) return this;
    final resolved = legacyMapping[legacyKey];
    if (resolved == null) return this;
    return ContentProgressReference(
      ownerScope: ownerScope,
      contentId: resolved,
      legacyKey: legacyKey,
    );
  }
}
