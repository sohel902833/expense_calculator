import 'package:flutter/material.dart';

class BudgetPeriod {
  static const monthly = "monthly";
  static const weekly = "weekly";
  static const yearly = "yearly";
  static const custom = "custom";
  static const ongoing = "ongoing";
}

class BudgetType {
  static const overall = "Overall";
  static const category = "Category";
}

class BudgetModel {
  final String id;
  String? userId;
  final String name;
  final String budgetType; // BudgetType.overall | BudgetType.category
  final String? categoryId;
  final String? categoryName;
  final String period; // one of BudgetPeriod.*
  final DateTime? startDate; // null only when period == ongoing
  final DateTime? endDate; // null only when period == ongoing
  final double amount;
  final bool isRecurring;
  final bool notificationsEnabled;
  final DateTime createdAt;

  BudgetModel({
    required this.id,
    this.userId,
    required this.name,
    required this.budgetType,
    this.categoryId,
    this.categoryName,
    required this.period,
    this.startDate,
    this.endDate,
    required this.amount,
    this.isRecurring = false,
    this.notificationsEnabled = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Whether this budget applies on [date]. Ongoing budgets always apply --
  /// they're a standing monthly template, not a fixed date range.
  bool coversDate(DateTime date) {
    if (period == BudgetPeriod.ongoing) return true;
    if (startDate == null || endDate == null) return false;
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(startDate!.year, startDate!.month, startDate!.day);
    final e = DateTime(endDate!.year, endDate!.month, endDate!.day);
    return !d.isBefore(s) && !d.isAfter(e);
  }

  /// The date range spend should be calculated against for [contextDate].
  /// Ongoing budgets resolve to the calendar month containing [contextDate];
  /// all other periods use their own stored, fixed range.
  DateTimeRange evaluationRangeFor(DateTime contextDate) {
    if (period == BudgetPeriod.ongoing) {
      final lastDay = DateTime(contextDate.year, contextDate.month + 1, 0).day;
      return DateTimeRange(
        start: DateTime(contextDate.year, contextDate.month, 1),
        end: DateTime(contextDate.year, contextDate.month, lastDay),
      );
    }
    return DateTimeRange(start: startDate!, end: endDate!);
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'budgetType': budgetType,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'period': period,
    'startDate': startDate?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'amount': amount,
    'isRecurring': isRecurring,
    'notificationsEnabled': notificationsEnabled,
    'createdAt': createdAt.toIso8601String(),
    'userId': userId,
  };

  factory BudgetModel.fromMap(String id, Map<String, dynamic> map) =>
      BudgetModel(
        id: id,
        userId: map['userId'],
        name: map['name'] ?? '',
        budgetType: map['budgetType'] ?? BudgetType.overall,
        categoryId: map['categoryId'],
        categoryName: map['categoryName'],
        period: map['period'] ?? BudgetPeriod.monthly,
        startDate: map['startDate'] != null
            ? DateTime.parse(map['startDate'])
            : null,
        endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
        amount: (map['amount'] ?? 0).toDouble(),
        isRecurring: map['isRecurring'] ?? false,
        notificationsEnabled: map['notificationsEnabled'] ?? false,
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'])
            : DateTime.now(),
      );

  BudgetModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? budgetType,
    String? categoryId,
    String? categoryName,
    bool clearCategory = false,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
    bool clearDates = false,
    double? amount,
    bool? isRecurring,
    bool? notificationsEnabled,
    DateTime? createdAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      budgetType: budgetType ?? this.budgetType,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      categoryName: clearCategory
          ? null
          : (categoryName ?? this.categoryName),
      period: period ?? this.period,
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      amount: amount ?? this.amount,
      isRecurring: isRecurring ?? this.isRecurring,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
