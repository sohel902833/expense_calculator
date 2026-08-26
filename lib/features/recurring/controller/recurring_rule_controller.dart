import 'dart:async';

import 'package:expense_calculator/features/recurring/repository/recurring_rule_data_source.dart';
import 'package:expense_calculator/features/recurring/repository/recurring_rule_repository.dart';
import 'package:expense_calculator/models/recurring_rule_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final recurringRuleControllerProvider =
    StateNotifierProvider<RecurringRuleController, List<RecurringRuleModel>>((
      ref,
    ) {
      final repository = ref.watch(recurringRuleRepositoryProvider);
      return RecurringRuleController(repository: repository, ref: ref);
    });

class RecurringRuleController extends StateNotifier<List<RecurringRuleModel>> {
  final RecurringRuleDataSource repository;
  final Ref ref;
  StreamSubscription<List<RecurringRuleModel>>? _subscription;
  RecurringRuleController({required this.repository, required this.ref})
    : super([]) {
    _listenRules();
  }

  void _listenRules() {
    _subscription = repository.getUserRules().listen(
      (rules) => state = rules,
      onError: (Object error) {
        debugPrint('Recurring rule stream error: $error');
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> addRule(RecurringRuleModel rule) async {
    await repository.addRule(rule);
  }

  Future<void> updateRule(RecurringRuleModel rule) async {
    await repository.updateRule(rule);
  }

  Future<void> deleteRule(String id) async {
    await repository.deleteRule(id);
  }

  Future<void> setActive(RecurringRuleModel rule, bool isActive) async {
    await repository.updateRule(rule.copyWith(isActive: isActive));
  }
}
