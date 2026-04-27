import 'package:freezed_annotation/freezed_annotation.dart';

part 'irregular_verb.freezed.dart';
part 'irregular_verb.g.dart';

@freezed
class IrregularVerb with _$IrregularVerb {
  const factory IrregularVerb({
    @JsonKey(name: 'base_form') required String v1,
    @JsonKey(name: 'v2') required String v2,
    @JsonKey(name: 'v3') required String v3,
    @JsonKey(name: 'meaning_tr') required String meaningTr,
  }) = _IrregularVerb;

  const IrregularVerb._();

  factory IrregularVerb.fromJson(Map<String, dynamic> json) =>
      _$IrregularVerbFromJson(json);

  String get pattern {
    final cleanV1 = v1.toLowerCase().trim();
    final cleanV2 = v2.toLowerCase().trim();
    final cleanV3 = v3.toLowerCase().trim();

    if (cleanV1 == cleanV2 && cleanV2 == cleanV3) return 'AAA';
    if (cleanV2 == cleanV3) return 'ABB';
    if (cleanV1 == cleanV3) return 'ABA';
    if (cleanV1 == cleanV2) return 'AAB';
    return 'ABC';
  }

  String get patternDescription {
    switch (pattern) {
      case 'AAA':
        return 'Tüm formlar aynı';
      case 'ABB':
        return 'V2 ve V3 aynı';
      case 'ABA':
        return 'V1 ve V3 aynı';
      case 'AAB':
        return 'V1 ve V2 aynı';
      case 'ABC':
        return 'Tüm formlar farklı';
      default:
        return 'Karışık';
    }
  }
}
