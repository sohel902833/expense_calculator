import 'package:expense_calculator/features/auth/controller/auth_controller.dart';
import 'package:expense_calculator/features/auth/screens/login_screen.dart';
import 'package:expense_calculator/features/transaction-type/controller/transaction_type_controller.dart';
import 'package:expense_calculator/features/transaction-type/screens/transaction_type_screen.dart';
import 'package:expense_calculator/features/transactions/controller/transaction_controller.dart';
import 'package:expense_calculator/models/transaction_model.dart';
import 'package:expense_calculator/models/transaction_type_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import "../controller/dashboard_controller.dart";

class DashboardScreen extends ConsumerStatefulWidget {
  static const routeName = '/login-screen';
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Do you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // close dialog
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(authControllerProvider).logout();
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(context, LoginScreen.routeName);
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(dashboardControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "settings") {
                Navigator.pushNamed(context, TransactionTypeScreen.routeName);
              } else if (value == "logout") {
                _showLogoutDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: "settings",
                child: Text("Transaction Type"),
              ),
              const PopupMenuItem(value: "logout", child: Text("Logout")),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Dashboard",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Combine total + income items into a single list
                ...List.generate(
                  ((dashboard.incomes.length + 1) / 2).ceil(), // +1 for total
                  (rowIndex) {
                    final firstIndex = rowIndex * 2;
                    final secondIndex = firstIndex + 1;

                    // Get first item: firstIndex 0 = Total, rest = incomes
                    final firstItem = firstIndex == 0
                        ? {
                            "name": "Total",
                            "available": dashboard.totalAvailable,
                            "spent": dashboard.totalSpent,
                          }
                        : {
                            "name": dashboard.incomes[firstIndex - 1].name,
                            "available": dashboard
                                .incomes[firstIndex - 1]
                                .availableAmount,
                            "spent":
                                dashboard.incomes[firstIndex - 1].spentAmount,
                          };

                    // Get second item, if exists
                    Map<String, dynamic>? secondItem;
                    if (secondIndex == 1) {
                      // Second item after total = first income
                      if (dashboard.incomes.isNotEmpty) {
                        secondItem = {
                          "name": dashboard.incomes[0].name,
                          "available": dashboard.incomes[0].availableAmount,
                          "spent": dashboard.incomes[0].spentAmount,
                        };
                      }
                    } else if (secondIndex > 1 &&
                        secondIndex - 1 < dashboard.incomes.length) {
                      secondItem = {
                        "name": dashboard.incomes[secondIndex - 1].name,
                        "available":
                            dashboard.incomes[secondIndex - 1].availableAmount,
                        "spent": dashboard.incomes[secondIndex - 1].spentAmount,
                      };
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildDashboardItem(
                              name: firstItem["name"] as String,
                              availableAmount:
                                  firstItem["available"] as dynamic,
                              spentAmount: firstItem["spent"] as dynamic,
                            ),
                          ),
                          const SizedBox(width: 16),
                          if (secondItem != null)
                            Expanded(
                              child: _buildDashboardItem(
                                name: secondItem["name"],
                                availableAmount: secondItem["available"],
                                spentAmount: secondItem["spent"],
                              ),
                            )
                          else
                            const Expanded(child: SizedBox()),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionModal(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Helper function to render a single item
  Widget _buildDashboardItem({
    required String name,
    required double availableAmount,
    required double spentAmount,
    bool showShadow = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent, // removed ugly white
        borderRadius: BorderRadius.circular(12),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ), // subtle outline
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            "Available: \$${availableAmount.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            "Spent: \$${spentAmount.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionModal(BuildContext context, WidgetRef ref) {
    final _formKey = GlobalKey<FormState>();
    String selectedType = "Income"; // define outside
    TransactionTypeModel? selectedCategory;
    TransactionTypeModel? selectedIncomeTransaction;
    final amountController = TextEditingController();
    final descController = TextEditingController();

    final transactionTypes = ref.watch(transactionTypeControllerProvider);

    print("TranscationTypes--> $transactionTypes");
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
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
                    const SizedBox(height: 16),
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
