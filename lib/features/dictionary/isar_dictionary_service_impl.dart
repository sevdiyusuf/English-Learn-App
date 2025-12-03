import 'dictionary_service.dart';
import 'isar_dictionary_service.dart';
import 'load_dictionary.dart';

/// Factory function to create IsarDictionaryService
/// Only used on non-web platforms
Future<DictionaryService> createIsarDictionaryService() async {
  final isar = await openDictionaryStore();
  if (isar == null) {
    throw StateError('Isar instance is null on non-web platform');
  }
  return IsarDictionaryService(isar);
}
