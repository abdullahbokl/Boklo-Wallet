import 'package:boklo/core/error/app_error.dart';

sealed class Result<T> {
  const Result();

  R fold<R>(
    R Function(AppError error) onFailure,
    R Function(T data) onSuccess,
  );
}

class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;

  @override
  R fold<R>(
    R Function(AppError error) onFailure,
    R Function(T data) onSuccess,
  ) {
    return onSuccess(data);
  }
}

class Failure<T> extends Result<T> {
  const Failure(this.error);

  final AppError error;

  @override
  R fold<R>(
    R Function(AppError error) onFailure,
    R Function(T data) onSuccess,
  ) {
    return onFailure(error);
  }
}
