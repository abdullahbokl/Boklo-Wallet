import 'dart:async';
import 'package:boklo/core/base/base_cubit.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/base/result.dart';
import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:boklo/features/wallet/domain/usecases/get_transactions_usecase.dart';
import 'package:boklo/features/wallet/domain/usecases/watch_wallet_usecase.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class WalletCubit extends BaseCubit<WalletState> {
  WalletCubit(
    this._watchWalletUseCase,
    this._getTransactionsUseCase,
  ) : super(const BaseState.initial());

  final WatchWalletUseCase _watchWalletUseCase;
  final GetTransactionsUseCase _getTransactionsUseCase;

  StreamSubscription<Result<WalletEntity>>? _walletSubscription;
  StreamSubscription<Result<List<TransactionEntity>>>? _txSubscription;

  WalletEntity? _currentWallet;
  List<TransactionEntity> _lastTransactions = [];

  Future<void> loadWallet() async {
    emitLoading();

    // 1. Watch Wallet
    _walletSubscription?.cancel();
    _walletSubscription = _watchWalletUseCase().listen((result) {
      result.fold(
        emitError,
        (wallet) {
          _currentWallet = wallet;
          _emitMergedState();
        },
      );
    });

    // 2. Watch Transactions
    if (_txSubscription == null) {
      _txSubscription = _getTransactionsUseCase.watch().listen((result) {
        result.fold(
          (error) {
            // Log or handle error, but keep wallet visible if possible
            emitError(error);
          },
          (transactions) {
            _lastTransactions = transactions;
            _emitMergedState();
          },
        );
      });
    }
  }

  void _emitMergedState() {
    if (_currentWallet == null) return;

    final currentType = state.data?.filterType;
    final currentStatus = state.data?.filterStatus;

    final filtered =
        _applyFilters(_lastTransactions, currentType, currentStatus);

    emitSuccess(
      WalletState(
        wallet: _currentWallet!,
        transactions: filtered,
        filterType: currentType,
        filterStatus: currentStatus,
      ),
    );
  }

  void setFilterType(TransactionType? type) {
    if (_currentWallet == null) return;

    final currentStatus = state.data?.filterStatus;
    final filtered = _applyFilters(_lastTransactions, type, currentStatus);

    emitSuccess(
      WalletState(
        wallet: _currentWallet!,
        transactions: filtered,
        filterType: type,
        filterStatus: currentStatus,
      ),
    );
  }

  void setFilterStatus(TransactionStatus? status) {
    if (_currentWallet == null) return;

    final currentType = state.data?.filterType;
    final filtered = _applyFilters(_lastTransactions, currentType, status);

    emitSuccess(
      WalletState(
        wallet: _currentWallet!,
        transactions: filtered,
        filterType: currentType,
        filterStatus: status,
      ),
    );
  }

  void clearFilters() {
    if (_currentWallet == null) return;

    emitSuccess(
      WalletState(
        wallet: _currentWallet!,
        transactions: _lastTransactions,
        filterType: null,
        filterStatus: null,
      ),
    );
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
    _walletSubscription?.cancel();
    _txSubscription?.cancel();
    return super.close();
  }
}
