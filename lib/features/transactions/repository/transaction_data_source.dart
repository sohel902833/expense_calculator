import 'package:expense_calculator/models/transaction_model.dart';

/// Shared contract implemented by both the Firestore-backed
/// [TransactionRepository] and the Drift-backed [TransactionLocalRepository]
/// -- lets [TransactionController] and every screen stay unaware of which
/// backend is actually active.
abstract class TransactionDataSource {
  Future<String> addTransaction(TransactionModel transaction);
  Future<void> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
  Future<void> restoreTransaction(String id);
  Stream<List<TransactionModel>> getTransactions();
  Stream<List<TransactionModel>> getUserTransactions();
}
