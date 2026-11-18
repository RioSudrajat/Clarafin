part 'ai_chat_action_models.dart';

/// Surface presentation mode sent to the AI backend (`quick_sheet` vs `full_screen`).
enum AiSurfaceMode {
  quickSheet,
  fullScreen;

  /// Wire format expected by `POST /v1/ai/chat`.
  String get apiValue => switch (this) {
    AiSurfaceMode.quickSheet => 'quick_sheet',
    AiSurfaceMode.fullScreen => 'full_screen',
  };

  /// Parses backend or UI mode strings, defaulting safely to [quickSheet].
  static AiSurfaceMode fromApiValue(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase();
    if (normalized == 'full_screen' || normalized == 'fullscreen') {
      return AiSurfaceMode.fullScreen;
    }
    return AiSurfaceMode.quickSheet;
  }
}

/// Unified multimodal chat message shared across the Quick Action sheet and `/ai-chat`.
class UnifiedAiChatMessage {
  final String id;
  final String sessionId;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final AiThinkingTrace? thinkingTrace;
  final AiMoneyFlowData? moneyFlowCard;
  final AiSpendingTableData? spendingTableCard;
  final AiWalletCreationDraft? walletCreationDraft;
  final AiTransactionDraftGroup? transactionDraftGroup;
  final AiTransactionDraftGroup? pendingTransactionAfterWallet;
  final AiGoalDraft? goalDraft;
  final AiBudgetDraft? budgetDraft;
  final AiBillDraft? billDraft;
  final AiPackageRecommendation? recommendedPackage;
  final List<AiConsultantRecommendation> recommendedConsultants;
  final String? errorCode;
  final String? failedPrompt;

  UnifiedAiChatMessage({
    required this.id,
    required this.sessionId,
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.thinkingTrace,
    this.moneyFlowCard,
    this.spendingTableCard,
    this.walletCreationDraft,
    this.transactionDraftGroup,
    this.pendingTransactionAfterWallet,
    this.goalDraft,
    this.budgetDraft,
    this.billDraft,
    this.recommendedPackage,
    this.recommendedConsultants = const [],
    this.errorCode,
    this.failedPrompt,
  }) : timestamp = timestamp ?? DateTime.now();

  UnifiedAiChatMessage copyWith({
    String? id,
    String? sessionId,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    AiThinkingTrace? thinkingTrace,
    AiMoneyFlowData? moneyFlowCard,
    AiSpendingTableData? spendingTableCard,
    AiWalletCreationDraft? walletCreationDraft,
    AiTransactionDraftGroup? transactionDraftGroup,
    AiTransactionDraftGroup? pendingTransactionAfterWallet,
    AiGoalDraft? goalDraft,
    AiBudgetDraft? budgetDraft,
    AiBillDraft? billDraft,
    AiPackageRecommendation? recommendedPackage,
    List<AiConsultantRecommendation>? recommendedConsultants,
    String? errorCode,
    String? failedPrompt,
    bool clearError = false,
  }) {
    return UnifiedAiChatMessage(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      thinkingTrace: thinkingTrace ?? this.thinkingTrace,
      moneyFlowCard: moneyFlowCard ?? this.moneyFlowCard,
      spendingTableCard: spendingTableCard ?? this.spendingTableCard,
      walletCreationDraft: walletCreationDraft ?? this.walletCreationDraft,
      transactionDraftGroup:
          transactionDraftGroup ?? this.transactionDraftGroup,
      pendingTransactionAfterWallet:
          pendingTransactionAfterWallet ?? this.pendingTransactionAfterWallet,
      goalDraft: goalDraft ?? this.goalDraft,
      budgetDraft: budgetDraft ?? this.budgetDraft,
      billDraft: billDraft ?? this.billDraft,
      recommendedPackage: recommendedPackage ?? this.recommendedPackage,
      recommendedConsultants:
          recommendedConsultants ?? this.recommendedConsultants,
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      failedPrompt: clearError ? null : (failedPrompt ?? this.failedPrompt),
    );
  }

  /// Parses an SSE `final_response` payload or serialized chat message safely.
  factory UnifiedAiChatMessage.fromJson(Map<String, dynamic> json) {
    final root = _unwrapPayloadRoot(json);
    final cards = _asMap(root['action_cards']);
    dynamic pick(List<String> keys) => _pickFirst(root, cards, keys);

    final topMutationId = _firstNonEmpty([
      root['client_mutation_id'],
      root['clientMutationId'],
    ]);
    final rawPkg = _asMap(
      pick(['recommended_package', 'recommendedPackage']),
    );
    final prefill = _asMap(
      root['prefilled_intake_summary'] ??
          root['prefilledIntakeSummary'] ??
          rawPkg['prefilled_intake_summary'] ??
          rawPkg['prefilledIntakeSummary'],
    );
    final role = _asString(root['role']).toLowerCase();

    final rawWalletDraft = pick([
      'wallet_creation_draft_card',
      'wallet_creation_draft',
      'walletCreationDraft',
    ]);
    final walletCreationMap = _asMap(rawWalletDraft);
    final walletCreationDraft = _parseOpt(
      rawWalletDraft,
      AiWalletCreationDraft.fromJson,
    );

    final parsedTransactionDraft = _parseTransactionDraftGroup(
      pick([
        'transaction_draft_card',
        'transaction_draft',
        'transaction_draft_group',
        'transactionDraftGroup',
      ]),
      topMutationId,
    );
    var pendingTransactionDraft = _parseTransactionDraftGroup(
      pick([
        'pending_transaction_after_wallet',
        'pendingTransactionAfterWallet',
      ]),
      topMutationId,
    );
    final rawPendingItems =
        walletCreationMap['pending_items'] ?? walletCreationMap['pendingItems'];
    if (pendingTransactionDraft == null &&
        rawPendingItems is List &&
        rawPendingItems.isNotEmpty) {
      pendingTransactionDraft = AiTransactionDraftGroup.fromJson(
        {'items': rawPendingItems},
        fallbackMutationId: topMutationId,
      );
    }

    return UnifiedAiChatMessage(
      id: _firstNonEmpty([root['id'], root['message_id']]),
      sessionId: _firstNonEmpty([root['session_id'], root['sessionId']]),
      text: _firstNonEmpty([
        root['narrative'],
        root['text'],
        root['message'],
        root['content'],
      ]),
      isUser:
          _asBool(root['is_user'] ?? root['isUser']) || role == 'user',
      timestamp: _parseDateTime(root['timestamp'] ?? root['created_at']),
      thinkingTrace: _parseThinkingTrace(
        pick([
          'thinking_trace',
          'thinkingTrace',
          'thinking_summary',
          'thinkingSummary',
        ]),
        durationHint: root['duration_ms'] ?? root['thinking_duration_ms'],
      ),
      moneyFlowCard: _parseOpt(
        pick(['money_flow_card', 'moneyFlowCard', 'money_flow']),
        AiMoneyFlowData.fromJson,
      ),
      spendingTableCard: _parseOpt(
        pick([
          'spending_breakdown_table_card',
          'spending_breakdown_table',
          'spending_table_card',
          'spendingTableCard',
        ]),
        AiSpendingTableData.fromJson,
      ),
      walletCreationDraft: walletCreationDraft,
      transactionDraftGroup: parsedTransactionDraft,
      pendingTransactionAfterWallet: pendingTransactionDraft,
      goalDraft: _parseOpt(
        pick(['goal_draft_card', 'goal_draft', 'goalDraft']),
        (m) => AiGoalDraft.fromJson(m, fallbackMutationId: topMutationId),
      ),
      budgetDraft: _parseOpt(
        pick(['budget_draft_card', 'budget_draft', 'budgetDraft']),
        (m) => AiBudgetDraft.fromJson(m, fallbackMutationId: topMutationId),
      ),
      billDraft: _parseOpt(
        pick(['bill_draft_card', 'bill_draft', 'billDraft']),
        (m) => AiBillDraft.fromJson(m, fallbackMutationId: topMutationId),
      ),
      recommendedPackage: _parseOpt(
        pick(['recommended_package', 'recommendedPackage']),
        AiPackageRecommendation.fromJson,
      ),
      recommendedConsultants: _asMapList(
        pick([
          'recommended_consultants',
          'recommendedConsultants',
          'consultants',
        ]),
      )
          .map(
            (m) => AiConsultantRecommendation.fromJson(m, parentPrefill: prefill),
          )
          .toList(),
      errorCode: _asNullableString(root['error_code'] ?? root['errorCode']),
      failedPrompt: _asNullableString(
        root['failed_prompt'] ?? root['failedPrompt'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'session_id': sessionId,
    'text': text,
    'is_user': isUser,
    'timestamp': timestamp.toIso8601String(),
    if (thinkingTrace != null) 'thinking_trace': thinkingTrace!.toJson(),
    if (moneyFlowCard != null) 'money_flow_card': moneyFlowCard!.toJson(),
    if (spendingTableCard != null)
      'spending_breakdown_table': spendingTableCard!.toJson(),
    if (walletCreationDraft != null)
      'wallet_creation_draft': walletCreationDraft!.toJson(),
    if (transactionDraftGroup != null)
      'transaction_draft': transactionDraftGroup!.toJson(),
    if (pendingTransactionAfterWallet != null)
      'pending_transaction_after_wallet':
          pendingTransactionAfterWallet!.toJson(),
    if (goalDraft != null) 'goal_draft': goalDraft!.toJson(),
    if (budgetDraft != null) 'budget_draft': budgetDraft!.toJson(),
    if (billDraft != null) 'bill_draft': billDraft!.toJson(),
    if (recommendedPackage != null)
      'recommended_package': recommendedPackage!.toJson(),
    if (recommendedConsultants.isNotEmpty)
      'recommended_consultants':
          recommendedConsultants.map((c) => c.toJson()).toList(),
    if (errorCode != null) 'error_code': errorCode,
    if (failedPrompt != null) 'failed_prompt': failedPrompt,
  };

  /// Compacts action and analytical cards into <= 1000-rune factual history text.
  String toCompactedHistoryText() => _compactMessage(this);
}
