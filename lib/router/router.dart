import 'package:expense_calculator/features/auth/screens/login_screen.dart';
import 'package:expense_calculator/features/auth/screens/signup_screen.dart';
import 'package:expense_calculator/features/comparison/screens/comparison_screen.dart';
import 'package:expense_calculator/features/common/not_found_screen.dart';
import 'package:expense_calculator/features/dashboard/screens/dashboard_screen.dart';
import 'package:expense_calculator/features/transaction-type/screens/transaction_type_screen.dart';
import 'package:flutter/material.dart';

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
    default:
      return MaterialPageRoute(
        builder: (context) => const Scaffold(
          body: NotFoundScreen(error: 'This page doesn\'t exist'),
        ),
      );
  }
}
