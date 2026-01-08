import 'package:equatable/equatable.dart';

import 'package:boklo/core/error/app_error.dart';

sealed class Result<T> extends Equatable {
  const Result();

  R fold<R>(
    R Function(AppError error) onFailure,
    R Function(T data) onSuccess,
  );

  @override
  List<Object?> get props => [];
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

  @override
  List<Object?> get props => [data];
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

  @override
  List<Object?> get props => [error];
}
