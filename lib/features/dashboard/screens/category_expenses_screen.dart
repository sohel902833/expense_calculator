import 'package:expense_calculator/constants/currency.dart';
import 'package:expense_calculator/features/transaction-type/controller/transaction_type_controller.dart';
import 'package:expense_calculator/features/transactions/controller/transaction_controller.dart';
import 'package:expense_calculator/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(DateTime d) =>
    "${d.day} ${_monthNames[d.month - 1]} ${d.year}";

const _categoryPalette = [
  Color(0xFFE74C3C),
  Color(0xFF9B59B6),
  Color(0xFF3498DB),
  Color(0xFFE67E22),
  Color(0xFF1ABC9C),
  Color(0xFFF1C40F),
  Color(0xFF2ECC71),
  Color(0xFF34495E),
];

Color _colorForCategory(String categoryId) =>
    _categoryPalette[categoryId.hashCode.abs() % _categoryPalette.length];

class _CategoryFilter {
  final String? categoryId;
  final DateTime? startDate;
  final DateTime? endDate;

  const _CategoryFilter({this.categoryId, this.startDate, this.endDate});

  int get activeFilterCount =>
      (categoryId != null ? 1 : 0) +
      (startDate != null || endDate != null ? 1 : 0);
}

class _CategoryTotal {
  final String categoryId;
  final String categoryName;
  final double total;
  final int count;

  _CategoryTotal({
    required this.categoryId,
    required this.categoryName,
    required this.total,
    required this.count,
  });
}

/// Shows expense transactions grouped by category, with a totals bar per
/// category. Reachable from the Transactions tab's app bar (unfiltered) or
/// by tapping a transaction there (pre-filtered to that item's category).
class CategoryExpensesScreen extends ConsumerStatefulWidget {
  final String? initialCategoryId;
  const CategoryExpensesScreen({super.key, this.initialCategoryId});

  @override
  ConsumerState<CategoryExpensesScreen> createState() =>
      _CategoryExpensesScreenState();
}

class _CategoryExpensesScreenState
    extends ConsumerState<CategoryExpensesScreen> {
  late _CategoryFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = _CategoryFilter(categoryId: widget.initialCategoryId);
  }

  List<TransactionModel> _applyFilter(List<TransactionModel> list) {
    return list.where((t) {
      if (t.isDeleted || t.type != "Expense") return false;
      if (_filter.categoryId != null && t.categoryId != _filter.categoryId) {
        return false;
      }
      final d = DateTime(t.date.year, t.date.month, t.date.day);
      if (_filter.startDate != null) {
        final start = DateTime(
          _filter.startDate!.year,
          _filter.startDate!.month,
          _filter.startDate!.day,
        );
        if (d.isBefore(start)) return false;
      }
      if (_filter.endDate != null) {
        final end = DateTime(
          _filter.endDate!.year,
          _filter.endDate!.month,
          _filter.endDate!.day,
        );
        if (d.isAfter(end)) return false;
      }
      return true;
    }).toList();
  }

  List<_CategoryTotal> _groupByCategory(List<TransactionModel> list) {
    final map = <String, _CategoryTotal>{};
    for (final t in list) {
      final existing = map[t.categoryId];
      map[t.categoryId] = _CategoryTotal(
        categoryId: t.categoryId,
        categoryName: t.categoryName,
        total: (existing?.total ?? 0) + t.amount,
        count: (existing?.count ?? 0) + 1,
      );
    }
    final result = map.values.toList();
    result.sort((a, b) => b.total.compareTo(a.total));
    return result;
  }

  void _openFilterSheet() {
    final categories = ref
        .read(transactionTypeControllerProvider)
        .where((t) => t.type == "Expense")
        .toList();

    String? tempCategoryId = _filter.categoryId;
    DateTime? tempStart = _filter.startDate;
    DateTime? tempEnd = _filter.endDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          final bottomSafeArea = MediaQuery.of(context).padding.bottom;
          final borderColor = (isDark ? Colors.white : Colors.black)
              .withValues(alpha: 0.2);

          return Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomSafeArea),
              child: SingleChildScrollView(
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
                      "Filter",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Narrow down by category or date",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 22),
                    DropdownButtonFormField<String?>(
                      initialValue: tempCategoryId,
                      decoration: const InputDecoration(
                        labelText: "Category",
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text("All categories"),
                        ),
                        ...categories.map(
                          (c) => DropdownMenuItem<String?>(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        ),
                      ],
                      onChanged: (val) =>
                          setModalState(() => tempCategoryId = val),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Date Range",
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _DateField(
                            icon: Icons.event_rounded,
                            label: tempStart == null
                                ? "Start date"
                                : _formatDate(tempStart!),
                            borderColor: borderColor,
                            onTap: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: tempStart ?? now,
                                firstDate: DateTime(now.year - 10),
                                lastDate: tempEnd ?? now,
                              );
                              if (picked != null) {
                                setModalState(() => tempStart = picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateField(
                            icon: Icons.event_rounded,
                            label: tempEnd == null
                                ? "End date"
                                : _formatDate(tempEnd!),
                            borderColor: borderColor,
                            onTap: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: tempEnd ?? tempStart ?? now,
                                firstDate:
                                    tempStart ?? DateTime(now.year - 10),
                                lastDate: now,
                              );
                              if (picked != null) {
                                setModalState(() => tempEnd = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(
                                () => _filter = const _CategoryFilter(),
                              );
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              side: BorderSide(color: borderColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text("Reset"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(
                                () => _filter = _CategoryFilter(
                                  categoryId: tempCategoryId,
                                  startDate: tempStart,
                                  endDate: tempEnd,
                                ),
                              );
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              backgroundColor: const Color(0xFF37474F),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              "Apply Filters",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionControllerProvider);
    final types = ref.watch(transactionTypeControllerProvider);
    final filtered = _applyFilter(transactions);
    final grouped = _groupByCategory(filtered);
    final total = filtered.fold<double>(0, (s, t) => s + t.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Expenses by Category"),
        actions: [
          IconButton(
            tooltip: "Filter",
            onPressed: _openFilterSheet,
            icon: Badge(
              isLabelVisible: _filter.activeFilterCount > 0,
              label: Text("${_filter.activeFilterCount}"),
              child: const Icon(Icons.tune_rounded),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (_filter.activeFilterCount > 0)
            _buildActiveFilterChips(context, types),
          _buildTotalHeader(context, total, grouped.length),
          Expanded(
            child: grouped.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                    itemCount: grouped.length,
                    itemBuilder: (_, index) =>
                        _buildCategoryTile(context, grouped[index], total),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChips(
    BuildContext context,
    List<dynamic> types,
  ) {
    final chips = <Widget>[];
    if (_filter.categoryId != null) {
      final match = types.where((t) => t.id == _filter.categoryId);
      final name = match.isEmpty ? "Category" : match.first.name as String;
      chips.add(
        Chip(
          label: Text(name, style: const TextStyle(fontSize: 12)),
          onDeleted: () => setState(
            () => _filter = _CategoryFilter(
              startDate: _filter.startDate,
              endDate: _filter.endDate,
            ),
          ),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }
    if (_filter.startDate != null || _filter.endDate != null) {
      final label = _filter.startDate != null && _filter.endDate != null
          ? "${_formatDate(_filter.startDate!)} - ${_formatDate(_filter.endDate!)}"
          : _filter.startDate != null
          ? "From ${_formatDate(_filter.startDate!)}"
          : "Until ${_formatDate(_filter.endDate!)}";
      chips.add(
        Chip(
          label: Text(label, style: const TextStyle(fontSize: 12)),
          onDeleted: () => setState(
            () => _filter = _CategoryFilter(categoryId: _filter.categoryId),
          ),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          ...chips,
          ActionChip(
            label: const Text("Clear all"),
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => _filter = const _CategoryFilter()),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalHeader(BuildContext context, double total, int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Total Expenses",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  "${Currency.TAKA}${total.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Color(0xFFE74C3C),
                  ),
                ),
              ],
            ),
          ),
          Text(
            "$count ${count == 1 ? 'category' : 'categories'}",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(
    BuildContext context,
    _CategoryTotal category,
    double total,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _colorForCategory(category.categoryId);
    final fraction = total <= 0 ? 0.0 : (category.total / total).clamp(0, 1);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      elevation: 0,
      color: isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.black.withValues(alpha: 0.03),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(
          () => _filter = _CategoryFilter(
            categoryId: category.categoryId,
            startDate: _filter.startDate,
            endDate: _filter.endDate,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Text(
                      category.categoryName.isNotEmpty
                          ? category.categoryName[0].toUpperCase()
                          : "?",
                      style: TextStyle(color: color, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.categoryName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "${category.count} ${category.count == 1 ? 'transaction' : 'transactions'}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${Currency.TAKA}${category.total.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: color,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        "${(fraction * 100).toStringAsFixed(0)}%",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fraction.toDouble(),
                  minHeight: 6,
                  backgroundColor: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final filtersActive = _filter.activeFilterCount > 0;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.pie_chart_outline_rounded,
            size: 56,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            filtersActive
                ? "No expenses match your filters"
                : "No expenses yet",
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (filtersActive) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _filter = const _CategoryFilter()),
              child: const Text("Clear filters"),
            ),
          ],
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color borderColor;
  final VoidCallback onTap;

  const _DateField({
    required this.icon,
    required this.label,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}
