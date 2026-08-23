import 'package:flutter/material.dart';

class CurrentTheme {
  static bool isDark(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark;
  }
}
