import 'package:expense_calculator/constants/color.dart';
import 'package:expense_calculator/constants/currency.dart';
import 'package:expense_calculator/features/budget/controller/budget_controller.dart';
import 'package:expense_calculator/features/budget/models/budget_progress.dart';
import 'package:expense_calculator/features/budget/widgets/budget_form_sheet.dart';
import 'package:expense_calculator/features/transactions/controller/transaction_controller.dart';
import 'package:expense_calculator/models/budget_model.dart';
import 'package:expense_calculator/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(DateTime d) =>
    "${d.day} ${_monthNames[d.month - 1]} ${d.year}";

class BudgetDetailsScreen extends ConsumerWidget {
  final BudgetModel budget;

  const BudgetDetailsScreen({super.key, required this.budget});

  void _openEdit(BuildContext context, WidgetRef ref, BudgetModel current) {
    showBudgetFormSheet(context, ref, editItem: current);
  }

  void _openClone(BuildContext context, WidgetRef ref, BudgetModel current) {
    final clone = current.copyWith(id: '', name: "${current.name} (Copy)");
    showBudgetFormSheet(context, ref, editItem: clone, isClone: true);
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, BudgetModel current) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Delete Budget"),
        content: Text('Delete "${current.name}"? This can\'t be undone.'),
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
              ref
                  .read(budgetControllerProvider.notifier)
                  .deleteBudget(current.id);
              Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final budgets = ref.watch(budgetControllerProvider);
    final current = budgets.firstWhere(
      (b) => b.id == budget.id,
      orElse: () => budget,
    );
    final transactions = ref.watch(transactionControllerProvider);
    final progress = BudgetProgress.calculate(current, transactions);

    return Scaffold(
      appBar: AppBar(
        title: Text(current.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "edit") {
                _openEdit(context, ref, current);
              } else if (value == "clone") {
                _openClone(context, ref, current);
              } else if (value == "delete") {
                _confirmDelete(context, ref, current);
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
                    Text("Delete", style: TextStyle(color: Color(0xFFE74C3C))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summaryCard(progress),
            if (progress.dailyRecommended != null) ...[
              const SizedBox(height: 16),
              _dailyRecommendationCard(progress),
            ],
            const SizedBox(height: 28),
            Text(
              "Transactions",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (progress.transactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    "No transactions in this period",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              ...(List.of(progress.transactions)
                    ..sort((a, b) => b.date.compareTo(a.date)))
                  .map((t) => _transactionTile(context, isDark, t)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(BudgetProgress p) {
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
            children: [
              Expanded(
                child: _stat("Budget", p.budget.amount),
              ),
              Expanded(child: _stat("Spent", p.spent)),
              Expanded(child: _stat("Remaining", p.remaining)),
            ],
          ),
          const SizedBox(height: 18),
          LinearPercentIndicator(
            lineHeight: 12,
            percent: (p.usagePercent / 100).clamp(0.0, 1.0),
            padding: EdgeInsets.zero,
            barRadius: const Radius.circular(8),
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            progressColor: Colors.white,
            animation: true,
            animationDuration: 600,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
                  "${p.usagePercent.toStringAsFixed(0)}% used",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
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
                  p.status.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              if (p.daysRemaining != null)
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
                    "${p.daysRemaining} days left",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
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

  Widget _dailyRecommendationCard(BudgetProgress p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2ECC71).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.insights_rounded,
            color: Color(0xFF2ECC71),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "You can spend around ${Currency.TAKA}${p.dailyRecommended!.toStringAsFixed(0)}/day "
              "for the remaining period.",
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _transactionTile(BuildContext context, bool isDark, TransactionModel t) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.black.withValues(alpha: 0.03),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE74C3C).withValues(alpha: 0.15),
          child: const Icon(
            Icons.arrow_upward_rounded,
            color: Color(0xFFE74C3C),
          ),
        ),
        title: Text(
          t.categoryName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          t.description.isEmpty ? _formatDate(t.date) : "${_formatDate(t.date)} • ${t.description}",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          "-${Currency.TAKA}${t.amount.toStringAsFixed(0)}",
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFFE74C3C),
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
