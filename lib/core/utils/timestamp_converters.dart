import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

class TimestampConverter extends JsonConverter<DateTime?, Object?> {
  const TimestampConverter();

  @override
  DateTime? fromJson(Object? json) {
    if (json == null) {
      return null;
    }
    if (json is Timestamp) {
      return json.toDate();
    }
    if (json is DateTime) {
      return json;
    }
    return DateTime.tryParse(json.toString());
  }

  @override
  Object? toJson(DateTime? object) {
    if (object == null) {
      return null;
    }
    return Timestamp.fromDate(object.toUtc());
  }
}
