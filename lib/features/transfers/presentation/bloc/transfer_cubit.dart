import 'dart:async';

import 'package:boklo/core/base/base_cubit.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/error/failures.dart';
import 'package:boklo/core/services/analytics_service.dart';
import 'package:boklo/features/transfers/domain/entities/transfer_entity.dart';
import 'package:boklo/features/transfers/domain/usecases/create_transfer_usecase.dart';
import 'package:boklo/features/transfers/domain/usecases/observe_transfer_status_usecase.dart';
import 'package:boklo/features/transfers/domain/usecases/request_transfer_usecase.dart';
import 'package:boklo/features/transfers/domain/usecases/resolve_recipient_usecase.dart';
import 'package:boklo/features/transfers/presentation/bloc/transfer_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class TransferCubit extends BaseCubit<TransferState> {
  TransferCubit(
    this._createTransferUseCase,
    this._requestTransferUseCase,
    this._resolveRecipientUseCase,
    this._observeTransferStatusUseCase,
    this._analyticsService,
  ) : super(const BaseState.initial());

  final CreateTransferUseCase _createTransferUseCase;
  final RequestTransferUseCase _requestTransferUseCase;
  final ResolveRecipientUseCase _resolveRecipientUseCase;
  final ObserveTransferStatusUseCase _observeTransferStatusUseCase;
  final AnalyticsService _analyticsService;

  DateTime? _lastExecution;
  static const _minTransferInterval = Duration(seconds: 2);

  Future<void> createTransfer({
    required String fromWalletId,
    required String recipient,
    required int amount,
    required String currency,
  }) async {
    // 0. Rate Limit
    final now = DateTime.now();
    if (_lastExecution != null &&
        now.difference(_lastExecution!) < _minTransferInterval) {
      // Silently ignore or show error
      emitError(const ValidationFailure('Please wait before trying again'));
      return;
    }
    _lastExecution = now;

    emitLoading();

    try {
      // 1. Resolve Recipient
      final resolutionResult = await _resolveRecipientUseCase(recipient);

      var toWalletId = recipient;
      Failure? resolutionError;

      resolutionResult.fold(
        (error) => resolutionError = error,
        (id) => toWalletId = id,
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

      // --- Request Transfer (backend authoritative) ---
      // 1. Validate & create the transfer entity via the use case. A
      // uuid id is minted here and doubles as the Firestore document id,
      // which makes retries idempotent.
      final requestResult = await _requestTransferUseCase(
        fromWalletId: fromWalletId,
        toWalletId: toWalletId,
        amount: amount,
      );

      await requestResult.fold(
        (error) async {
          unawaited(
            _analyticsService.logTransferFailure(reason: error.message),
          );
          emitError(error);
        },
        (transfer) async {
          // 2. Persist Transfer
          // Note: createTransferUseCase calls repo.createTransfer which
          // might re-validate.
          // This is acceptable redundancy for safety.
          final persistResult = await _createTransferUseCase(transfer);

          await persistResult.fold(
            (error) async {
              unawaited(
                _analyticsService.logTransferFailure(
                  reason: error.message,
                ),
              );
              emitError(error);
            },
            (_) async {
              // 3. Wait for Backend Completion
              await _waitForBackendResult(transfer, amount, currency);
            },
          );
        },
      );
    } on Object catch (e) {
      unawaited(_analyticsService.logTransferFailure(reason: e.toString()));
      emitError(const UnknownFailure('An unexpected error occurred'));
    }
  }

  Future<void> _waitForBackendResult(
    TransferEntity requestedTransfer,
    int amount,
    String currency,
  ) async {
    final transferId = requestedTransfer.id;
    try {
      final transferOrFailure = await _observeTransferStatusUseCase(transferId)
          .firstWhere(
            (either) => either.fold(
              (l) => true,
              (t) {
                if (t == null) return false;
                // Terminal statuses
                final isTerminal =
                    t.status == TransferStatus.completed ||
                    t.status == TransferStatus.failed;
                if (isTerminal) return true;

                // Risk Block (ENFORCE)
                if (t.riskMode == 'ENFORCE' &&
                    (t.reasons?.isNotEmpty ?? false)) {
                  return true;
                }
                return false;
              },
            ),
          )
          .timeout(const Duration(seconds: 15));

      transferOrFailure.fold(
        (failure) {
          final reason = failure.message;
          unawaited(_analyticsService.logTransferFailure(reason: reason));
          emitError(UnknownFailure(reason));
        },
        (transfer) {
          if (transfer?.status == TransferStatus.completed) {
            unawaited(
              _analyticsService.logTransferInitiated(
                amount: amount,
                currency: currency,
              ),
            );
            emitSuccess(TransferState(completedTransfer: transfer));
          } else {
            // Check for risk enforcement reasons first
            var reason = 'Transfer failed';

            if (transfer?.riskMode == 'ENFORCE' &&
                (transfer?.reasons?.isNotEmpty ?? false)) {
              reason = transfer!.reasons!.join('. ');
            } else {
              reason = transfer?.failureReason ?? 'Transfer failed on backend';
            }

            unawaited(_analyticsService.logTransferFailure(reason: reason));
            emitError(UnknownFailure(reason));
          }
        },
      );
    } on TimeoutException catch (_) {
      unawaited(
        _analyticsService.logTransferFailure(reason: 'Transfer timed out'),
      );
      emitError(const UnknownFailure('Transfer processing timed out'));
    } on Object catch (e) {
      unawaited(
        _analyticsService.logTransferFailure(reason: e.toString()),
      );
      emitError(const UnknownFailure('Transfer processing failed'));
    }
  }
}
