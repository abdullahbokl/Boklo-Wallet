import 'dart:io';

import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:boklo/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:boklo/features/wallet/domain/services/csv_statement_builder.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Builds a CSV statement of the user's full transaction history and hands
/// the file to the platform share sheet.
@injectable
class ExportStatementUseCase {
  ExportStatementUseCase(this._repository);

  final WalletRepository _repository;

  Future<Either<Failure, XFile>> call({
    required String currency,
  }) async {
    final history = await _repository.getAllTransactions();
    if (history.isLeft()) {
      return Left(history.getLeft().toNullable()!);
    }
    return _buildAndShare(history.getRight().toNullable()!, currency);
  }

  Future<Either<Failure, XFile>> _buildAndShare(
    List<TransactionEntity> transactions,
    String currency,
  ) async {
    try {
      final csv = CsvStatementBuilder.build(
        transactions: transactions,
        currency: currency,
      );

      final dir = await getTemporaryDirectory();
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/boklo_statement_$stamp.csv');
      await file.writeAsString(csv);

      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/csv')],
          subject: 'Boklo statement',
        ),
      );
      // ShareParams.status is null on some platforms; treat a presented
      // sheet (no thrown error) as success.
      if (result.status == ShareResultStatus.dismissed) {
        return const Left(UnknownFailure('Share dismissed'));
      }
      return Right(XFile(file.path));
    } on Object catch (e) {
      return Left(UnknownFailure('Statement export failed: $e'));
    }
  }
}

/// Fetches the full transaction history (used by the insights card).
@injectable
class GetAllTransactionsUseCase {
  GetAllTransactionsUseCase(this._repository);

  final WalletRepository _repository;

  Future<Either<Failure, List<TransactionEntity>>> call() {
    return _repository.getAllTransactions();
  }
}
