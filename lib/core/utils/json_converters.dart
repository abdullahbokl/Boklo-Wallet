import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

class TimestampConverter implements JsonConverter<DateTime, Object> {
  const TimestampConverter();

  @override
  DateTime fromJson(Object json) {
    if (json is Timestamp) {
      return json.toDate();
    } else if (json is String) {
      return DateTime.parse(json);
    } else if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json);
    }
    // Never fabricate a financial timestamp: surface malformed data as a
    // mapping failure instead.
    throw FormatException('Unsupported timestamp value: $json');
  }

  @override
  Object toJson(DateTime object) => object.millisecondsSinceEpoch;
}
