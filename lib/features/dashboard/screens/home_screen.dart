import 'package:expense_calculator/constants/currency.dart';
import 'package:expense_calculator/features/dashboard/controller/dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Future<void> _onRefresh() async {
    ref.invalidate(dashboardControllerProvider);
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dashboard = ref.watch(dashboardControllerProvider);

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 15),
              _balanceCard(
                isDark,
                "Available Balance",
                dashboard.totalAvailable,
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _balanceCard(
                      isDark,
                      "Total Income",
                      dashboard.totalIncome,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _balanceCard(
                      isDark,
                      "Total Expense",
                      dashboard.totalSpent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 110),
            ],
          ),
        ),
      ),
    );
  }

  Widget _balanceCard(bool isDark, String label, double amount) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xff536976), Color(0xff292e49)],
                stops: [0, 1],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : const LinearGradient(
                colors: [Color(0xff00f5a0), Color(0xff00d9f5)],
                stops: [0, 1],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            "${Currency.TAKA}${amount.toStringAsFixed(0)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
