import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:expense_calculator/local_db/tables/local_budgets_table.dart';
import 'package:expense_calculator/local_db/tables/local_recurring_occurrences_table.dart';
import 'package:expense_calculator/local_db/tables/local_recurring_rules_table.dart';
import 'package:expense_calculator/local_db/tables/local_transaction_types_table.dart';
import 'package:expense_calculator/local_db/tables/local_transactions_table.dart';
import 'package:expense_calculator/local_db/tables/local_users_table.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

part 'app_local_database.g.dart';

final appLocalDatabaseProvider = Provider<AppLocalDatabase>((ref) {
  final db = AppLocalDatabase();
  ref.onDispose(db.close);
  return db;
});

@DriftDatabase(
  tables: [
    LocalUsers,
    LocalTransactionTypes,
    LocalTransactions,
    LocalBudgets,
    LocalRecurringRules,
    LocalRecurringOccurrences,
  ],
)
class AppLocalDatabase extends _$AppLocalDatabase {
  AppLocalDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v1 -> v2: transaction types became per-user instead of global.
      if (from < 2) {
        await m.addColumn(localTransactionTypes, localTransactionTypes.userId);
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'app_local.sqlite'));
    return NativeDatabase.createInBackground(
      file,
      setup: (database) {
        applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
      },
    );
  });
}
