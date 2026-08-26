import 'package:expense_calculator/models/budget_model.dart';

abstract class BudgetDataSource {
  Future<void> addBudget(BudgetModel budget);
  Future<void> updateBudget(BudgetModel budget);
  Future<void> deleteBudget(String id);
  Stream<List<BudgetModel>> getUserBudgets();
}
