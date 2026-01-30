import 'dart:async';
import 'dart:developer';
import 'package:boklo/core/base/base_cubit.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/base/result.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:boklo/features/wallet/domain/usecases/get_transactions_usecase.dart';
import 'package:boklo/features/wallet/domain/usecases/provision_wallet_usecase.dart';
import 'package:boklo/features/wallet/domain/usecases/watch_wallet_usecase.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class WalletCubit extends BaseCubit<WalletState> {
  WalletCubit(
    this._watchWalletUseCase,
    this._getTransactionsUseCase,
    this._provisionWalletUseCase,
  ) : super(const BaseState.initial());

  final WatchWalletUseCase _watchWalletUseCase;
  final GetTransactionsUseCase _getTransactionsUseCase;
  final ProvisionWalletUseCase _provisionWalletUseCase;

  StreamSubscription<Result<WalletEntity>>? _walletSubscription;
  StreamSubscription<Result<List<TransactionEntity>>>? _txSubscription;
  Timer? _provisionTimer;
  Timer? _timeoutTimer;
  bool _hasCalledProvision = false;
  bool _walletReceived = false;

  WalletEntity? _currentWallet;
  List<TransactionEntity> _lastTransactions = [];

  Future<void> loadWallet() async {
    emitLoading();
    _hasCalledProvision = false;
    _walletReceived = false;

    log('🔄 WalletCubit: Starting wallet load...');

    // 1. Start watching wallet stream
    _walletSubscription?.cancel();
    _walletSubscription = _watchWalletUseCase().listen((result) {
      result.fold(
        emitError,
        (wallet) {
          _walletReceived = true;
          _currentWallet = wallet;
          _cancelTimers();
          log('✅ WalletCubit: Wallet received');
          _emitMergedState();
        },
      );
    });

    // 2. If wallet not received after 3 seconds, call provisionWallet (once)
    _provisionTimer = Timer(const Duration(seconds: 3), () {
      if (!_walletReceived && !_hasCalledProvision) {
        log('⏱️ WalletCubit: Wallet not received after 3s, calling provision...');
        _callProvisionWallet();
      }
    });

    // 3. Final timeout after 15 seconds
    _timeoutTimer = Timer(const Duration(seconds: 15), () {
      if (!_walletReceived) {
        log('❌ WalletCubit: Wallet not received after 15s timeout');
        emitError(const UnknownError(
          'Wallet setup is taking longer than expected. '
          'Please try logging out and back in.',
        ));
      }
    });

    // 4. Watch Transactions in parallel
    if (_txSubscription == null) {
      _txSubscription = _getTransactionsUseCase.watch().listen((result) {
        result.fold(
          (error) {
            // Log error but don't block wallet display
            log('⚠️ WalletCubit: Transaction error: $error');
          },
          (transactions) {
            _lastTransactions = transactions;
            _emitMergedState();
          },
        );
      });
    }
  }

  Future<void> _callProvisionWallet() async {
    if (_hasCalledProvision) return;
    _hasCalledProvision = true;

    log('🔧 WalletCubit: Calling provisionWallet...');
    final result = await _provisionWalletUseCase();
    result.fold(
      (error) {
        log('❌ WalletCubit: provisionWallet failed: $error');
        // Don't emit error, the timeout will handle it
      },
      (_) {
        log('✅ WalletCubit: provisionWallet succeeded, waiting for stream...');
        // The wallet stream should now emit the wallet
      },
    );
  }

  void _cancelTimers() {
    _provisionTimer?.cancel();
    _timeoutTimer?.cancel();
    _provisionTimer = null;
    _timeoutTimer = null;
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
    _cancelTimers();
    return super.close();
  }
}
