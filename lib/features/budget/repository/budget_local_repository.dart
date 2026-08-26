import 'package:drift/drift.dart';
import 'package:expense_calculator/features/budget/repository/budget_data_source.dart';
import 'package:expense_calculator/features/offline_mode/controller/offline_mode_controller.dart';
import 'package:expense_calculator/local_db/app_local_database.dart';
import 'package:expense_calculator/models/budget_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final budgetLocalRepositoryProvider = Provider((ref) {
  return BudgetLocalRepository(db: ref.watch(appLocalDatabaseProvider), ref: ref);
});

class BudgetLocalRepository implements BudgetDataSource {
  final AppLocalDatabase db;
  final Ref ref;
  BudgetLocalRepository({required this.db, required this.ref});

  BudgetModel _toModel(LocalBudget row) => BudgetModel(
    id: row.id,
    userId: row.userId,
    name: row.name,
    budgetType: row.budgetType,
    categoryId: row.categoryId,
    categoryName: row.categoryName,
    period: row.period,
    startDate: row.startDate,
    endDate: row.endDate,
    amount: row.amount,
    isRecurring: row.isRecurring,
    notificationsEnabled: row.notificationsEnabled,
    createdAt: row.createdAt,
  );

  @override
  Future<void> addBudget(BudgetModel budget) async {
    final uid = ref.read(currentLocalUserIdProvider) ?? '';
    budget.userId = uid;
    await db
        .into(db.localBudgets)
        .insert(
          LocalBudgetsCompanion.insert(
            id: const Uuid().v4(),
            userId: uid,
            name: budget.name,
            budgetType: budget.budgetType,
            categoryId: Value(budget.categoryId),
            categoryName: Value(budget.categoryName),
            period: budget.period,
            startDate: Value(budget.startDate),
            endDate: Value(budget.endDate),
            amount: budget.amount,
            isRecurring: Value(budget.isRecurring),
            notificationsEnabled: Value(budget.notificationsEnabled),
            createdAt: Value(budget.createdAt),
          ),
        );
  }

  @override
  Future<void> updateBudget(BudgetModel budget) async {
    await (db.update(
      db.localBudgets,
    )..where((t) => t.id.equals(budget.id))).write(
      LocalBudgetsCompanion(
        name: Value(budget.name),
        budgetType: Value(budget.budgetType),
        categoryId: Value(budget.categoryId),
        categoryName: Value(budget.categoryName),
        period: Value(budget.period),
        startDate: Value(budget.startDate),
        endDate: Value(budget.endDate),
        amount: Value(budget.amount),
        isRecurring: Value(budget.isRecurring),
        notificationsEnabled: Value(budget.notificationsEnabled),
      ),
    );
  }

  @override
  Future<void> deleteBudget(String id) async {
    await (db.delete(db.localBudgets)..where((t) => t.id.equals(id))).go();
  }

  @override
  Stream<List<BudgetModel>> getUserBudgets() {
    final uid = ref.read(currentLocalUserIdProvider) ?? '';
    return (db.select(db.localBudgets)
          ..where((t) => t.userId.equals(uid))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch()
        .map((rows) => rows.map(_toModel).toList());
  }
}
