import 'package:boklo/core/base/base_cubit.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/features/transfers/domain/entities/transfer_entity.dart';
import 'package:boklo/features/transfers/domain/usecases/create_transfer_usecase.dart';
import 'package:boklo/features/transfers/presentation/bloc/transfer_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class TransferCubit extends BaseCubit<TransferState> {
  TransferCubit(
    this._createTransferUseCase,
    this._navigationService,
    this._snackbarService,
  ) : super(const BaseState.initial());

  final CreateTransferUseCase _createTransferUseCase;
  final NavigationService _navigationService;
  final SnackbarService _snackbarService;

  Future<void> createTransfer(TransferEntity transfer) async {
    emitLoading();

    final result = await _createTransferUseCase(transfer);

    result.fold(
      (error) {
        emitError(error);
        _snackbarService.showError(error.message);
      },
      (_) {
        emitSuccess(const TransferState());
        _snackbarService.showSuccess('Transfer successful!');
        _navigationService.pop(true);
      },
    );
  }
}
