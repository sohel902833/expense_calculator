import 'package:expense_calculator/models/budget_model.dart';
import 'package:expense_calculator/models/transaction_model.dart';
import 'package:flutter/material.dart';

enum BudgetStatus { healthy, warning, critical, exceeded }

extension BudgetStatusX on BudgetStatus {
  String get label {
    switch (this) {
      case BudgetStatus.healthy:
        return "Healthy";
      case BudgetStatus.warning:
        return "Warning";
      case BudgetStatus.critical:
        return "Critical";
      case BudgetStatus.exceeded:
        return "Exceeded";
    }
  }

  Color get color {
    switch (this) {
      case BudgetStatus.healthy:
        return const Color(0xFF2ECC71);
      case BudgetStatus.warning:
        return const Color(0xFFF39C12);
      case BudgetStatus.critical:
        return const Color(0xFFE67E22);
      case BudgetStatus.exceeded:
        return const Color(0xFFE74C3C);
    }
  }
}

BudgetStatus _statusForUsage(double usagePercent) {
  if (usagePercent >= 100) return BudgetStatus.exceeded;
  if (usagePercent >= 90) return BudgetStatus.critical;
  if (usagePercent >= 75) return BudgetStatus.warning;
  return BudgetStatus.healthy;
}

/// Computed, read-only progress for a [BudgetModel] against a set of
/// transactions. This is the single place spend/remaining/usage/status/
/// days-remaining/daily-recommendation are calculated -- reused by the
/// dashboard, list, and details screens so the math never drifts.
class BudgetProgress {
  final BudgetModel budget;
  final DateTimeRange range;
  final double spent;
  final List<TransactionModel> transactions;
  final DateTime contextDate;

  BudgetProgress._({
    required this.budget,
    required this.range,
    required this.spent,
    required this.transactions,
    required this.contextDate,
  });

  double get remaining => budget.amount - spent;

  double get usagePercent =>
      budget.amount <= 0 ? 0 : (spent / budget.amount) * 100;

  BudgetStatus get status => _statusForUsage(usagePercent);

  bool get isActive {
    final d = DateTime(contextDate.year, contextDate.month, contextDate.day);
    final s = DateTime(range.start.year, range.start.month, range.start.day);
    final e = DateTime(range.end.year, range.end.month, range.end.day);
    return !d.isBefore(s) && !d.isAfter(e);
  }

  /// Days left in [range] counted from [contextDate], inclusive. Null when
  /// [contextDate] falls outside the range (e.g. browsing a past/future
  /// period) since "days remaining" isn't meaningful there.
  int? get daysRemaining {
    if (!isActive) return null;
    final today = DateTime(contextDate.year, contextDate.month, contextDate.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day);
    return end.difference(today).inDays + 1;
  }

  double? get dailyRecommended {
    final days = daysRemaining;
    if (days == null || days <= 0 || remaining <= 0) return null;
    return remaining / days;
  }

  static BudgetProgress calculate(
    BudgetModel budget,
    List<TransactionModel> allTransactions, {
    DateTime? contextDate,
  }) {
    final context = contextDate ?? DateTime.now();
    final range = budget.evaluationRangeFor(context);
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day);

    final matching = allTransactions.where((t) {
      if (t.isDeleted || t.type != "Expense") return false;
      if (budget.budgetType == BudgetType.category &&
          t.categoryId != budget.categoryId) {
        return false;
      }
      final d = DateTime(t.date.year, t.date.month, t.date.day);
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();

    final spent = matching.fold<double>(0, (s, t) => s + t.amount);

    return BudgetProgress._(
      budget: budget,
      range: range,
      spent: spent,
      transactions: matching,
      contextDate: context,
    );
  }
}
