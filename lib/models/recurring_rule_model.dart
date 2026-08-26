class RecurringFrequency {
  static const monthly = "monthly";
  static const weekly = "weekly";
}

class RecurringRuleModel {
  final String id;
  String? userId;
  final String title;
  final String type; // "Income" or "Expense"
  final String categoryId;
  final String categoryName;
  final double amount;
  final String? spentFromIncomeId;
  final String description;
  final String frequency; // one of RecurringFrequency.*
  final int? dayOfMonth; // 1-31, used when frequency == monthly
  final List<int> weekdays; // DateTime.weekday values (1=Mon..7=Sun), used when frequency == weekly
  final DateTime startDate;
  final DateTime? lastProcessedDate;
  final bool isActive;
  final DateTime createdAt;

  RecurringRuleModel({
    required this.id,
    this.userId,
    required this.title,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    this.spentFromIncomeId,
    this.description = '',
    required this.frequency,
    this.dayOfMonth,
    this.weekdays = const [],
    required this.startDate,
    this.lastProcessedDate,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// The due-date for [rule] within [month]/[year], clamped to the last day
  /// of the month for rules whose `dayOfMonth` overshoots shorter months.
  int clampedDayOfMonth(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return (dayOfMonth ?? 1).clamp(1, lastDay);
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'type': type,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'amount': amount,
    'spentFromIncomeId': spentFromIncomeId,
    'description': description,
    'frequency': frequency,
    'dayOfMonth': dayOfMonth,
    'weekdays': weekdays,
    'startDate': startDate.toIso8601String(),
    'lastProcessedDate': lastProcessedDate?.toIso8601String(),
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'userId': userId,
  };

  factory RecurringRuleModel.fromMap(String id, Map<String, dynamic> map) =>
      RecurringRuleModel(
        id: id,
        userId: map['userId'],
        title: map['title'] ?? '',
        type: map['type'] ?? '',
        categoryId: map['categoryId'] ?? '',
        categoryName: map['categoryName'] ?? '',
        amount: (map['amount'] ?? 0).toDouble(),
        spentFromIncomeId: map['spentFromIncomeId'],
        description: map['description'] ?? '',
        frequency: map['frequency'] ?? RecurringFrequency.monthly,
        dayOfMonth: map['dayOfMonth'],
        weekdays: map['weekdays'] != null
            ? List<int>.from(map['weekdays'])
            : const [],
        startDate: map['startDate'] != null
            ? DateTime.parse(map['startDate'])
            : DateTime.now(),
        lastProcessedDate: map['lastProcessedDate'] != null
            ? DateTime.parse(map['lastProcessedDate'])
            : null,
        isActive: map['isActive'] ?? true,
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'])
            : DateTime.now(),
      );

  RecurringRuleModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? type,
    String? categoryId,
    String? categoryName,
    String? spentFromIncomeId,
    bool clearSpentFromIncome = false,
    double? amount,
    String? description,
    String? frequency,
    int? dayOfMonth,
    List<int>? weekdays,
    DateTime? startDate,
    DateTime? lastProcessedDate,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return RecurringRuleModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      amount: amount ?? this.amount,
      spentFromIncomeId: clearSpentFromIncome
          ? null
          : (spentFromIncomeId ?? this.spentFromIncomeId),
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      weekdays: weekdays ?? this.weekdays,
      startDate: startDate ?? this.startDate,
      lastProcessedDate: lastProcessedDate ?? this.lastProcessedDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
