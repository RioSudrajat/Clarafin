/// Typed DTOs matching Go `quota_handler.go` and `tracker_handler.go` payloads.
class RemoteQuotaStatus {
  final String planType;
  final int quotaTotal;
  final int quotaUsed;
  final int quotaRemaining;
  final String renewalDate;

  const RemoteQuotaStatus({
    required this.planType,
    required this.quotaTotal,
    required this.quotaUsed,
    required this.quotaRemaining,
    required this.renewalDate,
  });

  factory RemoteQuotaStatus.fromJson(Map<String, dynamic> json) {
    return RemoteQuotaStatus(
      planType: json['plan_type']?.toString() ?? 'free',
      quotaTotal: (json['quota_total'] as num?)?.toInt() ?? 40,
      quotaUsed: (json['quota_used'] as num?)?.toInt() ?? 0,
      quotaRemaining: (json['quota_remaining'] as num?)?.toInt() ?? 40,
      renewalDate: json['renewal_date']?.toString() ?? '',
    );
  }
}

class RemoteWalletResult {
  final String id;
  final String name;
  final String type;
  final String? institutionCode;
  final int balance;

  const RemoteWalletResult({
    required this.id,
    required this.name,
    required this.type,
    this.institutionCode,
    required this.balance,
  });

  factory RemoteWalletResult.fromJson(Map<String, dynamic> json) {
    return RemoteWalletResult(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'other',
      institutionCode: json['institution_code']?.toString(),
      balance: (json['balance'] as num?)?.toInt() ?? 0,
    );
  }
}

class RemoteTransactionResult {
  final String transactionId;
  final String walletId;
  final bool idempotentReplay;
  final int walletBalanceIdr;
  final int? destinationWalletBalanceIdr;

  const RemoteTransactionResult({
    required this.transactionId,
    required this.walletId,
    required this.idempotentReplay,
    required this.walletBalanceIdr,
    this.destinationWalletBalanceIdr,
  });

  factory RemoteTransactionResult.fromJson(Map<String, dynamic> json) {
    final tx = json['transaction'] is Map
        ? Map<String, dynamic>.from(json['transaction'] as Map)
        : const <String, dynamic>{};
    return RemoteTransactionResult(
      transactionId: tx['id']?.toString() ?? '',
      walletId: tx['wallet_id']?.toString() ?? '',
      idempotentReplay: json['idempotent_replay'] as bool? ?? false,
      walletBalanceIdr: (json['wallet_balance_idr'] as num?)?.toInt() ?? 0,
      destinationWalletBalanceIdr:
          (json['destination_wallet_balance_idr'] as num?)?.toInt(),
    );
  }
}

class RemoteGoalResult {
  final String id;
  final String title;
  final int targetAmount;
  final int savedAmount;
  final String priority;

  const RemoteGoalResult({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
    required this.priority,
  });

  factory RemoteGoalResult.fromJson(Map<String, dynamic> json) {
    return RemoteGoalResult(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      targetAmount: (json['target_amount'] as num?)?.toInt() ?? 0,
      savedAmount: (json['saved_amount'] as num?)?.toInt() ?? 0,
      priority: json['priority']?.toString() ?? 'wants',
    );
  }
}

class RemoteBudgetResult {
  final String id;
  final String category;
  final String monthYear;
  final int limitAmount;

  const RemoteBudgetResult({
    required this.id,
    required this.category,
    required this.monthYear,
    required this.limitAmount,
  });

  factory RemoteBudgetResult.fromJson(Map<String, dynamic> json) {
    return RemoteBudgetResult(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      monthYear: json['month_year']?.toString() ?? '',
      limitAmount: (json['limit_amount'] as num?)?.toInt() ?? 0,
    );
  }
}

class RemoteBillResult {
  final String id;
  final String title;
  final int amount;
  final String frequency;

  const RemoteBillResult({
    required this.id,
    required this.title,
    required this.amount,
    required this.frequency,
  });

  factory RemoteBillResult.fromJson(Map<String, dynamic> json) {
    return RemoteBillResult(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      frequency: json['frequency']?.toString() ?? 'monthly',
    );
  }
}

class TrackerSyncSummary {
  final bool skippedAlreadySynced;
  final int walletsSynced;
  final int transactionsSynced;
  final int budgetsSynced;
  final int goalsSynced;
  final int billsSynced;

  const TrackerSyncSummary({
    this.skippedAlreadySynced = false,
    this.walletsSynced = 0,
    this.transactionsSynced = 0,
    this.budgetsSynced = 0,
    this.goalsSynced = 0,
    this.billsSynced = 0,
  });
}
