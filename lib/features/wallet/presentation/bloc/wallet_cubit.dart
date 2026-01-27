import 'dart:async';
import 'package:boklo/core/base/base_cubit.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/base/result.dart';
import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
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

  StreamSubscription<Result<List<TransactionEntity>>>? _txSubscription;
  List<TransactionEntity> _lastTransactions = [];

  Future<void> loadWallet() async {
    emitLoading();

    // 1. Fetch Wallet (Future)
    final walletResult = await _getWalletUseCase();

    walletResult.fold(
      emitError,
      (wallet) {
        // 2. Setup Stream Subscription if not active
        if (_txSubscription == null) {
          _txSubscription = _getTransactionsUseCase.watch().listen((result) {
            result.fold(
              (error) {
                // Should we emit error state?
                // If we do, we lose the wallet view.
                // But typically if transactions fail, we show error.
                emitError(error);
              },
              (transactions) {
                _lastTransactions = transactions;
                // We need the current wallet to emit state.
                // We can cache it locally or read from state.
                WalletEntity? currentWallet;
                currentWallet = state.data?.wallet;

                // Use the wallet from the closure if state is not yet Success (initial load)
                currentWallet ??= wallet;

                final currentType = state.data?.filterType;
                final currentStatus = state.data?.filterStatus;

                final filtered = _applyFilters(
                    _lastTransactions, currentType, currentStatus);

                emitSuccess(
                  WalletState(
                    wallet: currentWallet,
                    transactions: filtered,
                    filterType: currentType,
                    filterStatus: currentStatus,
                  ),
                );
              },
            );
          });
        } else {
          // 3. Refresh: Use new wallet and cached transactions
          final currentType = state.data?.filterType;
          final currentStatus = state.data?.filterStatus;
          final filtered =
              _applyFilters(_lastTransactions, currentType, currentStatus);

          emitSuccess(
            WalletState(
              wallet: wallet,
              transactions: filtered,
              filterType: currentType,
              filterStatus: currentStatus,
            ),
          );
        }
      },
    );
  }

  void setFilterType(TransactionType? type) {
    if (state.data == null) return;

    final currentStatus = state.data!.filterStatus;
    final filtered = _applyFilters(_lastTransactions, type, currentStatus);

    emitSuccess(state.data!.copyWith(
      filterType: type,
      transactions: filtered,
    ));
  }

  void setFilterStatus(TransactionStatus? status) {
    if (state.data == null) return;

    final currentType = state.data!.filterType;
    final filtered = _applyFilters(_lastTransactions, currentType, status);

    emitSuccess(state.data!.copyWith(
      filterStatus: status,
      transactions: filtered,
    ));
  }

  void clearFilters() {
    if (state.data == null) return;

    emitSuccess(state.data!.copyWith(
      filterType: null,
      filterStatus: null,
      transactions: _lastTransactions,
    ));
  }

  List<TransactionEntity> _applyFilters(List<TransactionEntity> transactions,
      TransactionType? type, TransactionStatus? status) {
    return transactions.where((tx) {
      if (type != null && tx.type != type) return false;
      if (status != null && tx.status != status) return false;
      return true;
    }).toList();
  }

  @override
  Future<void> close() {
    _txSubscription?.cancel();
    return super.close();
  }
}
