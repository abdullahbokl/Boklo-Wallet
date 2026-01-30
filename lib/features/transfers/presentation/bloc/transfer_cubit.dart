import 'dart:async';
import 'package:boklo/core/base/result.dart';
import 'package:boklo/core/base/base_cubit.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/config/feature_flags.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/core/services/analytics_service.dart';
import 'package:boklo/features/discovery/domain/usecases/resolve_wallet_by_email_usecase.dart';
import 'package:boklo/features/discovery/domain/usecases/resolve_wallet_by_username_usecase.dart';
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
    this._resolveWalletByUsernameUseCase,
    this._observeTransferStatusUseCase,
    this._analyticsService,
    this._featureFlags,
  ) : super(const BaseState.initial());

  final CreateTransferUseCase _createTransferUseCase;
  final RequestTransferUseCase _requestTransferUseCase;
  final ResolveWalletByEmailUseCase _resolveWalletByEmailUseCase;
  final ResolveWalletByUsernameUseCase _resolveWalletByUsernameUseCase;
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

        AppError? emailError;

        resolution.fold<void>(
          (error) => emailError = error,
          (id) => toWalletId = id,
        );

        if (emailError != null) {
          unawaited(
            _analyticsService.logTransferFailure(
              reason: emailError!.message,
            ),
          );
          emitError(emailError!);
          return;
        }
      } else if (recipient.length < 28 &&
          !recipient.contains(RegExp(r'[^a-zA-Z0-9_.]'))) {
        // 1.5 Resolve Recipient if Username (approx heuristic: short, valid chars)
        final resolution = await _resolveWalletByUsernameUseCase(recipient);

        AppError? usernameError;

        resolution.fold<void>(
          (error) => usernameError = error,
          (id) => toWalletId = id,
        );

        // If username resolution fails, we fall back to treating it as Wallet ID
        // (but only if it looks like a Wallet ID, which is usually 28 chars)
        // Actually, if it fails, we should probably fail?
        // But maybe "recipient" IS a Wallet ID?
        // If it's short, it's likely a username.

        if (usernameError != null) {
          // If it failed, check if it COULD be a wallet ID.
          // Wallet IDs are usually longer (20-30 chars).
          // Usernames are 3-20.
          // If it is 28 chars, it's likely a UID.
          // If it failed username resolution, and it's NOT a UID length, error out.
          if (recipient.length != 28) {
            unawaited(
              _analyticsService.logTransferFailure(
                reason: usernameError!.message,
              ),
            );
            emitError(usernameError!);
            return;
          }
          // If it IS 28 chars, ignore username error and try as Wallet ID
        }
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
    String transferId,
    double amount,
    String currency,
  ) async {
    try {
      final transfer = await _observeTransferStatusUseCase(transferId)
          .firstWhere(
            (t) =>
                t?.status == TransferStatus.completed ||
                t?.status == TransferStatus.failed,
          )
          .timeout(const Duration(seconds: 15));

      if (transfer?.status == TransferStatus.completed) {
        unawaited(
          _analyticsService.logTransferInitiated(
            amount: amount,
            currency: currency,
          ),
        );
        emitSuccess(const TransferState());
      } else {
        // Log detailed failure reason from backend
        final reason = transfer?.failureReason ?? 'Transfer failed on backend';
        unawaited(_analyticsService.logTransferFailure(reason: reason));

        // Emit error with the specific reason
        emitError(UnknownError(reason));
      }
    } on TimeoutException catch (_) {
      unawaited(
        _analyticsService.logTransferFailure(reason: 'Transfer timed out'),
      );
      emitError(const UnknownError('Transfer processing timed out'));
    } catch (e) {
      unawaited(
        _analyticsService.logTransferFailure(reason: e.toString()),
      );
      emitError(const UnknownError('Transfer processing failed'));
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
}
