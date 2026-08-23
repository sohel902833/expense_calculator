import 'package:expense_calculator/constants/currency.dart';
import 'package:expense_calculator/features/budget/models/budget_progress.dart';
import 'package:expense_calculator/models/transaction_model.dart';

/// Generates a short, prioritized list of human-readable budget insights
/// (spec sections 9 "Alerts" and 10 "Insights" -- surfaced together here as
/// plain text + the budget's own status color, since push notifications are
/// intentionally out of scope for now, see PENDING_FEATURES.md).
List<String> generateBudgetInsights({
  required List<BudgetProgress> progresses,
  required List<TransactionModel> currentMonthExpenses,
  required List<TransactionModel> previousMonthExpenses,
}) {
  final insights = <String>[];

  for (final p in progresses) {
    if (p.status == BudgetStatus.exceeded) {
      final over = (-p.remaining).toStringAsFixed(0);
      insights.add(
        "🚨 ${p.budget.name} exceeded by ${Currency.TAKA}$over.",
      );
    }
  }

  for (final p in progresses) {
    if (p.status == BudgetStatus.warning || p.status == BudgetStatus.critical) {
      insights.add(
        "⚠️ ${p.budget.name} is ${p.usagePercent.toStringAsFixed(0)}% used.",
      );
    }
  }

  final currentTotal = currentMonthExpenses.fold<double>(
    0,
    (s, t) => s + t.amount,
  );
  final previousTotal = previousMonthExpenses.fold<double>(
    0,
    (s, t) => s + t.amount,
  );
  if (previousTotal > 0) {
    insights.add(
      currentTotal < previousTotal
          ? "You spent less than last month."
          : currentTotal > previousTotal
          ? "You spent more than last month."
          : "You spent about the same as last month.",
    );
  }

  if (currentMonthExpenses.isNotEmpty) {
    final byCategory = <String, double>{};
    for (final t in currentMonthExpenses) {
      byCategory[t.categoryName] = (byCategory[t.categoryName] ?? 0) + t.amount;
    }
    final top = byCategory.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    insights.add("Your highest expense category is ${top.key}.");
  }

  return insights.take(4).toList();
}
