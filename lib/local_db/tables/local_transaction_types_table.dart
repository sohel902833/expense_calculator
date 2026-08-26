import 'package:drift/drift.dart';

/// Mirrors the Firestore `transaction_types` collection -- per-user
/// categories, scoped by `userId` like every other table.
class LocalTransactionTypes extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().withDefault(const Constant(''))();
  TextColumn get type => text()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
