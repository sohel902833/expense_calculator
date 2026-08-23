import 'package:expense_calculator/constants/currency.dart';
import 'package:expense_calculator/features/transaction-type/controller/transaction_type_controller.dart';
import 'package:expense_calculator/features/transactions/controller/transaction_controller.dart';
import 'package:expense_calculator/models/transaction_model.dart';
import 'package:expense_calculator/models/transaction_type_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TransactionModals {
  static Color _typeColor(String type) =>
      type == "Income" ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C);

  static String _formatAmount(double value) => value % 1 == 0
      ? value.toStringAsFixed(0)
      : value.toString();

  static void showAddTransactionModal(
    BuildContext context,
    WidgetRef ref, {
    TransactionModel? editItem,
  }) {
    final formKey = GlobalKey<FormState>();
    final isEditing = editItem != null;

    final initialTypes = ref.read(transactionTypeControllerProvider);
    String selectedType = editItem?.type ?? "Income";
    TransactionTypeModel? selectedCategory;
    TransactionTypeModel? selectedIncomeTransaction;
    if (editItem != null) {
      final catMatches = initialTypes.where((t) => t.id == editItem.categoryId);
      selectedCategory = catMatches.isEmpty ? null : catMatches.first;
      if (editItem.spentFromIncomeId != null) {
        final incMatches = initialTypes.where(
          (t) => t.id == editItem.spentFromIncomeId,
        );
        selectedIncomeTransaction = incMatches.isEmpty
            ? null
            : incMatches.first;
      }
    }
    final amountController = TextEditingController(
      text: editItem != null ? _formatAmount(editItem.amount) : '',
    );
    final descController = TextEditingController(
      text: editItem?.description ?? '',
    );
    bool isSubmitting = false;

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
          final accent = _typeColor(selectedType);

          final transactionTypes = ref.watch(
            transactionTypeControllerProvider,
          );
          final categories = transactionTypes
              .where((t) => t.type == selectedType)
              .toList();
          final incomeSources = transactionTypes
              .where((t) => t.type == "Income")
              .toList();

          Future<void> submit() async {
            if (!formKey.currentState!.validate()) return;
            setModalState(() => isSubmitting = true);
            final controller = ref.read(
              transactionControllerProvider.notifier,
            );
            try {
              if (editItem != null) {
                final transaction = TransactionModel(
                  id: editItem.id,
                  type: selectedType,
                  categoryId: selectedCategory!.id,
                  spentFromIncomeId: selectedIncomeTransaction?.id,
                  categoryName: selectedCategory!.name,
                  amount: double.tryParse(amountController.text) ?? 0,
                  description: descController.text.trim(),
                  date: editItem.date,
                  userId: editItem.userId,
                  isDeleted: editItem.isDeleted,
                );
                await controller.updateTransaction(transaction);
              } else {
                final transaction = TransactionModel(
                  id: "",
                  type: selectedType,
                  categoryId: selectedCategory!.id,
                  spentFromIncomeId: selectedIncomeTransaction?.id,
                  categoryName: selectedCategory!.name,
                  amount: double.tryParse(amountController.text) ?? 0,
                  description: descController.text.trim(),
                  date: DateTime.now(),
                );
                await controller.addTransaction(transaction);
              }
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEditing
                          ? "Transaction updated successfully"
                          : "Transaction added successfully",
                    ),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                setModalState(() => isSubmitting = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Something went wrong: $e")),
                );
              }
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
              child: Form(
                key: formKey,
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
                        isEditing ? "Edit Transaction" : "New Transaction",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isEditing
                            ? "Update the details below"
                            : "Record an income or expense",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      const SizedBox(height: 22),
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
                            _TypeOption(
                              label: "Income",
                              icon: Icons.arrow_downward_rounded,
                              color: const Color(0xFF2ECC71),
                              selected: selectedType == "Income",
                              onTap: () => setModalState(() {
                                selectedType = "Income";
                                selectedCategory = null;
                                selectedIncomeTransaction = null;
                              }),
                            ),
                            const SizedBox(width: 4),
                            _TypeOption(
                              label: "Expense",
                              icon: Icons.arrow_upward_rounded,
                              color: const Color(0xFFE74C3C),
                              selected: selectedType == "Expense",
                              onTap: () => setModalState(() {
                                selectedType = "Expense";
                                selectedCategory = null;
                                selectedIncomeTransaction = null;
                              }),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<TransactionTypeModel>(
                        initialValue: selectedCategory,
                        decoration: InputDecoration(
                          labelText: "Category",
                          prefixIcon: const Icon(Icons.category_outlined),
                          hintText: categories.isEmpty
                              ? "No categories yet"
                              : null,
                        ),
                        items: categories
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setModalState(() => selectedCategory = val),
                        validator: (val) =>
                            val == null ? "Select a category" : null,
                      ),
                      if (selectedType == "Expense") ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<TransactionTypeModel>(
                          initialValue: selectedIncomeTransaction,
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
                                  value: t,
                                  child: Text(t.name),
                                ),
                              )
                              .toList(),
                          onChanged: (val) => setModalState(
                            () => selectedIncomeTransaction = val,
                          ),
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
                        decoration: const InputDecoration(
                          labelText: "Amount",
                          hintText: "0.00",
                          prefixIcon: Padding(
                            padding: EdgeInsets.fromLTRB(14, 14, 4, 14),
                            child: Text(
                              Currency.TAKA,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          prefixIconConstraints: BoxConstraints(minWidth: 32),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return "Enter an amount";
                          }
                          final n = double.tryParse(val);
                          if (n == null || n <= 0) {
                            return "Enter a valid amount";
                          }
                          return null;
                        },
                      ),
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
                      const SizedBox(height: 26),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: BorderSide(
                                  color: (isDark ? Colors.white : Colors.black)
                                      .withValues(alpha: 0.2),
                                ),
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
                              onPressed: isSubmitting ? null : submit,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                backgroundColor: accent,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: accent.withValues(
                                  alpha: 0.6,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      isEditing
                                          ? "Update Transaction"
                                          : "Add Transaction",
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
}

class _TypeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.label,
    required this.icon,
    required this.color,
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
            color: selected
                ? color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? color : Colors.grey),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : Colors.grey,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
