class TransactionTypeModel {
  final String id;
  final String type; // "Income" or "Expense"
  final String name;
  final String description;

  TransactionTypeModel({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
  });

  Map<String, dynamic> toMap() => {
    'type': type,
    'name': name,
    'description': description,
  };

  factory TransactionTypeModel.fromMap(String id, Map<String, dynamic> map) =>
      TransactionTypeModel(
        id: id,
        type: map['type'] ?? '',
        name: map['name'] ?? '',
        description: map['description'] ?? '',
      );
}
