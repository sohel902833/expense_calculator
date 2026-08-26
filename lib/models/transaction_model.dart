class TransactionModel {
  final String id;
  final String type; // "Income" or "Expense"
  final String categoryId; // Reference to TransactionType ID
  final String categoryName; // For easier display
  final double amount;
  final String description;
  final DateTime date;
  String? userId;
  final String? spentFromIncomeId;
  final bool isDeleted;
  final String? recurringRuleId; // set when created from a recurring rule
  // timestamp

  TransactionModel({
    required this.id,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.description,
    required this.date,
    this.userId,
    this.spentFromIncomeId,
    this.isDeleted = false,
    this.recurringRuleId,
  });

  Map<String, dynamic> toMap() => {
    'type': type,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'amount': amount,
    'description': description,
    'date': date.toIso8601String(),
    'userId': userId,
    'spentFromIncomeId': spentFromIncomeId,
    'isDeleted': isDeleted,
    'recurringRuleId': recurringRuleId,
  };

  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) =>
      TransactionModel(
        id: id,
        type: map['type'] ?? '',
        categoryId: map['categoryId'] ?? '',
        categoryName: map['categoryName'] ?? '',
        amount: (map['amount'] ?? 0).toDouble(),
        description: map['description'] ?? '',
        userId: map['userId'] ?? '',
        date: map['date'] != null
            ? DateTime.parse(map['date'])
            : DateTime.now(),
        spentFromIncomeId: map['spentFromIncomeId'],
        isDeleted: map['isDeleted'] ?? false,
        recurringRuleId: map['recurringRuleId'],
      );
}
