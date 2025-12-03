import 'dictionary_service.dart';

/// Stub factory function for web - should never be called
/// Web uses InMemoryDictionaryService instead
Future<DictionaryService> createIsarDictionaryService() async {
  throw UnsupportedError(
    'createIsarDictionaryService should not be called on web platform. '
    'Use InMemoryDictionaryService.create() instead.',
  );
}
