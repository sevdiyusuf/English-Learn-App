// This file is only used on non-web platforms
import 'package:isar/isar.dart';

import 'dictionary_service.dart';
import 'models/dict_entry.dart';

/// Isar-based dictionary service (for non-web platforms)
class IsarDictionaryService implements DictionaryService {
  IsarDictionaryService(this._isar);

  final Isar _isar;

  @override
  Future<bool> validateWord({
    required String word,
    required String type,
  }) async {
    final normalizedWord = word.toLowerCase().trim();
    final normalizedType = type.toLowerCase().trim();

    final found =
        await _isar.dictEntrys
            .filter()
            .wordEqualTo(normalizedWord)
            .and()
            .typeEqualTo(normalizedType)
            .findFirst();

    return found != null;
  }
}
