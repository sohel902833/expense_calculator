import 'package:expense_calculator/models/transaction_type_model.dart';

abstract class TransactionTypeDataSource {
  Future<void> addTransactionType(TransactionTypeModel type);
  Future<void> updateTransactionType(TransactionTypeModel type);
  Future<void> deleteTransactionType(String id);
  Stream<List<TransactionTypeModel>> getTransactionTypes();
}
