import 'dart:async';
import 'package:boklo/core/base/result.dart';
import 'package:boklo/core/base/base_cubit.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/config/feature_flags.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/core/services/analytics_service.dart';
import 'package:boklo/features/discovery/domain/usecases/resolve_wallet_by_email_usecase.dart';
import 'package:boklo/features/transfers/domain/entities/transfer_entity.dart';
import 'package:boklo/features/transfers/domain/usecases/create_transfer_usecase.dart';
import 'package:boklo/features/transfers/domain/usecases/request_transfer_usecase.dart';
import 'package:boklo/features/transfers/domain/usecases/observe_transfer_status_usecase.dart';
import 'package:boklo/features/transfers/presentation/bloc/transfer_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class TransferCubit extends BaseCubit<TransferState> {
  TransferCubit(
    this._createTransferUseCase,
    this._requestTransferUseCase,
    this._resolveWalletByEmailUseCase,
    this._observeTransferStatusUseCase,
    this._analyticsService,
    this._featureFlags,
  ) : super(const BaseState.initial());

  final CreateTransferUseCase _createTransferUseCase;
  final RequestTransferUseCase _requestTransferUseCase;
  final ResolveWalletByEmailUseCase _resolveWalletByEmailUseCase;
  final ObserveTransferStatusUseCase _observeTransferStatusUseCase;
  final AnalyticsService _analyticsService;
  final FeatureFlags _featureFlags;

  DateTime? _lastExecution;
  static const _minTransferInterval = Duration(seconds: 2);

  Future<void> createTransfer({
    required String fromWalletId,
    required String recipient,
    required double amount,
    required String currency,
  }) async {
    // 0. Rate Limit
    final now = DateTime.now();
    if (_lastExecution != null &&
        now.difference(_lastExecution!) < _minTransferInterval) {
      // Silently ignore or show error
      emitError(const ValidationError('Please wait before trying again'));
      return;
    }
    _lastExecution = now;

    emitLoading();

    try {
      var toWalletId = recipient;

      // 1. Resolve Recipient if Email
      if (recipient.contains('@')) {
        final resolution = await _resolveWalletByEmailUseCase(recipient);

        AppError? resolutionError;

        final resolvedId = resolution.fold(
          (error) {
            resolutionError = error;
            return null;
          },
          (id) => id,
        );

        if (resolutionError != null) {
          unawaited(
            _analyticsService.logTransferFailure(
              reason: resolutionError!.message,
            ),
          );
          emitError(resolutionError!);
          return;
        }
        toWalletId = resolvedId!;
      }

      if (_featureFlags.backendAuthoritativeTransfers) {
        // --- NEW FLOW: Request Transfer (Backend Authoritative) ---
        // 1. Validate & Create Entity via UseCase (fetches wallets internally)
        final requestResult = await _requestTransferUseCase(
          fromWalletId: fromWalletId,
          toWalletId: toWalletId,
          amount: amount,
        );

        await requestResult.fold(
          (error) {
            unawaited(
                _analyticsService.logTransferFailure(reason: error.message));
            emitError(error);
          },
          (transfer) async {
            // 2. Persist Transfer
            // Note: createTransferUseCase calls repo.createTransfer which might re-validate.
            // This is acceptable redundancy for safety.
            final persistResult = await _createTransferUseCase(transfer);

            await persistResult.fold(
              (error) {
                unawaited(_analyticsService.logTransferFailure(
                    reason: error.message));
                emitError(error);
              },
              (_) async {
                // 3. Wait for Backend Completion
                await _waitForBackendResult(transfer.id, amount, currency);
              },
            );
          },
        );
      } else {
        // --- OLD FLOW: Legacy Manual Creation ---
        // 1. Create Entity Manually
        final transfer = TransferEntity(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          fromWalletId: fromWalletId,
          toWalletId: toWalletId,
          amount: amount,
          currency: currency,
          status: TransferStatus.pending,
          createdAt: DateTime.now(),
        );

        // 2. Persist Transfer
        final persistResult = await _createTransferUseCase(transfer);
        _handlePersistenceResult(persistResult, amount, currency);
      }
    } catch (e) {
      unawaited(_analyticsService.logTransferFailure(reason: e.toString()));
      emitError(const UnknownError('An unexpected error occurred'));
    }
  }

  Future<void> _waitForBackendResult(
      String transferId, double amount, String currency) async {
    try {
      final status = await _observeTransferStatusUseCase(transferId)
          .firstWhere(
            (s) => s == TransferStatus.completed || s == TransferStatus.failed,
          )
          .timeout(const Duration(seconds: 15));

      if (status == TransferStatus.completed) {
        unawaited(_analyticsService.logTransferInitiated(
            amount: amount, currency: currency));
        emitSuccess(const TransferState());
      } else {
        unawaited(_analyticsService.logTransferFailure(
            reason: 'Transfer failed on backend'));
        emitError(const UnknownError('Transfer processing failed'));
      }
    } catch (e) {
      unawaited(
          _analyticsService.logTransferFailure(reason: 'Transfer timed out'));
      // We emit error, but maybe we should show "Processing..."?
      // For now, adhere to "React to COMPLETED and FAILED states".
      emitError(const UnknownError('Transfer processing timed out'));
    }
  }

  void _handlePersistenceResult(
    Result<void> result,
    double amount,
    String currency,
  ) {
    result.fold(
      (error) {
        unawaited(
          _analyticsService.logTransferFailure(reason: error.message),
        );
        emitError(error);
      },
      (_) {
        // Success (Pending)
        unawaited(
          _analyticsService.logTransferInitiated(
            amount: amount,
            currency: currency,
          ),
        );
        emitSuccess(const TransferState());
      },
    );
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
