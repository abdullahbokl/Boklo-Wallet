import 'package:bloc/bloc.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/core/base/result.dart';

/// A generic base class for Cubits that adhere to Clean Architecture.
///
/// Wraps state in [BaseState] and provides helper methods for safe emission
/// and result handling.
abstract class BaseCubit<T> extends Cubit<BaseState<T>> {
  BaseCubit(super.initialState);

  /// Emits [BaseState.loading].
  void emitLoading() => safeEmit(BaseState<T>.loading());

  /// Emits [BaseState.success] with the provided [data].
  void emitSuccess(T data) => safeEmit(BaseState<T>.success(data));

  /// Emits [BaseState.error] with the provided [error].
  void emitError(AppError error) => safeEmit(BaseState<T>.error(error));

  /// Safely emits a state if the Cubit is not closed.
  void safeEmit(BaseState<T> state) {
    if (!isClosed) {
      emit(state);
    }
  }

  /// Executes a [Future] returning [Result] and handles state emission automatically.
  ///
  /// 1. Emits [BaseState.loading].
  /// 2. Awaits [action].
  /// 3. Emits [BaseState.success] or [BaseState.error] based on the result.
  Future<void> runBlocCatching<R>({
    required Future<Result<T>> Function() action,
    void Function(T data)? onSuccess,
    void Function(AppError error)? onError,
    bool doOnSuccessOrError = true,
  }) async {
    emitLoading();
    final result = await action();
    result.fold(
      (error) {
        if (doOnSuccessOrError) emitError(error);
        onError?.call(error);
      },
      (data) {
        if (doOnSuccessOrError) emitSuccess(data);
        onSuccess?.call(data);
      },
    );
  }
}
