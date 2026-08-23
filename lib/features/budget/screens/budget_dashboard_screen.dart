import 'package:expense_calculator/constants/color.dart';
import 'package:expense_calculator/constants/currency.dart';
import 'package:expense_calculator/features/budget/controller/budget_controller.dart';
import 'package:expense_calculator/features/budget/models/budget_insights.dart';
import 'package:expense_calculator/features/budget/models/budget_progress.dart';
import 'package:expense_calculator/features/budget/screens/budget_details_screen.dart';
import 'package:expense_calculator/features/budget/screens/budget_list_screen.dart';
import 'package:expense_calculator/features/transactions/controller/transaction_controller.dart';
import 'package:expense_calculator/models/budget_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';

class BudgetDashboardScreen extends ConsumerStatefulWidget {
  const BudgetDashboardScreen({super.key});

  @override
  ConsumerState<BudgetDashboardScreen> createState() =>
      _BudgetDashboardScreenState();
}

class _BudgetDashboardScreenState
    extends ConsumerState<BudgetDashboardScreen> {
  Future<void> _onRefresh() async {
    ref.invalidate(budgetControllerProvider);
    ref.invalidate(transactionControllerProvider);
    await Future.delayed(const Duration(milliseconds: 400));
  }

  bool _sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final today = DateTime.now();
    final budgets = ref.watch(budgetControllerProvider);
    final transactions = ref.watch(transactionControllerProvider);

    final activeBudgets = budgets.where((b) => b.coversDate(today)).toList();
    final activeOverall = activeBudgets
        .where((b) => b.budgetType == BudgetType.overall)
        .toList();
    final activeCategoryBudgets = activeBudgets
        .where((b) => b.budgetType == BudgetType.category)
        .toList();

    final overallProgresses =
        activeOverall
            .map((b) => BudgetProgress.calculate(b, transactions))
            .toList()
          ..sort((a, b) => b.usagePercent.compareTo(a.usagePercent));
    final categoryProgresses =
        activeCategoryBudgets
            .map((b) => BudgetProgress.calculate(b, transactions))
            .toList()
          ..sort((a, b) => b.usagePercent.compareTo(a.usagePercent));

    final totalBudget = activeBudgets.fold<double>(0, (s, b) => s + b.amount);
    final totalSpent = [...overallProgresses, ...categoryProgresses].fold<double>(
      0,
      (s, p) => s + p.spent,
    );
    final usagePercent = totalBudget <= 0 ? 0.0 : (totalSpent / totalBudget) * 100;
    final remaining = totalBudget - totalSpent;

    final currentMonthExpenses = transactions
        .where(
          (t) =>
              !t.isDeleted &&
              t.type == "Expense" &&
              _sameMonth(t.date, today),
        )
        .toList();
    final previousMonth = DateTime(today.year, today.month - 1, 1);
    final previousMonthExpenses = transactions
        .where(
          (t) =>
              !t.isDeleted &&
              t.type == "Expense" &&
              _sameMonth(t.date, previousMonth),
        )
        .toList();

    final insights = generateBudgetInsights(
      progresses: [...overallProgresses, ...categoryProgresses],
      currentMonthExpenses: currentMonthExpenses,
      previousMonthExpenses: previousMonthExpenses,
    );

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            if (activeBudgets.isEmpty)
              _emptyState(context)
            else ...[
              _headlineCard(
                title: "Total Progress",
                subtitle: "Across ${activeBudgets.length} active "
                    "budget${activeBudgets.length == 1 ? '' : 's'}",
                totalBudget: totalBudget,
                totalSpent: totalSpent,
                remaining: remaining,
                usagePercent: usagePercent,
              ),
              const SizedBox(height: 24),
              _sectionHeader(context, "Overall Budgets"),
              const SizedBox(height: 12),
              if (overallProgresses.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "No overall budgets active this month.",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              else
                ...overallProgresses.map(
                  (p) => _budgetRow(context, isDark, p),
                ),
              const SizedBox(height: 12),
              _sectionHeader(context, "Category Budgets"),
              const SizedBox(height: 12),
              if (categoryProgresses.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "No category budgets active this month.",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              else
                ...categoryProgresses.map(
                  (p) => _budgetRow(context, isDark, p),
                ),
              _insightsPanel(context, isDark, insights),
            ],
            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  String _periodSubtitle(BudgetModel budget) {
    switch (budget.period) {
      case BudgetPeriod.ongoing:
        return "Ongoing";
      case BudgetPeriod.monthly:
        final d = budget.startDate!;
        const months = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December',
        ];
        return "For ${months[d.month - 1]} ${d.year}";
      case BudgetPeriod.weekly:
        return "This week";
      case BudgetPeriod.yearly:
        return "For ${budget.startDate!.year}";
      default:
        return "Custom period";
    }
  }

  Widget _headlineCard({
    required String title,
    required String subtitle,
    required double totalBudget,
    required double totalSpent,
    required double remaining,
    required double usagePercent,
  }) {
    final resolvedStatus = usagePercent >= 100
        ? BudgetStatus.exceeded
        : usagePercent >= 90
        ? BudgetStatus.critical
        : usagePercent >= 75
        ? BudgetStatus.warning
        : BudgetStatus.healthy;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tabColor, tabColor.withValues(alpha: 0.65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  resolvedStatus.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _stat("Budget", totalBudget)),
              Expanded(child: _stat("Spent", totalSpent)),
              Expanded(child: _stat("Remaining", remaining)),
            ],
          ),
          const SizedBox(height: 18),
          LinearPercentIndicator(
            lineHeight: 12,
            percent: (usagePercent / 100).clamp(0.0, 1.0),
            padding: EdgeInsets.zero,
            barRadius: const Radius.circular(8),
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            progressColor: Colors.white,
            animation: true,
            animationDuration: 600,
          ),
          const SizedBox(height: 8),
          Text(
            "${usagePercent.toStringAsFixed(0)}% used",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, double amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          "${Currency.TAKA}${amount.toStringAsFixed(0)}",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _budgetRow(BuildContext context, bool isDark, BudgetProgress p) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BudgetDetailsScreen(budget: p.budget),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.budget.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _periodSubtitle(p.budget),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "${Currency.TAKA}${p.spent.toStringAsFixed(0)} / ${Currency.TAKA}${p.budget.amount.toStringAsFixed(0)}",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: LinearPercentIndicator(
                    lineHeight: 8,
                    percent: (p.usagePercent / 100).clamp(0.0, 1.0),
                    padding: EdgeInsets.zero,
                    barRadius: const Radius.circular(4),
                    backgroundColor: p.status.color.withValues(alpha: 0.15),
                    progressColor: p.status.color,
                    animation: true,
                    animationDuration: 600,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "${p.usagePercent.toStringAsFixed(0)}%",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: p.status.color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _insightsPanel(
    BuildContext context,
    bool isDark,
    List<String> insights,
  ) {
    if (insights.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: Color(0xFFF39C12),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Insights",
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...insights.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(s, style: const TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 60),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 56,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            "No budgets set for this month",
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            "Create a budget to start tracking your spending limits.",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () =>
                Navigator.pushNamed(context, BudgetListScreen.routeName),
            style: ElevatedButton.styleFrom(
              backgroundColor: tabColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text("Create Budget"),
          ),
        ],
      ),
    );
  }
}
