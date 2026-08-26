import 'package:expense_calculator/constants/color.dart';
import 'package:expense_calculator/constants/currency.dart';
import 'package:expense_calculator/features/recurring/controller/recurring_rule_controller.dart';
import 'package:expense_calculator/features/recurring/widgets/recurring_rule_form_sheet.dart';
import 'package:expense_calculator/models/recurring_rule_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _weekdayOrder = [7, 1, 2, 3, 4, 5, 6];
const _weekdayShort = {
  1: "Mon",
  2: "Tue",
  3: "Wed",
  4: "Thu",
  5: "Fri",
  6: "Sat",
  7: "Sun",
};

String _ordinalSuffix(int n) {
  if (n >= 11 && n <= 13) return "th";
  switch (n % 10) {
    case 1:
      return "st";
    case 2:
      return "nd";
    case 3:
      return "rd";
    default:
      return "th";
  }
}

String _frequencySummary(RecurringRuleModel rule) {
  if (rule.frequency == RecurringFrequency.monthly) {
    final day = rule.dayOfMonth ?? 1;
    return "Monthly on the $day${_ordinalSuffix(day)}";
  }
  final selected = _weekdayOrder.where((w) => rule.weekdays.contains(w));
  if (selected.length == 7) return "Every day";
  return "Every ${selected.map((w) => _weekdayShort[w]).join(", ")}";
}

class RecurringRuleListScreen extends ConsumerWidget {
  static const routeName = '/recurring-rule-list-screen';
  const RecurringRuleListScreen({super.key});

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    RecurringRuleModel rule,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Delete Rule"),
        content: Text('Delete "${rule.title}"? This can\'t be undone.'),
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
                  .read(recurringRuleControllerProvider.notifier)
                  .deleteRule(rule.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Rule deleted")));
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
    final rules = ref.watch(recurringRuleControllerProvider);
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(title: const Text("Recurring Rules")),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: bottomSafeArea),
        child: FloatingActionButton(
          onPressed: () => showRecurringRuleFormSheet(context, ref),
          backgroundColor: tabColor,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      ),
      body: rules.isEmpty
          ? _emptyState(context)
          : ListView.builder(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 100 + bottomSafeArea),
              itemCount: rules.length,
              itemBuilder: (_, i) => _ruleTile(context, ref, isDark, rules[i]),
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
              Icons.event_repeat_rounded,
              size: 56,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              "No recurring rules yet",
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

  Widget _ruleTile(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    RecurringRuleModel rule,
  ) {
    final typeColor = rule.type == "Income"
        ? const Color(0xFF2ECC71)
        : const Color(0xFFE74C3C);
    return Opacity(
      opacity: rule.isActive ? 1 : 0.5,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
        ),
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              rule.title,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (!rule.isActive) ...[
                            const SizedBox(width: 6),
                            _badge("Paused", Colors.grey),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _badge(rule.categoryName, tabColor),
                          _badge(_frequencySummary(rule), Colors.grey),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  "${rule.type == "Income" ? "+" : "-"}${Currency.TAKA}${rule.amount.toStringAsFixed(0)}",
                  style: TextStyle(fontWeight: FontWeight.w700, color: typeColor),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                  onSelected: (value) {
                    if (value == "edit") {
                      showRecurringRuleFormSheet(context, ref, editItem: rule);
                    } else if (value == "toggle") {
                      ref
                          .read(recurringRuleControllerProvider.notifier)
                          .setActive(rule, !rule.isActive);
                    } else if (value == "delete") {
                      _confirmDelete(context, ref, rule);
                    }
                  },
                  itemBuilder: (context) => [
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
                    PopupMenuItem(
                      value: "toggle",
                      child: Row(
                        children: [
                          Icon(
                            rule.isActive
                                ? Icons.pause_circle_outline_rounded
                                : Icons.play_circle_outline_rounded,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(rule.isActive ? "Pause" : "Resume"),
                        ],
                      ),
                    ),
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
                          Text("Delete", style: TextStyle(color: Color(0xFFE74C3C))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
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
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
