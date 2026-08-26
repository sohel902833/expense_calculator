import 'package:expense_calculator/constants/color.dart';
import 'package:expense_calculator/constants/currency.dart';
import 'package:expense_calculator/features/recurring/controller/recurring_rule_controller.dart';
import 'package:expense_calculator/features/transaction-type/controller/transaction_type_controller.dart';
import 'package:expense_calculator/models/recurring_rule_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _frequencyLabels = {
  RecurringFrequency.monthly: "Monthly",
  RecurringFrequency.weekly: "Weekly",
};

// DateTime.weekday values, displayed starting Sunday to match the app's
// example use case ("Every Sunday-Thursday").
const _weekdayOrder = [7, 1, 2, 3, 4, 5, 6];
const _weekdayLabels = {
  1: "Mon",
  2: "Tue",
  3: "Wed",
  4: "Thu",
  5: "Fri",
  6: "Sat",
  7: "Sun",
};

/// Opens the create/edit form for a recurring rule. Pass [editItem] to
/// pre-fill and update in place, otherwise a new rule is created.
Future<void> showRecurringRuleFormSheet(
  BuildContext context,
  WidgetRef ref, {
  RecurringRuleModel? editItem,
}) {
  final isEdit = editItem != null;

  final titleController = TextEditingController(text: editItem?.title ?? "");
  final amountController = TextEditingController(
    text: editItem == null || editItem.amount == 0
        ? ""
        : editItem.amount.toStringAsFixed(0),
  );
  final descController = TextEditingController(
    text: editItem?.description ?? "",
  );

  String type = editItem?.type ?? "Income";
  String? categoryId = editItem?.categoryId;
  String? categoryName = editItem?.categoryName;
  String? spentFromIncomeId = editItem?.spentFromIncomeId;
  String frequency = editItem?.frequency ?? RecurringFrequency.monthly;
  int dayOfMonth = editItem?.dayOfMonth ?? 1;
  List<int> weekdays = editItem?.weekdays.isNotEmpty == true
      ? List<int>.from(editItem!.weekdays)
      : List<int>.from(_weekdayOrder);
  bool isActive = editItem?.isActive ?? true;
  bool saving = false;

  final formKey = GlobalKey<FormState>();

  return showModalBottomSheet(
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

        final transactionTypes = ref.watch(transactionTypeControllerProvider);
        final categories = transactionTypes
            .where((t) => t.type == type)
            .toList();
        final incomeSources = transactionTypes
            .where((t) => t.type == "Income")
            .toList();
        if (categoryId != null && !categories.any((c) => c.id == categoryId)) {
          categoryId = null;
          categoryName = null;
        }

        Future<void> save() async {
          if (!formKey.currentState!.validate()) return;
          if (categoryId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please select a category")),
            );
            return;
          }
          if (type == "Expense" && spentFromIncomeId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Select an income to spend from")),
            );
            return;
          }
          if (frequency == RecurringFrequency.weekly && weekdays.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Select at least one day")),
            );
            return;
          }

          final rule = RecurringRuleModel(
            id: isEdit ? editItem.id : '',
            userId: isEdit ? editItem.userId : null,
            title: titleController.text.trim(),
            type: type,
            categoryId: categoryId!,
            categoryName: categoryName ?? '',
            amount: double.tryParse(amountController.text.trim()) ?? 0,
            spentFromIncomeId: type == "Expense" ? spentFromIncomeId : null,
            description: descController.text.trim(),
            frequency: frequency,
            dayOfMonth: frequency == RecurringFrequency.monthly
                ? dayOfMonth
                : null,
            weekdays: frequency == RecurringFrequency.weekly ? weekdays : const [],
            startDate: isEdit ? editItem.startDate : DateTime.now(),
            lastProcessedDate: isEdit ? editItem.lastProcessedDate : null,
            isActive: isActive,
            createdAt: isEdit ? editItem.createdAt : null,
          );

          setModalState(() => saving = true);
          final controller = ref.read(recurringRuleControllerProvider.notifier);
          try {
            if (isEdit) {
              await controller.updateRule(rule);
            } else {
              await controller.addRule(rule);
            }
          } catch (e) {
            setModalState(() => saving = false);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Failed to save rule: $e")),
              );
            }
            return;
          }
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(isEdit ? "Rule updated" : "Rule created")),
            );
          }
        }

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
              child: Form(
                key: formKey,
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
                      isEdit ? "Edit Recurring Rule" : "New Recurring Rule",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: "Title",
                        hintText: "e.g. Salary, Rent, Office Travel",
                        prefixIcon: Icon(Icons.label_outline_rounded),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "Please enter a title"
                          : null,
                    ),
                    const SizedBox(height: 20),
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
                            label: "Income",
                            selected: type == "Income",
                            onTap: () => setModalState(() {
                              type = "Income";
                              categoryId = null;
                              categoryName = null;
                              spentFromIncomeId = null;
                            }),
                          ),
                          const SizedBox(width: 4),
                          _SegmentOption(
                            label: "Expense",
                            selected: type == "Expense",
                            onTap: () => setModalState(() {
                              type = "Expense";
                              categoryId = null;
                              categoryName = null;
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: categoryId,
                      decoration: InputDecoration(
                        labelText: "Category",
                        prefixIcon: const Icon(Icons.category_outlined),
                        hintText: categories.isEmpty
                            ? "No categories yet"
                            : null,
                      ),
                      items: categories
                          .map(
                            (c) =>
                                DropdownMenuItem(value: c.id, child: Text(c.name)),
                          )
                          .toList(),
                      onChanged: (val) => setModalState(() {
                        categoryId = val;
                        categoryName = categories
                            .firstWhere((c) => c.id == val)
                            .name;
                      }),
                      validator: (val) => val == null ? "Select a category" : null,
                    ),
                    if (type == "Expense") ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: spentFromIncomeId,
                        decoration: InputDecoration(
                          labelText: "Expense from Income",
                          prefixIcon: const Icon(
                            Icons.account_balance_wallet_outlined,
                          ),
                          hintText: incomeSources.isEmpty
                              ? "No income sources yet"
                              : null,
                        ),
                        items: incomeSources
                            .map(
                              (t) => DropdownMenuItem(
                                value: t.id,
                                child: Text(t.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setModalState(() => spentFromIncomeId = val),
                        validator: (val) => val == null
                            ? "Select an income to spend from"
                            : null,
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: "Amount",
                        prefixText: "${Currency.TAKA} ",
                      ),
                      validator: (v) {
                        final value = double.tryParse((v ?? '').trim());
                        if (value == null || value <= 0) {
                          return "Enter an amount greater than 0";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Repeats",
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _frequencyLabels.entries
                          .map(
                            (e) => _PillOption(
                              label: e.value,
                              selected: frequency == e.key,
                              onTap: () =>
                                  setModalState(() => frequency = e.key),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                    if (frequency == RecurringFrequency.monthly)
                      DropdownButtonFormField<int>(
                        initialValue: dayOfMonth,
                        decoration: const InputDecoration(
                          labelText: "Day of month",
                          prefixIcon: Icon(Icons.event_repeat_rounded),
                        ),
                        items: List.generate(
                          31,
                          (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text("${i + 1}${_ordinalSuffix(i + 1)}"),
                          ),
                        ),
                        onChanged: (val) =>
                            setModalState(() => dayOfMonth = val!),
                      )
                    else ...[
                      Text(
                        "All days selected by default -- tap to deselect.",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _weekdayOrder
                            .map(
                              (w) => _PillOption(
                                label: _weekdayLabels[w]!,
                                selected: weekdays.contains(w),
                                onTap: () => setModalState(() {
                                  if (weekdays.contains(w)) {
                                    weekdays.remove(w);
                                  } else {
                                    weekdays.add(w);
                                  }
                                }),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descController,
                      maxLines: 2,
                      minLines: 1,
                      decoration: const InputDecoration(
                        labelText: "Description (optional)",
                        hintText: "Add a short note",
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Active"),
                      subtitle: const Text(
                        "Paused rules stop generating new occurrences",
                      ),
                      value: isActive,
                      onChanged: (val) => setModalState(() => isActive = val),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: saving ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: borderColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text("Cancel"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: saving ? null : save,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: tabColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: tabColor.withValues(
                                alpha: 0.6,
                              ),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: saving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    isEdit ? "Update Rule" : "Save Rule",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

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

class _SegmentOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentOption({
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

class _PillOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PillOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? tabColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? tabColor : Colors.grey.withValues(alpha: 0.4),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? tabColor : Colors.grey,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
