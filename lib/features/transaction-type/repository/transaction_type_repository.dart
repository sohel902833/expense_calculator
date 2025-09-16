import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_calculator/constants/firestore_collection_path.dart';
import 'package:expense_calculator/models/transaction_type_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transactionTypeRepositoryProvider = Provider((ref) {
  return TransactionTypeRepository(firestore: FirebaseFirestore.instance);
});

class TransactionTypeRepository {
  final FirebaseFirestore firestore;
  final collectionName = FireSotreCollection.TRANSACTION_TYPE;
  TransactionTypeRepository({required this.firestore});
  Future<void> addTransactionType(TransactionTypeModel type) async {
    await firestore.collection(collectionName).add(type.toMap());
  }

  Future<void> updateTransactionType(TransactionTypeModel type) async {
    await firestore
        .collection(collectionName)
        .doc(type.id)
        .update(type.toMap());
  }

  Future<void> deleteTransactionType(String id) async {
    await firestore.collection(collectionName).doc(id).delete();
  }

  Stream<List<TransactionTypeModel>> getTransactionTypes() {
    return firestore
        .collection(collectionName)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransactionTypeModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }
}
