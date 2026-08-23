import 'package:expense_calculator/constants/color.dart';
import 'package:expense_calculator/constants/currency.dart';
import 'package:expense_calculator/features/budget/controller/budget_controller.dart';
import 'package:expense_calculator/features/budget/models/budget_progress.dart';
import 'package:expense_calculator/features/budget/screens/budget_details_screen.dart';
import 'package:expense_calculator/features/budget/widgets/budget_form_sheet.dart';
import 'package:expense_calculator/features/transactions/controller/transaction_controller.dart';
import 'package:expense_calculator/models/budget_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const _periodLabels = {
  BudgetPeriod.monthly: "Monthly",
  BudgetPeriod.weekly: "Weekly",
  BudgetPeriod.yearly: "Yearly",
  BudgetPeriod.custom: "Custom",
  BudgetPeriod.ongoing: "Ongoing",
};

class BudgetListScreen extends ConsumerStatefulWidget {
  static const routeName = '/budget-list-screen';
  const BudgetListScreen({super.key});

  @override
  ConsumerState<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends ConsumerState<BudgetListScreen> {
  bool _thisMonthOnly = true;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  Future<void> _onRefresh() async {
    ref.invalidate(budgetControllerProvider);
    ref.invalidate(transactionControllerProvider);
    await Future.delayed(const Duration(milliseconds: 400));
  }

  void _shiftMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      );
    });
  }

  void _openCreate() {
    showBudgetFormSheet(context, ref);
  }

  void _openEdit(BudgetModel budget) {
    showBudgetFormSheet(context, ref, editItem: budget);
  }

  void _openClone(BudgetModel budget) {
    final clone = budget.copyWith(id: '', name: "${budget.name} (Copy)");
    showBudgetFormSheet(context, ref, editItem: clone, isClone: true);
  }

  void _confirmDelete(BudgetModel budget) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Delete Budget"),
        content: Text('Delete "${budget.name}"? This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
            ),
            onPressed: () {
              ref.read(budgetControllerProvider.notifier).deleteBudget(budget.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Budget deleted")));
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  bool _matchesMonthFilter(BudgetModel b) {
    if (!_thisMonthOnly) return true;
    if (b.period == BudgetPeriod.ongoing) return true;
    if (b.startDate == null || b.endDate == null) return false;
    final monthStart = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final monthEnd = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    );
    return !b.endDate!.isBefore(monthStart) && !b.startDate!.isAfter(monthEnd);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final budgets = ref.watch(budgetControllerProvider);
    final transactions = ref.watch(transactionControllerProvider);
    final filtered = budgets.where(_matchesMonthFilter).toList();
    final contextDate = _thisMonthOnly
        ? DateTime(_selectedMonth.year, _selectedMonth.month, 15)
        : DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text("Budgets")),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        backgroundColor: tabColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _FilterSegment(
                    label: "This Month",
                    selected: _thisMonthOnly,
                    onTap: () => setState(() => _thisMonthOnly = true),
                  ),
                  _FilterSegment(
                    label: "All Budgets",
                    selected: !_thisMonthOnly,
                    onTap: () => setState(() => _thisMonthOnly = false),
                  ),
                ],
              ),
            ),
          ),
          if (_thisMonthOnly)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => _shiftMonth(-1),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Text(
                    "${_monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _shiftMonth(1),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: filtered.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.15,
                        ),
                        _emptyState(context),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final budget = filtered[i];
                        final progress = BudgetProgress.calculate(
                          budget,
                          transactions,
                          contextDate: contextDate,
                        );
                        return _budgetTile(context, isDark, progress);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 56,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _thisMonthOnly ? "No budgets for this month" : "No budgets yet",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              "Tap the + button to create one",
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _budgetTile(BuildContext context, bool isDark, BudgetProgress p) {
    final budget = p.budget;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BudgetDetailsScreen(budget: budget)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _badge(
                              budget.budgetType == BudgetType.overall
                                  ? "Overall"
                                  : (budget.categoryName ?? "Category"),
                              tabColor,
                            ),
                            _badge(
                              _periodLabels[budget.period] ?? budget.period,
                              Colors.grey,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 20),
                    onSelected: (value) {
                      if (value == "edit") {
                        _openEdit(budget);
                      } else if (value == "clone") {
                        _openClone(budget);
                      } else if (value == "delete") {
                        _confirmDelete(budget);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: "edit",
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 10),
                            Text("Edit"),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: "clone",
                        child: Row(
                          children: [
                            Icon(Icons.copy_outlined, size: 18),
                            SizedBox(width: 10),
                            Text("Clone"),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: "delete",
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: Color(0xFFE74C3C),
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Delete",
                              style: TextStyle(color: Color(0xFFE74C3C)),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                      animationDuration: 500,
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
              const SizedBox(height: 6),
              Text(
                "${Currency.TAKA}${p.spent.toStringAsFixed(0)} of ${Currency.TAKA}${budget.amount.toStringAsFixed(0)}",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _FilterSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? tabColor.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? tabColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? tabColor : Colors.grey,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
