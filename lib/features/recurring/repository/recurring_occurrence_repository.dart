import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_calculator/constants/firestore_collection_path.dart';
import 'package:expense_calculator/features/auth/controller/auth_controller.dart';
import 'package:expense_calculator/features/offline_mode/controller/offline_mode_controller.dart';
import 'package:expense_calculator/features/recurring/repository/recurring_occurrence_data_source.dart';
import 'package:expense_calculator/features/recurring/repository/recurring_occurrence_local_repository.dart';
import 'package:expense_calculator/models/recurring_occurrence_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final recurringOccurrenceRepositoryProvider =
    Provider<RecurringOccurrenceDataSource>((ref) {
      ref.watch(currentIdentityProvider); // rebuild on account/profile switch
      if (ref.watch(isOfflineModeProvider)) {
        return ref.watch(recurringOccurrenceLocalRepositoryProvider);
      }
      return RecurringOccurrenceRepository(
        firestore: FirebaseFirestore.instance,
        auth: FirebaseAuth.instance,
      );
    });

class RecurringOccurrenceRepository implements RecurringOccurrenceDataSource {
  final FirebaseFirestore firestore;
  final collectionName = FireSotreCollection.RECURRING_OCCURRENCES;
  final FirebaseAuth auth;
  RecurringOccurrenceRepository({required this.firestore, required this.auth});

  @override
  Future<void> logOccurrence(RecurringOccurrenceModel occurrence) async {
    String userId = "";
    if (auth.currentUser != null) {
      userId = auth.currentUser!.uid;
    }
    occurrence.userId = userId;
    await firestore.collection(collectionName).add(occurrence.toMap());
  }

  @override
  Stream<List<RecurringOccurrenceModel>> getUserOccurrenceLogs() {
    final uid = auth.currentUser!.uid;
    return firestore
        .collection(collectionName)
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => RecurringOccurrenceModel.fromMap(doc.id, doc.data()),
              )
              .toList(),
        );
  }
}
