import 'package:expense_calculator/constants/color.dart';
import 'package:expense_calculator/constants/currency.dart';
import 'package:expense_calculator/features/budget/controller/budget_controller.dart';
import 'package:expense_calculator/features/transaction-type/controller/transaction_type_controller.dart';
import 'package:expense_calculator/models/budget_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(DateTime d) =>
    "${d.day} ${_monthNames[d.month - 1]} ${d.year}";

const _periodLabels = {
  BudgetPeriod.monthly: "Monthly",
  BudgetPeriod.weekly: "Weekly",
  BudgetPeriod.yearly: "Yearly",
  BudgetPeriod.custom: "Custom",
  BudgetPeriod.ongoing: "Ongoing",
};

/// Opens the create/edit/clone budget form. Pass [editItem] to pre-fill the
/// form; an [editItem] with an empty `id` (as produced when cloning) is
/// treated as a new budget on save, otherwise it updates that budget.
Future<void> showBudgetFormSheet(
  BuildContext context,
  WidgetRef ref, {
  BudgetModel? editItem,
  bool isClone = false,
}) {
  final isEdit = editItem != null && editItem.id.isNotEmpty;

  final nameController = TextEditingController(text: editItem?.name ?? "");
  final amountController = TextEditingController(
    text: editItem == null || editItem.amount == 0
        ? ""
        : editItem.amount.toStringAsFixed(0),
  );

  String budgetType = editItem?.budgetType ?? BudgetType.overall;
  String? categoryId = editItem?.categoryId;
  String? categoryName = editItem?.categoryName;
  String period = editItem?.period ?? BudgetPeriod.monthly;
  DateTime? startDate = editItem?.startDate;
  DateTime? endDate = editItem?.endDate;
  bool isRecurring = editItem?.isRecurring ?? false;
  bool notificationsEnabled = editItem?.notificationsEnabled ?? false;
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

        final categories = ref
            .watch(transactionTypeControllerProvider)
            .where((c) => c.type == "Expense")
            .toList();
        if (categoryId != null && !categories.any((c) => c.id == categoryId)) {
          categoryId = null;
          categoryName = null;
        }

        String dateFieldLabel() {
          switch (period) {
            case BudgetPeriod.monthly:
              return startDate == null
                  ? "Select month"
                  : "${_monthNames[startDate!.month - 1]} ${startDate!.year}";
            case BudgetPeriod.weekly:
              return startDate == null || endDate == null
                  ? "Select week"
                  : "${_formatDate(startDate!)} - ${_formatDate(endDate!)}";
            case BudgetPeriod.yearly:
              return startDate == null ? "Select year" : "${startDate!.year}";
            default:
              return "";
          }
        }

        Future<void> pickPeriodDate() async {
          final now = DateTime.now();
          switch (period) {
            case BudgetPeriod.monthly:
              final result = await _pickMonthYear(
                context,
                initialYear: startDate?.year ?? now.year,
                initialMonth: startDate?.month ?? now.month,
              );
              if (result != null) {
                final lastDay = DateTime(result.year, result.month + 1, 0).day;
                setModalState(() {
                  startDate = DateTime(result.year, result.month, 1);
                  endDate = DateTime(result.year, result.month, lastDay);
                });
              }
              break;
            case BudgetPeriod.weekly:
              final picked = await showDatePicker(
                context: context,
                initialDate: startDate ?? now,
                firstDate: DateTime(now.year - 10),
                lastDate: DateTime(now.year + 10),
              );
              if (picked != null) {
                final monday = picked.subtract(
                  Duration(days: picked.weekday - 1),
                );
                setModalState(() {
                  startDate = DateTime(monday.year, monday.month, monday.day);
                  endDate = startDate!.add(const Duration(days: 6));
                });
              }
              break;
            case BudgetPeriod.yearly:
              final picked = await _pickYear(
                context,
                initialYear: startDate?.year ?? now.year,
              );
              if (picked != null) {
                setModalState(() {
                  startDate = DateTime(picked, 1, 1);
                  endDate = DateTime(picked, 12, 31);
                });
              }
              break;
          }
        }

        Future<void> pickCustomDate({required bool isStart}) async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: (isStart ? startDate : endDate) ?? now,
            firstDate: DateTime(now.year - 10),
            lastDate: DateTime(now.year + 10),
          );
          if (picked == null) return;
          setModalState(() {
            if (isStart) {
              startDate = picked;
            } else {
              endDate = picked;
            }
          });
        }

        Future<void> save() async {
          if (!formKey.currentState!.validate()) return;
          if (budgetType == BudgetType.category && categoryId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please select a category")),
            );
            return;
          }
          if (period != BudgetPeriod.ongoing &&
              (startDate == null || endDate == null)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please select a date range")),
            );
            return;
          }
          if (period == BudgetPeriod.custom &&
              endDate!.isBefore(startDate!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("End date must be after start date")),
            );
            return;
          }

          final amount = double.tryParse(amountController.text.trim()) ?? 0;
          final budget = BudgetModel(
            id: isEdit ? editItem.id : '',
            userId: isEdit ? editItem.userId : null,
            name: nameController.text.trim(),
            budgetType: budgetType,
            categoryId: budgetType == BudgetType.category ? categoryId : null,
            categoryName: budgetType == BudgetType.category
                ? categoryName
                : null,
            period: period,
            startDate: period == BudgetPeriod.ongoing ? null : startDate,
            endDate: period == BudgetPeriod.ongoing ? null : endDate,
            amount: amount,
            isRecurring: period == BudgetPeriod.ongoing ? false : isRecurring,
            notificationsEnabled: notificationsEnabled,
            createdAt: isEdit ? editItem.createdAt : null,
          );

          setModalState(() => saving = true);
          final controller = ref.read(budgetControllerProvider.notifier);
          try {
            if (isEdit) {
              await controller.updateBudget(budget);
            } else {
              await controller.addBudget(budget);
            }
          } catch (e) {
            setModalState(() => saving = false);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Failed to save budget: $e")),
              );
            }
            return;
          }
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isEdit ? "Budget updated" : "Budget saved"),
              ),
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
                      isEdit
                          ? "Edit Budget"
                          : (isClone ? "Clone Budget" : "Add Budget"),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Budget Name",
                        hintText: "e.g. Food Budget",
                        prefixIcon: Icon(Icons.label_outline_rounded),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "Please enter a budget name"
                          : null,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Budget Type",
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
                            label: "Overall",
                            selected: budgetType == BudgetType.overall,
                            onTap: () => setModalState(() {
                              budgetType = BudgetType.overall;
                              categoryId = null;
                              categoryName = null;
                            }),
                          ),
                          const SizedBox(width: 4),
                          _SegmentOption(
                            label: "Category",
                            selected: budgetType == BudgetType.category,
                            onTap: () => setModalState(
                              () => budgetType = BudgetType.category,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (budgetType == BudgetType.category) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: categoryId,
                        decoration: const InputDecoration(
                          labelText: "Category",
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: categories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => setModalState(() {
                          categoryId = val;
                          categoryName = categories
                              .firstWhere((c) => c.id == val)
                              .name;
                        }),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      "Period",
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _periodLabels.entries
                          .map(
                            (e) => _PillOption(
                              label: e.value,
                              selected: period == e.key,
                              onTap: () => setModalState(() {
                                period = e.key;
                                startDate = null;
                                endDate = null;
                              }),
                            ),
                          )
                          .toList(),
                    ),
                    if (period == BudgetPeriod.custom) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _DateField(
                              icon: Icons.event_rounded,
                              label: startDate == null
                                  ? "Start date"
                                  : _formatDate(startDate!),
                              borderColor: borderColor,
                              onTap: () => pickCustomDate(isStart: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DateField(
                              icon: Icons.event_rounded,
                              label: endDate == null
                                  ? "End date"
                                  : _formatDate(endDate!),
                              borderColor: borderColor,
                              onTap: () => pickCustomDate(isStart: false),
                            ),
                          ),
                        ],
                      ),
                    ] else if (period != BudgetPeriod.ongoing) ...[
                      const SizedBox(height: 14),
                      _DateField(
                        icon: Icons.event_rounded,
                        label: dateFieldLabel(),
                        borderColor: borderColor,
                        onTap: pickPeriodDate,
                      ),
                    ] else ...[
                      const SizedBox(height: 10),
                      Text(
                        "Applies automatically to whichever month you're viewing.",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: "Budget Amount",
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
                    if (period != BudgetPeriod.ongoing) ...[
                      const SizedBox(height: 4),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Recurring"),
                        subtitle: const Text(
                          "Auto-create the next period when this one ends",
                        ),
                        value: isRecurring,
                        onChanged: (val) =>
                            setModalState(() => isRecurring = val),
                      ),
                    ],
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Enable Notifications"),
                      subtitle: const Text("Coming soon"),
                      value: notificationsEnabled,
                      onChanged: (val) =>
                          setModalState(() => notificationsEnabled = val),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: saving ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
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
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
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
                                    isEdit ? "Update Budget" : "Save Budget",
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

Future<({int year, int month})?> _pickMonthYear(
  BuildContext context, {
  required int initialYear,
  required int initialMonth,
}) {
  int year = initialYear;
  int month = initialMonth;
  final years = List.generate(10, (i) => DateTime.now().year - i + 1);

  return showDialog<({int year, int month})>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Select Month"),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: month,
                decoration: const InputDecoration(labelText: "Month"),
                items: List.generate(
                  12,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text(_monthNames[i]),
                  ),
                ),
                onChanged: (val) => setDialogState(() => month = val!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: year,
                decoration: const InputDecoration(labelText: "Year"),
                items: years
                    .map((y) => DropdownMenuItem(value: y, child: Text("$y")))
                    .toList(),
                onChanged: (val) => setDialogState(() => year = val!),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, (year: year, month: month)),
            child: const Text("OK"),
          ),
        ],
      ),
    ),
  );
}

Future<int?> _pickYear(BuildContext context, {required int initialYear}) {
  int year = initialYear;
  final years = List.generate(10, (i) => DateTime.now().year - i + 1);

  return showDialog<int>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Select Year"),
        content: DropdownButtonFormField<int>(
          initialValue: year,
          decoration: const InputDecoration(labelText: "Year"),
          items: years
              .map((y) => DropdownMenuItem(value: y, child: Text("$y")))
              .toList(),
          onChanged: (val) => setDialogState(() => year = val!),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, year),
            child: const Text("OK"),
          ),
        ],
      ),
    ),
  );
}
