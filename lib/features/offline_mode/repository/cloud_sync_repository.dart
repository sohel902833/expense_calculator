import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:expense_calculator/common/repository/common_firebase_storage_repository.dart';
import 'package:expense_calculator/constants/firestore_collection_path.dart';
import 'package:expense_calculator/features/auth/repository/local_auth_repository.dart';
import 'package:expense_calculator/features/offline_mode/controller/offline_mode_controller.dart';
import 'package:expense_calculator/local_db/app_local_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cloudSyncRepositoryProvider = Provider((ref) {
  return CloudSyncRepository(db: ref.watch(appLocalDatabaseProvider), ref: ref);
});

List<int> _parseWeekdays(String text) =>
    text.isEmpty ? const [] : text.split(',').map(int.parse).toList();

/// Creates a Firebase account from the currently signed-in local profile
/// and uploads everything that profile built up locally into Firestore,
/// remapping `userId` from the local id to the new Firebase uid and
/// stamping every migrated doc with `syncedFromLocalId` so a later sync
/// attempt (more local data added after going offline again) never
/// re-uploads what's already there -- driven by each local row's own
/// `isSynced` flag, checked before upload.
class CloudSyncRepository {
  final AppLocalDatabase db;
  final Ref ref;
  CloudSyncRepository({required this.db, required this.ref});

  Future<void> syncToCloud({
    required String name,
    required String email,
    required String password,
  }) async {
    final localUserId = ref.read(currentLocalUserIdProvider);
    if (localUserId == null) {
      throw Exception('No local session to sync');
    }

    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    String uid;
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      uid = credential.user!.uid;
    } on FirebaseAuthException catch (e) {
      // The account may already exist from a previous attempt that failed
      // partway through migration -- sign in and resume instead of
      // hard-failing, since local rows already marked synced are safely
      // skipped below.
      if (e.code == 'email-already-in-use') {
        final credential = await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        uid = credential.user!.uid;
      } else {
        rethrow;
      }
    }

    await _migrateUser(uid: uid, name: name, localUserId: localUserId);
    await _migrateTransactionTypes(
      firestore,
      localUserId: localUserId,
      uid: uid,
    );
    await _migrateTransactions(firestore, localUserId: localUserId, uid: uid);
    await _migrateBudgets(firestore, localUserId: localUserId, uid: uid);
    await _migrateRecurringRules(firestore, localUserId: localUserId, uid: uid);
    await _migrateRecurringOccurrences(
      firestore,
      localUserId: localUserId,
      uid: uid,
    );

    final offlineModeController = ref.read(offlineModeControllerProvider);
    await offlineModeController.setOfflineMode(false);
    await offlineModeController.setCurrentLocalUser(null);
  }

  Future<void> _migrateUser({
    required String uid,
    required String name,
    required String localUserId,
  }) async {
    final localUser = await ref
        .read(localAuthRepositoryProvider)
        .getUserById(localUserId);

    String photoUrl =
        'https://png.pngitem.com/pimgs/s/649-6490124_katie-notopoulos-katienotopoulos-i-write-about-tech-round.png';
    final localPic = localUser?.profilePic;
    if (localPic != null && localPic.isNotEmpty) {
      final file = File(localPic);
      if (await file.exists()) {
        try {
          photoUrl = await ref
              .read(commonFirebaseStorageRepositoryProvider)
              .storeFileToFirebase('profilePic/$uid', file);
        } catch (_) {
          // Non-fatal -- keep the placeholder, same as online signup when
          // no picture is supplied.
        }
      }
    }

    await FirebaseFirestore.instance
        .collection(FireSotreCollection.USER_COLLECTION)
        .doc(uid)
        .set({
          'name': name,
          'uid': uid,
          'profilePic': photoUrl,
          'isOnline': true,
          'phoneNumber': localUser?.phoneNumber ?? '',
        });
  }

  Future<void> _migrateTransactionTypes(
    FirebaseFirestore firestore, {
    required String localUserId,
    required String uid,
  }) async {
    final rows =
        await (db.select(db.localTransactionTypes)..where(
              (t) => t.userId.equals(localUserId) & t.isSynced.equals(false),
            ))
            .get();
    for (final row in rows) {
      await firestore.collection(FireSotreCollection.TRANSACTION_TYPE).add({
        'type': row.type,
        'name': row.name,
        'description': row.description,
        'userId': uid,
        'syncedFromLocalId': row.id,
      });
      await (db.update(
        db.localTransactionTypes,
      )..where((t) => t.id.equals(row.id))).write(
        const LocalTransactionTypesCompanion(isSynced: Value(true)),
      );
    }
  }

  Future<void> _migrateTransactions(
    FirebaseFirestore firestore, {
    required String localUserId,
    required String uid,
  }) async {
    final rows =
        await (db.select(db.localTransactions)..where(
              (t) => t.userId.equals(localUserId) & t.isSynced.equals(false),
            ))
            .get();
    for (final row in rows) {
      await firestore.collection(FireSotreCollection.TRANSACTIONS).add({
        'type': row.type,
        'categoryId': row.categoryId,
        'categoryName': row.categoryName,
        'amount': row.amount,
        'description': row.description,
        'date': row.date.toIso8601String(),
        'userId': uid,
        'spentFromIncomeId': row.spentFromIncomeId,
        'isDeleted': row.isDeleted,
        'recurringRuleId': row.recurringRuleId,
        'syncedFromLocalId': row.id,
      });
      await (db.update(db.localTransactions)..where((t) => t.id.equals(row.id)))
          .write(const LocalTransactionsCompanion(isSynced: Value(true)));
    }
  }

  Future<void> _migrateBudgets(
    FirebaseFirestore firestore, {
    required String localUserId,
    required String uid,
  }) async {
    final rows =
        await (db.select(db.localBudgets)..where(
              (t) => t.userId.equals(localUserId) & t.isSynced.equals(false),
            ))
            .get();
    for (final row in rows) {
      await firestore.collection(FireSotreCollection.BUDGETS).add({
        'name': row.name,
        'budgetType': row.budgetType,
        'categoryId': row.categoryId,
        'categoryName': row.categoryName,
        'period': row.period,
        'startDate': row.startDate?.toIso8601String(),
        'endDate': row.endDate?.toIso8601String(),
        'amount': row.amount,
        'isRecurring': row.isRecurring,
        'notificationsEnabled': row.notificationsEnabled,
        'createdAt': row.createdAt.toIso8601String(),
        'userId': uid,
        'syncedFromLocalId': row.id,
      });
      await (db.update(db.localBudgets)..where((t) => t.id.equals(row.id)))
          .write(const LocalBudgetsCompanion(isSynced: Value(true)));
    }
  }

  Future<void> _migrateRecurringRules(
    FirebaseFirestore firestore, {
    required String localUserId,
    required String uid,
  }) async {
    final rows =
        await (db.select(db.localRecurringRules)..where(
              (t) => t.userId.equals(localUserId) & t.isSynced.equals(false),
            ))
            .get();
    for (final row in rows) {
      await firestore.collection(FireSotreCollection.RECURRING_RULES).add({
        'title': row.title,
        'type': row.type,
        'categoryId': row.categoryId,
        'categoryName': row.categoryName,
        'amount': row.amount,
        'spentFromIncomeId': row.spentFromIncomeId,
        'description': row.description,
        'frequency': row.frequency,
        'dayOfMonth': row.dayOfMonth,
        'weekdays': _parseWeekdays(row.weekdays),
        'startDate': row.startDate.toIso8601String(),
        'lastProcessedDate': row.lastProcessedDate?.toIso8601String(),
        'isActive': row.isActive,
        'createdAt': row.createdAt.toIso8601String(),
        'userId': uid,
        'syncedFromLocalId': row.id,
      });
      await (db.update(
        db.localRecurringRules,
      )..where((t) => t.id.equals(row.id))).write(
        const LocalRecurringRulesCompanion(isSynced: Value(true)),
      );
    }
  }

  Future<void> _migrateRecurringOccurrences(
    FirebaseFirestore firestore, {
    required String localUserId,
    required String uid,
  }) async {
    final rows =
        await (db.select(db.localRecurringOccurrences)..where(
              (t) => t.userId.equals(localUserId) & t.isSynced.equals(false),
            ))
            .get();
    for (final row in rows) {
      await firestore
          .collection(FireSotreCollection.RECURRING_OCCURRENCES)
          .add({
            'ruleId': row.ruleId,
            'occurrenceDate': row.occurrenceDate.toIso8601String(),
            'status': row.status,
            'transactionId': row.transactionId,
            'resolvedAt': row.resolvedAt.toIso8601String(),
            'userId': uid,
            'syncedFromLocalId': row.id,
          });
      await (db.update(
        db.localRecurringOccurrences,
      )..where((t) => t.id.equals(row.id))).write(
        const LocalRecurringOccurrencesCompanion(isSynced: Value(true)),
      );
    }
  }
}
