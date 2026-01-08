import 'dart:async';

import 'package:boklo/core/base/base_cubit.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/core/services/analytics_service.dart';
import 'package:boklo/features/discovery/domain/usecases/resolve_wallet_by_email_usecase.dart';
import 'package:boklo/features/transfers/domain/entities/transfer_entity.dart';
import 'package:boklo/features/transfers/domain/usecases/create_transfer_usecase.dart';
import 'package:boklo/features/transfers/presentation/bloc/transfer_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class TransferCubit extends BaseCubit<TransferState> {
  TransferCubit(
    this._createTransferUseCase,
    this._resolveWalletByEmailUseCase,
    this._analyticsService,
  ) : super(const BaseState.initial());

  final CreateTransferUseCase _createTransferUseCase;
  final ResolveWalletByEmailUseCase _resolveWalletByEmailUseCase;
  final AnalyticsService _analyticsService;

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
        final resolvedId = resolution.fold(
          (error) => null, // Handle error below
          (id) => id,
        );

        if (resolvedId == null) {
          const error = ValidationError('Recipient email not found');
          unawaited(
            _analyticsService.logTransferFailure(reason: error.message),
          );
          emitError(error);
          return;
        }
        toWalletId = resolvedId;
      }

      // 2. Create Entity
      final transfer = TransferEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fromWalletId: fromWalletId,
        toWalletId: toWalletId,
        amount: amount,
        currency: currency,
        status: TransferStatus.pending,
        createdAt: DateTime.now(),
      );

      // 3. Execute
      final result = await _createTransferUseCase(transfer);

      result.fold(
        (error) {
          unawaited(
            _analyticsService.logTransferFailure(reason: error.message),
          );
          emitError(error);
        },
        (_) {
          unawaited(
            _analyticsService.logTransferSuccess(
              amount: amount,
              currency: currency,
            ),
          );
          emitSuccess(const TransferState());
        },
      );
      // Map generic exceptions to AppError
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      unawaited(_analyticsService.logTransferFailure(reason: e.toString()));
      emitError(const UnknownError('An unexpected error occurred'));
    }
  }
}
