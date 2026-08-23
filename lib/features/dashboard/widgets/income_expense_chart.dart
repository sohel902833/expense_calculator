import 'package:expense_calculator/constants/currency.dart';
import 'package:flutter/material.dart';

/// Simple two-bar Income vs Expense comparison for a single period. No
/// charting package is in this project's dependencies, and a two-value
/// comparison doesn't need one -- plain sized/animated containers read just
/// as clearly.
class IncomeExpenseChart extends StatelessWidget {
  final double income;
  final double expense;

  const IncomeExpenseChart({
    super.key,
    required this.income,
    required this.expense,
  });

  static const double _maxBarHeight = 120;

  @override
  Widget build(BuildContext context) {
    final maxVal = [income, expense].reduce((a, b) => a > b ? a : b);
    final incomeHeight = maxVal <= 0 ? 4.0 : (income / maxVal) * _maxBarHeight;
    final expenseHeight = maxVal <= 0
        ? 4.0
        : (expense / maxVal) * _maxBarHeight;

    return SizedBox(
      height: _maxBarHeight + 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _bar("Income", income, incomeHeight, const Color(0xFF2ECC71)),
          _bar("Expense", expense, expenseHeight, const Color(0xFFE74C3C)),
        ],
      ),
    );
  }

  Widget _bar(String label, double value, double height, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "${Currency.TAKA}${value.toStringAsFixed(0)}",
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          width: 56,
          height: height.clamp(4, _maxBarHeight),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.6)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
