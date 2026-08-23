import 'package:expense_calculator/common/modals/transaction_modals.dart';
import 'package:expense_calculator/features/auth/controller/auth_controller.dart';
import 'package:expense_calculator/features/auth/screens/login_screen.dart';
import 'package:expense_calculator/features/dashboard/screens/home_screen.dart';
import 'package:expense_calculator/features/dashboard/screens/profile_screen.dart';
import 'package:expense_calculator/features/dashboard/screens/settings_screen.dart';
import 'package:expense_calculator/features/dashboard/screens/transaction_screen.dart';
import 'package:expense_calculator/features/transaction-type/controller/transaction_type_controller.dart';
import 'package:expense_calculator/features/transaction-type/screens/transaction_type_screen.dart';
import 'package:expense_calculator/features/transactions/controller/transaction_controller.dart';
import 'package:expense_calculator/models/transaction_model.dart';
import 'package:expense_calculator/models/transaction_type_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import "../controller/dashboard_controller.dart";

class DashboardScreen extends ConsumerStatefulWidget {
  static const routeName = '/login-screen';
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Do you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // close dialog
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(authControllerProvider).logout();
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(context, LoginScreen.routeName);
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  int _currentIndex = 0;

  void _onItemTapped(int index) {
    if (index == 2) {
    } else {
      setState(() => _currentIndex = index);
    }
  }

  // pages are created only once and kept alive
  final List<Widget> _pages = const [
    HomeScreen(),
    TransactionScreen(),
    SizedBox.shrink(),
    ProfileScreen(),
    SettingsScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(dashboardControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "settings") {
                Navigator.pushNamed(context, TransactionTypeScreen.routeName);
              } else if (value == "logout") {
                _showLogoutDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: "settings",
                child: Text("Transaction Type"),
              ),
              const PopupMenuItem(value: "logout", child: Text("Logout")),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onItemTapped,

        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Transaction"),
          BottomNavigationBarItem(icon: SizedBox.shrink(), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterDocked,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 10), // raise it above nav bar
        child: ElevatedButton(
          onPressed: () {
            TransactionModals.showAddTransactionModal(context, ref);
          },
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(15),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 6,
          ),
          child: const Icon(Icons.add, size: 32),
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => _showAddTransactionModal(context, ref),
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}
