import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_calculator/constants/firestore_collection_path.dart';
import 'package:expense_calculator/models/recurring_rule_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final recurringRuleRepositoryProvider = Provider((ref) {
  return RecurringRuleRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

class RecurringRuleRepository {
  final FirebaseFirestore firestore;
  final collectionName = FireSotreCollection.RECURRING_RULES;
  final FirebaseAuth auth;
  RecurringRuleRepository({required this.firestore, required this.auth});

  Future<void> addRule(RecurringRuleModel rule) async {
    String userId = "";
    if (auth.currentUser != null) {
      userId = auth.currentUser!.uid;
    }
    rule.userId = userId;
    await firestore.collection(collectionName).add(rule.toMap());
  }

  Future<void> updateRule(RecurringRuleModel rule) async {
    // Ownership is set once on create and must never change on edit -- drop
    // it from the update payload, same as BudgetRepository.updateBudget.
    final data = rule.toMap()..remove('userId');
    await firestore.collection(collectionName).doc(rule.id).update(data);
  }

  Future<void> deleteRule(String id) async {
    await firestore.collection(collectionName).doc(id).delete();
  }

  /// Sorted client-side so this only needs the automatic single-field index
  /// on `userId`, same rationale as BudgetRepository.getUserBudgets.
  Stream<List<RecurringRuleModel>> getUserRules() {
    final uid = auth.currentUser!.uid;
    return firestore
        .collection(collectionName)
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final rules = snapshot.docs
              .map((doc) => RecurringRuleModel.fromMap(doc.id, doc.data()))
              .toList();
          rules.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return rules;
        });
  }
}
