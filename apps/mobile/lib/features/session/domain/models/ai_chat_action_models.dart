part of 'ai_chat_models.dart';

/// Single step in the expandable AI process trace shown above an assistant reply.
class AiThinkingStep {
  final String id;
  final String label;
  final String? detail;
  final bool isDone;

  const AiThinkingStep({
    required this.id,
    required this.label,
    this.detail,
    this.isDone = false,
  });

  AiThinkingStep copyWith({
    String? id,
    String? label,
    String? detail,
    bool clearDetail = false,
    bool? isDone,
  }) {
    return AiThinkingStep(
      id: id ?? this.id,
      label: label ?? this.label,
      detail: clearDetail ? null : (detail ?? this.detail),
      isDone: isDone ?? this.isDone,
    );
  }

  factory AiThinkingStep.fromJson(Map<String, dynamic> json) {
    return AiThinkingStep(
      id: _firstNonEmpty([json['id'], json['step_id']]),
      label: _firstNonEmpty([json['label'], json['title'], json['message']]),
      detail: _asNullableString(json['detail'] ?? json['description']),
      isDone: _asBool(json['is_done'] ?? json['isDone'] ?? json['done']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    if (detail != null) 'detail': detail,
    'is_done': isDone,
  };
}

/// Expandable reasoning/tool execution trace attached to an AI chat message.
class AiThinkingTrace {
  final List<AiThinkingStep> steps;
  final int durationMs;
  final bool isLive;

  const AiThinkingTrace({
    this.steps = const [],
    this.durationMs = 0,
    this.isLive = false,
  });

  AiThinkingTrace copyWith({
    List<AiThinkingStep>? steps,
    int? durationMs,
    bool? isLive,
  }) {
    return AiThinkingTrace(
      steps: steps ?? this.steps,
      durationMs: durationMs ?? this.durationMs,
      isLive: isLive ?? this.isLive,
    );
  }

  factory AiThinkingTrace.fromJson(Map<String, dynamic> json) {
    final parsedSteps = _asMapList(
      json['steps'],
    ).map(AiThinkingStep.fromJson).toList();
    if (parsedSteps.isEmpty) {
      final summary = _firstNonEmpty([json['summary'], json['label']]);
      if (summary.isNotEmpty) {
        parsedSteps.add(
          AiThinkingStep(id: 'summary', label: summary, isDone: true),
        );
      }
    }
    return AiThinkingTrace(
      steps: parsedSteps,
      durationMs: _asInt(json['duration_ms'] ?? json['durationMs']),
      isLive: _asBool(json['is_live'] ?? json['isLive']),
    );
  }

  Map<String, dynamic> toJson() => {
    'steps': steps.map((s) => s.toJson()).toList(),
    'duration_ms': durationMs,
    'is_live': isLive,
  };
}

/// Node in the Money Flow Sankey chart representing an income source or expense category.
class AiMoneyFlowNode {
  final String label;
  final double amount;
  final String colorHex;
  final double percentage;

  const AiMoneyFlowNode({
    required this.label,
    required this.amount,
    this.colorHex = '#0F758A',
    this.percentage = 0.0,
  });

  factory AiMoneyFlowNode.fromJson(Map<String, dynamic> json) {
    return AiMoneyFlowNode(
      label: _firstNonEmpty([json['label'], json['category'], json['name']]),
      amount: _asDouble(
        json['amount'] ?? json['amount_idr'] ?? json['total_amount'],
      ),
      colorHex: _firstNonEmpty(
        [json['color_hex'], json['colorHex'], json['color']],
        fallback: '#0F758A',
      ),
      percentage: _asDouble(
        json['percentage'] ?? json['share_pct'] ?? json['sharePct'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'amount': amount,
    'color_hex': colorHex,
    'percentage': percentage,
  };
}

/// Directed ribbon between an income source index and an expense category index.
class AiMoneyFlowEdge {
  final int sourceIndex;
  final int targetIndex;
  final double amount;

  const AiMoneyFlowEdge({
    required this.sourceIndex,
    required this.targetIndex,
    required this.amount,
  });

  factory AiMoneyFlowEdge.fromJson(Map<String, dynamic> json) {
    return AiMoneyFlowEdge(
      sourceIndex: _asInt(json['source_index'] ?? json['sourceIndex']),
      targetIndex: _asInt(json['target_index'] ?? json['targetIndex']),
      amount: _asDouble(
        json['amount'] ?? json['flow_amount'] ?? json['flowAmount'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'source_index': sourceIndex,
    'target_index': targetIndex,
    'amount': amount,
  };
}

/// Analytical Money Flow Sankey card payload computed from SQL cashflow aggregations.
class AiMoneyFlowData {
  final String periodLabel;
  final double totalIncome;
  final double totalExpense;
  final double netCashflow;
  final int transactionCount;
  final List<AiMoneyFlowNode> incomeSources;
  final List<AiMoneyFlowNode> expenseCategories;
  final List<AiMoneyFlowEdge> flows;
  final String breakdownSummary;

  const AiMoneyFlowData({
    required this.periodLabel,
    required this.totalIncome,
    required this.totalExpense,
    required this.netCashflow,
    required this.transactionCount,
    this.incomeSources = const [],
    this.expenseCategories = const [],
    this.flows = const [],
    this.breakdownSummary = '',
  });

  factory AiMoneyFlowData.fromJson(Map<String, dynamic> json) {
    final totalIncome = _asDouble(
      json['total_income'] ?? json['total_income_idr'] ?? json['totalIncome'],
    );
    final totalExpense = _asDouble(
      json['total_expense'] ?? json['total_expense_idr'] ?? json['totalExpense'],
    );
    final rawNet =
        json['net_cashflow'] ?? json['net_cashflow_idr'] ?? json['netCashflow'];
    final netCashflow =
        rawNet != null ? _asDouble(rawNet) : (totalIncome - totalExpense);

    final sources = _asMapList(
      json['income_sources'] ?? json['incomeSources'],
    ).map(AiMoneyFlowNode.fromJson).toList();
    final targets = _asMapList(
      json['expense_categories'] ?? json['expenseCategories'],
    ).map(AiMoneyFlowNode.fromJson).toList();

    final rawEdges = _asMapList(
      json['flows'] ?? json['flow_edges'] ?? json['flowEdges'],
    );
    final edges = rawEdges.map((edgeMap) {
      if (edgeMap.containsKey('source_index') ||
          edgeMap.containsKey('sourceIndex')) {
        return AiMoneyFlowEdge.fromJson(edgeMap);
      }
      final srcLabel = _asString(edgeMap['source_category']);
      final dstLabel = _asString(edgeMap['target_category']);
      return AiMoneyFlowEdge(
        sourceIndex: _findNodeIndex(sources, srcLabel),
        targetIndex: _findNodeIndex(targets, dstLabel),
        amount: _asDouble(
          edgeMap['amount'] ?? edgeMap['flow_amount'] ?? edgeMap['flowAmount'],
        ),
      );
    }).toList();

    return AiMoneyFlowData(
      periodLabel: _firstNonEmpty([
        json['period_label'],
        json['periodLabel'],
        json['period'],
      ]),
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netCashflow: netCashflow,
      transactionCount: _asInt(
        json['transaction_count'] ?? json['transactionCount'],
      ),
      incomeSources: sources,
      expenseCategories: targets,
      flows: edges,
      breakdownSummary: _firstNonEmpty([
        json['breakdown_summary'],
        json['breakdownSummary'],
        json['summary'],
      ]),
    );
  }

  Map<String, dynamic> toJson() => {
    'period_label': periodLabel,
    'total_income': totalIncome,
    'total_expense': totalExpense,
    'net_cashflow': netCashflow,
    'transaction_count': transactionCount,
    'income_sources': incomeSources.map((n) => n.toJson()).toList(),
    'expense_categories': expenseCategories.map((n) => n.toJson()).toList(),
    'flows': flows.map((e) => e.toJson()).toList(),
    'breakdown_summary': breakdownSummary,
  };
}

/// Single merchant row inside [AiSpendingTableData].
class AiSpendingMerchantRow {
  final String merchant;
  final int transactionCount;
  final double totalAmount;

  const AiSpendingMerchantRow({
    required this.merchant,
    required this.transactionCount,
    required this.totalAmount,
  });

  factory AiSpendingMerchantRow.fromJson(Map<String, dynamic> json) {
    return AiSpendingMerchantRow(
      merchant: _firstNonEmpty([json['merchant'], json['name']]),
      transactionCount: _asInt(
        json['transaction_count'] ??
            json['tx_count'] ??
            json['transactionCount'],
      ),
      totalAmount: _asDouble(
        json['total_amount'] ??
            json['total_amount_idr'] ??
            json['totalAmount'] ??
            json['amount'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'merchant': merchant,
    'transaction_count': transactionCount,
    'total_amount': totalAmount,
  };
}

/// Analytical 3-column merchant spending breakdown table card payload.
class AiSpendingTableData {
  final String title;
  final List<AiSpendingMerchantRow> rows;
  final double totalAmount;
  final int totalTransactions;
  final String footnote;

  const AiSpendingTableData({
    required this.title,
    this.rows = const [],
    required this.totalAmount,
    required this.totalTransactions,
    this.footnote = '',
  });

  factory AiSpendingTableData.fromJson(Map<String, dynamic> json) {
    final rows = _asMapList(
      json['rows'] ??
          json['merchant_rows'] ??
          json['merchantRows'] ??
          json['items'],
    ).map(AiSpendingMerchantRow.fromJson).toList();

    final rawTotal =
        json['total_amount'] ??
        json['total_amount_idr'] ??
        json['totalAmount'] ??
        json['total_expense_idr'];
    final totalAmount = rawTotal != null
        ? _asDouble(rawTotal)
        : rows.fold<double>(0.0, (sum, r) => sum + r.totalAmount);

    final rawCount =
        json['total_transactions'] ??
        json['totalTransactions'] ??
        json['transaction_count'];
    final totalTransactions = rawCount != null
        ? _asInt(rawCount)
        : rows.fold<int>(0, (sum, r) => sum + r.transactionCount);

    return AiSpendingTableData(
      title: _firstNonEmpty([
        json['title'],
        json['heading'],
        json['period_label'],
      ]),
      rows: rows,
      totalAmount: totalAmount,
      totalTransactions: totalTransactions,
      footnote: _firstNonEmpty([json['footnote'], json['note']]),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'rows': rows.map((r) => r.toJson()).toList(),
    'total_amount': totalAmount,
    'total_transactions': totalTransactions,
    'footnote': footnote,
  };
}

/// Prerequisite card shown when a requested wallet does not yet exist for the user.
class AiWalletCreationDraft {
  final String institutionId;
  final String institutionName;
  final String walletType;
  final List<String> existingWalletIds;
  final double initialBalance;
  final bool isCreated;
  final String? createdWalletId;

  const AiWalletCreationDraft({
    required this.institutionId,
    required this.institutionName,
    required this.walletType,
    this.existingWalletIds = const [],
    this.initialBalance = 0.0,
    this.isCreated = false,
    this.createdWalletId,
  });

  AiWalletCreationDraft copyWith({
    String? institutionId,
    String? institutionName,
    String? walletType,
    List<String>? existingWalletIds,
    double? initialBalance,
    bool? isCreated,
    String? createdWalletId,
    bool clearCreatedWalletId = false,
  }) {
    return AiWalletCreationDraft(
      institutionId: institutionId ?? this.institutionId,
      institutionName: institutionName ?? this.institutionName,
      walletType: walletType ?? this.walletType,
      existingWalletIds: existingWalletIds ?? this.existingWalletIds,
      initialBalance: initialBalance ?? this.initialBalance,
      isCreated: isCreated ?? this.isCreated,
      createdWalletId:
          clearCreatedWalletId ? null : (createdWalletId ?? this.createdWalletId),
    );
  }

  factory AiWalletCreationDraft.fromJson(Map<String, dynamic> json) {
    var walletIds = _asStringList(
      json['existing_wallet_ids'] ?? json['existingWalletIds'],
    );
    if (walletIds.isEmpty && json['existing_wallets'] is List) {
      walletIds = (json['existing_wallets'] as List)
          .map((item) {
            if (item is Map) return _asString(item['id']);
            return _asString(item);
          })
          .where((id) => id.isNotEmpty)
          .toList();
    }

    return AiWalletCreationDraft(
      institutionId: _firstNonEmpty([
        json['institution_id'],
        json['institutionId'],
      ]),
      institutionName: _firstNonEmpty([
        json['institution_name'],
        json['institutionName'],
        json['name'],
      ]),
      walletType: _firstNonEmpty([
        json['wallet_type'],
        json['walletType'],
        json['institution_type'],
        json['type'],
      ], fallback: 'other'),
      existingWalletIds: walletIds,
      initialBalance: _asDouble(
        json['initial_balance'] ??
            json['initial_balance_idr'] ??
            json['initialBalance'],
      ),
      isCreated: _asBool(json['is_created'] ?? json['isCreated']),
      createdWalletId: _asNullableString(
        json['created_wallet_id'] ?? json['createdWalletId'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'institution_id': institutionId,
    'institution_name': institutionName,
    'wallet_type': walletType,
    'existing_wallet_ids': existingWalletIds,
    'initial_balance': initialBalance,
    'is_created': isCreated,
    if (createdWalletId != null) 'created_wallet_id': createdWalletId,
  };
}

/// Single proposed transaction inside [AiTransactionDraftGroup].
class AiTransactionDraftItem {
  final String title;
  final double amount;
  final String type;
  final String canonicalCategory;
  final String walletId;
  final String walletName;
  final String? targetWalletId;
  final DateTime occurredAt;

  const AiTransactionDraftItem({
    required this.title,
    required this.amount,
    required this.type,
    required this.canonicalCategory,
    required this.walletId,
    required this.walletName,
    this.targetWalletId,
    required this.occurredAt,
  });

  AiTransactionDraftItem copyWith({
    String? title,
    double? amount,
    String? type,
    String? canonicalCategory,
    String? walletId,
    String? walletName,
    String? targetWalletId,
    bool clearTargetWalletId = false,
    DateTime? occurredAt,
  }) {
    return AiTransactionDraftItem(
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      canonicalCategory: canonicalCategory ?? this.canonicalCategory,
      walletId: walletId ?? this.walletId,
      walletName: walletName ?? this.walletName,
      targetWalletId:
          clearTargetWalletId ? null : (targetWalletId ?? this.targetWalletId),
      occurredAt: occurredAt ?? this.occurredAt,
    );
  }

  factory AiTransactionDraftItem.fromJson(Map<String, dynamic> json) {
    final rawType = _firstNonEmpty([
      json['type'],
      json['tx_type'],
      json['txType'],
    ]);
    final rawCategory = _firstNonEmpty([
      json['canonical_category'],
      json['canonicalCategory'],
      json['category'],
      json['canonical_main_category'],
    ]);
    final resolvedType = _resolveTxType(rawType, rawCategory);

    return AiTransactionDraftItem(
      title: _firstNonEmpty([
        json['title'],
        json['merchant'],
        json['description'],
      ]),
      amount: _asDouble(
        json['amount'] ?? json['amount_idr'] ?? json['nominal'],
      ),
      type: resolvedType,
      canonicalCategory: rawCategory.isNotEmpty
          ? rawCategory
          : _defaultCategoryForType(resolvedType),
      walletId: _firstNonEmpty([json['wallet_id'], json['walletId']]),
      walletName: _firstNonEmpty([json['wallet_name'], json['walletName']]),
      targetWalletId: _asNullableString(
        json['target_wallet_id'] ?? json['targetWalletId'],
      ),
      occurredAt: _parseDateTime(
        json['occurred_at'] ??
            json['occurredAt'] ??
            json['date'] ??
            json['timestamp'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'amount': amount,
    'type': type,
    'canonical_category': canonicalCategory,
    'wallet_id': walletId,
    'wallet_name': walletName,
    if (targetWalletId != null) 'target_wallet_id': targetWalletId,
    'occurred_at': occurredAt.toIso8601String(),
  };
}

/// One-shot batch of 1..N transaction draft items sharing an idempotent mutation key.
class AiTransactionDraftGroup {
  final String clientMutationId;
  final List<AiTransactionDraftItem> items;
  final bool isSubmitting;
  final bool isConfirmed;
  final bool isCancelled;

  const AiTransactionDraftGroup({
    required this.clientMutationId,
    this.items = const [],
    this.isSubmitting = false,
    this.isConfirmed = false,
    this.isCancelled = false,
  });

  AiTransactionDraftGroup copyWith({
    String? clientMutationId,
    List<AiTransactionDraftItem>? items,
    bool? isSubmitting,
    bool? isConfirmed,
    bool? isCancelled,
  }) {
    return AiTransactionDraftGroup(
      clientMutationId: clientMutationId ?? this.clientMutationId,
      items: items ?? this.items,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      isCancelled: isCancelled ?? this.isCancelled,
    );
  }

  /// Parses either `{items: [...]}` or a single transaction draft map cleanly.
  factory AiTransactionDraftGroup.fromJson(
    Map<String, dynamic> json, {
    String fallbackMutationId = '',
  }) {
    final mutationId = _firstNonEmpty([
      json['client_mutation_id'],
      json['clientMutationId'],
    ], fallback: fallbackMutationId);

    final rawList = json['items'] ?? json['transactions'];
    final List<AiTransactionDraftItem> parsedItems;
    if (rawList is List) {
      parsedItems = _asMapList(
        rawList,
      ).map(AiTransactionDraftItem.fromJson).toList();
    } else if (_hasTransactionFields(json)) {
      parsedItems = [AiTransactionDraftItem.fromJson(json)];
    } else {
      parsedItems = const [];
    }

    return AiTransactionDraftGroup(
      clientMutationId: mutationId,
      items: parsedItems,
      isSubmitting: _asBool(json['is_submitting'] ?? json['isSubmitting']),
      isConfirmed: _asBool(json['is_confirmed'] ?? json['isConfirmed']),
      isCancelled: _asBool(json['is_cancelled'] ?? json['isCancelled']),
    );
  }

  Map<String, dynamic> toJson() => {
    'client_mutation_id': clientMutationId,
    'items': items.map((i) => i.toJson()).toList(),
    'is_submitting': isSubmitting,
    'is_confirmed': isConfirmed,
    'is_cancelled': isCancelled,
  };
}

/// Interactive savings goal draft proposed by AI for explicit user approval.
class AiGoalDraft {
  final String clientMutationId;
  final String name;
  final double targetAmount;
  final DateTime? deadline;
  final String? linkedWalletId;
  final double? monthlySavingEstimate;
  final bool isSubmitting;
  final bool isConfirmed;
  final bool isCancelled;

  const AiGoalDraft({
    required this.clientMutationId,
    required this.name,
    required this.targetAmount,
    this.deadline,
    this.linkedWalletId,
    this.monthlySavingEstimate,
    this.isSubmitting = false,
    this.isConfirmed = false,
    this.isCancelled = false,
  });

  AiGoalDraft copyWith({
    String? clientMutationId,
    String? name,
    double? targetAmount,
    DateTime? deadline,
    String? linkedWalletId,
    double? monthlySavingEstimate,
    bool? isSubmitting,
    bool? isConfirmed,
    bool? isCancelled,
  }) {
    return AiGoalDraft(
      clientMutationId: clientMutationId ?? this.clientMutationId,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      deadline: deadline ?? this.deadline,
      linkedWalletId: linkedWalletId ?? this.linkedWalletId,
      monthlySavingEstimate:
          monthlySavingEstimate ?? this.monthlySavingEstimate,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      isCancelled: isCancelled ?? this.isCancelled,
    );
  }

  factory AiGoalDraft.fromJson(
    Map<String, dynamic> json, {
    String fallbackMutationId = '',
  }) {
    return AiGoalDraft(
      clientMutationId: _firstNonEmpty([
        json['client_mutation_id'],
        json['clientMutationId'],
      ], fallback: fallbackMutationId),
      name: _firstNonEmpty([json['name'], json['title']]),
      targetAmount: _asDouble(
        json['target_amount'] ??
            json['target_amount_idr'] ??
            json['targetAmount'],
      ),
      deadline: _parseNullableDateTime(
        json['deadline'] ?? json['target_date'] ?? json['targetDate'],
      ),
      linkedWalletId: _asNullableString(
        json['linked_wallet_id'] ?? json['linkedWalletId'],
      ),
      monthlySavingEstimate: _asNullableDouble(
        json['monthly_saving_estimate'] ??
            json['monthly_saving_estimate_idr'] ??
            json['monthlySavingEstimate'],
      ),
      isSubmitting: _asBool(json['is_submitting'] ?? json['isSubmitting']),
      isConfirmed: _asBool(json['is_confirmed'] ?? json['isConfirmed']),
      isCancelled: _asBool(json['is_cancelled'] ?? json['isCancelled']),
    );
  }

  Map<String, dynamic> toJson() => {
    'client_mutation_id': clientMutationId,
    'name': name,
    'target_amount': targetAmount,
    if (deadline != null) 'deadline': deadline!.toIso8601String(),
    if (linkedWalletId != null) 'linked_wallet_id': linkedWalletId,
    if (monthlySavingEstimate != null)
      'monthly_saving_estimate': monthlySavingEstimate,
    'is_submitting': isSubmitting,
    'is_confirmed': isConfirmed,
    'is_cancelled': isCancelled,
  };
}

/// Interactive monthly category budget draft proposed by AI.
class AiBudgetDraft {
  final String clientMutationId;
  final String category;
  final double limitAmount;
  final double? avg30dSpend;
  final bool isUpdate;
  final bool isSubmitting;
  final bool isConfirmed;
  final bool isCancelled;

  const AiBudgetDraft({
    required this.clientMutationId,
    required this.category,
    required this.limitAmount,
    this.avg30dSpend,
    this.isUpdate = false,
    this.isSubmitting = false,
    this.isConfirmed = false,
    this.isCancelled = false,
  });

  AiBudgetDraft copyWith({
    String? clientMutationId,
    String? category,
    double? limitAmount,
    double? avg30dSpend,
    bool? isUpdate,
    bool? isSubmitting,
    bool? isConfirmed,
    bool? isCancelled,
  }) {
    return AiBudgetDraft(
      clientMutationId: clientMutationId ?? this.clientMutationId,
      category: category ?? this.category,
      limitAmount: limitAmount ?? this.limitAmount,
      avg30dSpend: avg30dSpend ?? this.avg30dSpend,
      isUpdate: isUpdate ?? this.isUpdate,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      isCancelled: isCancelled ?? this.isCancelled,
    );
  }

  factory AiBudgetDraft.fromJson(
    Map<String, dynamic> json, {
    String fallbackMutationId = '',
  }) {
    return AiBudgetDraft(
      clientMutationId: _firstNonEmpty([
        json['client_mutation_id'],
        json['clientMutationId'],
      ], fallback: fallbackMutationId),
      category: _asString(json['category']),
      limitAmount: _asDouble(
        json['limit_amount'] ??
            json['limit_amount_idr'] ??
            json['limitAmount'],
      ),
      avg30dSpend: _asNullableDouble(
        json['avg_30d_spend'] ??
            json['avg_30d_spend_idr'] ??
            json['avg30dSpend'],
      ),
      isUpdate: _asBool(json['is_update'] ?? json['isUpdate']),
      isSubmitting: _asBool(json['is_submitting'] ?? json['isSubmitting']),
      isConfirmed: _asBool(json['is_confirmed'] ?? json['isConfirmed']),
      isCancelled: _asBool(json['is_cancelled'] ?? json['isCancelled']),
    );
  }

  Map<String, dynamic> toJson() => {
    'client_mutation_id': clientMutationId,
    'category': category,
    'limit_amount': limitAmount,
    if (avg30dSpend != null) 'avg_30d_spend': avg30dSpend,
    'is_update': isUpdate,
    'is_submitting': isSubmitting,
    'is_confirmed': isConfirmed,
    'is_cancelled': isCancelled,
  };
}

/// Interactive recurring bill reminder draft proposed by AI.
class AiBillDraft {
  final String clientMutationId;
  final String title;
  final double amount;
  final int? dueDay;
  final DateTime? dueDate;
  final String frequency;
  final String category;
  final bool isSubmitting;
  final bool isConfirmed;
  final bool isCancelled;

  const AiBillDraft({
    required this.clientMutationId,
    required this.title,
    required this.amount,
    this.dueDay,
    this.dueDate,
    this.frequency = 'monthly',
    this.category = 'Bills & Utilities',
    this.isSubmitting = false,
    this.isConfirmed = false,
    this.isCancelled = false,
  });

  AiBillDraft copyWith({
    String? clientMutationId,
    String? title,
    double? amount,
    int? dueDay,
    DateTime? dueDate,
    String? frequency,
    String? category,
    bool? isSubmitting,
    bool? isConfirmed,
    bool? isCancelled,
  }) {
    return AiBillDraft(
      clientMutationId: clientMutationId ?? this.clientMutationId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDay: dueDay ?? this.dueDay,
      dueDate: dueDate ?? this.dueDate,
      frequency: frequency ?? this.frequency,
      category: category ?? this.category,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      isCancelled: isCancelled ?? this.isCancelled,
    );
  }

  factory AiBillDraft.fromJson(
    Map<String, dynamic> json, {
    String fallbackMutationId = '',
  }) {
    return AiBillDraft(
      clientMutationId: _firstNonEmpty([
        json['client_mutation_id'],
        json['clientMutationId'],
      ], fallback: fallbackMutationId),
      title: _firstNonEmpty([json['title'], json['name']]),
      amount: _asDouble(json['amount'] ?? json['amount_idr']),
      dueDay: _asNullableInt(json['due_day'] ?? json['dueDay']),
      dueDate: _parseNullableDateTime(
        json['due_date'] ??
            json['dueDate'] ??
            json['next_due_date'] ??
            json['nextDueDate'],
      ),
      frequency: _firstNonEmpty([json['frequency']], fallback: 'monthly'),
      category: _firstNonEmpty([
        json['category'],
        json['canonical_category'],
        json['canonical_main_category'],
      ], fallback: 'Bills & Utilities'),
      isSubmitting: _asBool(json['is_submitting'] ?? json['isSubmitting']),
      isConfirmed: _asBool(json['is_confirmed'] ?? json['isConfirmed']),
      isCancelled: _asBool(json['is_cancelled'] ?? json['isCancelled']),
    );
  }

  Map<String, dynamic> toJson() => {
    'client_mutation_id': clientMutationId,
    'title': title,
    'amount': amount,
    if (dueDay != null) 'due_day': dueDay,
    if (dueDate != null) 'due_date': dueDate!.toIso8601String(),
    'frequency': frequency,
    'category': category,
    'is_submitting': isSubmitting,
    'is_confirmed': isConfirmed,
    'is_cancelled': isCancelled,
  };
}

/// Catalog service package banner embedded in consultant recommendations.
class AiPackageRecommendation {
  final String packageCode;
  final String categoryTag;
  final String packageTitle;
  final double priceIdr;
  final int durationMinutes;
  final int sessionCount;

  const AiPackageRecommendation({
    required this.packageCode,
    required this.categoryTag,
    required this.packageTitle,
    required this.priceIdr,
    this.durationMinutes = 60,
    this.sessionCount = 1,
  });

  factory AiPackageRecommendation.fromJson(Map<String, dynamic> json) {
    final method = _asString(
      json['recommended_method'] ?? json['recommendedMethod'],
    ).toLowerCase();
    final isOffline = method == 'offline' || method == 'tatap muka';

    final price = _asDouble(
      json['price_idr'] ??
          json['priceIdr'] ??
          json['price'] ??
          (isOffline ? json['offline_price_idr'] : json['online_price_idr']) ??
          json['online_price_idr'] ??
          json['offline_price_idr'],
    );
    final rawDuration =
        json['duration_minutes'] ??
        json['durationMinutes'] ??
        (isOffline
            ? json['offline_duration_minutes']
            : json['online_duration_minutes']) ??
        json['online_duration_minutes'] ??
        json['offline_duration_minutes'];
    final rawSessions = json['session_count'] ?? json['sessionCount'];

    return AiPackageRecommendation(
      packageCode: _firstNonEmpty([
        json['package_code'],
        json['packageCode'],
        json['code'],
      ]),
      categoryTag: _firstNonEmpty([
        json['category_tag'],
        json['categoryTag'],
        json['selected_tier_label'],
        json['service_category'],
      ]),
      packageTitle: _firstNonEmpty([
        json['package_title'],
        json['packageTitle'],
        json['title'],
      ]),
      priceIdr: price,
      durationMinutes: rawDuration != null ? _asInt(rawDuration) : 60,
      sessionCount: rawSessions != null ? _asInt(rawSessions) : 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'package_code': packageCode,
    'category_tag': categoryTag,
    'package_title': packageTitle,
    'price_idr': priceIdr,
    'duration_minutes': durationMinutes,
    'session_count': sessionCount,
  };
}

/// Practitioner card payload with live next slot and booking prefill context.
class AiConsultantRecommendation {
  final String consultantId;
  final String name;
  final List<String> certifications;
  final String avatarUrl;
  final String tierLabel;
  final double ratingAvg;
  final int totalSessionsCompleted;
  final String matchReason;
  final DateTime? nextAvailableSlotAt;
  final String nextAvailableSlotLabel;
  final bool isStaffPinned;
  final String selectedPackageCode;
  final double unitPrice;
  final List<String> recommendedTopics;
  final String prefilledDescription;
  final String prefilledExpectations;

  const AiConsultantRecommendation({
    required this.consultantId,
    required this.name,
    this.certifications = const [],
    this.avatarUrl = '',
    this.tierLabel = '',
    this.ratingAvg = 0.0,
    this.totalSessionsCompleted = 0,
    this.matchReason = '',
    this.nextAvailableSlotAt,
    this.nextAvailableSlotLabel = '',
    this.isStaffPinned = false,
    this.selectedPackageCode = '',
    this.unitPrice = 0.0,
    this.recommendedTopics = const [],
    this.prefilledDescription = '',
    this.prefilledExpectations = '',
  });

  factory AiConsultantRecommendation.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? parentPrefill,
  }) {
    final rawCerts = json['certifications'] ?? json['credentials'];
    final certifications = rawCerts is String
        ? rawCerts
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList()
        : _asStringList(rawCerts);

    final topics = _asStringList(
      json['recommended_topics'] ??
          json['recommendedTopics'] ??
          parentPrefill?['recommended_topics'] ??
          parentPrefill?['recommendedTopics'],
    );

    return AiConsultantRecommendation(
      consultantId: _firstNonEmpty([
        json['consultant_id'],
        json['consultantId'],
        json['id'],
      ]),
      name: _firstNonEmpty([
        json['name'],
        json['display_name'],
        json['displayName'],
      ]),
      certifications: certifications,
      avatarUrl: _firstNonEmpty([json['avatar_url'], json['avatarUrl']]),
      tierLabel: _firstNonEmpty([
        json['tier_label'],
        json['tierLabel'],
        json['tier'],
      ]),
      ratingAvg: _asDouble(
        json['rating_avg'] ?? json['ratingAvg'] ?? json['rating'],
      ),
      totalSessionsCompleted: _asInt(
        json['total_sessions_completed'] ??
            json['totalSessionsCompleted'] ??
            json['total_sessions'],
      ),
      matchReason: _firstNonEmpty([
        json['match_reason'],
        json['matchReason'],
      ]),
      nextAvailableSlotAt: _parseNullableDateTime(
        json['next_available_slot_at'] ??
            json['nextAvailableSlotAt'] ??
            json['next_available_slot_iso'] ??
            json['nextAvailableSlotIso'],
      ),
      nextAvailableSlotLabel: _firstNonEmpty([
        json['next_available_slot_label'],
        json['nextAvailableSlotLabel'],
      ]),
      isStaffPinned: _asBool(
        json['is_staff_pinned'] ?? json['isStaffPinned'],
      ),
      selectedPackageCode: _firstNonEmpty([
        json['selected_package_code'],
        json['selectedPackageCode'],
        json['package_code'],
        json['packageCode'],
      ]),
      unitPrice: _asDouble(
        json['unit_price'] ??
            json['unitPrice'] ??
            json['online_price_idr'] ??
            json['price_idr'],
      ),
      recommendedTopics: topics,
      prefilledDescription: _firstNonEmpty([
        json['prefilled_description'],
        json['prefilledDescription'],
        parentPrefill?['prefilled_description'],
        parentPrefill?['prefilledDescription'],
      ]),
      prefilledExpectations: _firstNonEmpty([
        json['prefilled_expectations'],
        json['prefilledExpectations'],
        parentPrefill?['prefilled_expectations'],
        parentPrefill?['prefilledExpectations'],
      ]),
    );
  }

  Map<String, dynamic> toJson() => {
    'consultant_id': consultantId,
    'name': name,
    'certifications': certifications,
    'avatar_url': avatarUrl,
    'tier_label': tierLabel,
    'rating_avg': ratingAvg,
    'total_sessions_completed': totalSessionsCompleted,
    'match_reason': matchReason,
    if (nextAvailableSlotAt != null)
      'next_available_slot_at': nextAvailableSlotAt!.toIso8601String(),
    'next_available_slot_label': nextAvailableSlotLabel,
    'is_staff_pinned': isStaffPinned,
    'selected_package_code': selectedPackageCode,
    'unit_price': unitPrice,
    'recommended_topics': recommendedTopics,
    'prefilled_description': prefilledDescription,
    'prefilled_expectations': prefilledExpectations,
  };
}

Map<String, dynamic> _unwrapPayloadRoot(Map<String, dynamic> json) {
  if (json.containsKey('narrative') ||
      json.containsKey('text') ||
      json.containsKey('transaction_draft') ||
      json.containsKey('transaction_draft_card') ||
      json.containsKey('money_flow_card')) {
    return json;
  }
  for (final key in const ['data', 'response', 'payload']) {
    final nested = json[key];
    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }
  }
  return json;
}

dynamic _pickFirst(
  Map<String, dynamic> primary,
  Map<String, dynamic> secondary,
  List<String> keys,
) {
  for (final k in keys) {
    if (primary[k] != null) return primary[k];
  }
  for (final k in keys) {
    if (secondary[k] != null) return secondary[k];
  }
  return null;
}

T? _parseOpt<T>(dynamic raw, T Function(Map<String, dynamic>) builder) {
  if (raw is Map) {
    return builder(Map<String, dynamic>.from(raw));
  }
  return null;
}

AiThinkingTrace? _parseThinkingTrace(dynamic raw, {dynamic durationHint}) {
  if (raw == null) return null;
  if (raw is Map) {
    return AiThinkingTrace.fromJson(Map<String, dynamic>.from(raw));
  }
  if (raw is String && raw.trim().isNotEmpty) {
    return AiThinkingTrace(
      steps: [AiThinkingStep(id: 'summary', label: raw.trim(), isDone: true)],
      durationMs: _asInt(durationHint),
    );
  }
  if (raw is List) {
    final steps = <AiThinkingStep>[];
    for (var i = 0; i < raw.length; i++) {
      final entry = raw[i];
      if (entry is Map) {
        steps.add(AiThinkingStep.fromJson(Map<String, dynamic>.from(entry)));
      } else {
        final label = _asString(entry);
        if (label.isNotEmpty) {
          steps.add(AiThinkingStep(id: 'step-$i', label: label, isDone: true));
        }
      }
    }
    if (steps.isEmpty) return null;
    return AiThinkingTrace(steps: steps, durationMs: _asInt(durationHint));
  }
  return null;
}

AiTransactionDraftGroup? _parseTransactionDraftGroup(
  dynamic raw,
  String fallbackMutationId,
) {
  if (raw == null) return null;
  if (raw is Map) {
    return AiTransactionDraftGroup.fromJson(
      Map<String, dynamic>.from(raw),
      fallbackMutationId: fallbackMutationId,
    );
  }
  if (raw is List) {
    final items = _asMapList(raw).map(AiTransactionDraftItem.fromJson).toList();
    if (items.isEmpty) return null;
    return AiTransactionDraftGroup(
      clientMutationId: fallbackMutationId,
      items: items,
    );
  }
  return null;
}

bool _hasTransactionFields(Map<String, dynamic> json) {
  return json.containsKey('title') ||
      json.containsKey('amount') ||
      json.containsKey('amount_idr') ||
      json.containsKey('merchant');
}

int _findNodeIndex(List<AiMoneyFlowNode> nodes, String label) {
  final target = label.trim().toLowerCase();
  if (target.isEmpty) return 0;
  final exact = nodes.indexWhere((n) => n.label.trim().toLowerCase() == target);
  return exact >= 0 ? exact : 0;
}

String _resolveTxType(String rawType, String rawCategory) {
  switch (rawType.trim().toLowerCase()) {
    case 'income':
    case 'pemasukan':
    case 'masuk':
      return 'income';
    case 'transfer':
    case 'pemindahan':
    case 'topup':
      return 'transfer';
    case 'expense':
    case 'pengeluaran':
    case 'keluar':
      return 'expense';
    default:
      final lowerCat = rawCategory.trim().toLowerCase();
      if (lowerCat == 'transfer') return 'transfer';
      if (lowerCat.startsWith('income')) return 'income';
      return 'expense';
  }
}

String _defaultCategoryForType(String type) => switch (type) {
  'transfer' => 'Transfer',
  'income' => 'Income • Additional Income',
  _ => 'Others • General Uncategorized',
};

String _compactMessage(UnifiedAiChatMessage msg) {
  if (msg.isUser) return _capRunes(msg.text.trim(), 1000);

  final completed = _completedActionMarkers(msg);
  if (completed.isNotEmpty) {
    return _capRunes(completed.join(' '), 1000);
  }

  final base = msg.text.trim().replaceAll(RegExp(r'\s+'), ' ');
  final pendingDrafts = _pendingDraftMarkers(msg);
  if (base.isNotEmpty) {
    if (pendingDrafts.isNotEmpty) {
      return _capRunes('$base ${pendingDrafts.join(' ')}', 1000);
    }
    return _capRunes(base, 1000);
  }
  final analytical = _analyticalMarkers(msg);
  return _capRunes([...pendingDrafts, ...analytical].join(' '), 1000);
}

List<String> _completedActionMarkers(UnifiedAiChatMessage msg) {
  final markers = <String>[];
  final txGroup = msg.transactionDraftGroup;
  if (txGroup != null && (txGroup.isConfirmed || txGroup.isCancelled)) {
    markers.add(_compactTxGroup(txGroup));
  }
  final wallet = msg.walletCreationDraft;
  if (wallet != null && wallet.isCreated) {
    markers.add('[User membuat dompet: ${wallet.institutionName}]');
  }
  final goal = msg.goalDraft;
  if (goal != null && (goal.isConfirmed || goal.isCancelled)) {
    markers.add(
      goal.isConfirmed
          ? '[User menyetujui Goal: ${goal.name} ${_formatIdr(goal.targetAmount)}]'
          : '[User membatalkan Goal: ${goal.name}]',
    );
  }
  final budget = msg.budgetDraft;
  if (budget != null && (budget.isConfirmed || budget.isCancelled)) {
    markers.add(
      budget.isConfirmed
          ? '[User menyetujui Budget: ${budget.category} ${_formatIdr(budget.limitAmount)}]'
          : '[User membatalkan Budget: ${budget.category}]',
    );
  }
  final bill = msg.billDraft;
  if (bill != null && (bill.isConfirmed || bill.isCancelled)) {
    markers.add(
      bill.isConfirmed
          ? '[User menyetujui Tagihan: ${bill.title} ${_formatIdr(bill.amount)}]'
          : '[User membatalkan Tagihan: ${bill.title}]',
    );
  }
  return markers;
}

List<String> _pendingDraftMarkers(UnifiedAiChatMessage msg) {
  final markers = <String>[];
  if (msg.transactionDraftGroup != null) {
    markers.add(_compactTxGroup(msg.transactionDraftGroup!));
  }
  if (msg.walletCreationDraft != null) {
    markers.add(
      '[Menawarkan pembuatan dompet: ${msg.walletCreationDraft!.institutionName}]',
    );
  }
  if (msg.goalDraft != null) {
    markers.add(
      '[Draf Goal: ${msg.goalDraft!.name} ${_formatIdr(msg.goalDraft!.targetAmount)}]',
    );
  }
  if (msg.budgetDraft != null) {
    markers.add(
      '[Draf Budget: ${msg.budgetDraft!.category} ${_formatIdr(msg.budgetDraft!.limitAmount)}]',
    );
  }
  if (msg.billDraft != null) {
    markers.add(
      '[Draf Tagihan: ${msg.billDraft!.title} ${_formatIdr(msg.billDraft!.amount)}]',
    );
  }
  return markers;
}

List<String> _analyticalMarkers(UnifiedAiChatMessage msg) {
  final markers = <String>[];
  if (msg.moneyFlowCard != null) {
    final mf = msg.moneyFlowCard!;
    markers.add(
      '[Money Flow ${mf.periodLabel}: Pemasukan ${_formatIdr(mf.totalIncome)}, Pengeluaran ${_formatIdr(mf.totalExpense)}]',
    );
  }
  if (msg.spendingTableCard != null) {
    final st = msg.spendingTableCard!;
    markers.add(
      '[Rincian Pengeluaran: ${st.totalTransactions} transaksi, total ${_formatIdr(st.totalAmount)}]',
    );
  }
  if (msg.recommendedConsultants.isNotEmpty) {
    final names = msg.recommendedConsultants.map((c) => c.name).join(', ');
    markers.add('[Rekomendasi Konsultan: $names]');
  }
  return markers;
}

String _compactTxGroup(AiTransactionDraftGroup group) {
  final summaries = group.items
      .map((item) {
        final via = item.walletName.isNotEmpty ? ' via ${item.walletName}' : '';
        return '${item.title} ${_formatIdr(item.amount)}$via';
      })
      .join(', ');

  if (group.isConfirmed) {
    if (group.items.isEmpty) return '[User mengonfirmasi draf transaksi]';
    if (group.items.length == 1) {
      return '[User mengonfirmasi draf: $summaries]';
    }
    return '[User mengonfirmasi ${group.items.length} draf transaksi: $summaries]';
  }
  if (group.isCancelled) {
    return summaries.isEmpty
        ? '[User membatalkan draf transaksi]'
        : '[User membatalkan draf transaksi: $summaries]';
  }
  return summaries.isEmpty
      ? '[Draf transaksi menunggu konfirmasi]'
      : '[Draf transaksi menunggu konfirmasi: $summaries]';
}

String _formatIdr(double amount) {
  final rounded = amount.round();
  final sign = rounded < 0 ? '-' : '';
  final digits = rounded.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
    buf.write(digits[i]);
  }
  return '${sign}Rp $buf';
}

String _capRunes(String text, int maxRunes) {
  final runes = text.runes;
  if (runes.length <= maxRunes) return text;
  return String.fromCharCodes(runes.take(maxRunes));
}

String _asString(dynamic value) => value == null ? '' : value.toString().trim();

String? _asNullableString(dynamic value) {
  final s = _asString(value);
  return s.isEmpty ? null : s;
}

String _firstNonEmpty(List<dynamic> candidates, {String fallback = ''}) {
  for (final c in candidates) {
    final s = _asString(c);
    if (s.isNotEmpty) return s;
  }
  return fallback;
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? 0.0;
  return 0.0;
}

double? _asNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) {
    return int.tryParse(value.trim()) ??
        double.tryParse(value.trim())?.round() ??
        0;
  }
  return 0;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final lower = value.trim().toLowerCase();
    return lower == 'true' || lower == '1' || lower == 'yes';
  }
  return false;
}

List<String> _asStringList(dynamic value) {
  if (value is! List) return const [];
  return value.map(_asString).where((s) => s.isNotEmpty).toList();
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((m) => Map<String, dynamic>.from(m))
      .toList();
}

DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value.trim()) ?? DateTime.now();
  }
  return DateTime.now();
}

DateTime? _parseNullableDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value.trim());
  }
  return null;
}
