import 'package:equatable/equatable.dart';

sealed class AppError extends Equatable implements Exception {
  const AppError(this.message, [this.cause]);
  final String message;
  final dynamic cause;

  @override
  List<Object?> get props => [message, cause];
}

class NetworkError extends AppError {
  const NetworkError(super.message, [super.cause]);
}

class CacheError extends AppError {
  const CacheError(super.message, [super.cause]);
}

class FirebaseError extends AppError {
  const FirebaseError(super.message, this.code, [super.cause]);

  final String code;

  @override
  List<Object?> get props => [...super.props, code];
}

class DatabaseError extends AppError {
  const DatabaseError(super.message, [super.cause]);
}

class ValidationError extends AppError {
  const ValidationError(super.message, [super.cause]);
}

class UnknownError extends AppError {
  const UnknownError(super.message, [super.cause]);
}
