import 'package:expense_calculator/constants/currency.dart';
import 'package:expense_calculator/features/transactions/controller/transaction_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';

const _colorA = Color(0xFF78909C);

class ComparisonResultScreen extends ConsumerWidget {
  final String comparisonType; // "Income" | "Expense"
  final DateTimeRange rangeA;
  final DateTimeRange rangeB;
  final String labelA;
  final String labelB;

  const ComparisonResultScreen({
    super.key,
    required this.comparisonType,
    required this.rangeA,
    required this.rangeB,
    required this.labelA,
    required this.labelB,
  });

  bool _inRange(DateTime date, DateTimeRange range) {
    final d = DateTime(date.year, date.month, date.day);
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  Color get _typeColor =>
      comparisonType == "Income" ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allTransactions = ref.watch(transactionControllerProvider);
    final relevant = allTransactions
        .where((t) => !t.isDeleted && t.type == comparisonType)
        .toList();

    final listA = relevant.where((t) => _inRange(t.date, rangeA)).toList();
    final listB = relevant.where((t) => _inRange(t.date, rangeB)).toList();

    final totalA = listA.fold<double>(0, (s, t) => s + t.amount);
    final totalB = listB.fold<double>(0, (s, t) => s + t.amount);

    final Map<String, double> catA = {};
    for (final t in listA) {
      catA[t.categoryName] = (catA[t.categoryName] ?? 0) + t.amount;
    }
    final Map<String, double> catB = {};
    for (final t in listB) {
      catB[t.categoryName] = (catB[t.categoryName] ?? 0) + t.amount;
    }

    final categories = {...catA.keys, ...catB.keys}.toList()
      ..sort(
        (a, b) => ((catB[b] ?? 0) + (catA[b] ?? 0))
            .compareTo((catB[a] ?? 0) + (catA[a] ?? 0)),
      );

    var maxCatValue = 0.0;
    for (final c in categories) {
      final a = catA[c] ?? 0;
      final b = catB[c] ?? 0;
      if (a > maxCatValue) maxCatValue = a;
      if (b > maxCatValue) maxCatValue = b;
    }

    final diff = totalB - totalA;
    final percent = totalA == 0
        ? (totalB == 0 ? 0.0 : 100.0)
        : (diff / totalA * 100);
    final isIncrease = diff > 0;
    final isFlat = diff == 0;
    final favorable = comparisonType == "Income" ? isIncrease : !isIncrease;
    final deltaColor = isFlat
        ? Colors.grey
        : (favorable ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Comparison"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  comparisonType,
                  style: TextStyle(
                    color: _typeColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _totalCard(context, totalA, totalB, diff, percent, isFlat, deltaColor),
            const SizedBox(height: 28),
            Text(
              "By Category",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            _legend(),
            const SizedBox(height: 14),
            if (categories.isEmpty)
              _emptyState(context)
            else
              ...categories.map(
                (c) => _categoryRow(
                  context,
                  isDark,
                  name: c,
                  amountA: catA[c] ?? 0,
                  amountB: catB[c] ?? 0,
                  maxValue: maxCatValue,
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _totalCard(
    BuildContext context,
    double totalA,
    double totalB,
    double diff,
    double percent,
    bool isFlat,
    Color deltaColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_typeColor, _typeColor.withValues(alpha: 0.65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _periodTotal(labelA, totalA)),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "VS",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: _periodTotal(labelB, totalB, alignEnd: true),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.25)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isFlat
                      ? Icons.remove_rounded
                      : (diff > 0
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded),
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  isFlat
                      ? "No change"
                      : "${percent.abs().toStringAsFixed(1)}% ${diff > 0 ? 'increase' : 'decrease'}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodTotal(String label, double amount, {bool alignEnd = false}) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
        ),
        const SizedBox(height: 6),
        Text(
          "${Currency.TAKA}${amount.toStringAsFixed(0)}",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _legend() {
    return Row(
      children: [
        _legendDot(_colorA, labelA),
        const SizedBox(width: 16),
        _legendDot(_typeColor, labelB),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryRow(
    BuildContext context,
    bool isDark, {
    required String name,
    required double amountA,
    required double amountB,
    required double maxValue,
  }) {
    final diff = amountB - amountA;
    final percent = amountA == 0
        ? (amountB == 0 ? 0.0 : 100.0)
        : (diff / amountA * 100);
    final isFlat = diff == 0;
    final favorable = comparisonType == "Income" ? diff > 0 : diff < 0;
    final deltaColor = isFlat
        ? Colors.grey
        : (favorable ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (!isFlat)
                Icon(
                  diff > 0
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 14,
                  color: deltaColor,
                ),
              Text(
                isFlat ? "0%" : "${percent.abs().toStringAsFixed(0)}%",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: deltaColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _categoryBar(amountA, maxValue, _colorA),
          const SizedBox(height: 6),
          _categoryBar(amountB, maxValue, _typeColor),
        ],
      ),
    );
  }

  Widget _categoryBar(double value, double maxValue, Color color) {
    final percent = maxValue == 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);
    return Row(
      children: [
        Expanded(
          child: LinearPercentIndicator(
            lineHeight: 10,
            percent: percent,
            padding: EdgeInsets.zero,
            barRadius: const Radius.circular(6),
            backgroundColor: color.withValues(alpha: 0.12),
            progressColor: color,
            animation: true,
            animationDuration: 600,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 60,
          child: Text(
            "${Currency.TAKA}${value.toStringAsFixed(0)}",
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 48,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              "No transactions in either period",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
