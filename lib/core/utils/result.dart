import 'package:boklo/core/error/app_error.dart';

sealed class Result<T> {
  const Result();

  R fold<R>(
    R Function(AppError error) onFailure,
    R Function(T data) onSuccess,
  );
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  @override
  R fold<R>(
    R Function(AppError error) onFailure,
    R Function(T data) onSuccess,
  ) {
    return onSuccess(data);
  }
}

class Failure<T> extends Result<T> {
  final AppError error;
  const Failure(this.error);

  @override
  R fold<R>(
    R Function(AppError error) onFailure,
    R Function(T data) onSuccess,
  ) {
    return onFailure(error);
  }
}
