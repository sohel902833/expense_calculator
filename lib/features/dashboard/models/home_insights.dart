import 'package:expense_calculator/models/transaction_model.dart';

/// Simple, budget-agnostic spending insights for the home dashboard --
/// works even when the user hasn't set up any budgets yet.
List<String> generateHomeInsights({
  required List<TransactionModel> currentMonthExpenses,
  required List<TransactionModel> previousMonthExpenses,
}) {
  final insights = <String>[];

  final currentTotal = currentMonthExpenses.fold<double>(
    0,
    (s, t) => s + t.amount,
  );
  final previousTotal = previousMonthExpenses.fold<double>(
    0,
    (s, t) => s + t.amount,
  );

  if (previousTotal > 0) {
    final diffPercent = ((currentTotal - previousTotal) / previousTotal * 100)
        .abs();
    if (currentTotal < previousTotal) {
      insights.add(
        "You spent ${diffPercent.toStringAsFixed(0)}% less this month.",
      );
    } else if (currentTotal > previousTotal) {
      insights.add(
        "You spent ${diffPercent.toStringAsFixed(0)}% more this month.",
      );
    } else {
      insights.add("You spent about the same as last month.");
    }
  }

  if (currentMonthExpenses.isNotEmpty) {
    final byCategory = <String, double>{};
    for (final t in currentMonthExpenses) {
      byCategory[t.categoryName] = (byCategory[t.categoryName] ?? 0) + t.amount;
    }
    final top = byCategory.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    insights.add("${top.key} is your highest expense category.");
  }

  return insights;
}
