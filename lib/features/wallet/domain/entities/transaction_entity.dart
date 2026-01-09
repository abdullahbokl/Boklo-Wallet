import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_entity.freezed.dart';

enum TransactionType {
  credit,
  debit,
}

enum TransactionStatus {
  pending,
  completed,
  failed,
}

@freezed
class TransactionEntity with _$TransactionEntity {
  const factory TransactionEntity({
    required String id,
    required double amount,
    required TransactionType type,
    required DateTime timestamp,
    @Default(TransactionStatus.completed) TransactionStatus status,
  }) = _TransactionEntity;
}
