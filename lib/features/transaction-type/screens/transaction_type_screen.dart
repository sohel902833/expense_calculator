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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _typeColor(String type) =>
      type == "Income" ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C);

  void _showAddEditModal(
    BuildContext context, {
    TransactionTypeModel? editItem,
    String? initialType,
  }) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: editItem?.name ?? '');
    final descController = TextEditingController(
      text: editItem?.description ?? '',
    );
    final isEditing = editItem != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        String selectedType =
            editItem?.type ?? initialType ?? "Income";
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            final bottomSafeArea = MediaQuery.of(context).padding.bottom;
            final accent = _typeColor(selectedType);

            Future<void> submit() async {
              if (!formKey.currentState!.validate()) return;
              setModalState(() => isSubmitting = true);
              final controller = ref.read(
                transactionTypeControllerProvider.notifier,
              );
              try {
                if (isEditing) {
                  await controller.updateTransactionType(
                    TransactionTypeModel(
                      id: editItem.id,
                      type: selectedType,
                      name: nameController.text.trim(),
                      description: descController.text.trim(),
                    ),
                  );
                } else {
                  await controller.addTransactionType(
                    TransactionTypeModel(
                      id: '',
                      type: selectedType,
                      name: nameController.text.trim(),
                      description: descController.text.trim(),
                    ),
                  );
                }
                if (context.mounted) Navigator.pop(context);
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
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  20 + bottomSafeArea,
                ),
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
                        isEditing
                            ? "Edit Transaction Type"
                            : "New Transaction Type",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isEditing
                            ? "Update the details below"
                            : "Fill in the details below",
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
                              onTap: () =>
                                  setModalState(() => selectedType = "Income"),
                            ),
                            const SizedBox(width: 4),
                            _TypeOption(
                              label: "Expense",
                              icon: Icons.arrow_upward_rounded,
                              color: const Color(0xFFE74C3C),
                              selected: selectedType == "Expense",
                              onTap: () => setModalState(
                                () => selectedType = "Expense",
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: "Name",
                          hintText: "e.g. Salary, Groceries",
                          prefixIcon: Icon(Icons.label_outline_rounded),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? "Name is required"
                            : null,
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
                                      isEditing ? "Update" : "Create",
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
            );
          },
        );
      },
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
              _buildListView(context, incomeList, "Income"),
              _buildListView(context, expenseList, "Expense"),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          final currentType =
              _tabController.index == 0 ? "Income" : "Expense";
          return FloatingActionButton.extended(
            onPressed: () =>
                _showAddEditModal(context, initialType: currentType),
            backgroundColor: _typeColor(currentType),
            icon: const Icon(Icons.add),
            label: const Text("Add"),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text("Delete Transaction Type"),
        content: const Text(
          "Are you sure you want to delete this item? This action cannot be undone.",
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
              final controller = ref.read(
                transactionTypeControllerProvider.notifier,
              );
              controller.deleteTransactionType(id);
              Navigator.of(context).pop();
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(
    BuildContext context,
    List<TransactionTypeModel> list,
    String type,
  ) {
    if (list.isEmpty) {
      final color = _typeColor(type);
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                type == "Income"
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                size: 36,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "No $type types yet",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              "Tap the Add button to create one",
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
      itemCount: list.length,
      itemBuilder: (_, index) {
        final item = list[index];
        final color = _typeColor(item.type);
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          elevation: 0,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(
                item.type == "Income"
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: color,
              ),
            ),
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: item.description.isEmpty
                ? null
                : Text(
                    item.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                  onPressed: () =>
                      _showAddEditModal(context, editItem: item),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFE74C3C),
                  ),
                  onPressed: () => _confirmDelete(context, item.id),
                ),
              ],
            ),
          ),
        );
      },
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
            color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
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
