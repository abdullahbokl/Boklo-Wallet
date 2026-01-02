sealed class AppError implements Exception {
  const AppError(this.message, [this.cause]);
  final String message;
  final dynamic cause;
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
}

class UnknownError extends AppError {
  const UnknownError(super.message, [super.cause]);
}
