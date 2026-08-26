import 'package:expense_calculator/models/recurring_occurrence_model.dart';
import 'package:expense_calculator/models/recurring_rule_model.dart';

DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// One computed due-date for a [rule] that hasn't been resolved (applied or
/// skipped) yet. Purely derived at read time -- never persisted itself.
class PendingOccurrence {
  final RecurringRuleModel rule;
  final DateTime date;

  const PendingOccurrence({required this.rule, required this.date});

  @override
  bool operator ==(Object other) =>
      other is PendingOccurrence &&
      other.rule.id == rule.id &&
      other.date == date;

  @override
  int get hashCode => Object.hash(rule.id, date);
}

/// Runtime (no persistence) computation of which recurring-rule occurrences
/// are due. Mirrors the "recompute on every stream refresh" approach already
/// used by BudgetController._rollForwardRecurring.
class RecurrenceEngine {
  /// All due-dates for [rule] within [from]..[to] inclusive (day-normalized),
  /// not before the rule's own start date.
  static List<DateTime> occurrenceDatesFor(
    RecurringRuleModel rule,
    DateTime from,
    DateTime to,
  ) {
    final start = _dayOnly(from);
    final end = _dayOnly(to);
    final ruleStart = _dayOnly(rule.startDate);
    var cursor = start.isBefore(ruleStart) ? ruleStart : start;
    if (cursor.isAfter(end)) return [];

    final dates = <DateTime>[];
    while (!cursor.isAfter(end)) {
      final matches = rule.frequency == RecurringFrequency.monthly
          ? cursor.day == rule.clampedDayOfMonth(cursor.year, cursor.month)
          : rule.weekdays.contains(cursor.weekday);
      if (matches) dates.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    return dates;
  }

  static Set<DateTime> _loggedDatesFor(
    String ruleId,
    List<RecurringOccurrenceModel> logs,
  ) => logs
      .where((l) => l.ruleId == ruleId)
      .map((l) => _dayOnly(l.occurrenceDate))
      .toSet();

  /// Backlog (from the rule's last processed date, or start date if never
  /// processed) through today inclusive, minus anything already resolved.
  static List<PendingOccurrence> computeToday(
    List<RecurringRuleModel> rules,
    List<RecurringOccurrenceModel> logs, {
    DateTime? now,
  }) {
    final today = _dayOnly(now ?? DateTime.now());
    final result = <PendingOccurrence>[];
    for (final rule in rules.where((r) => r.isActive)) {
      final windowStart = rule.lastProcessedDate != null
          ? _dayOnly(rule.lastProcessedDate!).add(const Duration(days: 1))
          : _dayOnly(rule.startDate);
      if (windowStart.isAfter(today)) continue;
      final loggedDates = _loggedDatesFor(rule.id, logs);
      for (final date in occurrenceDatesFor(rule, windowStart, today)) {
        if (!loggedDates.contains(date)) {
          result.add(PendingOccurrence(rule: rule, date: date));
        }
      }
    }
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  /// The next [days] days (today excluded), minus anything already resolved.
  static List<PendingOccurrence> computeUpcoming(
    List<RecurringRuleModel> rules,
    List<RecurringOccurrenceModel> logs, {
    DateTime? now,
    int days = 5,
  }) {
    final today = _dayOnly(now ?? DateTime.now());
    final rangeStart = today.add(const Duration(days: 1));
    final rangeEnd = today.add(Duration(days: days));
    final result = <PendingOccurrence>[];
    for (final rule in rules.where((r) => r.isActive)) {
      final loggedDates = _loggedDatesFor(rule.id, logs);
      for (final date in occurrenceDatesFor(rule, rangeStart, rangeEnd)) {
        if (!loggedDates.contains(date)) {
          result.add(PendingOccurrence(rule: rule, date: date));
        }
      }
    }
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }
}
