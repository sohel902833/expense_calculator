import 'package:drift/drift.dart';

class LocalRecurringRules extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  TextColumn get type => text()();
  TextColumn get categoryId => text()();
  TextColumn get categoryName => text()();
  RealColumn get amount => real()();
  TextColumn get spentFromIncomeId => text().nullable()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get frequency => text()();
  IntColumn get dayOfMonth => integer().nullable()();
  // Comma-separated DateTime.weekday values (e.g. "1,2,3,4,5") -- Drift has
  // no native list column for sqlite3, and this mirrors how RecurringRuleModel
  // itself just needs a List<int> back out, nothing relational.
  TextColumn get weekdays => text().withDefault(const Constant(''))();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get lastProcessedDate => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
