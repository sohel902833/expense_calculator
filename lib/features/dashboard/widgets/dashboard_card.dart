import 'package:expense_calculator/constants/currency.dart';
import 'package:flutter/material.dart';

class DashboardCard extends StatelessWidget {
  const DashboardCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? LinearGradient(
                              colors: [Color(0xff536976), Color(0xff292e49)],
                              stops: [0, 1],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            )
                          : LinearGradient(
                              colors: [Color(0xff00f5a0), Color(0xff00d9f5)],
                              stops: [0, 1],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 25,
                      horizontal: 20,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Available Balance",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        const Text(
                          "5000${Currency.TAKA}",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
  }
}