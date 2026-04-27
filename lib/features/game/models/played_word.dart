import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/timestamp_converters.dart';

part 'played_word.freezed.dart';
part 'played_word.g.dart';

enum WordType { verb, adjective, noun, adverb, word }

class WordTypeConverter extends JsonConverter<WordType, String> {
  const WordTypeConverter();

  @override
  WordType fromJson(String json) {
    final lower = json.toLowerCase();
    return WordType.values.firstWhere(
      (value) => value.name == lower,
      orElse: () => WordType.word,
    );
  }

  @override
  String toJson(WordType object) => object.name;
}

@freezed
class PlayedWord with _$PlayedWord {
  const factory PlayedWord({
    required String word,
    @WordTypeConverter() required WordType type,
    required String byUid,
    @TimestampConverter() required DateTime at,
  }) = _PlayedWord;

  factory PlayedWord.fromJson(Map<String, dynamic> json) =>
      _$PlayedWordFromJson(json);
}
