import 'package:expense_calculator/common/modals/transaction_modals.dart';
import 'package:expense_calculator/constants/color.dart';
import 'package:expense_calculator/constants/currency.dart';
import 'package:expense_calculator/features/budget/controller/budget_controller.dart';
import 'package:expense_calculator/features/budget/models/budget_progress.dart';
import 'package:expense_calculator/features/dashboard/models/home_insights.dart';
import 'package:expense_calculator/features/dashboard/screens/dashboard_screen.dart';
import 'package:expense_calculator/features/dashboard/widgets/expense_donut_chart.dart';
import 'package:expense_calculator/features/dashboard/widgets/income_expense_chart.dart';
import 'package:expense_calculator/features/transactions/controller/transaction_controller.dart';
import 'package:expense_calculator/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';

const _fullMonthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const _expenseCategoryPalette = [
  Color(0xFFE74C3C), Color(0xFFF39C12), Color(0xFF3498DB),
  Color(0xFF9B59B6), Color(0xFF2ECC71), Color(0xFF1ABC9C),
];

/// Which calendar month the dashboard's month-scoped sections show. Total
/// Balance stays all-time regardless of this filter.
final selectedDashboardMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

String _monthYearLabel(DateTime d) => "${_fullMonthNames[d.month - 1]} ${d.year}";

String _fullDateLabel(DateTime d) =>
    "${_fullMonthNames[d.month - 1]} ${d.day}, ${d.year}";

bool _sameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

String _categoryEmoji(String categoryName) {
  final n = categoryName.toLowerCase();
  if (n.contains('salary') || n.contains('income') || n.contains('job')) {
    return '💼';
  }
  if (n.contains('restaurant') || n.contains('dining') || n.contains('food')) {
    return '🍔';
  }
  if (n.contains('grocery') || n.contains('groceries')) return '🛒';
  if (n.contains('transport') ||
      n.contains('uber') ||
      n.contains('taxi') ||
      n.contains('cab')) {
    return '🚕';
  }
  if (n.contains('rent') || n.contains('house') || n.contains('home')) {
    return '🏠';
  }
  if (n.contains('shopping')) return '🛍️';
  if (n.contains('health') || n.contains('medical') || n.contains('doctor')) {
    return '🏥';
  }
  if (n.contains('bill') || n.contains('utility') || n.contains('electric')) {
    return '💡';
  }
  if (n.contains('entertainment') || n.contains('movie')) return '🎬';
  if (n.contains('education') || n.contains('school')) return '📚';
  if (n.contains('travel')) return '✈️';
  if (n.contains('gift')) return '🎁';
  return '💰';
}

/// Bottom sheet for picking which month HomeScreen's month-scoped sections
/// show. Top-level (rather than State-owned) so DashboardScreen's app bar
/// filter icon can open it directly, the same way TransactionScreen's
/// filter sheet is opened from outside that screen.
void showDashboardMonthFilterSheet(BuildContext context, WidgetRef ref) {
  DateTime temp = ref.read(selectedDashboardMonthProvider);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => StatefulBuilder(
      builder: (context, setModalState) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final bottomSafeArea = MediaQuery.of(context).padding.bottom;
        final now = DateTime.now();
        final isCurrent = temp.year == now.year && temp.month == now.month;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomSafeArea),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                "Filter by Month",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Choose which month's data to show",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => setModalState(
                      () => temp = DateTime(temp.year, temp.month - 1),
                    ),
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                  ),
                  Expanded(
                    child: Text(
                      _monthYearLabel(temp),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setModalState(
                      () => temp = DateTime(temp.year, temp.month + 1),
                    ),
                    icon: const Icon(Icons.chevron_right_rounded, size: 28),
                  ),
                ],
              ),
              if (!isCurrent)
                Center(
                  child: TextButton(
                    onPressed: () => setModalState(
                      () => temp = DateTime(now.year, now.month),
                    ),
                    child: const Text("Reset to This Month"),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(selectedDashboardMonthProvider.notifier).state =
                        temp;
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tabColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Apply",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Future<void> _onRefresh() async {
    ref.invalidate(transactionControllerProvider);
    ref.invalidate(budgetControllerProvider);
    await Future.delayed(const Duration(milliseconds: 400));
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final today = DateTime.now();
    final selectedMonth = ref.watch(selectedDashboardMonthProvider);
    final transactions = ref.watch(transactionControllerProvider);
    final budgets = ref.watch(budgetControllerProvider);

    final allNonDeleted = transactions.where((t) => !t.isDeleted).toList();

    final allTimeIncome = allNonDeleted
        .where((t) => t.type == "Income")
        .fold<double>(0, (s, t) => s + t.amount);
    final allTimeExpense = allNonDeleted
        .where((t) => t.type == "Expense")
        .fold<double>(0, (s, t) => s + t.amount);
    final totalBalance = allTimeIncome - allTimeExpense;

    final monthTx = allNonDeleted
        .where((t) => _sameMonth(t.date, selectedMonth))
        .toList();
    final monthIncome = monthTx
        .where((t) => t.type == "Income")
        .fold<double>(0, (s, t) => s + t.amount);
    final monthExpenseTx = monthTx.where((t) => t.type == "Expense").toList();
    final monthExpense = monthExpenseTx.fold<double>(
      0,
      (s, t) => s + t.amount,
    );
    final savings = monthIncome - monthExpense;
    final savingsPercent = monthIncome <= 0 ? 0.0 : (savings / monthIncome * 100);

    final previousMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
    final previousMonthExpenses = allNonDeleted
        .where(
          (t) => t.type == "Expense" && _sameMonth(t.date, previousMonth),
        )
        .toList();
    final insights = generateHomeInsights(
      currentMonthExpenses: monthExpenseTx,
      previousMonthExpenses: previousMonthExpenses,
    );

    final byCategory = <String, double>{};
    for (final t in monthExpenseTx) {
      byCategory[t.categoryName] = (byCategory[t.categoryName] ?? 0) + t.amount;
    }
    final sortedCategories = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(4).toList();
    final othersTotal =
        monthExpense - topCategories.fold<double>(0, (s, e) => s + e.value);

    final activeBudgets = budgets.where((b) => b.coversDate(today)).toList();
    final totalBudgetAmount = activeBudgets.fold<double>(
      0,
      (s, b) => s + b.amount,
    );
    final totalBudgetSpent = activeBudgets
        .map((b) => BudgetProgress.calculate(b, transactions))
        .fold<double>(0, (s, p) => s + p.spent);
    final budgetUsage = totalBudgetAmount <= 0
        ? 0.0
        : (totalBudgetSpent / totalBudgetAmount * 100);

    final recent = List<TransactionModel>.of(allNonDeleted)
      ..sort((a, b) => b.date.compareTo(a.date));
    final recentTop = recent.take(4).toList();

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          20,
          15,
          20,
          glassNavFabBottomOffset(context) + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _greetingHeader(context, today),
            if (!_sameMonth(selectedMonth, today)) ...[
              const SizedBox(height: 12),
              _monthChip(selectedMonth),
            ],
            const SizedBox(height: 20),
            _totalBalanceCard(
              isDark,
              totalBalance,
              monthIncome,
              monthExpense,
              savings,
              savingsPercent,
            ),
            const SizedBox(height: 20),
            _sectionCard(
              context,
              isDark: isDark,
              title: "Income vs Expense",
              child: IncomeExpenseChart(
                income: monthIncome,
                expense: monthExpense,
              ),
            ),
            const SizedBox(height: 20),
            _sectionCard(
              context,
              isDark: isDark,
              title: "Budget Overview",
              trailing: _seeAllLink(
                () => ref.read(dashboardTabIndexProvider.notifier).state = 2,
              ),
              child: activeBudgets.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        "No active budgets. Tap See All to set one up.",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : _budgetOverviewContent(
                      totalBudgetAmount,
                      totalBudgetSpent,
                      budgetUsage,
                    ),
            ),
            const SizedBox(height: 20),
            _sectionCard(
              context,
              isDark: isDark,
              title: "Expense Breakdown",
              child: topCategories.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          "No expenses this month",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    )
                  : _expenseBreakdownContent(
                      topCategories,
                      othersTotal,
                      monthExpense,
                    ),
            ),
            const SizedBox(height: 20),
            _sectionCard(
              context,
              isDark: isDark,
              title: "Recent Transactions",
              trailing: _seeAllLink(
                () => ref.read(dashboardTabIndexProvider.notifier).state = 1,
              ),
              child: recentTop.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          "No transactions yet",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    )
                  : Column(
                      children: recentTop.map(_recentTile).toList(),
                    ),
            ),
            if (insights.isNotEmpty) ...[
              const SizedBox(height: 20),
              _insightsCard(context, isDark, insights),
            ],
            const SizedBox(height: 24),
            _quickAddRow(context),
          ],
        ),
      ),
    );
  }

  Widget _greetingHeader(BuildContext context, DateTime today) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${_greeting()} 👋",
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          _fullDateLabel(today),
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
      ],
    );
  }

  Widget _monthChip(DateTime month) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: tabColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_rounded, size: 14, color: tabColor),
            const SizedBox(width: 6),
            Text(
              "Showing ${_monthYearLabel(month)}",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tabColor,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () {
                final now = DateTime.now();
                ref.read(selectedDashboardMonthProvider.notifier).state =
                    DateTime(now.year, now.month);
              },
              child: const Icon(Icons.close_rounded, size: 14, color: tabColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalBalanceCard(
    bool isDark,
    double balance,
    double income,
    double expense,
    double savings,
    double savingsPercent,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xff536976), Color(0xff292e49)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xff00f5a0), Color(0xff00d9f5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Total Balance",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "${Currency.TAKA}${balance.toStringAsFixed(0)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  "Income",
                  income,
                  Icons.arrow_downward_rounded,
                ),
              ),
              Expanded(
                child: _miniStat(
                  "Expense",
                  expense,
                  Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.25)),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.savings_outlined,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                "Savings: ${Currency.TAKA}${savings.toStringAsFixed(0)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "• ${savingsPercent.toStringAsFixed(1)}%",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, double amount, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 11,
              ),
            ),
            Text(
              "${Currency.TAKA}${amount.toStringAsFixed(0)}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required bool isDark,
    required String title,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _seeAllLink(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "See All",
            style: TextStyle(
              color: tabColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Icon(Icons.arrow_forward_rounded, size: 14, color: tabColor),
        ],
      ),
    );
  }

  Widget _budgetOverviewContent(
    double totalAmount,
    double totalSpent,
    double usage,
  ) {
    final status = usage >= 100
        ? BudgetStatus.exceeded
        : usage >= 90
        ? BudgetStatus.critical
        : usage >= 75
        ? BudgetStatus.warning
        : BudgetStatus.healthy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Overall Budget",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${Currency.TAKA}${totalSpent.toStringAsFixed(0)} / ${Currency.TAKA}${totalAmount.toStringAsFixed(0)}",
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              "${usage.toStringAsFixed(0)}%",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: status.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LinearPercentIndicator(
          lineHeight: 10,
          percent: (usage / 100).clamp(0.0, 1.0),
          padding: EdgeInsets.zero,
          barRadius: const Radius.circular(6),
          backgroundColor: status.color.withValues(alpha: 0.15),
          progressColor: status.color,
          animation: true,
          animationDuration: 600,
        ),
      ],
    );
  }

  Widget _expenseBreakdownContent(
    List<MapEntry<String, double>> topCategories,
    double othersTotal,
    double totalExpense,
  ) {
    final chartData = [
      ...topCategories,
      if (othersTotal > 0.5) MapEntry("Others", othersTotal),
    ];
    final chartColors = [
      ..._expenseCategoryPalette.take(topCategories.length),
      if (othersTotal > 0.5) Colors.grey,
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ExpenseDonutChart(data: chartData, colors: chartColors),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            children: List.generate(topCategories.length, (index) {
              final entry = topCategories[index];
              final percent = totalExpense <= 0
                  ? 0.0
                  : (entry.value / totalExpense * 100);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _expenseCategoryPalette[index %
                            _expenseCategoryPalette.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      "${Currency.TAKA}${entry.value.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 32,
                      child: Text(
                        "${percent.toStringAsFixed(0)}%",
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _recentTile(TransactionModel t) {
    final color = t.type == "Income"
        ? const Color(0xFF2ECC71)
        : const Color(0xFFE74C3C);
    final sign = t.type == "Income" ? "+" : "-";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _categoryEmoji(t.categoryName),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              t.categoryName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            "$sign${Currency.TAKA}${t.amount.toStringAsFixed(0)}",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightsCard(BuildContext context, bool isDark, List<String> insights) {
    return _sectionCard(
      context,
      isDark: isDark,
      title: "Financial Insights",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < insights.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == insights.length - 1 ? 0 : 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Color(0xFFF39C12),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insights[i],
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _quickAddRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => TransactionModals.showAddTransactionModal(
              context,
              ref,
              defaultType: "Expense",
            ),
            icon: const Icon(
              Icons.remove_circle_outline_rounded,
              color: Color(0xFFE74C3C),
            ),
            label: const Text(
              "Add Expense",
              style: TextStyle(
                color: Color(0xFFE74C3C),
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFFE74C3C)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => TransactionModals.showAddTransactionModal(
              context,
              ref,
              defaultType: "Income",
            ),
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: Color(0xFF2ECC71),
            ),
            label: const Text(
              "Add Income",
              style: TextStyle(
                color: Color(0xFF2ECC71),
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFF2ECC71)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
