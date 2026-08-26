import 'package:expense_calculator/constants/color.dart';
import 'package:expense_calculator/constants/currency.dart';
import 'package:expense_calculator/features/recurring/controller/recurring_occurrence_controller.dart';
import 'package:expense_calculator/features/recurring/screens/recurring_rule_list_screen.dart';
import 'package:expense_calculator/features/recurring/utils/recurrence_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

Map<DateTime, List<PendingOccurrence>> _groupByDate(
  List<PendingOccurrence> items,
) {
  final map = <DateTime, List<PendingOccurrence>>{};
  for (final item in items) {
    map.putIfAbsent(_dayOnly(item.date), () => []).add(item);
  }
  return map;
}

class RecurringTransactionsScreen extends ConsumerStatefulWidget {
  static const routeName = '/recurring-transactions-screen';
  const RecurringTransactionsScreen({super.key});

  @override
  ConsumerState<RecurringTransactionsScreen> createState() =>
      _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState
    extends ConsumerState<RecurringTransactionsScreen> {
  final Set<PendingOccurrence> _selected = {};
  bool _applying = false;
  final Set<PendingOccurrence> _busy = {};

  String _groupLabel(DateTime date, {required bool isUpcomingTab}) {
    final today = _dayOnly(DateTime.now());
    if (date == today) return "Today";
    if (isUpcomingTab && date == today.add(const Duration(days: 1))) {
      return "Tomorrow";
    }
    if (!isUpcomingTab && date.isBefore(today)) {
      return "${date.day} ${_monthNames[date.month - 1]} ${date.year} (Overdue)";
    }
    return "${date.day} ${_monthNames[date.month - 1]} ${date.year}";
  }

  Future<void> _applyAll(List<PendingOccurrence> pending) async {
    setState(() => _applying = true);
    try {
      await ref
          .read(recurringOccurrenceControllerProvider.notifier)
          .applyOccurrences(pending);
      _selected.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${pending.length} transaction(s) created")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to apply: $e")));
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  Future<void> _deleteSelected() async {
    final toDelete = List<PendingOccurrence>.from(_selected);
    setState(() => _selected.clear());
    final controller = ref.read(recurringOccurrenceControllerProvider.notifier);
    for (final occurrence in toDelete) {
      await controller.skipOccurrence(occurrence);
    }
  }

  Future<void> _runNow(PendingOccurrence occurrence) async {
    setState(() => _busy.add(occurrence));
    try {
      await ref
          .read(recurringOccurrenceControllerProvider.notifier)
          .applyOccurrences([occurrence], bumpLastProcessed: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${occurrence.rule.title} created")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(occurrence));
    }
  }

  Future<void> _markCompleted(PendingOccurrence occurrence) async {
    setState(() => _busy.add(occurrence));
    await ref
        .read(recurringOccurrenceControllerProvider.notifier)
        .skipOccurrence(occurrence);
    if (mounted) setState(() => _busy.remove(occurrence));
  }

  @override
  Widget build(BuildContext context) {
    final pendingToday = ref.watch(pendingTodayOccurrencesProvider);
    final upcoming = ref.watch(upcomingOccurrencesProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Recurring Transactions"),
          bottom: const TabBar(
            tabs: [Tab(text: "Today"), Tab(text: "Upcoming")],
          ),
          actions: [
            IconButton(
              tooltip: "Manage Rules",
              onPressed: () => Navigator.pushNamed(
                context,
                RecurringRuleListScreen.routeName,
              ),
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildTodayTab(context, pendingToday),
            _buildUpcomingTab(context, upcoming),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayTab(BuildContext context, List<PendingOccurrence> pending) {
    if (pending.isEmpty) {
      return _emptyState(
        icon: Icons.task_alt_rounded,
        title: "You're all caught up",
        subtitle: "No pending recurring transactions right now.",
      );
    }

    final allSelected = _selected.length == pending.length;
    final grouped = _groupByDate(pending);
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Checkbox(
                value: allSelected,
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selected
                        ..clear()
                        ..addAll(pending);
                    } else {
                      _selected.clear();
                    }
                  });
                },
              ),
              const Text("Select all"),
              const Spacer(),
              TextButton.icon(
                onPressed: _selected.isEmpty ? null : _deleteSelected,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: Text("Delete (${_selected.length})"),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFE74C3C),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: grouped.entries
                    .expand(
                      (entry) => [
                        _groupHeader(
                          _groupLabel(entry.key, isUpcomingTab: false),
                        ),
                        ...entry.value.map(
                          (occurrence) => _TodayOccurrenceTile(
                            occurrence: occurrence,
                            selected: _selected.contains(occurrence),
                            onToggle: () => setState(() {
                              if (_selected.contains(occurrence)) {
                                _selected.remove(occurrence);
                              } else {
                                _selected.add(occurrence);
                              }
                            }),
                          ),
                        ),
                      ],
                    )
                    .toList(),
              ),
              Positioned(
                top: 4,
                right: 16,
                child: _TotalsOverlayCard(pending: pending),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomSafeArea),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applying ? null : () => _applyAll(pending),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: tabColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _applying
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      "Apply ${pending.length}",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingTab(
    BuildContext context,
    List<PendingOccurrence> upcoming,
  ) {
    if (upcoming.isEmpty) {
      return _emptyState(
        icon: Icons.event_available_rounded,
        title: "Nothing coming up",
        subtitle: "No recurring transactions due in the next few days.",
      );
    }

    final grouped = _groupByDate(upcoming);
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomSafeArea),
      children: grouped.entries
          .expand(
            (entry) => [
              _groupHeader(_groupLabel(entry.key, isUpcomingTab: true)),
              ...entry.value.map(
                (occurrence) => _UpcomingOccurrenceTile(
                  occurrence: occurrence,
                  busy: _busy.contains(occurrence),
                  onRunNow: () => _runNow(occurrence),
                  onMarkCompleted: () => _markCompleted(occurrence),
                ),
              ),
            ],
          )
          .toList(),
    );
  }

  Widget _groupHeader(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
    child: Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
    ),
  );

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating top-right summary of what "Apply" will actually create --
/// total Income vs total Expense across the currently pending occurrences.
class _TotalsOverlayCard extends StatelessWidget {
  final List<PendingOccurrence> pending;

  const _TotalsOverlayCard({required this.pending});

  @override
  Widget build(BuildContext context) {
    if (pending.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double income = 0;
    double expense = 0;
    for (final occurrence in pending) {
      if (occurrence.rule.type == "Income") {
        income += occurrence.rule.amount;
      } else {
        expense += occurrence.rule.amount;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (income > 0)
            _totalLine("Income", income, const Color(0xFF2ECC71)),
          if (income > 0 && expense > 0) const SizedBox(height: 4),
          if (expense > 0)
            _totalLine("Expense", expense, const Color(0xFFE74C3C)),
        ],
      ),
    );
  }

  Widget _totalLine(String label, double amount, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Text(
          "$label  ${Currency.TAKA}${amount.toStringAsFixed(0)}",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TodayOccurrenceTile extends StatelessWidget {
  final PendingOccurrence occurrence;
  final bool selected;
  final VoidCallback onToggle;

  const _TodayOccurrenceTile({
    required this.occurrence,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rule = occurrence.rule;
    final typeColor = rule.type == "Income"
        ? const Color(0xFF2ECC71)
        : const Color(0xFFE74C3C);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
      ),
      child: CheckboxListTile(
        value: selected,
        onChanged: (_) => onToggle(),
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(rule.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(rule.categoryName),
        secondary: Text(
          "${rule.type == "Income" ? "+" : "-"}${Currency.TAKA}${rule.amount.toStringAsFixed(0)}",
          style: TextStyle(fontWeight: FontWeight.w700, color: typeColor),
        ),
      ),
    );
  }
}

class _UpcomingOccurrenceTile extends StatelessWidget {
  final PendingOccurrence occurrence;
  final bool busy;
  final VoidCallback onRunNow;
  final VoidCallback onMarkCompleted;

  const _UpcomingOccurrenceTile({
    required this.occurrence,
    required this.busy,
    required this.onRunNow,
    required this.onMarkCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rule = occurrence.rule;
    final typeColor = rule.type == "Income"
        ? const Color(0xFF2ECC71)
        : const Color(0xFFE74C3C);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
      ),
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
                      rule.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      rule.categoryName,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Text(
                "${rule.type == "Income" ? "+" : "-"}${Currency.TAKA}${rule.amount.toStringAsFixed(0)}",
                style: TextStyle(fontWeight: FontWeight.w700, color: typeColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (busy)
            const Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onMarkCompleted,
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text("Mark completed"),
                ),
                const SizedBox(width: 4),
                FilledButton.icon(
                  onPressed: onRunNow,
                  icon: const Icon(Icons.bolt_rounded, size: 18),
                  label: const Text("Run now"),
                  style: FilledButton.styleFrom(backgroundColor: tabColor),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
