import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_calculator/constants/firestore_collection_path.dart';
import 'package:expense_calculator/models/transaction_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transactionRepositoryProvider = Provider((ref) {
  return TransactionRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

class TransactionRepository {
  final FirebaseFirestore firestore;
  final collectionName = FireSotreCollection.TRANSACTIONS;
  final FirebaseAuth auth;
  TransactionRepository({required this.firestore, required this.auth});

  Future<void> addTransaction(TransactionModel transaction) async {
    String userId = "";
    if (auth.currentUser != null) {
      userId = auth.currentUser!.uid;
    }
    transaction.userId = userId;
    await firestore.collection(collectionName).add(transaction.toMap());
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await firestore
        .collection(collectionName)
        .doc(transaction.id)
        .update(transaction.toMap());
  }

  Future<void> deleteTransaction(String id) async {
    await firestore.collection(collectionName).doc(id).delete();
  }

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
