enum ScheduleFrequency { daily, weekly, monthly }

enum ScheduleStatus { active, paused, cancelled, completed }

/// A recurring transfer the backend executes automatically.
class ScheduledTransferEntity {
  const ScheduledTransferEntity({
    required this.id,
    required this.toWalletId,
    required this.amount, // integer minor units
    required this.currency,
    required this.frequency,
    required this.status,
    required this.nextRunAt,
    this.note,
    this.runCount = 0,
  });

  final String id;
  final String toWalletId;
  final int amount;
  final String currency;
  final ScheduleFrequency frequency;
  final ScheduleStatus status;
  final DateTime nextRunAt;
  final String? note;
  final int runCount;
}
