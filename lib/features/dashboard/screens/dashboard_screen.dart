import 'dart:ui';

import 'package:expense_calculator/common/modals/transaction_modals.dart';
import 'package:expense_calculator/features/dashboard/screens/home_screen.dart';
import 'package:expense_calculator/features/dashboard/screens/settings_screen.dart';
import 'package:expense_calculator/features/dashboard/screens/transaction_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared geometry for the floating glass nav bar so any screen that needs
/// to float its own button above it (e.g. TransactionScreen's filter button)
/// can line up with the DashboardScreen's own floating "add" button exactly.
const double kGlassNavBarHeight = 64;
const double kGlassNavBarMargin = 16;
const double kGlassNavFabGap = 10;

/// Mini FloatingActionButton's built-in size, and the breathing room between
/// the two stacked buttons (filter above add) on the Transaction tab.
const double kMiniFabSize = 40;
const double kFabStackGap = 12;

double glassNavFabBottomOffset(BuildContext context) =>
    kGlassNavBarMargin +
    kGlassNavBarHeight +
    kGlassNavFabGap +
    MediaQuery.of(context).padding.bottom;

class DashboardScreen extends ConsumerStatefulWidget {
  static const routeName = '/dashboard-screen';
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  // pages are created only once and kept alive
  final List<Widget> _pages = const [
    HomeScreen(),
    TransactionScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final fabBottom = glassNavFabBottomOffset(context);

    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: const Text("Dashboard")),
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _pages),
          if (_currentIndex == 1)
            Positioned(
              right: 20,
              bottom: fabBottom + kMiniFabSize + kFabStackGap,
              child: _buildFilterFab(context),
            ),
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
      bottomNavigationBar: _buildGlassNavBar(context),
    );
  }

  Widget _buildFilterFab(BuildContext context) {
    final activeCount = ref.watch(transactionFilterProvider).activeFilterCount;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        FloatingActionButton(
          mini: true,
          heroTag: "transactionFilterFab",
          onPressed: () => showTransactionFilterSheet(context, ref),
          backgroundColor: const Color(0xFF37474F),
          child: const Icon(Icons.tune_rounded),
        ),
        if (activeCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              child: Text(
                "$activeCount",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGlassNavBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;

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
                  selected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.list_alt_rounded,
                  label: "Transaction",
                  selected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.settings_rounded,
                  label: "Settings",
                  selected: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
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
