import 'package:expense_calculator/features/auth/screens/login_screen.dart';
import 'package:expense_calculator/features/auth/screens/signup_screen.dart';
import 'package:expense_calculator/features/budget/screens/budget_list_screen.dart';
import 'package:expense_calculator/features/comparison/screens/comparison_screen.dart';
import 'package:expense_calculator/features/common/not_found_screen.dart';
import 'package:expense_calculator/features/dashboard/screens/dashboard_screen.dart';
import 'package:expense_calculator/features/dashboard/screens/settings_screen.dart';
import 'package:expense_calculator/features/recurring/screens/recurring_rule_list_screen.dart';
import 'package:expense_calculator/features/recurring/screens/recurring_transactions_screen.dart';
import 'package:expense_calculator/features/session_lock/screens/biometric_settings_screen.dart';
import 'package:expense_calculator/features/transaction-type/screens/transaction_type_screen.dart';
import 'package:flutter/material.dart';

/// The app's single Navigator, keyed so widgets that live outside the
/// Navigator's own subtree (namely the session-lock overlay, injected via
/// MaterialApp.builder as a sibling of the Navigator rather than a route
/// inside it) can still navigate.
final rootNavigatorKey = GlobalKey<NavigatorState>();

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case LoginScreen.routeName:
      {
        return MaterialPageRoute(builder: (context) => const LoginScreen());
      }
    case SignupScreen.routeName:
      {
        return MaterialPageRoute(builder: (context) => const SignupScreen());
      }
    case DashboardScreen.routeName:
      {
        return MaterialPageRoute(builder: (context) => const DashboardScreen());
      }
    case TransactionTypeScreen.routeName:
      {
        return MaterialPageRoute(
          builder: (context) => const TransactionTypeScreen(),
        );
      }
    case ComparisonScreen.routeName:
      {
        return MaterialPageRoute(
          builder: (context) => const ComparisonScreen(),
        );
      }
    case SettingsScreen.routeName:
      {
        return MaterialPageRoute(builder: (context) => const SettingsScreen());
      }
    case BudgetListScreen.routeName:
      {
        return MaterialPageRoute(
          builder: (context) => const BudgetListScreen(),
        );
      }
    case RecurringTransactionsScreen.routeName:
      {
        return MaterialPageRoute(
          builder: (context) => const RecurringTransactionsScreen(),
        );
      }
    case RecurringRuleListScreen.routeName:
      {
        return MaterialPageRoute(
          builder: (context) => const RecurringRuleListScreen(),
        );
      }
    case BiometricSettingsScreen.routeName:
      {
        return MaterialPageRoute(
          builder: (context) => const BiometricSettingsScreen(),
        );
      }
    default:
      return MaterialPageRoute(
        builder: (context) => const Scaffold(
          body: NotFoundScreen(error: 'This page doesn\'t exist'),
        ),
      );
  }
}
