import 'package:expense_calculator/constants/app_mode.dart';

class FireSotreCollection {
  /// Shared across every [AppMode] so the same account/user record works
  /// whether the app is pointed at DEV or PROD -- only the collections
  /// below are split per environment.
  static const USER_COLLECTION = "users";

  static String get TRANSACTION_TYPE => _scoped("transaction_types");
  static String get TRANSACTIONS => _scoped("transactions");
  static String get BUDGETS => _scoped("budgets");
  static String get RECURRING_RULES => _scoped("recurring_rules");
  static String get RECURRING_OCCURRENCES => _scoped("recurring_occurrences");

  /// Every mode -- including PROD -- gets its own namespaced collection,
  /// so switching [AppMode.current] always lands on a clean dataset.
  static String _scoped(String name) =>
      "${AppMode.current.toLowerCase()}_$name";
}
