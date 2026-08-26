import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_calculator/constants/firestore_collection_path.dart';
import 'package:expense_calculator/features/auth/controller/auth_controller.dart';
import 'package:expense_calculator/features/offline_mode/controller/offline_mode_controller.dart';
import 'package:expense_calculator/features/transactions/repository/transaction_data_source.dart';
import 'package:expense_calculator/features/transactions/repository/transaction_local_repository.dart';
import 'package:expense_calculator/models/transaction_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transactionRepositoryProvider = Provider<TransactionDataSource>((ref) {
  ref.watch(currentIdentityProvider); // rebuild on account/profile switch
  if (ref.watch(isOfflineModeProvider)) {
    return ref.watch(transactionLocalRepositoryProvider);
  }
  return TransactionRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

class TransactionRepository implements TransactionDataSource {
  final FirebaseFirestore firestore;
  final collectionName = FireSotreCollection.TRANSACTIONS;
  final FirebaseAuth auth;
  TransactionRepository({required this.firestore, required this.auth});

  @override
  Future<String> addTransaction(TransactionModel transaction) async {
    String userId = "";
    if (auth.currentUser != null) {
      userId = auth.currentUser!.uid;
    }
    transaction.userId = userId;
    final doc = await firestore
        .collection(collectionName)
        .add(transaction.toMap());
    return doc.id;
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    await firestore
        .collection(collectionName)
        .doc(transaction.id)
        .update(transaction.toMap());
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await firestore.collection(collectionName).doc(id).update({
      'isDeleted': true,
    });
  }

  @override
  Future<void> restoreTransaction(String id) async {
    await firestore.collection(collectionName).doc(id).update({
      'isDeleted': false,
    });
  }

  @override
  Stream<List<TransactionModel>> getTransactions() {
    return firestore
        .collection(collectionName)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransactionModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// ✅ Stream all transactions of current user
  @override
  Stream<List<TransactionModel>> getUserTransactions() {
    final uid = auth.currentUser!.uid;
    return firestore
        .collection(collectionName)
        .where('userId', isEqualTo: uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransactionModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }
}
