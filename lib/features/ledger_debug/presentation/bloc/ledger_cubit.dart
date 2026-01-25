import 'dart:async';

import 'package:boklo/features/ledger_debug/domain/repositories/ledger_repository.dart';
import 'package:boklo/features/ledger_debug/presentation/bloc/ledger_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class LedgerCubit extends Cubit<LedgerState> {
  final LedgerRepository _repository;
  StreamSubscription<dynamic>? _subscription;

  LedgerCubit(this._repository) : super(const LedgerState.initial());

  Future<void> startWatching() async {
    emit(const LedgerState.loading());

    await _subscription?.cancel();
    _subscription = _repository.watchLedgerEntries().listen(
      (result) {
        result.fold(
          (error) {
            emit(LedgerState.error(error.message));
          },
          (entries) {
            if (entries.isEmpty) {
              emit(const LedgerState.empty());
            } else {
              double totalCredits = 0;
              double totalDebits = 0;

              for (final e in entries) {
                if (e.direction == 'CREDIT') {
                  totalCredits += e.amount;
                } else if (e.direction == 'DEBIT') {
                  totalDebits += e.amount;
                }
              }

              // Net Delta: Credits - Debits.
              // In a closed system, should be 0. Ideally.
              final netDelta = totalCredits - totalDebits;

              emit(LedgerState.success(
                entries: entries,
                totalCredits: totalCredits,
                totalDebits: totalDebits,
                netDelta: netDelta,
              ));
            }
          },
        );
      },
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
