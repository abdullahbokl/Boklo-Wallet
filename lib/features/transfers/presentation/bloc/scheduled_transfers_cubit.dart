import 'dart:async';

import 'package:boklo/core/base/base_cubit.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/transfers/data/repositories/scheduled_transfer_repository_impl.dart';
import 'package:boklo/features/transfers/domain/entities/scheduled_transfer_entity.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@injectable
class ScheduledTransfersCubit extends BaseCubit<List<ScheduledTransferEntity>> {
  ScheduledTransfersCubit(this._repository) : super(const BaseState.initial());

  final ScheduledTransferRepository _repository;
  StreamSubscription<Either<Failure, List<ScheduledTransferEntity>>>? _sub;

  void load() {
    emitLoading();
    unawaited(_sub?.cancel());
    _sub = _repository.watchSchedules().listen((result) {
      result.fold(emitError, emitSuccess);
    });
  }

  Future<bool> cancel(String id) async {
    final result = await _repository.cancelSchedule(id);
    return result.fold(
      (error) {
        emitError(error);
        return false;
      },
      (_) => true,
    );
  }

  @override
  Future<void> close() {
    unawaited(_sub?.cancel());
    return super.close();
  }
}
