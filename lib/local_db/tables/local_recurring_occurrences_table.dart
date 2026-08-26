import 'package:drift/drift.dart';

class LocalRecurringOccurrences extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get ruleId => text()();
  DateTimeColumn get occurrenceDate => dateTime()();
  TextColumn get status => text()();
  TextColumn get transactionId => text().nullable()();
  DateTimeColumn get resolvedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
