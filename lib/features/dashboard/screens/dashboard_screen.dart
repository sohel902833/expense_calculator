import 'dart:ui';

import 'package:expense_calculator/common/modals/transaction_modals.dart';
import 'package:expense_calculator/features/budget/screens/budget_dashboard_screen.dart';
import 'package:expense_calculator/features/budget/screens/budget_list_screen.dart';
import 'package:expense_calculator/features/comparison/screens/comparison_screen.dart';
import 'package:expense_calculator/features/dashboard/screens/home_screen.dart';
import 'package:expense_calculator/features/dashboard/screens/settings_screen.dart';
import 'package:expense_calculator/features/dashboard/screens/transaction_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared geometry for the floating glass nav bar so any screen that needs
/// to float its own button above it can line up with the DashboardScreen's
/// own floating "add" button exactly.
const double kGlassNavBarHeight = 64;
const double kGlassNavBarMargin = 16;
const double kGlassNavFabGap = 10;

double glassNavFabBottomOffset(BuildContext context) =>
    kGlassNavBarMargin +
    kGlassNavBarHeight +
    kGlassNavFabGap +
    MediaQuery.of(context).padding.bottom;

/// The bottom-nav tab currently shown. Exposed as a provider (rather than
/// private State) so other screens embedded in the tab stack -- e.g.
/// HomeScreen's "See All" links -- can switch tabs without needing a
/// callback threaded down from DashboardScreen.
final dashboardTabIndexProvider = StateProvider<int>((ref) => 0);

class DashboardScreen extends ConsumerWidget {
  static const routeName = '/dashboard-screen';
  const DashboardScreen({super.key});

  static const _tabTitles = ["Dashboard", "Transactions", "Budget"];

  // pages are created only once and kept alive
  static const _pages = [
    HomeScreen(),
    TransactionScreen(),
    BudgetDashboardScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fabBottom = glassNavFabBottomOffset(context);
    final currentIndex = ref.watch(dashboardTabIndexProvider);

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(_tabTitles[currentIndex]),
        actions: [
          if (currentIndex == 0)
            IconButton(
              tooltip: "Filter by month",
              onPressed: () => showDashboardMonthFilterSheet(context, ref),
              icon: const Icon(Icons.tune_rounded),
            ),
          if (currentIndex == 1) _buildTransactionFilterAction(ref, context),
          if (currentIndex == 2)
            IconButton(
              tooltip: "Manage Budgets",
              onPressed: () =>
                  Navigator.pushNamed(context, BudgetListScreen.routeName),
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
          IconButton(
            tooltip: "Settings",
            onPressed: () =>
                Navigator.pushNamed(context, SettingsScreen.routeName),
            icon: const CircleAvatar(
              radius: 14,
              child: Icon(Icons.person_rounded, size: 18),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(index: currentIndex, children: _pages),
          Positioned(
            right: 20,
            bottom: fabBottom,
            child: FloatingActionButton(
              mini: true,
              heroTag: "addTransactionFab",
              onPressed: () {
                TransactionModals.showAddTransactionModal(context, ref);
              },
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildGlassNavBar(context, ref, currentIndex),
    );
  }

  Widget _buildTransactionFilterAction(WidgetRef ref, BuildContext context) {
    final activeCount = ref.watch(transactionFilterProvider).activeFilterCount;
    return IconButton(
      tooltip: "Filter transactions",
      onPressed: () => showTransactionFilterSheet(context, ref),
      icon: Badge(
        isLabelVisible: activeCount > 0,
        label: Text("$activeCount"),
        child: const Icon(Icons.tune_rounded),
      ),
    );
  }

  Widget _buildGlassNavBar(
    BuildContext context,
    WidgetRef ref,
    int currentIndex,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;

    void setIndex(int index) =>
        ref.read(dashboardTabIndexProvider.notifier).state = index;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottomSafeArea),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.white).withValues(
                alpha: 0.35,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.12,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: "Home",
                  selected: currentIndex == 0,
                  onTap: () => setIndex(0),
                ),
                _NavItem(
                  icon: Icons.list_alt_rounded,
                  label: "Transaction",
                  selected: currentIndex == 1,
                  onTap: () => setIndex(1),
                ),
                _NavItem(
                  icon: Icons.account_balance_wallet_rounded,
                  label: "Budget",
                  selected: currentIndex == 2,
                  onTap: () => setIndex(2),
                ),
                _NavItem(
                  icon: Icons.compare_arrows_rounded,
                  label: "Compare",
                  selected: false,
                  onTap: () => Navigator.pushNamed(
                    context,
                    ComparisonScreen.routeName,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.blue : Colors.grey;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
