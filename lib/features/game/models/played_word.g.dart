// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'played_word.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlayedWordImpl _$$PlayedWordImplFromJson(Map<String, dynamic> json) =>
    _$PlayedWordImpl(
      word: json['word'] as String,
      type: const WordTypeConverter().fromJson(json['type'] as String),
      byUid: json['byUid'] as String,
      at: DateTime.parse(json['at'] as String),
    );

Map<String, dynamic> _$$PlayedWordImplToJson(_$PlayedWordImpl instance) =>
    <String, dynamic>{
      'word': instance.word,
      'type': const WordTypeConverter().toJson(instance.type),
      'byUid': instance.byUid,
      'at': instance.at.toIso8601String(),
    };
