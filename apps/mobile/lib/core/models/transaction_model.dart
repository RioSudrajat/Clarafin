class TransactionModel {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final String type; // expense, income, transfer
  final String walletId; // Source wallet
  final String? targetWalletId; // Target wallet for transfer
  final String? targetGoalId; // Target goal for transfer
  final String? notes; // Optional user description/notes

  TransactionModel({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.type,
    required this.walletId,
    this.targetWalletId,
    this.targetGoalId,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'amount': amount,
    'date': date.toIso8601String(),
    'type': type,
    'walletId': walletId,
    'targetWalletId': targetWalletId,
    'targetGoalId': targetGoalId,
    'notes': notes,
  };

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    category: json['category'] as String? ?? '',
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    type: json['type'] as String? ?? 'expense',
    walletId: json['walletId'] as String? ?? '',
    targetWalletId: json['targetWalletId'] as String?,
    targetGoalId: json['targetGoalId'] as String?,
    notes: json['notes'] as String?,
  );
}
