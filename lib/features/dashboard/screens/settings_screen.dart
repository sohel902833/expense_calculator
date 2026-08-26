import 'package:expense_calculator/common/providers/theme_provider.dart';
import 'package:expense_calculator/features/auth/controller/auth_controller.dart';
import 'package:expense_calculator/features/auth/screens/login_screen.dart';
import 'package:expense_calculator/features/budget/screens/budget_list_screen.dart';
import 'package:expense_calculator/features/session_lock/controller/session_lock_controller.dart';
import 'package:expense_calculator/features/session_lock/screens/biometric_settings_screen.dart';
import 'package:expense_calculator/features/transaction-type/screens/transaction_type_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  static const routeName = '/settings-screen';
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text("Logout"),
        content: const Text("Do you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("No"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
            ),
            onPressed: () async {
              await ref.read(authControllerProvider).logout();
              ref.read(sessionLockControllerProvider).resetOnLogout();
              if (context.mounted) {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, LoginScreen.routeName);
              }
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 110),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              "Preferences",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text("Dark Mode"),
            value: themeMode == ThemeMode.dark,
            onChanged: (isDark) {
              ref.read(themeProvider.notifier).state = isDark
                  ? ThemeMode.dark
                  : ThemeMode.light;
            },
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              "Manage",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text("Transaction Type"),
            subtitle: const Text("Manage income & expense categories"),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () =>
                Navigator.pushNamed(context, TransactionTypeScreen.routeName),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text("Budgets"),
            subtitle: const Text("Create, edit, and manage budgets"),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () =>
                Navigator.pushNamed(context, BudgetListScreen.routeName),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              "Security",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.fingerprint_rounded),
            title: const Text("Biometric Lock"),
            subtitle: const Text("Unlock the app with your fingerprint"),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.pushNamed(
              context,
              BiometricSettingsScreen.routeName,
            ),
          ),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Color(0xFFE74C3C)),
            title: const Text(
              "Logout",
              style: TextStyle(color: Color(0xFFE74C3C)),
            ),
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }
}
