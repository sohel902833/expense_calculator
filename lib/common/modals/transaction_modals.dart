import 'package:expense_calculator/features/transaction-type/controller/transaction_type_controller.dart';
import 'package:expense_calculator/features/transactions/controller/transaction_controller.dart';
import 'package:expense_calculator/models/transaction_model.dart';
import 'package:expense_calculator/models/transaction_type_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TransactionModals {
  static void showAddTransactionModal(BuildContext context, WidgetRef ref) {
    final _formKey = GlobalKey<FormState>();
    String selectedType = "Income"; // define outside
    TransactionTypeModel? selectedCategory;
    TransactionTypeModel? selectedIncomeTransaction;
    final amountController = TextEditingController();
    final descController = TextEditingController();

    final transactionTypes = ref.watch(transactionTypeControllerProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 25,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Type Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: "Transaction Type",
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "Income",
                          child: Text("Income"),
                        ),
                        DropdownMenuItem(
                          value: "Expense",
                          child: Text("Expense"),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          selectedType = val ?? "Income";
                          selectedCategory = null;
                          selectedIncomeTransaction = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Category Dropdown (depends on selectedType)
                    DropdownButtonFormField<TransactionTypeModel>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(labelText: "Category"),
                      items: transactionTypes
                          .where((t) {
                            return t.type == selectedType;
                          })
                          .map(
                            (t) =>
                                DropdownMenuItem(value: t, child: Text(t.name)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => selectedCategory = val),
                      validator: (val) =>
                          val == null ? "Select a category" : null,
                    ),
                    const SizedBox(height: 12),

                    // **Conditional Expense-from dropdown**
                    if (selectedType == "Expense") ...[
                      DropdownButtonFormField<TransactionTypeModel>(
                        initialValue: selectedIncomeTransaction,
                        decoration: const InputDecoration(
                          labelText: "Expense from Income",
                        ),
                        items: transactionTypes
                            .where((t) {
                              return t.type == "Income";
                            })
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => selectedIncomeTransaction = val),
                        validator: (val) => val == null
                            ? "Select an income to spend from"
                            : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Amount
                    TextFormField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: "Amount",
                        prefixText: "\$ ",
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) =>
                          val == null || val.isEmpty ? "Enter an amount" : null,
                    ),
                    const SizedBox(height: 12),

                    // Optional Description
                    TextFormField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: "Description (Optional)",
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final controller = ref.read(
                            transactionControllerProvider.notifier,
                          );

                          final transaction = TransactionModel(
                            id: "",
                            type: selectedType,
                            categoryId: selectedCategory!.id,
                            spentFromIncomeId: selectedIncomeTransaction?.id,
                            categoryName: selectedCategory!.name,
                            amount: double.tryParse(amountController.text) ?? 0,
                            description: descController.text,
                            date: DateTime.now(),
                          );

                          controller.addTransaction(transaction);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Transaction added successfully"),
                            ),
                          );
                        }
                      },
                      child: const Text("Add Transaction"),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
