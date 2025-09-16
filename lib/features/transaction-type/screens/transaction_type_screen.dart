import 'package:expense_calculator/models/transaction_type_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/transaction_type_controller.dart';

class TransactionTypeScreen extends ConsumerStatefulWidget {
  static const routeName = '/transaction-type';

  const TransactionTypeScreen({super.key});

  @override
  ConsumerState<TransactionTypeScreen> createState() =>
      _TransactionTypeScreenState();
}

class _TransactionTypeScreenState extends ConsumerState<TransactionTypeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  void _showAddEditModal(
    BuildContext context, [
    TransactionTypeModel? editItem,
  ]) {
    final _formKey = GlobalKey<FormState>();
    String selectedType = editItem?.type ?? "Income";
    final nameController = TextEditingController(text: editItem?.name ?? '');
    final descController = TextEditingController(
      text: editItem?.description ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedType,
                items: const [
                  DropdownMenuItem(value: "Income", child: Text("Income")),
                  DropdownMenuItem(value: "Expense", child: Text("Expense")),
                ],
                onChanged: (val) => selectedType = val ?? "Income",
                decoration: const InputDecoration(labelText: "Type"),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
                validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final controller = ref.read(
                      transactionTypeControllerProvider.notifier,
                    );
                    if (editItem != null) {
                      await controller.updateTransactionType(
                        TransactionTypeModel(
                          id: editItem.id,
                          type: selectedType,
                          name: nameController.text,
                          description: descController.text,
                        ),
                      );
                    } else {
                      await controller.addTransactionType(
                        TransactionTypeModel(
                          id: '',
                          type: selectedType,
                          name: nameController.text,
                          description: descController.text,
                        ),
                      );
                    }
                    Navigator.pop(context);
                  }
                },
                child: Text(editItem != null ? "Update" : "Create"),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionTypes = ref.watch(transactionTypesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Transaction Types"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Income"),
            Tab(text: "Expense"),
          ],
        ),
      ),
      body: transactionTypes.when(
        data: (types) {
          final incomeList = types.where((e) => e.type == "Income").toList();
          final expenseList = types.where((e) => e.type == "Expense").toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildListView(context, incomeList),
              _buildListView(context, expenseList),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditModal(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Transaction Type"),
        content: const Text("Are you sure you want to delete this item?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Close dialog
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () {
              // Delete the item
              final controller = ref.read(
                transactionTypeControllerProvider.notifier,
              );
              controller.deleteTransactionType(id);

              Navigator.of(context).pop(); // Close dialog
            },
            child: const Text("Yes", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(BuildContext context, List<TransactionTypeModel> list) {
    final controller = ref.read(transactionTypeControllerProvider);

    if (list.isEmpty) {
      return const Center(child: Text("No data"));
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, index) {
        final item = list[index];
        return ListTile(
          title: Text(item.name),
          subtitle: Text(item.description),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _showAddEditModal(context, item),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _confirmDelete(context, item.id),
              ),
            ],
          ),
        );
      },
    );
  }
}
