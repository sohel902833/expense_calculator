import 'package:expense_calculator/common/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      body: ListTile(
        title: const Text("Dark Mode"),
        trailing: Switch(
          value: themeMode == ThemeMode.dark,
          onChanged: (isDark) {
            ref.read(themeProvider.notifier).state = isDark
                ? ThemeMode.dark
                : ThemeMode.light;
          },
        ),
      ),
    );
  }
}
