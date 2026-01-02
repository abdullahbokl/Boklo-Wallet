import 'package:bloc/bloc.dart';
import 'package:boklo/core/error/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'base_bloc.freezed.dart';

@freezed
class BaseState<T> with _$BaseState<T> {
  const factory BaseState.initial() = _Initial;
  const factory BaseState.loading() = _Loading;
  const factory BaseState.success(T data) = _Success;
  const factory BaseState.error(Failure failure) = _Error;
}

abstract class BaseCubit<T> extends Cubit<BaseState<T>> {
  BaseCubit(super.initialState);

  void safeEmit(BaseState<T> state) {
    if (!isClosed) {
      emit(state);
    }
  }

  Future<void> runBlocCatching<R>({
    required Future<Either<Failure, T>> Function() action,
    void Function(T data)? onSuccess,
    void Function(Failure failure)? onError,
    bool doOnSuccessOrError = true,
  }) async {
    safeEmit(const BaseState.loading());
    final result = await action();
    result.fold(
      (failure) {
        if (doOnSuccessOrError) safeEmit(BaseState.error(failure));
        onError?.call(failure);
      },
      (data) {
        if (doOnSuccessOrError) safeEmit(BaseState.success(data));
        onSuccess?.call(data);
      },
    );
  }
}
