import 'package:expense_calculator/models/recurring_rule_model.dart';

abstract class RecurringRuleDataSource {
  Future<void> addRule(RecurringRuleModel rule);
  Future<void> updateRule(RecurringRuleModel rule);
  Future<void> deleteRule(String id);
  Stream<List<RecurringRuleModel>> getUserRules();
}
