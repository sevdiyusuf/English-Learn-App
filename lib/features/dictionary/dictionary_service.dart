import 'package:flutter/foundation.dart';

// Conditional imports: Different implementations for web vs non-web
import 'in_memory_dictionary_service.dart';
import 'isar_dictionary_service_stub.dart'
    if (dart.library.io) 'isar_dictionary_service_impl.dart';

/// Dictionary service interface
abstract class DictionaryService {
  Future<bool> validateWord({required String word, required String type});
}

/// Platform-agnostic dictionary service factory
Future<DictionaryService> createDictionaryService() async {
  if (kIsWeb) {
    return await InMemoryDictionaryService.create();
  } else {
    // createIsarDictionaryService is defined in isar_dictionary_service_impl.dart
    // For web, it's a stub that throws (but never called)
    return await createIsarDictionaryService();
  }
}
