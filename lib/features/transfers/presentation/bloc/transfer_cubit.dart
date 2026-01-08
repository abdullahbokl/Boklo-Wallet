import 'package:boklo/core/base/base_cubit.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/features/transfers/domain/entities/transfer_entity.dart';
import 'package:boklo/features/transfers/domain/usecases/create_transfer_usecase.dart';
import 'package:boklo/features/transfers/presentation/bloc/transfer_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class TransferCubit extends BaseCubit<TransferState> {
  TransferCubit(
    this._createTransferUseCase,
  ) : super(const BaseState.initial());

  final CreateTransferUseCase _createTransferUseCase;

  Future<void> createTransfer(TransferEntity transfer) async {
    emitLoading();

    try {
      final result = await _createTransferUseCase(transfer);

      result.fold(
        (error) => emitError(error),
        (_) => emitSuccess(const TransferState()),
      );
    } catch (e) {
      // Fallback for unexpected errors not caught by the repository
      emitError(const UnknownError('An unexpected error occurred'));
    }
  }
}
