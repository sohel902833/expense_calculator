import 'dart:async';

import 'package:expense_calculator/features/transactions/repository/transaction_data_source.dart';
import 'package:expense_calculator/features/transactions/repository/transaction_repository.dart';
import 'package:expense_calculator/models/transaction_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transactionControllerProvider =
    StateNotifierProvider<TransactionController, List<TransactionModel>>((ref) {
      final repository = ref.watch(transactionRepositoryProvider);
      return TransactionController(repository: repository, ref: ref);
    });

class TransactionController extends StateNotifier<List<TransactionModel>> {
  final TransactionDataSource repository;
  final Ref ref;
  StreamSubscription<List<TransactionModel>>? _subscription;
  TransactionController({required this.repository, required this.ref})
    : super([]) {
    _listenTransactions();
  }

  void _listenTransactions() {
    _subscription = repository.getUserTransactions().listen((transactions) {
      state = transactions;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<String> addTransaction(TransactionModel transaction) async {
    return repository.addTransaction(transaction);
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await repository.updateTransaction(transaction);
  }

  Future<void> deleteTransaction(String id) async {
    await repository.deleteTransaction(id);
  }

  Future<void> restoreTransaction(String id) async {
    await repository.restoreTransaction(id);
  }
}
