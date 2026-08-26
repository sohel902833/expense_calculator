import 'package:expense_calculator/common/modals/transaction_modals.dart';
import 'package:expense_calculator/constants/currency.dart';
import 'package:expense_calculator/features/transaction-type/controller/transaction_type_controller.dart';
import 'package:expense_calculator/features/transactions/controller/transaction_controller.dart';
import 'package:expense_calculator/models/transaction_model.dart';
import 'package:expense_calculator/models/transaction_type_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(DateTime d) =>
    "${d.day} ${_monthNames[d.month - 1]} ${d.year}";

/// Immutable description of the currently selected time period filter.
/// tab is one of: Date | Month | Year | Range.
class _PeriodFilter {
  final String tab;
  final bool isToday;
  final DateTime? customDate;
  final String monthOption; // current | previous | custom
  final int customMonthYear;
  final int customMonthMonth;
  final String yearOption; // current | previous | custom
  final int customYear;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;

  _PeriodFilter({
    this.tab = "Month",
    this.isToday = true,
    this.customDate,
    this.monthOption = "current",
    int? customMonthYear,
    int? customMonthMonth,
    this.yearOption = "current",
    int? customYear,
    this.rangeStart,
    this.rangeEnd,
  }) : customMonthYear = customMonthYear ?? DateTime.now().year,
       customMonthMonth = customMonthMonth ?? DateTime.now().month,
       customYear = customYear ?? DateTime.now().year;

  _PeriodFilter copyWith({
    String? tab,
    bool? isToday,
    DateTime? customDate,
    String? monthOption,
    int? customMonthYear,
    int? customMonthMonth,
    String? yearOption,
    int? customYear,
    DateTime? rangeStart,
    DateTime? rangeEnd,
  }) {
    return _PeriodFilter(
      tab: tab ?? this.tab,
      isToday: isToday ?? this.isToday,
      customDate: customDate ?? this.customDate,
      monthOption: monthOption ?? this.monthOption,
      customMonthYear: customMonthYear ?? this.customMonthYear,
      customMonthMonth: customMonthMonth ?? this.customMonthMonth,
      yearOption: yearOption ?? this.yearOption,
      customYear: customYear ?? this.customYear,
      rangeStart: rangeStart ?? this.rangeStart,
      rangeEnd: rangeEnd ?? this.rangeEnd,
    );
  }

  bool get isDefault => tab == "Month" && monthOption == "current";

  bool get isComplete =>
      tab != "Range" || (rangeStart != null && rangeEnd != null);

  DateTimeRange? resolve() {
    final now = DateTime.now();
    switch (tab) {
      case "Date":
        final d = isToday ? now : (customDate ?? now);
        final day = DateTime(d.year, d.month, d.day);
        return DateTimeRange(start: day, end: day);
      case "Year":
        final y = yearOption == "current"
            ? now.year
            : yearOption == "previous"
            ? now.year - 1
            : customYear;
        return DateTimeRange(
          start: DateTime(y, 1, 1),
          end: DateTime(y, 12, 31),
        );
      case "Range":
        if (rangeStart == null || rangeEnd == null) return null;
        return DateTimeRange(start: rangeStart!, end: rangeEnd!);
      case "Month":
      default:
        int y, m;
        if (monthOption == "current") {
          y = now.year;
          m = now.month;
        } else if (monthOption == "previous") {
          if (now.month == 1) {
            y = now.year - 1;
            m = 12;
          } else {
            y = now.year;
            m = now.month - 1;
          }
        } else {
          y = customMonthYear;
          m = customMonthMonth;
        }
        final lastDay = DateTime(y, m + 1, 0).day;
        return DateTimeRange(
          start: DateTime(y, m, 1),
          end: DateTime(y, m, lastDay),
        );
    }
  }

  String label() {
    final now = DateTime.now();
    switch (tab) {
      case "Date":
        if (isToday) return "Today";
        return _formatDate(customDate ?? now);
      case "Year":
        if (yearOption == "current") return "This Year";
        if (yearOption == "previous") return "${now.year - 1}";
        return "$customYear";
      case "Range":
        if (rangeStart == null || rangeEnd == null) return "Select range";
        return "${_formatDate(rangeStart!)} - ${_formatDate(rangeEnd!)}";
      case "Month":
      default:
        if (monthOption == "current") return "This Month";
        if (monthOption == "previous") return "Previous Month";
        return "${_monthNames[customMonthMonth - 1]} $customMonthYear";
    }
  }
}

/// Shared filter state for the Transaction screen. Lives in a provider
/// (rather than TransactionScreen's own State) so DashboardScreen can also
/// read the active-filter count and open the filter sheet from its own
/// floating button, positioned alongside the "add" button in the same Stack.
class TransactionFilterState {
  final String typeFilter; // All | Income | Expense
  final String? categoryId;
  final bool showDeleted;
  final _PeriodFilter period;

  TransactionFilterState({
    this.typeFilter = "All",
    this.categoryId,
    this.showDeleted = false,
    _PeriodFilter? period,
  }) : period = period ?? _PeriodFilter();

  TransactionFilterState copyWith({
    String? typeFilter,
    String? categoryId,
    bool clearCategoryId = false,
    bool? showDeleted,
    _PeriodFilter? period,
  }) {
    return TransactionFilterState(
      typeFilter: typeFilter ?? this.typeFilter,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      showDeleted: showDeleted ?? this.showDeleted,
      period: period ?? this.period,
    );
  }

  int get activeFilterCount =>
      (typeFilter != "All" ? 1 : 0) +
      (categoryId != null ? 1 : 0) +
      (!period.isDefault ? 1 : 0) +
      (showDeleted ? 1 : 0);
}

final transactionFilterProvider = StateProvider<TransactionFilterState>(
  (ref) => TransactionFilterState(),
);

Color _typeColor(String type) =>
    type == "Income" ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C);

class TransactionScreen extends ConsumerStatefulWidget {
  const TransactionScreen({Key? key}) : super(key: key);

  @override
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends ConsumerState<TransactionScreen> {
  Future<void> _onRefresh() async {
    ref.invalidate(transactionControllerProvider);
    ref.invalidate(transactionTypeControllerProvider);
    await Future.delayed(const Duration(milliseconds: 400));
  }

  List<TransactionModel> _applyFilters(
    List<TransactionModel> list,
    TransactionFilterState filterState,
  ) {
    final range = filterState.period.resolve();
    return list.where((t) {
      if (!filterState.showDeleted && t.isDeleted) return false;
      if (filterState.typeFilter != "All" && t.type != filterState.typeFilter) {
        return false;
      }
      if (filterState.categoryId != null &&
          t.categoryId != filterState.categoryId) {
        return false;
      }
      if (range != null) {
        final d = DateTime(t.date.year, t.date.month, t.date.day);
        final start = DateTime(
          range.start.year,
          range.start.month,
          range.start.day,
        );
        final end = DateTime(range.end.year, range.end.month, range.end.day);
        if (d.isBefore(start) || d.isAfter(end)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionControllerProvider);
    final transactionTypes = ref.watch(transactionTypeControllerProvider);
    final filterState = ref.watch(transactionFilterProvider);
    final filtered = _applyFilters(transactions, filterState);
    final activeFiltered = filtered.where((t) => !t.isDeleted);

    final totalIncome = activeFiltered
        .where((t) => t.type == "Income")
        .fold<double>(0, (s, t) => s + t.amount);
    final totalExpense = activeFiltered
        .where((t) => t.type == "Expense")
        .fold<double>(0, (s, t) => s + t.amount);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildSummaryBar(context, totalIncome, totalExpense, filterState),
          if (filterState.activeFilterCount > 0)
            _buildActiveFilterChips(context, transactionTypes, filterState),
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
                        _buildEmptyState(context, filterState),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 110),
                      itemCount: filtered.length,
                      itemBuilder: (_, index) =>
                          _buildTransactionTile(context, filtered[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(
    BuildContext context,
    double income,
    double expense,
    TransactionFilterState filterState,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final net = income - expense;
    final dividerColor = (isDark ? Colors.white : Colors.black).withValues(
      alpha: 0.1,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                filterState.period.label(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  "Income",
                  income,
                  const Color(0xFF2ECC71),
                ),
              ),
              Container(width: 1, height: 30, color: dividerColor),
              Expanded(
                child: _summaryItem(
                  "Expense",
                  expense,
                  const Color(0xFFE74C3C),
                ),
              ),
              Container(width: 1, height: 30, color: dividerColor),
              Expanded(
                child: _summaryItem(
                  "Net",
                  net,
                  net >= 0 ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          "${Currency.TAKA}${value.toStringAsFixed(0)}",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: color,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFilterChips(
    BuildContext context,
    List<TransactionTypeModel> types,
    TransactionFilterState filterState,
  ) {
    final notifier = ref.read(transactionFilterProvider.notifier);
    final chips = <Widget>[];

    if (filterState.typeFilter != "All") {
      chips.add(
        _filterChip(
          filterState.typeFilter,
          () => notifier.state = filterState.copyWith(typeFilter: "All"),
        ),
      );
    }
    if (filterState.categoryId != null) {
      final match = types.where((t) => t.id == filterState.categoryId);
      final name = match.isEmpty ? "Category" : match.first.name;
      chips.add(
        _filterChip(
          name,
          () => notifier.state = filterState.copyWith(clearCategoryId: true),
        ),
      );
    }
    if (!filterState.period.isDefault) {
      chips.add(
        _filterChip(
          filterState.period.label(),
          () => notifier.state = filterState.copyWith(period: _PeriodFilter()),
        ),
      );
    }
    if (filterState.showDeleted) {
      chips.add(
        _filterChip(
          "Showing deleted",
          () => notifier.state = filterState.copyWith(showDeleted: false),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          ...chips,
          ActionChip(
            label: const Text("Clear all"),
            visualDensity: VisualDensity.compact,
            onPressed: () => notifier.state = TransactionFilterState(),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, VoidCallback onDeleted) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onDeleted: onDeleted,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    TransactionFilterState filterState,
  ) {
    final filtersActive = filterState.activeFilterCount > 0;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 56,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            filtersActive
                ? "No transactions match your filters"
                : "No transactions yet",
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            filtersActive
                ? "Try adjusting or clearing your filters"
                : "Tap the add button to record one",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          if (filtersActive) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => ref
                  .read(transactionFilterProvider.notifier)
                  .state = TransactionFilterState(),
              child: const Text("Clear filters"),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, TransactionModel t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _typeColor(t.type);
    final sign = t.type == "Income" ? "+" : "-";

    return Opacity(
      opacity: t.isDeleted ? 0.55 : 1,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        elevation: 0,
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 4,
          ),
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(
              t.type == "Income"
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: color,
            ),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  t.categoryName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (t.recurringRuleId != null) ...[
                const SizedBox(width: 6),
                Tooltip(
                  message: "Created from a recurring rule",
                  child: Icon(
                    Icons.repeat_rounded,
                    size: 14,
                    color: Colors.grey.withValues(alpha: 0.8),
                  ),
                ),
              ],
              if (t.isDeleted) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "Deleted",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(
            t.description.isEmpty
                ? _formatDate(t.date)
                : "${_formatDate(t.date)} • ${t.description}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "$sign${Currency.TAKA}${t.amount.toStringAsFixed(0)}",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontSize: 15,
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                onSelected: (value) {
                  if (value == "edit") {
                    TransactionModals.showAddTransactionModal(
                      context,
                      ref,
                      editItem: t,
                    );
                  } else if (value == "delete") {
                    _confirmSoftDelete(context, t.id);
                  } else if (value == "restore") {
                    _restoreTransaction(context, t.id);
                  }
                },
                itemBuilder: (context) => [
                  if (!t.isDeleted)
                    const PopupMenuItem(
                      value: "edit",
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 10),
                          Text("Edit"),
                        ],
                      ),
                    ),
                  if (!t.isDeleted)
                    const PopupMenuItem(
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
                  if (t.isDeleted)
                    const PopupMenuItem(
                      value: "restore",
                      child: Row(
                        children: [
                          Icon(
                            Icons.restore_rounded,
                            size: 18,
                            color: Color(0xFF2ECC71),
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Restore",
                            style: TextStyle(color: Color(0xFF2ECC71)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSoftDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text("Delete Transaction"),
        content: const Text(
          "This transaction will be moved to deleted items. You can restore it later.",
        ),
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
                  .read(transactionControllerProvider.notifier)
                  .deleteTransaction(id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Transaction deleted")),
              );
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _restoreTransaction(BuildContext context, String id) {
    ref.read(transactionControllerProvider.notifier).restoreTransaction(id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Transaction restored")));
  }
}

/// Opens the transaction filter sheet. Callable from anywhere with a `ref`
/// (TransactionScreen doesn't own a floating button anymore -- DashboardScreen
/// renders it -- so this reads/writes [transactionFilterProvider] directly
/// instead of local widget state).
void showTransactionFilterSheet(BuildContext context, WidgetRef ref) {
  final types = ref.read(transactionTypeControllerProvider);
  final current = ref.read(transactionFilterProvider);

  String tempType = current.typeFilter;
  String? tempCategoryId = current.categoryId;
  bool tempShowDeleted = current.showDeleted;
  _PeriodFilter tempPeriod = current.period;

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

        final categories = tempType == "All"
            ? types
            : types.where((t) => t.type == tempType).toList();
        if (tempCategoryId != null &&
            !categories.any((c) => c.id == tempCategoryId)) {
          tempCategoryId = null;
        }

        final currentYear = DateTime.now().year;
        final years = List.generate(7, (i) => currentYear - i);

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
                    "Filter Transactions",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Narrow down what you see",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    "Type",
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _SegmentOption(
                          label: "All",
                          selected: tempType == "All",
                          color: const Color(0xFF37474F),
                          onTap: () => setModalState(() => tempType = "All"),
                        ),
                        const SizedBox(width: 4),
                        _SegmentOption(
                          label: "Income",
                          selected: tempType == "Income",
                          color: const Color(0xFF2ECC71),
                          onTap: () =>
                              setModalState(() => tempType = "Income"),
                        ),
                        const SizedBox(width: 4),
                        _SegmentOption(
                          label: "Expense",
                          selected: tempType == "Expense",
                          color: const Color(0xFFE74C3C),
                          onTap: () =>
                              setModalState(() => tempType = "Expense"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
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
                    "Period",
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _SegmentOption(
                          label: "Date",
                          selected: tempPeriod.tab == "Date",
                          color: const Color(0xFF37474F),
                          onTap: () => setModalState(
                            () => tempPeriod = tempPeriod.copyWith(
                              tab: "Date",
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        _SegmentOption(
                          label: "Month",
                          selected: tempPeriod.tab == "Month",
                          color: const Color(0xFF37474F),
                          onTap: () => setModalState(
                            () => tempPeriod = tempPeriod.copyWith(
                              tab: "Month",
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        _SegmentOption(
                          label: "Year",
                          selected: tempPeriod.tab == "Year",
                          color: const Color(0xFF37474F),
                          onTap: () => setModalState(
                            () => tempPeriod = tempPeriod.copyWith(
                              tab: "Year",
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        _SegmentOption(
                          label: "Range",
                          selected: tempPeriod.tab == "Range",
                          color: const Color(0xFF37474F),
                          onTap: () => setModalState(
                            () => tempPeriod = tempPeriod.copyWith(
                              tab: "Range",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (tempPeriod.tab == "Date") ...[
                    Row(
                      children: [
                        Expanded(
                          child: _ChoicePill(
                            label: "Today",
                            selected: tempPeriod.isToday,
                            onTap: () => setModalState(
                              () => tempPeriod = tempPeriod.copyWith(
                                isToday: true,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ChoicePill(
                            label: "Custom Date",
                            selected: !tempPeriod.isToday,
                            onTap: () => setModalState(
                              () => tempPeriod = tempPeriod.copyWith(
                                isToday: false,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!tempPeriod.isToday) ...[
                      const SizedBox(height: 12),
                      _DateField(
                        icon: Icons.event_rounded,
                        label: tempPeriod.customDate == null
                            ? "Select date"
                            : _formatDate(tempPeriod.customDate!),
                        borderColor: borderColor,
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: tempPeriod.customDate ?? now,
                            firstDate: DateTime(now.year - 10),
                            lastDate: now,
                          );
                          if (picked != null) {
                            setModalState(
                              () => tempPeriod = tempPeriod.copyWith(
                                customDate: picked,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ] else if (tempPeriod.tab == "Month") ...[
                    _ChoicePill(
                      label: "Current Month",
                      selected: tempPeriod.monthOption == "current",
                      onTap: () => setModalState(
                        () => tempPeriod = tempPeriod.copyWith(
                          monthOption: "current",
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ChoicePill(
                      label: "Previous Month",
                      selected: tempPeriod.monthOption == "previous",
                      onTap: () => setModalState(
                        () => tempPeriod = tempPeriod.copyWith(
                          monthOption: "previous",
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ChoicePill(
                      label: "Custom Month",
                      selected: tempPeriod.monthOption == "custom",
                      onTap: () => setModalState(
                        () => tempPeriod = tempPeriod.copyWith(
                          monthOption: "custom",
                        ),
                      ),
                    ),
                    if (tempPeriod.monthOption == "custom") ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: tempPeriod.customMonthMonth,
                              decoration: const InputDecoration(
                                labelText: "Month",
                              ),
                              items: List.generate(
                                12,
                                (i) => DropdownMenuItem(
                                  value: i + 1,
                                  child: Text(_monthNames[i]),
                                ),
                              ),
                              onChanged: (val) => setModalState(
                                () => tempPeriod = tempPeriod.copyWith(
                                  customMonthMonth: val,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: tempPeriod.customMonthYear,
                              decoration: const InputDecoration(
                                labelText: "Year",
                              ),
                              items: years
                                  .map(
                                    (y) => DropdownMenuItem(
                                      value: y,
                                      child: Text("$y"),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) => setModalState(
                                () => tempPeriod = tempPeriod.copyWith(
                                  customMonthYear: val,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ] else if (tempPeriod.tab == "Year") ...[
                    _ChoicePill(
                      label: "This Year",
                      selected: tempPeriod.yearOption == "current",
                      onTap: () => setModalState(
                        () => tempPeriod = tempPeriod.copyWith(
                          yearOption: "current",
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ChoicePill(
                      label: "Previous Year",
                      selected: tempPeriod.yearOption == "previous",
                      onTap: () => setModalState(
                        () => tempPeriod = tempPeriod.copyWith(
                          yearOption: "previous",
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ChoicePill(
                      label: "Custom Year",
                      selected: tempPeriod.yearOption == "custom",
                      onTap: () => setModalState(
                        () => tempPeriod = tempPeriod.copyWith(
                          yearOption: "custom",
                        ),
                      ),
                    ),
                    if (tempPeriod.yearOption == "custom") ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: tempPeriod.customYear,
                        decoration: const InputDecoration(labelText: "Year"),
                        items: years
                            .map(
                              (y) => DropdownMenuItem(
                                value: y,
                                child: Text("$y"),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => setModalState(
                          () => tempPeriod = tempPeriod.copyWith(
                            customYear: val,
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _DateField(
                            icon: Icons.event_rounded,
                            label: tempPeriod.rangeStart == null
                                ? "Start date"
                                : _formatDate(tempPeriod.rangeStart!),
                            borderColor: borderColor,
                            onTap: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: tempPeriod.rangeStart ?? now,
                                firstDate: DateTime(now.year - 10),
                                lastDate: tempPeriod.rangeEnd ?? now,
                              );
                              if (picked != null) {
                                setModalState(
                                  () => tempPeriod = tempPeriod.copyWith(
                                    rangeStart: picked,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateField(
                            icon: Icons.event_rounded,
                            label: tempPeriod.rangeEnd == null
                                ? "End date"
                                : _formatDate(tempPeriod.rangeEnd!),
                            borderColor: borderColor,
                            onTap: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate:
                                    tempPeriod.rangeEnd ??
                                    tempPeriod.rangeStart ??
                                    now,
                                firstDate:
                                    tempPeriod.rangeStart ??
                                    DateTime(now.year - 10),
                                lastDate: now,
                              );
                              if (picked != null) {
                                setModalState(
                                  () => tempPeriod = tempPeriod.copyWith(
                                    rangeEnd: picked,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () =>
                        setModalState(() => tempShowDeleted = !tempShowDeleted),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.restore_from_trash_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text("Show deleted transactions"),
                          ),
                          Switch(
                            value: tempShowDeleted,
                            onChanged: (val) =>
                                setModalState(() => tempShowDeleted = val),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            ref.read(transactionFilterProvider.notifier).state =
                                TransactionFilterState();
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                            if (!tempPeriod.isComplete) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Please select both start and end dates",
                                  ),
                                ),
                              );
                              return;
                            }
                            ref.read(transactionFilterProvider.notifier).state =
                                TransactionFilterState(
                                  typeFilter: tempType,
                                  categoryId: tempCategoryId,
                                  showDeleted: tempShowDeleted,
                                  period: tempPeriod,
                                );
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
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

class _SegmentOption extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _SegmentOption({
    required this.label,
    required this.selected,
    required this.color,
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
            color: selected
                ? color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? color : Colors.grey,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = Color(0xFF37474F);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? accent
                : (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.15,
                  ),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 18,
              color: selected ? accent : Colors.grey,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? accent : null,
              ),
            ),
          ],
        ),
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
