import 'package:expense_calculator/models/recurring_occurrence_model.dart';

abstract class RecurringOccurrenceDataSource {
  Future<void> logOccurrence(RecurringOccurrenceModel occurrence);
  Stream<List<RecurringOccurrenceModel>> getUserOccurrenceLogs();
}
