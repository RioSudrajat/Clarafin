import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/models/transaction_model.dart';
import '../../../../core/models/wallet_model.dart';
import '../../../../core/network/clarafin_api_client.dart';
import '../../../../core/network/tracker_remote_sync_service.dart';
import '../../../../core/providers/ai_quota_provider.dart';
import '../../../../core/providers/mock_providers.dart';
import '../../../budget/presentation/providers/finance_providers.dart';
import '../../../consult/presentation/providers/booking_provider.dart';
import '../../../match_expert/presentation/providers/match_expert_provider.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import '../../data/ai_chat_repository.dart';
import '../../domain/models/ai_chat_models.dart';
import 'unified_ai_chat_mutation_helpers.dart';

/// Shared state for both the Quick Action Sheet (`quick_sheet`) and `/ai-chat` (`full_screen`).
class UnifiedAiChatState {
  final String sessionId;
  final List<UnifiedAiChatMessage> messages;
  final bool isStreaming;
  final bool isMutating;
  final AiThinkingTrace? activeThinkingTrace;
  final bool hasRichCardsOrMultiReplies;
  final String? errorMessage;

  UnifiedAiChatState({
    required this.sessionId,
    this.messages = const [],
    this.isStreaming = false,
    this.isMutating = false,
    this.activeThinkingTrace,
    bool? hasRichCardsOrMultiReplies,
    this.errorMessage,
  }) : hasRichCardsOrMultiReplies =
           hasRichCardsOrMultiReplies ??
           _computeHasRichCardsOrMultiReplies(messages);

  UnifiedAiChatState copyWith({
    String? sessionId,
    List<UnifiedAiChatMessage>? messages,
    bool? isStreaming,
    bool? isMutating,
    AiThinkingTrace? activeThinkingTrace,
    bool clearActiveThinkingTrace = false,
    bool? hasRichCardsOrMultiReplies,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    final nextMessages = messages ?? this.messages;
    return UnifiedAiChatState(
      sessionId: sessionId ?? this.sessionId,
      messages: nextMessages,
      isStreaming: isStreaming ?? this.isStreaming,
      isMutating: isMutating ?? this.isMutating,
      activeThinkingTrace: clearActiveThinkingTrace
          ? null
          : (activeThinkingTrace ?? this.activeThinkingTrace),
      hasRichCardsOrMultiReplies:
          hasRichCardsOrMultiReplies ??
          _computeHasRichCardsOrMultiReplies(nextMessages),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  static bool _computeHasRichCardsOrMultiReplies(
    List<UnifiedAiChatMessage> messages,
  ) {
    var assistantCount = 0;
    for (final msg in messages) {
      if (!msg.isUser && msg.errorCode == null) {
        assistantCount++;
        if (assistantCount >= 2) return true;
      }
      if (_hasRichCard(msg)) return true;
    }
    return false;
  }

  static bool _hasRichCard(UnifiedAiChatMessage msg) {
    return msg.moneyFlowCard != null ||
        msg.spendingTableCard != null ||
        msg.walletCreationDraft != null ||
        msg.transactionDraftGroup != null ||
        msg.goalDraft != null ||
        msg.budgetDraft != null ||
        msg.billDraft != null ||
        msg.recommendedPackage != null ||
        msg.recommendedConsultants.isNotEmpty;
  }
}

/// Manages AI SSE streaming, session isolation, prerequisite wallet unlocking,
/// quota synchronization, and idempotent draft confirmations at 0 extra quota cost.
class UnifiedAiChatNotifier extends Notifier<UnifiedAiChatState> {
  static const int maxHistoryTurns = 10;
  static const int maxHistoryRunes = 1000;
  static const Uuid _uuid = Uuid();

  bool _isDisposed = false;
  CancelToken? _activeCancelToken;
  StreamSubscription<AiSseEvent>? _activeSubscription;
  Completer<void>? _activeStreamCompleter;
  String? _activeClientRequestId;
  final Set<String> _confirmingMessageIds = <String>{};
  final Map<String, List<AiTransactionDraftItem>> _pendingWalletTxItems =
      <String, List<AiTransactionDraftItem>>{};

  bool get _canMutateState => !_isDisposed && ref.mounted;

  @override
  UnifiedAiChatState build() {
    _isDisposed = false;
    ref.onDispose(_disposeResources);
    return UnifiedAiChatState(sessionId: _uuid.v4());
  }

  /// Cancels any active SSE stream, rotates `sessionId`, and clears state in 0 AI actions.
  void startNewChat() {
    _cancelActiveStream();
    _confirmingMessageIds.clear();
    _pendingWalletTxItems.clear();
    if (!_canMutateState) return;
    state = UnifiedAiChatState(
      sessionId: _uuid.v4(),
      messages: const [],
      isStreaming: false,
      isMutating: false,
      activeThinkingTrace: null,
      errorMessage: null,
    );
  }

  /// Clears any transient error banner without resetting the active chat thread.
  void clearError() {
    if (!_canMutateState) return;
    state = state.copyWith(clearErrorMessage: true);
  }

  /// Synchronizes live AI quota badge state from `GET /v1/ai/quota` when remote API is configured.
  Future<void> refreshQuota({CancelToken? cancelToken}) async {
    if (!_canMutateState) return;
    if (!ref.read(clarafinApiConfigProvider).isConfigured) return;

    final syncService = ref.read(trackerRemoteSyncServiceProvider);
    try {
      final remoteQuota = await syncService.fetchQuota(cancelToken: cancelToken);
      if (!_canMutateState) return;

      final profileNotifier = ref.read(userProfileProvider.notifier);
      final currentPlan = ref.read(userProfileProvider).subscriptionPlan;
      UnifiedAiChatMutationHelpers.applyQuotaUpdate(
        profileNotifier: profileNotifier,
        currentPlan: currentPlan,
        planType: remoteQuota.planType,
        quotaRemaining: remoteQuota.quotaRemaining,
        isPrefiltered: true,
        isQuotaExceeded: remoteQuota.quotaRemaining == 0,
        onUseLocalQuota: (_) {},
      );
    } catch (err) {
      if (err is DioException && CancelToken.isCancel(err)) return;
      if (!_canMutateState) return;
      state = state.copyWith(
        errorMessage: UnifiedAiChatMutationHelpers.formatSyncError(err),
      );
    }
  }

  /// Sends [text] to [AiChatRepository.streamChat] with fresh `client_request_id`
  /// and strict isolation against late events from cancelled or superseded streams.
  Future<void> sendMessage(
    String text, {
    AiSurfaceMode surfaceMode = AiSurfaceMode.quickSheet,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || !_canMutateState) return;

    _cancelActiveStream();

    final requestSessionId = state.sessionId;
    final clientRequestId = _uuid.v4();
    final historySnapshot = state.messages
        .where((m) => m.errorCode == null)
        .toList(growable: false);
    final cancelToken = CancelToken();
    final completer = Completer<void>();
    final startedAt = DateTime.now();

    _activeCancelToken = cancelToken;
    _activeStreamCompleter = completer;
    _activeClientRequestId = clientRequestId;

    final userMessage = UnifiedAiChatMessage(
      id: _uuid.v4(),
      sessionId: requestSessionId,
      text: trimmed,
      isUser: true,
      timestamp: startedAt,
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isStreaming: true,
      activeThinkingTrace: const AiThinkingTrace(steps: [], isLive: true),
      clearErrorMessage: true,
    );

    var receivedTerminalEvent = false;
    final Stream<AiSseEvent> stream;
    try {
      stream = ref.read(aiChatRepositoryProvider).streamChat(
            prompt: trimmed,
            surfaceMode: surfaceMode,
            sessionId: requestSessionId,
            clientRequestId: clientRequestId,
            sessionHistory: historySnapshot,
            cancelToken: cancelToken,
          );
    } catch (err) {
      _clearActiveStreamRefs(clientRequestId);
      if (_canMutateState && state.sessionId == requestSessionId) {
        _onErrorEvent(
          AiErrorEvent(
            errorCode: 'STREAM_ERROR',
            message: UnifiedAiChatMutationHelpers.formatSyncError(err),
          ),
          requestSessionId,
          trimmed,
        );
      }
      if (!completer.isCompleted) completer.complete();
      return;
    }

    _activeSubscription = stream.listen(
      (event) {
        if (_isStaleStream(requestSessionId, clientRequestId, cancelToken)) {
          return;
        }
        switch (event) {
          case AiThinkingStepEvent():
            _onThinkingStep(event, requestSessionId);
          case AiFinalResponseEvent():
            receivedTerminalEvent = true;
            _onFinalResponse(event, requestSessionId, trimmed, startedAt);
          case AiErrorEvent():
            receivedTerminalEvent = true;
            _onErrorEvent(event, requestSessionId, trimmed);
        }
      },
      onError: (Object error) {
        final stale = _isStaleStream(
          requestSessionId,
          clientRequestId,
          cancelToken,
        );
        _clearActiveStreamRefs(clientRequestId);
        if (!stale) {
          _onErrorEvent(
            AiErrorEvent(
              errorCode: 'STREAM_ERROR',
              message:
                  'Terjadi kendala saat memproses respons AI: ${UnifiedAiChatMutationHelpers.formatSyncError(error)}',
            ),
            requestSessionId,
            trimmed,
          );
        }
        if (!completer.isCompleted) completer.complete();
      },
      onDone: () {
        final stale = _isStaleStream(
          requestSessionId,
          clientRequestId,
          cancelToken,
        );
        _clearActiveStreamRefs(clientRequestId);
        if (!stale) {
          if (!receivedTerminalEvent) {
            _onErrorEvent(
              const AiErrorEvent(
                errorCode: 'STREAM_INTERRUPTED',
                message:
                    'Koneksi respons AI terputus sebelum selesai. Silakan coba lagi.',
              ),
              requestSessionId,
              trimmed,
            );
          } else if (state.isStreaming) {
            state = state.copyWith(
              isStreaming: false,
              clearActiveThinkingTrace: true,
            );
          }
        }
        if (!completer.isCompleted) completer.complete();
      },
      cancelOnError: false,
    );

    await completer.future;
  }

  /// Retries an errored assistant bubble's `failedPrompt` using a fresh `client_request_id`.
  Future<void> retryFailedMessage(
    String messageId, {
    AiSurfaceMode surfaceMode = AiSurfaceMode.quickSheet,
  }) async {
    if (!_canMutateState) return;
    final target = state.messages
        .where((m) => m.id == messageId)
        .firstOrNull;
    final failedPrompt = target?.failedPrompt?.trim() ?? '';
    if (failedPrompt.isEmpty) return;
    await sendMessage(failedPrompt, surfaceMode: surfaceMode);
  }

  /// Creates the missing prerequisite wallet at 0 AI quota cost and unlocks
  /// the pending `TransactionDraftGroup` on the same message.
  Future<void> confirmWalletCreation(
    String messageId, {
    double initialBalance = 0,
  }) async {
    if (!_canMutateState) return;
    if (initialBalance.isNaN || initialBalance.isInfinite || initialBalance < 0) {
      state = state.copyWith(
        errorMessage: 'Saldo awal dompet tidak boleh kurang dari Rp 0.',
      );
      return;
    }

    final lockKey = 'wallet:$messageId';
    if (_confirmingMessageIds.contains(lockKey)) return;

    final index = state.messages.indexWhere((m) => m.id == messageId);
    if (index < 0) return;

    final targetMsg = state.messages[index];
    final draft = targetMsg.walletCreationDraft;
    if (draft == null || draft.isCreated) return;

    final requestSessionId = state.sessionId;
    final isRemote = ref.read(clarafinApiConfigProvider).isConfigured;
    final syncService = isRemote
        ? ref.read(trackerRemoteSyncServiceProvider)
        : null;

    _confirmingMessageIds.add(lockKey);
    state = state.copyWith(isMutating: true, clearErrorMessage: true);

    try {
      final newWalletId = 'w_${_uuid.v4()}';
      final walletName = draft.institutionName.trim().isNotEmpty
          ? draft.institutionName.trim()
          : 'Dompet Baru';
      final displayType =
          UnifiedAiChatMutationHelpers.resolveDisplayWalletType(draft);

      final newWallet = WalletModel(
        id: newWalletId,
        name: walletName,
        type: displayType,
        balance: initialBalance,
        institutionId:
            draft.institutionId.trim().isEmpty ? null : draft.institutionId,
      );

      if (syncService != null) {
        await syncService.createWallet(
          name: newWallet.name,
          type: newWallet.type,
          institutionCode: newWallet.institutionId,
          balance: newWallet.balance,
          localWalletId: newWallet.id,
        );
      }

      if (!_canMutateState) return;

      ref.read(walletsProvider.notifier).addWallet(newWallet);

      if (state.sessionId == requestSessionId) {
        final currentIndex = state.messages.indexWhere((m) => m.id == messageId);
        if (currentIndex >= 0) {
          final currentMsg = state.messages[currentIndex];
          final existingTxGroup = currentMsg.transactionDraftGroup;
          final canUnlockTxGroup =
              existingTxGroup == null ||
              (!existingTxGroup.isConfirmed &&
                  !existingTxGroup.isSubmitting &&
                  !existingTxGroup.isCancelled);

          AiTransactionDraftGroup? unlockedGroup = existingTxGroup;
          if (canUnlockTxGroup) {
            final pendingItems = _resolvePendingTxItemsForMessage(
              currentIndex,
              currentMsg,
              fallbackWalletName: newWallet.name,
            );
            if (pendingItems.isNotEmpty) {
              unlockedGroup = AiTransactionDraftGroup(
                clientMutationId:
                    TrackerRemoteSyncService.sanitizeClientMutationId(
                      'tx_${_uuid.v4()}',
                    ),
                items: pendingItems
                    .map(
                      (item) => item.copyWith(
                        walletId: newWallet.id,
                        walletName: newWallet.name,
                      ),
                    )
                    .toList(),
              );
            }
          }

          _replaceMessageAt(
            currentIndex,
            currentMsg.copyWith(
              walletCreationDraft: draft.copyWith(
                initialBalance: initialBalance,
                isCreated: true,
                createdWalletId: newWallet.id,
              ),
              transactionDraftGroup: unlockedGroup,
            ),
          );
        }
        state = state.copyWith(clearErrorMessage: true);
      }
    } catch (err) {
      if (_canMutateState && state.sessionId == requestSessionId) {
        state = state.copyWith(
          errorMessage: UnifiedAiChatMutationHelpers.formatSyncError(err),
        );
      }
    } finally {
      _confirmingMessageIds.remove(lockKey);
      if (_canMutateState) {
        state = state.copyWith(isMutating: _confirmingMessageIds.isNotEmpty);
      }
    }
  }

  /// Rebinds a withheld transaction draft to an [existingWallet] selected by
  /// the user (typo recovery) at 0 AI quota cost and unlocks the draft card.
  void selectExistingWalletForPendingTx(
    String messageId,
    WalletModel existingWallet,
  ) {
    if (!_canMutateState) return;
    if (_confirmingMessageIds.contains('tx:$messageId')) return;

    final index = state.messages.indexWhere((m) => m.id == messageId);
    if (index < 0) return;

    final targetMsg = state.messages[index];
    final existingGroup = targetMsg.transactionDraftGroup;
    if (existingGroup != null &&
        (existingGroup.isConfirmed ||
            existingGroup.isSubmitting ||
            existingGroup.isCancelled)) {
      return;
    }

    final pendingItems = _resolvePendingTxItemsForMessage(
      index,
      targetMsg,
      fallbackWalletName: existingWallet.name,
    );
    if (pendingItems.isEmpty) return;

    final reboundItems = pendingItems
        .map(
          (item) => item.copyWith(
            walletId: existingWallet.id,
            walletName: existingWallet.name,
          ),
        )
        .toList();

    final existingMutationId = existingGroup?.clientMutationId ?? '';
    final mutationId = existingMutationId.isNotEmpty
        ? existingMutationId
        : TrackerRemoteSyncService.sanitizeClientMutationId('tx_${_uuid.v4()}');

    _replaceMessageAt(
      index,
      targetMsg.copyWith(
        transactionDraftGroup: AiTransactionDraftGroup(
          clientMutationId: mutationId,
          items: reboundItems,
          isSubmitting: false,
          isConfirmed: false,
          isCancelled: false,
        ),
      ),
    );
  }

  /// Idempotently confirms 1..N items in a `TransactionDraftGroup` at 0 AI quota cost.
  /// Synchronous in-flight locking prevents rapid double-taps from duplicating records.
  Future<void> confirmTransactionDraft(String messageId) async {
    if (!_canMutateState) return;
    final lockKey = 'tx:$messageId';
    if (_confirmingMessageIds.contains(lockKey)) return;

    final index = state.messages.indexWhere((m) => m.id == messageId);
    if (index < 0) return;

    final targetMsg = state.messages[index];
    final draft = targetMsg.transactionDraftGroup;
    if (draft == null ||
        draft.isSubmitting ||
        draft.isConfirmed ||
        draft.isCancelled) {
      return;
    }

    final validItems = draft.items.where((i) => i.amount > 0).toList();
    if (validItems.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Nominal transaksi harus lebih dari Rp 0.',
      );
      return;
    }

    final requestSessionId = state.sessionId;
    final wallets = ref.read(walletsProvider);
    final existingTxIds = ref.read(transactionsProvider).map((t) => t.id).toSet();
    final isRemote = ref.read(clarafinApiConfigProvider).isConfigured;
    final syncService = isRemote
        ? ref.read(trackerRemoteSyncServiceProvider)
        : null;

    final baseMutationId = TrackerRemoteSyncService.sanitizeClientMutationId(
      draft.clientMutationId.isNotEmpty
          ? draft.clientMutationId
          : 'tx_${_uuid.v4()}',
    );
    final lockedDraft = draft.copyWith(
      clientMutationId: baseMutationId,
      isSubmitting: true,
    );

    _confirmingMessageIds.add(lockKey);
    _replaceMessageAt(
      index,
      targetMsg.copyWith(transactionDraftGroup: lockedDraft),
    );
    state = state.copyWith(isMutating: true, clearErrorMessage: true);

    try {
      final prepared = <({TransactionModel tx, String mutationId})>[];
      for (var i = 0; i < validItems.length; i++) {
        final item = validItems[i];
        final itemMutationId =
            TrackerRemoteSyncService.sanitizeClientMutationId(
              validItems.length == 1
                  ? baseMutationId
                  : '${baseMutationId}_$i',
            );
        final resolvedWalletId =
            UnifiedAiChatMutationHelpers.resolveLocalWalletId(item, wallets);
        final resolvedTargetWalletId = item.type == 'transfer'
            ? UnifiedAiChatMutationHelpers.resolveTargetWalletId(
                item.targetWalletId,
                wallets,
              )
            : item.targetWalletId;
        final canonicalCategory =
            UnifiedAiChatMutationHelpers.normalizeLocalTransactionCategory(
              item,
            );

        prepared.add((
          mutationId: itemMutationId,
          tx: TransactionModel(
            id: itemMutationId,
            title: item.title,
            category: canonicalCategory,
            amount: item.amount,
            date: item.occurredAt,
            type: item.type,
            walletId: resolvedWalletId,
            targetWalletId: resolvedTargetWalletId,
          ),
        ));
      }

      for (final entry in prepared) {
        if (syncService != null) {
          await syncService.createTransaction(
            walletId: entry.tx.walletId,
            destinationWalletId: entry.tx.targetWalletId,
            targetGoalId: entry.tx.targetGoalId,
            type: entry.tx.type,
            category: entry.tx.category,
            amount: entry.tx.amount,
            title: entry.tx.title,
            note: entry.tx.notes,
            occurredAt: entry.tx.date,
            source: 'ai_text',
            clientMutationId: entry.mutationId,
          );
        }
        if (!_canMutateState) return;
        if (!existingTxIds.contains(entry.mutationId)) {
          // TransactionsNotifier.addTransaction updates walletsProvider balance once.
          ref.read(transactionsProvider.notifier).addTransaction(entry.tx);
          existingTxIds.add(entry.mutationId);
        }
      }

      _pendingWalletTxItems.remove(messageId);
      if (state.sessionId == requestSessionId) {
        _updateMessageById(
          messageId,
          (msg) => msg.copyWith(
            transactionDraftGroup:
                (msg.transactionDraftGroup ?? lockedDraft).copyWith(
                  clientMutationId: baseMutationId,
                  isSubmitting: false,
                  isConfirmed: true,
                ),
          ),
        );
        state = state.copyWith(clearErrorMessage: true);
      }
    } catch (err) {
      if (_canMutateState && state.sessionId == requestSessionId) {
        _updateMessageById(
          messageId,
          (msg) => msg.copyWith(
            transactionDraftGroup:
                (msg.transactionDraftGroup ?? lockedDraft).copyWith(
                  clientMutationId: baseMutationId,
                  isSubmitting: false,
                  isConfirmed: false,
                ),
          ),
        );
        state = state.copyWith(
          errorMessage: UnifiedAiChatMutationHelpers.formatSyncError(err),
        );
      }
    } finally {
      _confirmingMessageIds.remove(lockKey);
      if (_canMutateState) {
        state = state.copyWith(isMutating: _confirmingMessageIds.isNotEmpty);
      }
    }
  }

  /// Cancels a pending `TransactionDraftGroup` at 0 AI quota cost.
  void cancelTransactionDraft(String messageId) {
    _cancelSingleDraft(
      messageId,
      canCancel: (msg) {
        final d = msg.transactionDraftGroup;
        return d != null && !d.isConfirmed && !d.isSubmitting;
      },
      markCancelled: (msg) => msg.copyWith(
        transactionDraftGroup: msg.transactionDraftGroup!.copyWith(
          isCancelled: true,
        ),
      ),
    );
  }

  /// Idempotently confirms an `AiGoalDraft` and adds it to `goalsProvider` at 0 quota cost.
  Future<void> confirmGoalDraft(String messageId) async {
    await _runSingleDraftConfirmation<AiGoalDraft>(
      messageId: messageId,
      lockPrefix: 'goal',
      extractDraft: (msg) => msg.goalDraft,
      isBlocked: (d) => d.isSubmitting || d.isConfirmed || d.isCancelled,
      validateError: (d) => (d.name.trim().isEmpty || d.targetAmount <= 0)
          ? 'Nama target dan nominal tabungan harus valid.'
          : null,
      withDraftState: (msg, d) => msg.copyWith(goalDraft: d),
      updateDraftFlags: (d, {required isSubmitting, required isConfirmed, required mutationId}) =>
          d.copyWith(
            clientMutationId: mutationId,
            isSubmitting: isSubmitting,
            isConfirmed: isConfirmed,
          ),
      existingMutationId: (d) => d.clientMutationId,
      executeMutation: (d, mutationId, syncService) async {
        final goal = UnifiedAiChatMutationHelpers.buildGoalModel(
          d,
          ref.read(walletsProvider),
          clientMutationIdOverride: mutationId,
        );
        if (syncService != null) {
          await syncService.createGoal(
            title: goal.name,
            targetAmount: goal.targetAmount,
            savedAmount: goal.savedAmount,
            targetDate: goal.targetDate,
            priority: goal.priority,
            linkedWalletId: d.linkedWalletId,
            sourceAssetLabel: goal.sourceAsset,
          );
        }
        if (!_canMutateState) return;
        ref.read(goalsProvider.notifier).addGoal(goal);
      },
    );
  }

  /// Cancels a pending `AiGoalDraft` at 0 AI quota cost.
  void cancelGoalDraft(String messageId) {
    _cancelSingleDraft(
      messageId,
      canCancel: (msg) {
        final d = msg.goalDraft;
        return d != null && !d.isConfirmed && !d.isSubmitting;
      },
      markCancelled: (msg) => msg.copyWith(
        goalDraft: msg.goalDraft!.copyWith(isCancelled: true),
      ),
    );
  }

  /// Idempotently confirms an `AiBudgetDraft` (adds or updates category budget) at 0 quota cost.
  Future<void> confirmBudgetDraft(String messageId) async {
    await _runSingleDraftConfirmation<AiBudgetDraft>(
      messageId: messageId,
      lockPrefix: 'budget',
      extractDraft: (msg) => msg.budgetDraft,
      isBlocked: (d) => d.isSubmitting || d.isConfirmed || d.isCancelled,
      validateError: (d) => d.limitAmount <= 0
          ? 'Batas anggaran harus lebih dari Rp 0.'
          : null,
      withDraftState: (msg, d) => msg.copyWith(budgetDraft: d),
      updateDraftFlags: (d, {required isSubmitting, required isConfirmed, required mutationId}) =>
          d.copyWith(
            clientMutationId: mutationId,
            isSubmitting: isSubmitting,
            isConfirmed: isConfirmed,
          ),
      existingMutationId: (d) => d.clientMutationId,
      executeMutation: (d, mutationId, syncService) async {
        final canonicalCategory =
            UnifiedAiChatMutationHelpers.resolveCanonicalBudgetCategory(
              d.category,
            );
        if (syncService != null) {
          await syncService.upsertBudget(
            category: canonicalCategory,
            limitAmount: d.limitAmount,
          );
        }
        if (!_canMutateState) return;
        UnifiedAiChatMutationHelpers.applyBudgetDraftToProvider(
          ref,
          d,
          canonicalCategoryOverride: canonicalCategory,
          clientMutationIdOverride: mutationId,
        );
      },
    );
  }

  /// Cancels a pending `AiBudgetDraft` at 0 AI quota cost.
  void cancelBudgetDraft(String messageId) {
    _cancelSingleDraft(
      messageId,
      canCancel: (msg) {
        final d = msg.budgetDraft;
        return d != null && !d.isConfirmed && !d.isSubmitting;
      },
      markCancelled: (msg) => msg.copyWith(
        budgetDraft: msg.budgetDraft!.copyWith(isCancelled: true),
      ),
    );
  }

  /// Idempotently confirms an `AiBillDraft` and adds it to `billsProvider` at 0 quota cost.
  Future<void> confirmBillDraft(String messageId) async {
    await _runSingleDraftConfirmation<AiBillDraft>(
      messageId: messageId,
      lockPrefix: 'bill',
      extractDraft: (msg) => msg.billDraft,
      isBlocked: (d) => d.isSubmitting || d.isConfirmed || d.isCancelled,
      validateError: (d) => (d.title.trim().isEmpty || d.amount <= 0)
          ? 'Nama tagihan dan nominal tagihan harus valid.'
          : null,
      withDraftState: (msg, d) => msg.copyWith(billDraft: d),
      updateDraftFlags: (d, {required isSubmitting, required isConfirmed, required mutationId}) =>
          d.copyWith(
            clientMutationId: mutationId,
            isSubmitting: isSubmitting,
            isConfirmed: isConfirmed,
          ),
      existingMutationId: (d) => d.clientMutationId,
      executeMutation: (d, mutationId, syncService) async {
        final bill = UnifiedAiChatMutationHelpers.buildBillModel(
          d,
          clientMutationIdOverride: mutationId,
        );
        if (syncService != null) {
          await syncService.createBill(
            title: d.title,
            category: d.category,
            amount: d.amount,
            dueDate: bill.dueDate,
            frequency: d.frequency,
          );
        }
        if (!_canMutateState) return;
        ref.read(billsProvider.notifier).addBill(bill);
      },
    );
  }

  /// Cancels a pending `AiBillDraft` at 0 AI quota cost.
  void cancelBillDraft(String messageId) {
    _cancelSingleDraft(
      messageId,
      canCancel: (msg) {
        final d = msg.billDraft;
        return d != null && !d.isConfirmed && !d.isSubmitting;
      },
      markCancelled: (msg) => msg.copyWith(
        billDraft: msg.billDraft!.copyWith(isCancelled: true),
      ),
    );
  }

  /// Selects [consultant] and populates [bookingProvider] with AI intake context
  /// before navigating to booking at 0 AI quota cost.
  void prepareConsultantBooking(
    AiConsultantRecommendation consultant, {
    AiPackageRecommendation? fallbackPackage,
  }) {
    if (!_canMutateState) return;
    if (consultant.consultantId.trim().isNotEmpty) {
      ref.read(matchExpertProvider.notifier).selectConsultant(
            consultant.consultantId,
          );
    }

    final packageCode = consultant.selectedPackageCode.isNotEmpty
        ? consultant.selectedPackageCode
        : (fallbackPackage?.packageCode ?? 'personal_basic');
    final tierLabel = (fallbackPackage?.categoryTag.isNotEmpty ?? false)
        ? fallbackPackage!.categoryTag
        : consultant.tierLabel;
    final unitPrice = consultant.unitPrice > 0
        ? consultant.unitPrice
        : (fallbackPackage?.priceIdr ?? 0.0);

    ref.read(bookingProvider.notifier).prefillFromAi(
          packageCode: packageCode,
          selectedTierLabel: tierLabel,
          unitPrice: unitPrice,
          topics: consultant.recommendedTopics,
          description: consultant.prefilledDescription,
          expectations: consultant.prefilledExpectations,
        );
  }

  /// Builds a sanitized session history list (last 10 turns max, <= 1000 runes per entry,
  /// excluding failed error bubbles so transient network/quota errors never pollute AI context).
  List<Map<String, String>> buildSanitizedHistory() {
    final turns = <Map<String, String>>[];
    for (final msg in state.messages) {
      if (msg.errorCode != null) continue;
      final compacted = msg.toCompactedHistoryText().trim();
      if (compacted.isEmpty) continue;
      final runes = compacted.runes;
      final capped = runes.length <= maxHistoryRunes
          ? compacted
          : String.fromCharCodes(runes.take(maxHistoryRunes));
      turns.add({
        'role': msg.isUser ? 'user' : 'model',
        'text': capped,
      });
    }
    if (turns.length <= maxHistoryTurns) return turns;
    return turns.sublist(turns.length - maxHistoryTurns);
  }

  Future<void> _runSingleDraftConfirmation<T>({
    required String messageId,
    required String lockPrefix,
    required T? Function(UnifiedAiChatMessage msg) extractDraft,
    required bool Function(T draft) isBlocked,
    required String? Function(T draft) validateError,
    required UnifiedAiChatMessage Function(UnifiedAiChatMessage msg, T draft)
    withDraftState,
    required T Function(
      T draft, {
      required bool isSubmitting,
      required bool isConfirmed,
      required String mutationId,
    })
    updateDraftFlags,
    required String Function(T draft) existingMutationId,
    required Future<void> Function(
      T draft,
      String mutationId,
      TrackerRemoteSyncService? syncService,
    )
    executeMutation,
  }) async {
    if (!_canMutateState) return;
    final lockKey = '$lockPrefix:$messageId';
    if (_confirmingMessageIds.contains(lockKey)) return;

    final index = state.messages.indexWhere((m) => m.id == messageId);
    if (index < 0) return;

    final targetMsg = state.messages[index];
    final draft = extractDraft(targetMsg);
    if (draft == null || isBlocked(draft)) return;

    final validationMsg = validateError(draft);
    if (validationMsg != null) {
      state = state.copyWith(errorMessage: validationMsg);
      return;
    }

    final requestSessionId = state.sessionId;
    final isRemote = ref.read(clarafinApiConfigProvider).isConfigured;
    final syncService = isRemote
        ? ref.read(trackerRemoteSyncServiceProvider)
        : null;

    final rawId = existingMutationId(draft).trim();
    final mutationId = rawId.isNotEmpty
        ? rawId
        : '${lockPrefix}_${_uuid.v4()}';
    final submittingDraft = updateDraftFlags(
      draft,
      isSubmitting: true,
      isConfirmed: false,
      mutationId: mutationId,
    );

    _confirmingMessageIds.add(lockKey);
    _replaceMessageAt(index, withDraftState(targetMsg, submittingDraft));
    state = state.copyWith(isMutating: true, clearErrorMessage: true);

    try {
      await executeMutation(submittingDraft, mutationId, syncService);
      if (!_canMutateState) return;

      if (state.sessionId == requestSessionId) {
        _updateMessageById(messageId, (msg) {
          final current = extractDraft(msg) ?? submittingDraft;
          return withDraftState(
            msg,
            updateDraftFlags(
              current,
              isSubmitting: false,
              isConfirmed: true,
              mutationId: mutationId,
            ),
          );
        });
        state = state.copyWith(clearErrorMessage: true);
      }
    } catch (err) {
      if (_canMutateState && state.sessionId == requestSessionId) {
        _updateMessageById(messageId, (msg) {
          final current = extractDraft(msg) ?? submittingDraft;
          return withDraftState(
            msg,
            updateDraftFlags(
              current,
              isSubmitting: false,
              isConfirmed: false,
              mutationId: mutationId,
            ),
          );
        });
        state = state.copyWith(
          errorMessage: UnifiedAiChatMutationHelpers.formatSyncError(err),
        );
      }
    } finally {
      _confirmingMessageIds.remove(lockKey);
      if (_canMutateState) {
        state = state.copyWith(isMutating: _confirmingMessageIds.isNotEmpty);
      }
    }
  }

  void _cancelSingleDraft(
    String messageId, {
    required bool Function(UnifiedAiChatMessage msg) canCancel,
    required UnifiedAiChatMessage Function(UnifiedAiChatMessage msg)
    markCancelled,
  }) {
    if (!_canMutateState) return;
    _updateMessageById(messageId, (msg) {
      if (!canCancel(msg)) return msg;
      return markCancelled(msg);
    });
  }

  void _onThinkingStep(AiThinkingStepEvent event, String requestSessionId) {
    if (!_canMutateState || state.sessionId != requestSessionId) return;

    final rawStep = event.toThinkingStep();
    final stepId = rawStep.id.isNotEmpty
        ? rawStep.id
        : 'step-${event.stepNumber}';
    final existingSteps =
        state.activeThinkingTrace?.steps ?? const <AiThinkingStep>[];
    final existingIdx = existingSteps.indexWhere((s) => s.id == stepId);

    final nextStep = existingIdx >= 0
        ? rawStep.copyWith(
            id: stepId,
            detail: rawStep.detail ?? existingSteps[existingIdx].detail,
          )
        : rawStep.copyWith(id: stepId);

    final List<AiThinkingStep> updatedSteps;
    if (existingIdx >= 0) {
      updatedSteps = List<AiThinkingStep>.from(existingSteps);
      updatedSteps[existingIdx] = nextStep;
    } else {
      updatedSteps = [...existingSteps, nextStep];
    }

    state = state.copyWith(
      activeThinkingTrace: AiThinkingTrace(steps: updatedSteps, isLive: true),
    );
  }

  void _onFinalResponse(
    AiFinalResponseEvent event,
    String requestSessionId,
    String userPrompt,
    DateTime startedAt,
  ) {
    if (!_canMutateState || state.sessionId != requestSessionId) return;

    _syncQuotaFromResponse(
      planType: event.planType,
      quotaRemaining: event.quotaRemaining,
      isPrefiltered: event.isPrefiltered,
      isQuotaExceeded: false,
    );

    final msgId = event.message.id.isNotEmpty ? event.message.id : _uuid.v4();
    final liveSteps =
        state.activeThinkingTrace?.steps ?? const <AiThinkingStep>[];
    final msgSteps =
        event.message.thinkingTrace?.steps ?? const <AiThinkingStep>[];
    final combinedSteps = (msgSteps.isNotEmpty ? msgSteps : liveSteps)
        .map((s) => s.copyWith(isDone: true))
        .toList();

    final elapsedMs = max(
      1,
      DateTime.now().difference(startedAt).inMilliseconds,
    );
    final rawDuration = event.message.thinkingTrace?.durationMs ?? 0;
    final resolvedTrace = combinedSteps.isEmpty
        ? null
        : AiThinkingTrace(
            steps: combinedSteps,
            durationMs: rawDuration > 0 ? rawDuration : elapsedMs,
            isLive: false,
          );

    var resolvedTxGroup = event.message.transactionDraftGroup;
    final walletDraft = event.message.walletCreationDraft;
    if (walletDraft != null && !walletDraft.isCreated) {
      final withheldItems =
          resolvedTxGroup != null && resolvedTxGroup.items.isNotEmpty
          ? resolvedTxGroup.items
          : UnifiedAiChatMutationHelpers.extractPendingTxItemsFromPrompt(
              userPrompt,
              fallbackWalletName: walletDraft.institutionName,
              now: event.message.timestamp,
            );
      if (withheldItems.isNotEmpty) {
        _pendingWalletTxItems[msgId] = withheldItems;
      }
      // Keep TransactionDraftGroup locked until the prerequisite wallet is created or chosen.
      resolvedTxGroup = null;
    }

    if (event.message.recommendedConsultants.isNotEmpty) {
      final topId = event.message.recommendedConsultants.first.consultantId;
      if (topId.isNotEmpty) {
        ref.read(matchExpertProvider.notifier).selectConsultant(topId);
      }
    }

    final finalizedMessage = UnifiedAiChatMessage(
      id: msgId,
      sessionId: requestSessionId,
      text: event.message.text,
      isUser: false,
      timestamp: event.message.timestamp,
      thinkingTrace: resolvedTrace,
      moneyFlowCard: event.message.moneyFlowCard,
      spendingTableCard: event.message.spendingTableCard,
      walletCreationDraft: walletDraft,
      transactionDraftGroup: resolvedTxGroup,
      goalDraft: event.message.goalDraft,
      budgetDraft: event.message.budgetDraft,
      billDraft: event.message.billDraft,
      recommendedPackage: event.message.recommendedPackage,
      recommendedConsultants: event.message.recommendedConsultants,
      errorCode: event.message.errorCode,
      failedPrompt: event.message.failedPrompt,
    );

    state = state.copyWith(
      messages: [...state.messages, finalizedMessage],
      isStreaming: false,
      clearActiveThinkingTrace: true,
      clearErrorMessage: true,
    );
  }

  void _onErrorEvent(
    AiErrorEvent event,
    String requestSessionId,
    String userPrompt,
  ) {
    if (!_canMutateState || state.sessionId != requestSessionId) return;

    _syncQuotaFromResponse(
      planType: event.planType,
      quotaRemaining: event.quotaRemaining,
      isPrefiltered: true,
      isQuotaExceeded: event.isQuotaExceeded,
    );

    final errorMsg = UnifiedAiChatMessage(
      id: _uuid.v4(),
      sessionId: requestSessionId,
      text: event.message,
      isUser: false,
      timestamp: DateTime.now(),
      errorCode: event.errorCode,
      failedPrompt: userPrompt,
    );

    state = state.copyWith(
      messages: [...state.messages, errorMsg],
      isStreaming: false,
      clearActiveThinkingTrace: true,
      errorMessage: event.message,
    );
  }

  void _syncQuotaFromResponse({
    required String? planType,
    required int? quotaRemaining,
    required bool isPrefiltered,
    required bool isQuotaExceeded,
  }) {
    if (!_canMutateState) return;
    final profileNotifier = ref.read(userProfileProvider.notifier);
    final currentPlan = ref.read(userProfileProvider).subscriptionPlan;
    UnifiedAiChatMutationHelpers.applyQuotaUpdate(
      profileNotifier: profileNotifier,
      currentPlan: currentPlan,
      planType: planType,
      quotaRemaining: quotaRemaining,
      isPrefiltered: isPrefiltered,
      isQuotaExceeded: isQuotaExceeded,
      onUseLocalQuota: (amount) =>
          ref.read(aiQuotaProvider.notifier).useQuota(amount),
    );
  }

  List<AiTransactionDraftItem> _resolvePendingTxItemsForMessage(
    int messageIndex,
    UnifiedAiChatMessage targetMsg, {
    required String fallbackWalletName,
  }) {
    final cached = _pendingWalletTxItems[targetMsg.id];
    if (cached != null && cached.isNotEmpty) return cached;

    if (targetMsg.transactionDraftGroup != null &&
        targetMsg.transactionDraftGroup!.items.isNotEmpty) {
      return targetMsg.transactionDraftGroup!.items;
    }

    for (var i = messageIndex - 1; i >= 0; i--) {
      final candidate = state.messages[i];
      if (candidate.isUser && candidate.text.trim().isNotEmpty) {
        final parsed =
            UnifiedAiChatMutationHelpers.extractPendingTxItemsFromPrompt(
              candidate.text,
              fallbackWalletName: fallbackWalletName,
              now: targetMsg.timestamp,
            );
        if (parsed.isNotEmpty) return parsed;
        break;
      }
    }
    return UnifiedAiChatMutationHelpers.extractPendingTxItemsFromPrompt(
      targetMsg.text,
      fallbackWalletName: fallbackWalletName,
      now: targetMsg.timestamp,
    );
  }

  bool _isStaleStream(
    String requestSessionId,
    String clientRequestId,
    CancelToken cancelToken,
  ) {
    return !_canMutateState ||
        state.sessionId != requestSessionId ||
        _activeClientRequestId != clientRequestId ||
        cancelToken.isCancelled;
  }

  void _clearActiveStreamRefs(String clientRequestId) {
    if (_activeClientRequestId != clientRequestId) return;
    _activeClientRequestId = null;
    _activeCancelToken = null;
    _activeSubscription = null;
    _activeStreamCompleter = null;
  }

  void _replaceMessageAt(int index, UnifiedAiChatMessage updated) {
    if (!_canMutateState) return;
    if (index < 0 || index >= state.messages.length) return;
    final next = List<UnifiedAiChatMessage>.from(state.messages);
    next[index] = updated;
    state = state.copyWith(messages: next);
  }

  void _updateMessageById(
    String messageId,
    UnifiedAiChatMessage Function(UnifiedAiChatMessage current) updater,
  ) {
    if (!_canMutateState) return;
    final idx = state.messages.indexWhere((m) => m.id == messageId);
    if (idx < 0) return;
    _replaceMessageAt(idx, updater(state.messages[idx]));
  }

  void _cancelActiveStream() {
    _activeClientRequestId = null;
    final token = _activeCancelToken;
    _activeCancelToken = null;
    if (token != null && !token.isCancelled) {
      token.cancel('session_cancelled');
    }
    final sub = _activeSubscription;
    _activeSubscription = null;
    if (sub != null) {
      unawaited(sub.cancel());
    }
    final completer = _activeStreamCompleter;
    _activeStreamCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  void _disposeResources() {
    _isDisposed = true;
    _cancelActiveStream();
    _confirmingMessageIds.clear();
    _pendingWalletTxItems.clear();
  }
}

final unifiedAiChatProvider =
    NotifierProvider<UnifiedAiChatNotifier, UnifiedAiChatState>(
      UnifiedAiChatNotifier.new,
    );
