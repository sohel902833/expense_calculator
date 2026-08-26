import 'package:drift/drift.dart';
import 'package:expense_calculator/features/offline_mode/controller/offline_mode_controller.dart';
import 'package:expense_calculator/features/recurring/repository/recurring_rule_data_source.dart';
import 'package:expense_calculator/local_db/app_local_database.dart';
import 'package:expense_calculator/models/recurring_rule_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final recurringRuleLocalRepositoryProvider = Provider((ref) {
  return RecurringRuleLocalRepository(
    db: ref.watch(appLocalDatabaseProvider),
    ref: ref,
  );
});

String _weekdaysToText(List<int> weekdays) => weekdays.join(',');

List<int> _weekdaysFromText(String text) => text.isEmpty
    ? const []
    : text.split(',').map(int.parse).toList();

class RecurringRuleLocalRepository implements RecurringRuleDataSource {
  final AppLocalDatabase db;
  final Ref ref;
  RecurringRuleLocalRepository({required this.db, required this.ref});

  RecurringRuleModel _toModel(LocalRecurringRule row) => RecurringRuleModel(
    id: row.id,
    userId: row.userId,
    title: row.title,
    type: row.type,
    categoryId: row.categoryId,
    categoryName: row.categoryName,
    amount: row.amount,
    spentFromIncomeId: row.spentFromIncomeId,
    description: row.description,
    frequency: row.frequency,
    dayOfMonth: row.dayOfMonth,
    weekdays: _weekdaysFromText(row.weekdays),
    startDate: row.startDate,
    lastProcessedDate: row.lastProcessedDate,
    isActive: row.isActive,
    createdAt: row.createdAt,
  );

  @override
  Future<void> addRule(RecurringRuleModel rule) async {
    final uid = ref.read(currentLocalUserIdProvider) ?? '';
    rule.userId = uid;
    await db
        .into(db.localRecurringRules)
        .insert(
          LocalRecurringRulesCompanion.insert(
            id: const Uuid().v4(),
            userId: uid,
            title: rule.title,
            type: rule.type,
            categoryId: rule.categoryId,
            categoryName: rule.categoryName,
            amount: rule.amount,
            spentFromIncomeId: Value(rule.spentFromIncomeId),
            description: Value(rule.description),
            frequency: rule.frequency,
            dayOfMonth: Value(rule.dayOfMonth),
            weekdays: Value(_weekdaysToText(rule.weekdays)),
            startDate: rule.startDate,
            lastProcessedDate: Value(rule.lastProcessedDate),
            isActive: Value(rule.isActive),
            createdAt: Value(rule.createdAt),
          ),
        );
  }

  @override
  Future<void> updateRule(RecurringRuleModel rule) async {
    await (db.update(
      db.localRecurringRules,
    )..where((t) => t.id.equals(rule.id))).write(
      LocalRecurringRulesCompanion(
        title: Value(rule.title),
        type: Value(rule.type),
        categoryId: Value(rule.categoryId),
        categoryName: Value(rule.categoryName),
        amount: Value(rule.amount),
        spentFromIncomeId: Value(rule.spentFromIncomeId),
        description: Value(rule.description),
        frequency: Value(rule.frequency),
        dayOfMonth: Value(rule.dayOfMonth),
        weekdays: Value(_weekdaysToText(rule.weekdays)),
        startDate: Value(rule.startDate),
        lastProcessedDate: Value(rule.lastProcessedDate),
        isActive: Value(rule.isActive),
      ),
    );
  }

  @override
  Future<void> deleteRule(String id) async {
    await (db.delete(
      db.localRecurringRules,
    )..where((t) => t.id.equals(id))).go();
  }

  @override
  Stream<List<RecurringRuleModel>> getUserRules() {
    final uid = ref.read(currentLocalUserIdProvider) ?? '';
    return (db.select(db.localRecurringRules)
          ..where((t) => t.userId.equals(uid))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch()
        .map((rows) => rows.map(_toModel).toList());
  }
}
