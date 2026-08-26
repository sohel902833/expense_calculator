import 'package:expense_calculator/features/budget/repository/budget_data_source.dart';
import 'package:expense_calculator/features/budget/repository/budget_repository.dart';
import 'package:expense_calculator/models/budget_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final budgetControllerProvider =
    StateNotifierProvider<BudgetController, List<BudgetModel>>((ref) {
      final repository = ref.watch(budgetRepositoryProvider);
      return BudgetController(repository: repository, ref: ref);
    });

class BudgetController extends StateNotifier<List<BudgetModel>> {
  final BudgetDataSource repository;
  final Ref ref;
  BudgetController({required this.repository, required this.ref}) : super([]) {
    _listenBudgets();
  }

  void _listenBudgets() {
    repository.getUserBudgets().listen(
      (budgets) {
        state = budgets;
        _rollForwardRecurring(budgets);
      },
      onError: (Object error) {
        debugPrint('Budget stream error: $error');
      },
    );
  }

  Future<void> addBudget(BudgetModel budget) async {
    await repository.addBudget(budget);
  }

  Future<void> updateBudget(BudgetModel budget) async {
    await repository.updateBudget(budget);
  }

  Future<void> deleteBudget(String id) async {
    await repository.deleteBudget(id);
  }

  /// Best-effort auto-creation of the next period's budget for
  /// `isRecurring` monthly/weekly/yearly budgets whose window has already
  /// ended and that don't have a successor yet. Runs whenever the budget
  /// list refreshes, so it only fires while the app is open (no
  /// server-side scheduling).
  void _rollForwardRecurring(List<BudgetModel> budgets) {
    for (final budget in budgets) {
      if (!budget.isRecurring) continue;
      if (budget.period != BudgetPeriod.monthly &&
          budget.period != BudgetPeriod.weekly &&
          budget.period != BudgetPeriod.yearly) {
        continue;
      }
      final end = budget.endDate;
      if (end == null) continue;
      final today = DateTime.now();
      final endDay = DateTime(end.year, end.month, end.day);
      final todayDay = DateTime(today.year, today.month, today.day);
      if (!endDay.isBefore(todayDay)) continue;

      final next = _nextPeriod(budget);
      final hasSuccessor = budgets.any(
        (b) =>
            b.name == budget.name &&
            b.budgetType == budget.budgetType &&
            b.categoryId == budget.categoryId &&
            b.period == budget.period &&
            b.startDate != null &&
            _sameDay(b.startDate!, next.startDate!),
      );
      if (!hasSuccessor) {
        addBudget(
          budget.copyWith(
            id: '',
            startDate: next.startDate,
            endDate: next.endDate,
            createdAt: DateTime.now(),
          ),
        );
      }
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  ({DateTime? startDate, DateTime? endDate}) _nextPeriod(BudgetModel budget) {
    final start = budget.startDate!;
    final end = budget.endDate!;
    switch (budget.period) {
      case BudgetPeriod.weekly:
        return (
          startDate: start.add(const Duration(days: 7)),
          endDate: end.add(const Duration(days: 7)),
        );
      case BudgetPeriod.yearly:
        return (
          startDate: DateTime(start.year + 1, 1, 1),
          endDate: DateTime(start.year + 1, 12, 31),
        );
      case BudgetPeriod.monthly:
      default:
        final nextMonthStart = DateTime(start.year, start.month + 1, 1);
        final lastDay = DateTime(
          nextMonthStart.year,
          nextMonthStart.month + 1,
          0,
        ).day;
        return (
          startDate: nextMonthStart,
          endDate: DateTime(
            nextMonthStart.year,
            nextMonthStart.month,
            lastDay,
          ),
        );
    }
  }
}
