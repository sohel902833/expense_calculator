import 'package:drift/drift.dart';
import 'package:expense_calculator/features/offline_mode/controller/offline_mode_controller.dart';
import 'package:expense_calculator/features/transaction-type/repository/transaction_type_data_source.dart';
import 'package:expense_calculator/local_db/app_local_database.dart';
import 'package:expense_calculator/models/transaction_type_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final transactionTypeLocalRepositoryProvider = Provider((ref) {
  return TransactionTypeLocalRepository(
    db: ref.watch(appLocalDatabaseProvider),
    ref: ref,
  );
});

/// Per-user, like the Firestore version -- scoped by userId.
class TransactionTypeLocalRepository implements TransactionTypeDataSource {
  final AppLocalDatabase db;
  final Ref ref;
  TransactionTypeLocalRepository({required this.db, required this.ref});

  TransactionTypeModel _toModel(LocalTransactionType row) =>
      TransactionTypeModel(
        id: row.id,
        type: row.type,
        name: row.name,
        description: row.description,
        userId: row.userId,
      );

  @override
  Future<void> addTransactionType(TransactionTypeModel type) async {
    final uid = ref.read(currentLocalUserIdProvider) ?? '';
    type.userId = uid;
    await db
        .into(db.localTransactionTypes)
        .insert(
          LocalTransactionTypesCompanion.insert(
            id: const Uuid().v4(),
            userId: Value(uid),
            type: type.type,
            name: type.name,
            description: Value(type.description),
          ),
        );
  }

  @override
  Future<void> updateTransactionType(TransactionTypeModel type) async {
    await (db.update(
      db.localTransactionTypes,
    )..where((t) => t.id.equals(type.id))).write(
      LocalTransactionTypesCompanion(
        type: Value(type.type),
        name: Value(type.name),
        description: Value(type.description),
      ),
    );
  }

  @override
  Future<void> deleteTransactionType(String id) async {
    await (db.delete(
      db.localTransactionTypes,
    )..where((t) => t.id.equals(id))).go();
  }

  @override
  Stream<List<TransactionTypeModel>> getTransactionTypes() {
    final uid = ref.read(currentLocalUserIdProvider) ?? '';
    return (db.select(
      db.localTransactionTypes,
    )..where((t) => t.userId.equals(uid))).watch().map(
      (rows) => rows.map(_toModel).toList(),
    );
  }
}
