import 'package:boklo/core/error/app_error.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'base_state.freezed.dart';

/// A generic, immutable state wrapper for Clean Architecture.
///
/// Design Decisions:
/// 1. [Freezed]: Ensures immutability and generates consistent `copyWith`/`toString`.
/// 2. [Sealed Class]: Enforces exhaustive matching (switch cases must handle all states).
/// 3. [Generic T]: Allows reusability across any feature (Auth, Products, etc.) without code duplication.
/// 4. [AppError]: Enforces strongly-typed error handling instead of generic Strings or Exceptions.
@freezed
class BaseState<T> with _$BaseState<T> {
  /// Initial state before any action is triggered.
  const factory BaseState.initial() = _Initial;

  /// Loading state indicating an ongoing asynchronous operation.
  const factory BaseState.loading() = _Loading;

  /// Success state carrying the resulting data [T].
  const factory BaseState.success(T data) = _Success;

  /// Error state carrying a specific [AppError].
  const factory BaseState.error(AppError error) = _Error;
}

extension BaseStateX<T> on BaseState<T> {
  bool get isLoading => maybeMap(loading: (_) => true, orElse: () => false);
  bool get isSuccess => maybeMap(success: (_) => true, orElse: () => false);
  bool get isError => maybeMap(error: (_) => true, orElse: () => false);
  AppError? get error =>
      maybeMap(error: (state) => state.error, orElse: () => null);
  T? get data => maybeMap(success: (state) => state.data, orElse: () => null);
}
