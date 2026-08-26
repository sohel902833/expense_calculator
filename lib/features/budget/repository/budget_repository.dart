import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_calculator/constants/firestore_collection_path.dart';
import 'package:expense_calculator/features/budget/repository/budget_data_source.dart';
import 'package:expense_calculator/features/budget/repository/budget_local_repository.dart';
import 'package:expense_calculator/features/offline_mode/controller/offline_mode_controller.dart';
import 'package:expense_calculator/models/budget_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final budgetRepositoryProvider = Provider<BudgetDataSource>((ref) {
  if (ref.watch(isOfflineModeProvider)) {
    return ref.watch(budgetLocalRepositoryProvider);
  }
  return BudgetRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

class BudgetRepository implements BudgetDataSource {
  final FirebaseFirestore firestore;
  final collectionName = FireSotreCollection.BUDGETS;
  final FirebaseAuth auth;
  BudgetRepository({required this.firestore, required this.auth});

  @override
  Future<void> addBudget(BudgetModel budget) async {
    String userId = "";
    if (auth.currentUser != null) {
      userId = auth.currentUser!.uid;
    }
    budget.userId = userId;
    await firestore.collection(collectionName).add(budget.toMap());
  }

  @override
  Future<void> updateBudget(BudgetModel budget) async {
    // Ownership is set once on create and must never change on edit --
    // drop it from the update payload so a caller that forgets to carry
    // `userId` forward can't accidentally null it out.
    final data = budget.toMap()..remove('userId');
    await firestore.collection(collectionName).doc(budget.id).update(data);
  }

  @override
  Future<void> deleteBudget(String id) async {
    await firestore.collection(collectionName).doc(id).delete();
  }

  /// Sorted client-side (rather than via a Firestore `orderBy`) so this
  /// only needs the automatic single-field index on `userId` -- a
  /// composite index for `userId` + `createdAt` isn't guaranteed to exist
  /// for a fresh collection, and a missing index makes the query fail
  /// outright instead of just arriving unsorted.
  @override
  Stream<List<BudgetModel>> getUserBudgets() {
    final uid = auth.currentUser!.uid;
    return firestore
        .collection(collectionName)
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final budgets = snapshot.docs
              .map((doc) => BudgetModel.fromMap(doc.id, doc.data()))
              .toList();
          budgets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return budgets;
        });
  }
}
