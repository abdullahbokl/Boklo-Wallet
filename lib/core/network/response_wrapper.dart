import 'package:json_annotation/json_annotation.dart';

part 'response_wrapper.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class ResponseWrapper<T> {
  final bool success;
  final String? message;
  final T? data;

  const ResponseWrapper({
    this.success = false,
    this.message,
    this.data,
  });

  factory ResponseWrapper.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$ResponseWrapperFromJson(json, fromJsonT);
}
