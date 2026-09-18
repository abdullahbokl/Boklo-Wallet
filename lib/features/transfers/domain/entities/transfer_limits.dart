import 'package:equatable/equatable.dart';

/// The caller's current transfer limits (integer minor units), served by
/// the `getTransferLimits` callable from the same Remote Config values the
/// fraud engine enforces.
class TransferLimits extends Equatable {
  const TransferLimits({
    required this.singleLimitMinor,
    required this.dailyLimitMinor,
    required this.sentTodayMinor,
    required this.remainingTodayMinor,
  });

  final int singleLimitMinor;
  final int dailyLimitMinor;
  final int sentTodayMinor;
  final int remainingTodayMinor;

  @override
  List<Object?> get props => [
    singleLimitMinor,
    dailyLimitMinor,
    sentTodayMinor,
    remainingTodayMinor,
  ];
}
