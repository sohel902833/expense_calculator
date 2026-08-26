import 'package:drift/drift.dart';
import 'package:expense_calculator/features/offline_mode/controller/offline_mode_controller.dart';
import 'package:expense_calculator/features/recurring/repository/recurring_occurrence_data_source.dart';
import 'package:expense_calculator/local_db/app_local_database.dart';
import 'package:expense_calculator/models/recurring_occurrence_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final recurringOccurrenceLocalRepositoryProvider = Provider((ref) {
  return RecurringOccurrenceLocalRepository(
    db: ref.watch(appLocalDatabaseProvider),
    ref: ref,
  );
});

class RecurringOccurrenceLocalRepository
    implements RecurringOccurrenceDataSource {
  final AppLocalDatabase db;
  final Ref ref;
  RecurringOccurrenceLocalRepository({required this.db, required this.ref});

  RecurringOccurrenceModel _toModel(LocalRecurringOccurrence row) =>
      RecurringOccurrenceModel(
        id: row.id,
        userId: row.userId,
        ruleId: row.ruleId,
        occurrenceDate: row.occurrenceDate,
        status: row.status,
        transactionId: row.transactionId,
        resolvedAt: row.resolvedAt,
      );

  @override
  Future<void> logOccurrence(RecurringOccurrenceModel occurrence) async {
    final uid = ref.read(currentLocalUserIdProvider) ?? '';
    occurrence.userId = uid;
    await db
        .into(db.localRecurringOccurrences)
        .insert(
          LocalRecurringOccurrencesCompanion.insert(
            id: const Uuid().v4(),
            userId: uid,
            ruleId: occurrence.ruleId,
            occurrenceDate: occurrence.occurrenceDate,
            status: occurrence.status,
            transactionId: Value(occurrence.transactionId),
            resolvedAt: Value(occurrence.resolvedAt),
          ),
        );
  }

  @override
  Stream<List<RecurringOccurrenceModel>> getUserOccurrenceLogs() {
    final uid = ref.read(currentLocalUserIdProvider) ?? '';
    return (db.select(
      db.localRecurringOccurrences,
    )..where((t) => t.userId.equals(uid))).watch().map(
      (rows) => rows.map(_toModel).toList(),
    );
  }
}
