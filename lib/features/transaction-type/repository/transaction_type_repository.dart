import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_calculator/constants/firestore_collection_path.dart';
import 'package:expense_calculator/features/offline_mode/controller/offline_mode_controller.dart';
import 'package:expense_calculator/features/transaction-type/repository/transaction_type_data_source.dart';
import 'package:expense_calculator/features/transaction-type/repository/transaction_type_local_repository.dart';
import 'package:expense_calculator/models/transaction_type_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transactionTypeRepositoryProvider = Provider<TransactionTypeDataSource>((
  ref,
) {
  if (ref.watch(isOfflineModeProvider)) {
    return ref.watch(transactionTypeLocalRepositoryProvider);
  }
  return TransactionTypeRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

class TransactionTypeRepository implements TransactionTypeDataSource {
  final FirebaseFirestore firestore;
  final collectionName = FireSotreCollection.TRANSACTION_TYPE;
  final FirebaseAuth auth;
  TransactionTypeRepository({required this.firestore, required this.auth});

  @override
  Future<void> addTransactionType(TransactionTypeModel type) async {
    String userId = "";
    if (auth.currentUser != null) {
      userId = auth.currentUser!.uid;
    }
    type.userId = userId;
    await firestore.collection(collectionName).add(type.toMap());
  }

  @override
  Future<void> updateTransactionType(TransactionTypeModel type) async {
    // Ownership is set once on create and must never change on edit -- drop
    // it from the update payload, same as BudgetRepository.updateBudget.
    final data = type.toMap()..remove('userId');
    await firestore.collection(collectionName).doc(type.id).update(data);
  }

  @override
  Future<void> deleteTransactionType(String id) async {
    await firestore.collection(collectionName).doc(id).delete();
  }

  @override
  Stream<List<TransactionTypeModel>> getTransactionTypes() {
    final uid = auth.currentUser?.uid ?? '';
    return firestore
        .collection(collectionName)
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransactionTypeModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }
}
