import 'package:drift/drift.dart';
import 'package:expense_calculator/features/offline_mode/controller/offline_mode_controller.dart';
import 'package:expense_calculator/features/transactions/repository/transaction_data_source.dart';
import 'package:expense_calculator/local_db/app_local_database.dart';
import 'package:expense_calculator/models/transaction_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final transactionLocalRepositoryProvider = Provider((ref) {
  return TransactionLocalRepository(
    db: ref.watch(appLocalDatabaseProvider),
    ref: ref,
  );
});

class TransactionLocalRepository implements TransactionDataSource {
  final AppLocalDatabase db;
  final Ref ref;
  TransactionLocalRepository({required this.db, required this.ref});

  TransactionModel _toModel(LocalTransaction row) => TransactionModel(
    id: row.id,
    type: row.type,
    categoryId: row.categoryId,
    categoryName: row.categoryName,
    amount: row.amount,
    description: row.description,
    date: row.date,
    userId: row.userId,
    spentFromIncomeId: row.spentFromIncomeId,
    isDeleted: row.isDeleted,
    recurringRuleId: row.recurringRuleId,
  );

  @override
  Future<String> addTransaction(TransactionModel transaction) async {
    final uid = ref.read(currentLocalUserIdProvider) ?? '';
    transaction.userId = uid;
    final id = const Uuid().v4();
    await db
        .into(db.localTransactions)
        .insert(
          LocalTransactionsCompanion.insert(
            id: id,
            userId: uid,
            type: transaction.type,
            categoryId: transaction.categoryId,
            categoryName: transaction.categoryName,
            amount: transaction.amount,
            description: Value(transaction.description),
            date: transaction.date,
            spentFromIncomeId: Value(transaction.spentFromIncomeId),
            isDeleted: Value(transaction.isDeleted),
            recurringRuleId: Value(transaction.recurringRuleId),
          ),
        );
    return id;
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    await (db.update(
      db.localTransactions,
    )..where((t) => t.id.equals(transaction.id))).write(
      LocalTransactionsCompanion(
        type: Value(transaction.type),
        categoryId: Value(transaction.categoryId),
        categoryName: Value(transaction.categoryName),
        amount: Value(transaction.amount),
        description: Value(transaction.description),
        date: Value(transaction.date),
        spentFromIncomeId: Value(transaction.spentFromIncomeId),
        isDeleted: Value(transaction.isDeleted),
        recurringRuleId: Value(transaction.recurringRuleId),
      ),
    );
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await (db.update(db.localTransactions)..where((t) => t.id.equals(id)))
        .write(const LocalTransactionsCompanion(isDeleted: Value(true)));
  }

  @override
  Future<void> restoreTransaction(String id) async {
    await (db.update(db.localTransactions)..where((t) => t.id.equals(id)))
        .write(const LocalTransactionsCompanion(isDeleted: Value(false)));
  }

  @override
  Stream<List<TransactionModel>> getTransactions() {
    return (db.select(db.localTransactions)..orderBy([
          (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
        ]))
        .watch()
        .map((rows) => rows.map(_toModel).toList());
  }

  @override
  Stream<List<TransactionModel>> getUserTransactions() {
    final uid = ref.read(currentLocalUserIdProvider) ?? '';
    debugPrint('Current local user id: $uid');
    return (db.select(db.localTransactions)
          ..where((t) => t.userId.equals(uid))
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
          ]))
        .watch()
        .map((rows) => rows.map(_toModel).toList());
  }
}
