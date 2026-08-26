class RecurringOccurrenceStatus {
  static const applied = "applied";
  static const skipped = "skipped";
}

/// A resolved (applied or skipped) occurrence of a [RecurringRuleModel] for
/// one specific due date. Once logged here, the recurrence engine never
/// surfaces that rule+date combination again.
class RecurringOccurrenceModel {
  final String id;
  String? userId;
  final String ruleId;
  final DateTime occurrenceDate;
  final String status; // one of RecurringOccurrenceStatus.*
  final String? transactionId;
  final DateTime resolvedAt;

  RecurringOccurrenceModel({
    required this.id,
    this.userId,
    required this.ruleId,
    required this.occurrenceDate,
    required this.status,
    this.transactionId,
    DateTime? resolvedAt,
  }) : resolvedAt = resolvedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'ruleId': ruleId,
    'occurrenceDate': occurrenceDate.toIso8601String(),
    'status': status,
    'transactionId': transactionId,
    'resolvedAt': resolvedAt.toIso8601String(),
    'userId': userId,
  };

  factory RecurringOccurrenceModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) => RecurringOccurrenceModel(
    id: id,
    userId: map['userId'],
    ruleId: map['ruleId'] ?? '',
    occurrenceDate: map['occurrenceDate'] != null
        ? DateTime.parse(map['occurrenceDate'])
        : DateTime.now(),
    status: map['status'] ?? RecurringOccurrenceStatus.skipped,
    transactionId: map['transactionId'],
    resolvedAt: map['resolvedAt'] != null
        ? DateTime.parse(map['resolvedAt'])
        : DateTime.now(),
  );
}
