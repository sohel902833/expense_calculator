import 'package:expense_calculator/features/transaction-type/repository/transaction_type_repository.dart';
import 'package:expense_calculator/features/transactions/repository/transaction_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_calculator/models/transaction_model.dart';
import 'package:expense_calculator/models/transaction_type_model.dart';
import 'package:async/async.dart';

final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, DashboardData>((ref) {
      final txRepo = ref.watch(transactionRepositoryProvider);
      final typeRepo = ref.watch(transactionTypeRepositoryProvider);
      return DashboardController(txRepo, typeRepo);
    });

class DashboardController extends StateNotifier<DashboardData> {
  final TransactionRepository txRepo;
  final TransactionTypeRepository typeRepo;

  DashboardController(this.txRepo, this.typeRepo)
    : super(DashboardData.initial()) {
    _init();
  }

  void _init() {
    final txStream = txRepo.getUserTransactions();
    final typeStream = typeRepo.getTransactionTypes();

    StreamZip([txStream, typeStream]).listen((values) {
      final transactions = values[0] as List<TransactionModel>;
      final types = values[1] as List<TransactionTypeModel>;

      state = _calculateDashboardData(transactions, types);
    });
  }

  DashboardData _calculateDashboardData(
    List<TransactionModel> transactions,
    List<TransactionTypeModel> types,
  ) {
    // Group transactions by Income type
    final incomeTxns = transactions.where((t) => t.type == "Income");

    final Map<String, IncomeSummary> grouped = {};

    for (var tx in incomeTxns) {
      final typeName = types
          .firstWhere(
            (type) => type.id == tx.categoryId,
            orElse: () => TransactionTypeModel(
              id: tx.categoryId,
              name: tx.categoryName,
              type: "Income",
              description: tx.description,
            ),
          )
          .name;

      if (!grouped.containsKey(typeName)) {
        grouped[typeName] = IncomeSummary(
          name: typeName,
          totalAmount: tx.amount,
          spentAmount: 0.0,
          availableAmount: tx.amount,
        );
      } else {
        final exist = grouped[typeName]!;
        grouped[typeName] = IncomeSummary(
          name: exist.name,
          totalAmount: exist.totalAmount + tx.amount,
          spentAmount: exist.spentAmount,
          availableAmount: exist.availableAmount + tx.amount,
        );
      }
    }

    // Calculate spent amounts from Expense transactions
    final expenseTxns = transactions.where((t) => t.type == "Expense");
    for (var expense in expenseTxns) {
      final fromId = expense.spentFromIncomeId; // nullable field
      if (fromId != null) {
        final typeName = types
            .firstWhere(
              (type) => type.id == fromId,
              orElse: () => TransactionTypeModel(
                id: fromId,
                name: "Unknown",
                type: "Income",
                description: "",
              ),
            )
            .name;
        if (grouped.containsKey(typeName)) {
          final exist = grouped[typeName]!;
          final newSpent = exist.spentAmount + expense.amount;
          grouped[typeName] = IncomeSummary(
            name: exist.name,
            totalAmount: exist.totalAmount,
            spentAmount: newSpent,
            availableAmount: exist.totalAmount - newSpent,
          );
        }
      }
    }

    // Total values
    final totalIncome = grouped.values.fold(
      0.0,
      (sum, e) => sum + e.totalAmount,
    );
    final totalSpent = grouped.values.fold(
      0.0,
      (sum, e) => sum + e.spentAmount,
    );
    final totalAvailable = grouped.values.fold(
      0.0,
      (sum, e) => sum + e.availableAmount,
    );

    return DashboardData(
      incomes: grouped.values.toList(),
      totalIncome: totalIncome,
      totalSpent: totalSpent,
      totalAvailable: totalAvailable,
    );
  }
}

// Dashboard data
class DashboardData {
  final List<IncomeSummary> incomes;
  final double totalIncome;
  final double totalSpent;
  final double totalAvailable;

  DashboardData({
    required this.incomes,
    required this.totalIncome,
    required this.totalSpent,
    required this.totalAvailable,
  });

  factory DashboardData.initial() => DashboardData(
    incomes: [],
    totalIncome: 0.0,
    totalSpent: 0.0,
    totalAvailable: 0.0,
  );
}

// Income summary per type
class IncomeSummary {
  final String name;
  final double totalAmount;
  final double spentAmount;
  final double availableAmount;

  IncomeSummary({
    required this.name,
    required this.totalAmount,
    required this.spentAmount,
    required this.availableAmount,
  });
}
