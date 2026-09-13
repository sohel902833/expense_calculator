import 'package:expense_calculator/common/providers/theme_provider.dart';
import 'package:expense_calculator/constants/app_mode.dart';
import 'package:expense_calculator/features/auth/controller/auth_controller.dart';
import 'package:expense_calculator/features/auth/screens/login_screen.dart';
import 'package:expense_calculator/features/budget/screens/budget_list_screen.dart';
import 'package:expense_calculator/features/offline_mode/controller/offline_mode_controller.dart';
import 'package:expense_calculator/features/offline_mode/screens/sync_to_cloud_sheet.dart';
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
  Widget _buildBadge({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

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
              if (ref.read(isOfflineModeProvider)) {
                await ref
                    .read(offlineModeControllerProvider)
                    .setCurrentLocalUser(null);
              } else {
                await ref.read(authControllerProvider).logout();
              }
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

  Widget _buildProfileHeader(BuildContext context) {
    final isOffline = ref.watch(isOfflineModeProvider);
    final user = ref.watch(sessionProvider).valueOrNull;
    // The Firestore user doc only ever stores email for offline/local
    // accounts (see UserModel) -- online accounts' email lives on the
    // Firebase Auth user itself.
    final email = isOffline
        ? user?.email
        : ref.watch(firebaseAuthStateProvider).valueOrNull?.email;
    final name = (user?.name.isNotEmpty ?? false) ? user!.name : "User";
    final hasPhoto = user?.profilePic.isNotEmpty ?? false;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: hasPhoto ? NetworkImage(user!.profilePic) : null,
            child: hasPhoto
                ? null
                : Text(
                    name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (email != null && email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (!AppMode.isProd)
                      _buildBadge(
                        label: "${AppMode.current} MODE",
                        color: Colors.orange.shade700,
                        icon: Icons.build_rounded,
                      ),
                    isOffline
                        ? _buildBadge(
                            label: "Offline",
                            color: Colors.grey.shade600,
                            icon: Icons.cloud_off_rounded,
                          )
                        : _buildBadge(
                            label: "Online",
                            color: Colors.green.shade600,
                            icon: Icons.cloud_done_rounded,
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isOffline = ref.watch(isOfflineModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 110),
        children: [
          _buildProfileHeader(context),
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
          if (isOffline)
            ListTile(
              leading: const Icon(Icons.cloud_upload_outlined),
              title: const Text("Sync to Cloud"),
              subtitle: const Text(
                "Create an account and back up everything you've built up",
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => showSyncToCloudSheet(context, ref),
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
