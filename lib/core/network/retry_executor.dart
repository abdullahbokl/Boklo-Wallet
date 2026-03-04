import 'dart:developer';
import 'dart:math' as math;

/// Executes async operations with exponential backoff retry.
///
/// Only retries on transient errors (network issues, server errors).
/// Business logic errors (insufficient balance, validation) are NOT retried.
///
/// Usage:
/// ```dart
/// final result = await RetryExecutor.run(
///   () => remoteDataSource.createTransfer(params),
/// );
/// ```
class RetryExecutor {
  /// Retries [action] up to [maxAttempts] times with exponential backoff + jitter.
  ///
  /// - [maxAttempts]: Total attempts (including first try). Default: 3.
  /// - [baseDelay]: Initial delay before first retry. Default: 1 second.
  /// - [shouldRetry]: Custom predicate to decide if an error is retryable.
  ///   Defaults to retrying only transient/network errors.
  static Future<T> run<T>(
    Future<T> Function() action, {
    int maxAttempts = 3,
    Duration baseDelay = const Duration(seconds: 1),
    bool Function(Exception)? shouldRetry,
  }) async {
    final retryCheck = shouldRetry ?? _isTransientError;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await action();
      } on Exception catch (e) {
        final isLastAttempt = attempt == maxAttempts;
        final isRetryable = retryCheck(e);

        if (isLastAttempt || !isRetryable) {
          log(
            '⚠️ RetryExecutor: Final failure after $attempt attempt(s)',
            name: 'RetryExecutor',
          );
          rethrow;
        }

        // Exponential backoff: baseDelay * 2^(attempt-1) + jitter
        final delay = baseDelay * math.pow(2, attempt - 1).toInt();
        final jitter = Duration(
          milliseconds: math.Random().nextInt(delay.inMilliseconds ~/ 2 + 1),
        );
        final totalDelay = delay + jitter;

        log(
          '🔄 RetryExecutor: Attempt $attempt failed. '
          'Retrying in ${totalDelay.inMilliseconds}ms...',
          name: 'RetryExecutor',
        );

        await Future<void>.delayed(totalDelay);
      }
    }

    // This should never be reached due to rethrow above
    throw StateError('RetryExecutor: Unexpected state');
  }

  /// Determines if an error is transient and worth retrying.
  ///
  /// Retries: network timeouts, server errors (5xx), connection refused.
  /// Does NOT retry: auth errors, validation errors, permission denied.
  static bool _isTransientError(Exception e) {
    final message = e.toString().toLowerCase();

    // Network-level errors
    if (message.contains('socketexception') ||
        message.contains('timeout') ||
        message.contains('connection refused') ||
        message.contains('connection reset') ||
        message.contains('network is unreachable') ||
        message.contains('handshake')) {
      return true;
    }

    // Firebase-specific transient errors
    if (message.contains('unavailable') ||
        message.contains('deadline-exceeded') ||
        message.contains('resource-exhausted') ||
        message.contains('internal')) {
      return true;
    }

    // Do NOT retry business logic errors
    if (message.contains('insufficient') ||
        message.contains('unauthenticated') ||
        message.contains('permission-denied') ||
        message.contains('not-found') ||
        message.contains('already-exists') ||
        message.contains('invalid-argument') ||
        message.contains('failed-precondition')) {
      return false;
    }

    // Default: don't retry unknown errors
    return false;
  }
}
