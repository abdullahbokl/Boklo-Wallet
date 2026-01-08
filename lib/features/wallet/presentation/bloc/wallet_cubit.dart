import 'package:boklo/core/base/base_cubit.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/features/wallet/domain/usecases/get_transactions_usecase.dart';
import 'package:boklo/features/wallet/domain/usecases/get_wallet_usecase.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class WalletCubit extends BaseCubit<WalletState> {
  WalletCubit(
    this._getWalletUseCase,
    this._getTransactionsUseCase,
  ) : super(const BaseState.initial());

  final GetWalletUseCase _getWalletUseCase;
  final GetTransactionsUseCase _getTransactionsUseCase;

  Future<void> loadWallet() async {
    emitLoading();

    final walletResult = await _getWalletUseCase();

    walletResult.fold(
      emitError,
      (wallet) async {
        final transactionsResult = await _getTransactionsUseCase();

        transactionsResult.fold(
          emitError,
          (transactions) {
            emitSuccess(
              WalletState(
                wallet: wallet,
                transactions: transactions,
              ),
            );
          },
        );
      },
    );
  }
}
