import 'package:expense_calculator/features/recurring/controller/recurring_rule_controller.dart';
import 'package:expense_calculator/features/recurring/repository/recurring_occurrence_data_source.dart';
import 'package:expense_calculator/features/recurring/repository/recurring_occurrence_repository.dart';
import 'package:expense_calculator/features/recurring/repository/recurring_rule_repository.dart';
import 'package:expense_calculator/features/recurring/utils/recurrence_engine.dart';
import 'package:expense_calculator/features/transactions/repository/transaction_repository.dart';
import 'package:expense_calculator/models/recurring_occurrence_model.dart';
import 'package:expense_calculator/models/transaction_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final recurringOccurrenceControllerProvider =
    StateNotifierProvider<
      RecurringOccurrenceController,
      List<RecurringOccurrenceModel>
    >((ref) {
      final repository = ref.watch(recurringOccurrenceRepositoryProvider);
      return RecurringOccurrenceController(repository: repository, ref: ref);
    });

/// Occurrences due today or overdue, grouped by nothing -- date-grouping for
/// display happens in the UI. Recomputed from the current rule + log state
/// on every rebuild, same "recompute on refresh" approach as
/// BudgetController._rollForwardRecurring.
final pendingTodayOccurrencesProvider = Provider<List<PendingOccurrence>>((
  ref,
) {
  final rules = ref.watch(recurringRuleControllerProvider);
  final logs = ref.watch(recurringOccurrenceControllerProvider);
  return RecurrenceEngine.computeToday(rules, logs);
});

final pendingTodayCountProvider = Provider<int>(
  (ref) => ref.watch(pendingTodayOccurrencesProvider).length,
);

final upcomingOccurrencesProvider = Provider<List<PendingOccurrence>>((ref) {
  final rules = ref.watch(recurringRuleControllerProvider);
  final logs = ref.watch(recurringOccurrenceControllerProvider);
  return RecurrenceEngine.computeUpcoming(rules, logs);
});

class RecurringOccurrenceController
    extends StateNotifier<List<RecurringOccurrenceModel>> {
  final RecurringOccurrenceDataSource repository;
  final Ref ref;
  RecurringOccurrenceController({required this.repository, required this.ref})
    : super([]) {
    _listenLogs();
  }

  void _listenLogs() {
    repository.getUserOccurrenceLogs().listen(
      (logs) => state = logs,
      onError: (Object error) {
        debugPrint('Recurring occurrence log stream error: $error');
      },
    );
  }

  /// Creates a real transaction for each occurrence (dated now, since it's
  /// being recorded at the moment of approval) and logs it as applied so it
  /// is never surfaced again. Also fast-forwards each touched rule's
  /// `lastProcessedDate` through today, since the Today tab always resolves
  /// its whole backlog window at once (remaining items here were reviewed,
  /// not skipped).
  Future<void> applyOccurrences(
    List<PendingOccurrence> occurrences, {
    bool bumpLastProcessed = true,
  }) async {
    final transactionRepository = ref.read(transactionRepositoryProvider);
    final ruleRepository = ref.read(recurringRuleRepositoryProvider);
    final today = DateTime.now();

    for (final occurrence in occurrences) {
      final rule = occurrence.rule;
      final transaction = TransactionModel(
        id: '',
        type: rule.type,
        categoryId: rule.categoryId,
        categoryName: rule.categoryName,
        amount: rule.amount,
        description: rule.title,
        date: today,
        spentFromIncomeId: rule.spentFromIncomeId,
        recurringRuleId: rule.id,
      );
      final transactionId = await transactionRepository.addTransaction(
        transaction,
      );
      await repository.logOccurrence(
        RecurringOccurrenceModel(
          id: '',
          ruleId: rule.id,
          occurrenceDate: occurrence.date,
          status: RecurringOccurrenceStatus.applied,
          transactionId: transactionId,
        ),
      );
    }

    if (!bumpLastProcessed) return;
    final touchedRuleIds = occurrences.map((o) => o.rule.id).toSet();
    for (final ruleId in touchedRuleIds) {
      final rule = occurrences.firstWhere((o) => o.rule.id == ruleId).rule;
      await ruleRepository.updateRule(
        rule.copyWith(lastProcessedDate: DateTime(today.year, today.month, today.day)),
      );
    }
  }

  /// Logs [occurrence] as skipped -- no transaction is created and it will
  /// never be surfaced again, even before the app is closed and reopened.
  Future<void> skipOccurrence(PendingOccurrence occurrence) async {
    await repository.logOccurrence(
      RecurringOccurrenceModel(
        id: '',
        ruleId: occurrence.rule.id,
        occurrenceDate: occurrence.date,
        status: RecurringOccurrenceStatus.skipped,
      ),
    );
  }
}
