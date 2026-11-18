import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/models/transaction_model.dart';
import 'package:mobile/core/models/wallet_model.dart';
import 'package:mobile/core/network/clarafin_api_client.dart';
import 'package:mobile/core/network/tracker_remote_sync_service.dart';
import 'package:mobile/core/providers/ai_quota_provider.dart';
import 'package:mobile/core/providers/mock_providers.dart';
import 'package:mobile/core/services/local_storage_service.dart';
import 'package:mobile/features/budget/presentation/providers/finance_providers.dart';
import 'package:mobile/features/consult/presentation/providers/booking_provider.dart';
import 'package:mobile/features/match_expert/presentation/providers/match_expert_provider.dart';
import 'package:mobile/features/session/data/ai_chat_repository.dart';
import 'package:mobile/features/session/domain/models/ai_chat_models.dart';
import 'package:mobile/features/session/presentation/providers/unified_ai_chat_provider.dart';
import 'package:mobile/features/session/presentation/widgets/unified_ai_chat_panel_chrome.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef _AdapterHandler = Future<ResponseBody> Function(
  RequestOptions options,
  Stream<Uint8List>? requestStream,
  Future<void>? cancelFuture,
);

class _FakeHttpClientAdapter implements HttpClientAdapter {
  final _AdapterHandler handler;
  final List<RequestOptions> requests = [];

  _FakeHttpClientAdapter(this.handler);

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options, requestStream, cancelFuture);
  }
}

class _ControllableAiChatRepository implements AiChatRepository {
  final List<
    ({
      String prompt,
      AiSurfaceMode surfaceMode,
      String sessionId,
      String clientRequestId,
      List<UnifiedAiChatMessage> sessionHistory,
      CancelToken? cancelToken,
      StreamController<AiSseEvent> controller,
    })
  > calls = [];

  @override
  Stream<AiSseEvent> streamChat({
    required String prompt,
    required AiSurfaceMode surfaceMode,
    required String sessionId,
    required String clientRequestId,
    List<UnifiedAiChatMessage> sessionHistory = const [],
    AiChatContextSnapshot? contextSnapshot,
    CancelToken? cancelToken,
  }) {
    final controller = StreamController<AiSseEvent>();
    calls.add((
      prompt: prompt,
      surfaceMode: surfaceMode,
      sessionId: sessionId,
      clientRequestId: clientRequestId,
      sessionHistory: List<UnifiedAiChatMessage>.from(sessionHistory),
      cancelToken: cancelToken,
      controller: controller,
    ));
    return controller.stream;
  }
}

Future<ProviderContainer> _createTestContainer({
  AiChatRepository? repository,
  List<WalletModel>? initialWallets,
  List<BudgetCategoryModel>? initialBudgets,
  ClarafinApiConfig? apiConfig,
  TrackerRemoteSyncService? remoteSyncService,
}) async {
  const userId = 'u_test_43';
  final userMap = {
    'id': userId,
    'name': 'Raka Tester',
    'email': 'raka@clarafin.test',
    'password': 'secret',
    'avatarUrl': 'assets/images/avatars/avatar_1.png',
  };
  final initialPrefs = <String, Object>{
    'clarafin_registered_accounts': [jsonEncode(userMap)],
    'clarafin_is_logged_in': true,
    'clarafin_active_user_id': userId,
    if (initialWallets != null)
      'clarafin_wallets_$userId':
          initialWallets.map((w) => jsonEncode(w.toJson())).toList(),
    if (initialBudgets != null)
      'clarafin_budgets_$userId':
          initialBudgets.map((b) => jsonEncode(b.toJson())).toList(),
  };

  SharedPreferences.setMockInitialValues(initialPrefs);
  final prefs = await SharedPreferences.getInstance();

  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      if (apiConfig != null)
        clarafinApiConfigProvider.overrideWithValue(apiConfig),
      if (remoteSyncService != null)
        trackerRemoteSyncServiceProvider.overrideWithValue(remoteSyncService),
      if (repository != null)
        aiChatRepositoryProvider.overrideWithValue(repository),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Review Focus #1: Session Isolation & startNewChat()', () {
    test(
      'ignores late thinking_step, final_response, and error events from Session A after startNewChat()',
      () async {
        final fakeRepo = _ControllableAiChatRepository();
        final container = await _createTestContainer(repository: fakeRepo);
        addTearDown(container.dispose);

        final notifier = container.read(unifiedAiChatProvider.notifier);
        final sessionAId = container.read(unifiedAiChatProvider).sessionId;
        expect(sessionAId, isNotEmpty);

        // Start streaming in Session A.
        final sendFuture = notifier.sendMessage(
          'uangku lari ke mana aja?',
          surfaceMode: AiSurfaceMode.fullScreen,
        );
        await Future<void>.delayed(Duration.zero);

        expect(fakeRepo.calls.length, equals(1));
        final callA = fakeRepo.calls.single;
        expect(callA.sessionId, equals(sessionAId));

        // Emit live thinking step in Session A.
        callA.controller.add(
          AiThinkingStepEvent(
            stepNumber: 1,
            id: 'step-1',
            title: 'Menghitung arus kas',
            detail: 'Memeriksa transaksi bulan ini',
            status: 'in_progress',
            isDone: false,
            sessionId: sessionAId,
            clientRequestId: callA.clientRequestId,
          ),
        );
        await Future<void>.delayed(Duration.zero);

        final streamingState = container.read(unifiedAiChatProvider);
        expect(streamingState.isStreaming, isTrue);
        expect(streamingState.messages.length, equals(1));
        expect(streamingState.messages.first.isUser, isTrue);
        expect(streamingState.activeThinkingTrace, isNotNull);
        expect(
          streamingState.activeThinkingTrace!.steps.single.label,
          equals('Menghitung arus kas'),
        );

        // User taps New Chat while Session A is still streaming.
        final quotaBeforeReset = container.read(aiQuotaProvider).quotaRemaining;
        notifier.startNewChat();

        final sessionBState = container.read(unifiedAiChatProvider);
        final sessionBId = sessionBState.sessionId;
        expect(sessionBId, isNot(equals(sessionAId)));
        expect(sessionBState.messages, isEmpty);
        expect(sessionBState.isStreaming, isFalse);
        expect(sessionBState.activeThinkingTrace, isNull);
        expect(sessionBState.errorMessage, isNull);
        expect(callA.cancelToken?.isCancelled, isTrue);
        expect(
          container.read(aiQuotaProvider).quotaRemaining,
          equals(quotaBeforeReset),
        );

        // Emit late events on Session A stream after Session B is active.
        callA.controller.add(
          AiThinkingStepEvent(
            stepNumber: 2,
            id: 'step-2',
            title: 'Langkah terlambat',
            status: 'completed',
            isDone: true,
            sessionId: sessionAId,
            clientRequestId: callA.clientRequestId,
          ),
        );
        callA.controller.add(
          AiFinalResponseEvent(
            sessionId: sessionAId,
            clientRequestId: callA.clientRequestId,
            surfaceMode: AiSurfaceMode.fullScreen,
            quotaTotal: 40,
            quotaRemaining: 39,
            message: UnifiedAiChatMessage(
              id: 'msg-late-a',
              sessionId: sessionAId,
              text: 'Balasan terlambat dari sesi A yang harus diabaikan.',
              isUser: false,
            ),
          ),
        );
        callA.controller.add(
          const AiErrorEvent(
            errorCode: 'INTERNAL_ERROR',
            message: 'Error terlambat dari sesi A yang harus diabaikan.',
          ),
        );
        await callA.controller.close();
        await sendFuture;
        await Future<void>.delayed(Duration.zero);

        // Session B must remain 100% empty and untouched.
        final afterLateEvents = container.read(unifiedAiChatProvider);
        expect(afterLateEvents.sessionId, equals(sessionBId));
        expect(afterLateEvents.messages, isEmpty);
        expect(afterLateEvents.isStreaming, isFalse);
        expect(afterLateEvents.activeThinkingTrace, isNull);
        expect(afterLateEvents.errorMessage, isNull);
      },
    );
  });

  group('Review Focus #2: Idempotent Transaction Draft Confirmation', () {
    test(
      'rapid double confirmTransactionDraft call executes addTransaction and deducts wallet balance ONCE',
      () async {
        final gopay = WalletModel(
          id: 'w-gopay',
          name: 'GoPay',
          type: 'E-Wallet',
          balance: 250000,
          institutionId: 'gopay',
        );
        final container = await _createTestContainer(initialWallets: [gopay]);
        addTearDown(container.dispose);

        final notifier = container.read(unifiedAiChatProvider.notifier);
        await notifier.sendMessage(
          'kopi kenangan 25k + parkir goceng pake gopay',
          surfaceMode: AiSurfaceMode.quickSheet,
        );

        final chatState = container.read(unifiedAiChatProvider);
        final assistantMsg = chatState.messages.lastWhere((m) => !m.isUser);
        expect(assistantMsg.transactionDraftGroup, isNotNull);
        expect(assistantMsg.transactionDraftGroup!.items.length, equals(2));
        expect(chatState.hasRichCardsOrMultiReplies, isTrue);

        final quotaAfterChat = container.read(aiQuotaProvider).quotaRemaining;

        // Fire two concurrent confirmation calls before the first finishes.
        await Future.wait([
          notifier.confirmTransactionDraft(assistantMsg.id),
          notifier.confirmTransactionDraft(assistantMsg.id),
        ]);

        // Assert transactions were added ONCE (2 items total, not 4).
        final txs = container.read(transactionsProvider);
        expect(txs.length, equals(2));

        // Assert GoPay wallet balance deducted ONCE: 250.000 - (25.000 + 5.000) = 220.000.
        final updatedGopay = container
            .read(walletsProvider)
            .singleWhere((w) => w.id == 'w-gopay');
        expect(updatedGopay.balance, equals(220000.0));

        // Assert card state is confirmed and 0 additional quota was used.
        final confirmedMsg = container
            .read(unifiedAiChatProvider)
            .messages
            .singleWhere((m) => m.id == assistantMsg.id);
        expect(confirmedMsg.transactionDraftGroup!.isConfirmed, isTrue);
        expect(confirmedMsg.transactionDraftGroup!.isSubmitting, isFalse);
        expect(
          container.read(aiQuotaProvider).quotaRemaining,
          equals(quotaAfterChat),
        );
      },
    );
  });

  group('Review Focus #4: Prerequisite Wallet Creation & Typo Recovery', () {
    test(
      'creates missing Bank Jago wallet with initialBalance 500000, unlocks pending 45000 lunch draft, and deducts to 455000 on confirm',
      () async {
        final bca = WalletModel(
          id: 'w-bca',
          name: 'BCA Utama',
          type: 'Bank',
          balance: 2000000,
          institutionId: 'bca',
        );
        final container = await _createTestContainer(initialWallets: [bca]);
        addTearDown(container.dispose);

        final notifier = container.read(unifiedAiChatProvider.notifier);
        await notifier.sendMessage(
          'abis makan siang 45rb pake bank jago',
          surfaceMode: AiSurfaceMode.quickSheet,
        );

        final msgBeforeCreate = container
            .read(unifiedAiChatProvider)
            .messages
            .lastWhere((m) => !m.isUser);
        expect(msgBeforeCreate.walletCreationDraft, isNotNull);
        expect(
          msgBeforeCreate.walletCreationDraft!.institutionName,
          equals('Bank Jago'),
        );
        expect(msgBeforeCreate.walletCreationDraft!.isCreated, isFalse);
        // Transaction draft card is withheld until prerequisite wallet is resolved.
        expect(msgBeforeCreate.transactionDraftGroup, isNull);

        final quotaBeforeConfirm = container.read(aiQuotaProvider).quotaRemaining;

        // Step 1: Confirm wallet creation with Rp 500.000 initial balance (0 quota).
        await notifier.confirmWalletCreation(
          msgBeforeCreate.id,
          initialBalance: 500000,
        );

        final walletsAfterCreate = container.read(walletsProvider);
        final jagoWallet = walletsAfterCreate.singleWhere(
          (w) => w.name == 'Bank Jago' || w.institutionId == 'jago',
        );
        expect(jagoWallet.balance, equals(500000.0));

        final msgAfterCreate = container
            .read(unifiedAiChatProvider)
            .messages
            .singleWhere((m) => m.id == msgBeforeCreate.id);
        expect(msgAfterCreate.walletCreationDraft!.isCreated, isTrue);
        expect(
          msgAfterCreate.walletCreationDraft!.createdWalletId,
          equals(jagoWallet.id),
        );
        expect(msgAfterCreate.transactionDraftGroup, isNotNull);
        expect(msgAfterCreate.transactionDraftGroup!.items.length, equals(1));
        expect(
          msgAfterCreate.transactionDraftGroup!.items.single.amount,
          equals(45000.0),
        );
        expect(
          msgAfterCreate.transactionDraftGroup!.items.single.walletId,
          equals(jagoWallet.id),
        );
        expect(
          msgAfterCreate.transactionDraftGroup!.items.single.walletName,
          equals('Bank Jago'),
        );

        // Step 2: Confirm the unlocked transaction draft (0 quota).
        await notifier.confirmTransactionDraft(msgBeforeCreate.id);

        final jagoAfterTx = container
            .read(walletsProvider)
            .singleWhere((w) => w.id == jagoWallet.id);
        expect(jagoAfterTx.balance, equals(455000.0));
        expect(
          container.read(aiQuotaProvider).quotaRemaining,
          equals(quotaBeforeConfirm),
        );
      },
    );

    test(
      'selectExistingWalletForPendingTx rebinds withheld transaction to existing BCA wallet at 0 quota cost',
      () async {
        final bca = WalletModel(
          id: 'w-bca',
          name: 'BCA Utama',
          type: 'Bank',
          balance: 1000000,
          institutionId: 'bca',
        );
        final container = await _createTestContainer(initialWallets: [bca]);
        addTearDown(container.dispose);

        final notifier = container.read(unifiedAiChatProvider.notifier);
        await notifier.sendMessage(
          'makan malam 60rb pake bank jago',
          surfaceMode: AiSurfaceMode.quickSheet,
        );

        final assistantMsg = container
            .read(unifiedAiChatProvider)
            .messages
            .lastWhere((m) => !m.isUser);
        expect(assistantMsg.walletCreationDraft, isNotNull);
        expect(assistantMsg.transactionDraftGroup, isNull);

        final quotaBefore = container.read(aiQuotaProvider).quotaRemaining;

        // User selects existing BCA wallet instead of creating Bank Jago.
        notifier.selectExistingWalletForPendingTx(assistantMsg.id, bca);

        final reboundMsg = container
            .read(unifiedAiChatProvider)
            .messages
            .singleWhere((m) => m.id == assistantMsg.id);
        expect(reboundMsg.transactionDraftGroup, isNotNull);
        expect(reboundMsg.transactionDraftGroup!.items.single.walletId, equals('w-bca'));
        expect(
          reboundMsg.transactionDraftGroup!.items.single.walletName,
          equals('BCA Utama'),
        );
        expect(
          reboundMsg.transactionDraftGroup!.items.single.amount,
          equals(60000.0),
        );

        await notifier.confirmTransactionDraft(assistantMsg.id);
        final updatedBca = container
            .read(walletsProvider)
            .singleWhere((w) => w.id == 'w-bca');
        expect(updatedBca.balance, equals(940000.0));
        expect(container.read(aiQuotaProvider).quotaRemaining, equals(quotaBefore));
      },
    );
  });

  group('Planning Draft Confirmations, History Sanitization, & Error States', () {
    test(
      'confirmGoalDraft, confirmBudgetDraft (add & update), confirmBillDraft, and cancelTransactionDraft update providers accurately',
      () async {
        final existingFoodBudget = BudgetCategoryModel(
          id: 'b-food',
          name: 'Food & Beverage',
          totalAmount: 2000000,
          spentAmount: 500000,
          icon: Icons.restaurant,
          iconColor: Colors.orange,
          iconBgColor: Colors.orange.shade100,
        );
        final gopay = WalletModel(
          id: 'w-gopay',
          name: 'GoPay',
          type: 'E-Wallet',
          balance: 500000,
          institutionId: 'gopay',
        );
        final container = await _createTestContainer(
          initialWallets: [gopay],
          initialBudgets: [existingFoodBudget],
        );
        addTearDown(container.dispose);

        final notifier = container.read(unifiedAiChatProvider.notifier);

        // 1. Goal draft confirmation
        await notifier.sendMessage(
          'buat target tabungan Dana Darurat 15jt 10 bulan',
          surfaceMode: AiSurfaceMode.fullScreen,
        );
        final goalMsg = container
            .read(unifiedAiChatProvider)
            .messages
            .lastWhere((m) => !m.isUser);
        expect(goalMsg.goalDraft, isNotNull);
        await notifier.confirmGoalDraft(goalMsg.id);
        expect(container.read(goalsProvider).length, equals(1));
        expect(container.read(goalsProvider).single.targetAmount, equals(15000000.0));

        // 2. Budget draft confirmation (updates existing Food & Beverage budget)
        await notifier.sendMessage(
          'atur budget makan 1,5jt per bulan',
          surfaceMode: AiSurfaceMode.fullScreen,
        );
        final budgetMsg = container
            .read(unifiedAiChatProvider)
            .messages
            .lastWhere((m) => !m.isUser);
        expect(budgetMsg.budgetDraft, isNotNull);
        await notifier.confirmBudgetDraft(budgetMsg.id);
        final budgets = container.read(budgetsProvider);
        expect(budgets.length, equals(1));
        expect(budgets.single.name, equals('Food & Beverage'));
        expect(budgets.single.totalAmount, equals(1500000.0));

        // 3. Bill draft confirmation
        await notifier.sendMessage(
          'ingetin tagihan wifi indihome 385rb tiap tanggal 20',
          surfaceMode: AiSurfaceMode.fullScreen,
        );
        final billMsg = container
            .read(unifiedAiChatProvider)
            .messages
            .lastWhere((m) => !m.isUser);
        expect(billMsg.billDraft, isNotNull);
        await notifier.confirmBillDraft(billMsg.id);
        final bills = container.read(billsProvider);
        expect(bills.length, equals(1));
        expect(bills.single.amount, equals(385000.0));

        // 4. Transaction draft cancellation
        await notifier.sendMessage(
          'kopi kenangan 25k pake gopay',
          surfaceMode: AiSurfaceMode.quickSheet,
        );
        final txMsg = container
            .read(unifiedAiChatProvider)
            .messages
            .lastWhere((m) => !m.isUser);
        notifier.cancelTransactionDraft(txMsg.id);
        final cancelledTxMsg = container
            .read(unifiedAiChatProvider)
            .messages
            .singleWhere((m) => m.id == txMsg.id);
        expect(cancelledTxMsg.transactionDraftGroup!.isCancelled, isTrue);
        expect(container.read(transactionsProvider), isEmpty);

        // 5. Sanitized history verification (<= 10 turns, <= 1000 chars per entry)
        final history = notifier.buildSanitizedHistory();
        expect(history.length, equals(8));
        expect(history.first['role'], equals('user'));
        expect(history[1]['role'], equals('model'));
        expect(history[1]['text'], contains('[User menyetujui Goal:'));
        expect(history.last['text'], contains('[User membatalkan draf transaksi:'));
        for (final turn in history) {
          expect(turn['text']!.runes.length, lessThanOrEqualTo(1000));
        }
      },
    );

    test(
      'handles QUOTA_EXCEEDED error event and stores failedPrompt for retry/upgrade',
      () async {
        final fakeRepo = _ControllableAiChatRepository();
        final container = await _createTestContainer(repository: fakeRepo);
        addTearDown(container.dispose);

        final notifier = container.read(unifiedAiChatProvider.notifier);
        final sendFuture = notifier.sendMessage(
          'analisa cashflow bulan ini',
          surfaceMode: AiSurfaceMode.fullScreen,
        );
        await Future<void>.delayed(Duration.zero);

        final call = fakeRepo.calls.single;
        call.controller.add(
          const AiErrorEvent(
            errorCode: 'QUOTA_EXCEEDED',
            message: 'Kuota AI bulanan kamu sudah habis.',
            statusCode: 402,
            planType: 'free',
            quotaRemaining: 0,
            quotaTotal: 40,
          ),
        );
        await call.controller.close();
        await sendFuture;

        final state = container.read(unifiedAiChatProvider);
        expect(state.isStreaming, isFalse);
        expect(state.activeThinkingTrace, isNull);
        expect(state.errorMessage, contains('Kuota AI bulanan'));
        final errMsg = state.messages.last;
        expect(errMsg.isUser, isFalse);
        expect(errMsg.errorCode, equals('QUOTA_EXCEEDED'));
        expect(errMsg.failedPrompt, equals('analisa cashflow bulan ini'));
        expect(container.read(aiQuotaProvider).quotaRemaining, equals(0));
      },
    );

    test(
      'computes hasRichCardsOrMultiReplies accurately for plain vs multi-reply and caps buildSanitizedHistory to 10 turns',
      () async {
        final container = await _createTestContainer();
        addTearDown(container.dispose);

        final notifier = container.read(unifiedAiChatProvider.notifier);

        // Turn 1: pure greeting (1 plain assistant reply, 0 rich cards) -> false.
        await notifier.sendMessage(
          'Halo Clarafin!',
          surfaceMode: AiSurfaceMode.quickSheet,
        );
        expect(
          container.read(unifiedAiChatProvider).hasRichCardsOrMultiReplies,
          isFalse,
        );

        // Turn 2: second plain reply -> assistant count >= 2 -> true.
        await notifier.sendMessage(
          'Selamat pagi!',
          surfaceMode: AiSurfaceMode.quickSheet,
        );
        expect(
          container.read(unifiedAiChatProvider).hasRichCardsOrMultiReplies,
          isTrue,
        );

        // Add 5 more round-trips (total 7 user + 7 model = 14 messages).
        for (var i = 0; i < 5; i++) {
          await notifier.sendMessage(
            'Makasih!',
            surfaceMode: AiSurfaceMode.quickSheet,
          );
        }
        expect(container.read(unifiedAiChatProvider).messages.length, equals(14));

        final sanitized = notifier.buildSanitizedHistory();
        expect(sanitized.length, equals(10));
        expect(sanitized.first['role'], equals('user'));
        expect(sanitized.last['role'], equals('model'));
      },
    );

    test(
      'guards confirmWalletCreation, confirmGoalDraft, confirmBudgetDraft, and confirmBillDraft against concurrent double-taps',
      () async {
        final container = await _createTestContainer();
        addTearDown(container.dispose);

        final notifier = container.read(unifiedAiChatProvider.notifier);

        // Concurrent confirmWalletCreation calls must create only 1 wallet.
        await notifier.sendMessage(
          'abis makan 45rb pake bank jago',
          surfaceMode: AiSurfaceMode.quickSheet,
        );
        final walletMsgId = container
            .read(unifiedAiChatProvider)
            .messages
            .lastWhere((m) => !m.isUser)
            .id;

        await Future.wait([
          notifier.confirmWalletCreation(walletMsgId, initialBalance: 300000),
          notifier.confirmWalletCreation(walletMsgId, initialBalance: 300000),
        ]);
        expect(container.read(walletsProvider).length, equals(1));

        // Concurrent confirmGoalDraft calls must create only 1 goal.
        await notifier.sendMessage(
          'buat target tabungan Liburan Jepang 20jt 12 bulan',
          surfaceMode: AiSurfaceMode.fullScreen,
        );
        final goalMsgId = container
            .read(unifiedAiChatProvider)
            .messages
            .lastWhere((m) => !m.isUser)
            .id;

        await Future.wait([
          notifier.confirmGoalDraft(goalMsgId),
          notifier.confirmGoalDraft(goalMsgId),
        ]);
        expect(container.read(goalsProvider).length, equals(1));

        // Concurrent confirmBudgetDraft calls must add only 1 new category budget.
        await notifier.sendMessage(
          'atur budget transportasi 500rb per bulan',
          surfaceMode: AiSurfaceMode.fullScreen,
        );
        final budgetMsgId = container
            .read(unifiedAiChatProvider)
            .messages
            .lastWhere((m) => !m.isUser)
            .id;

        await Future.wait([
          notifier.confirmBudgetDraft(budgetMsgId),
          notifier.confirmBudgetDraft(budgetMsgId),
        ]);
        expect(container.read(budgetsProvider).length, equals(1));

        // Concurrent confirmBillDraft calls must add only 1 bill.
        await notifier.sendMessage(
          'ingetin tagihan listrik 450rb tiap tanggal 15',
          surfaceMode: AiSurfaceMode.fullScreen,
        );
        final billMsgId = container
            .read(unifiedAiChatProvider)
            .messages
            .lastWhere((m) => !m.isUser)
            .id;

        await Future.wait([
          notifier.confirmBillDraft(billMsgId),
          notifier.confirmBillDraft(billMsgId),
        ]);
        expect(container.read(billsProvider).length, equals(1));
      },
    );
  });

  group('Remote Sync Failures, Stream Races, & Edge-Case Guards', () {
    test(
      'surfaces error and does NOT mark confirmed or mutate local state when remote sync fails across all 5 draft types',
      () async {
        var shouldFail = true;
        final adapter = _FakeHttpClientAdapter((options, _, _) async {
          if (options.method == 'GET') {
            throw StateError('Initial pre-chat sync skipped');
          }
          if (shouldFail) {
            return ResponseBody.fromString(
              jsonEncode({
                'error': {
                  'code': 'SYNC_UNAVAILABLE',
                  'message': 'Server sedang sibuk. Data belum tersimpan.',
                },
              }),
              503,
              headers: {
                Headers.contentTypeHeader: ['application/json'],
              },
            );
          }

          if (options.path == '/v1/wallets') {
            return ResponseBody.fromString(
              jsonEncode({
                'data': {
                  'id': '99999999-9999-4999-8999-999999999991',
                  'name': 'Bank Jago',
                  'type': 'bank',
                  'institution_code': 'jago',
                  'balance': 500000,
                },
              }),
              201,
              headers: {
                Headers.contentTypeHeader: ['application/json'],
              },
            );
          }
          if (options.path == '/v1/transactions') {
            return ResponseBody.fromString(
              jsonEncode({
                'data': {
                  'transaction': {
                    'id': '99999999-9999-4999-8999-999999999992',
                    'wallet_id': '99999999-9999-4999-8999-999999999991',
                  },
                  'idempotent_replay': false,
                  'wallet_balance_idr': 455000,
                },
              }),
              201,
              headers: {
                Headers.contentTypeHeader: ['application/json'],
              },
            );
          }
          if (options.path == '/v1/goals') {
            return ResponseBody.fromString(
              jsonEncode({
                'data': {
                  'id': '99999999-9999-4999-8999-999999999993',
                  'title': 'Dana Darurat',
                  'target_amount': 15000000,
                  'saved_amount': 0,
                  'priority': 'wants',
                },
              }),
              201,
              headers: {
                Headers.contentTypeHeader: ['application/json'],
              },
            );
          }
          if (options.path == '/v1/budgets') {
            return ResponseBody.fromString(
              jsonEncode({
                'data': {
                  'id': '99999999-9999-4999-8999-999999999994',
                  'category': 'Food & Beverage',
                  'month_year': '2026-11',
                  'limit_amount': 1500000,
                },
              }),
              200,
              headers: {
                Headers.contentTypeHeader: ['application/json'],
              },
            );
          }
          if (options.path == '/v1/bills') {
            return ResponseBody.fromString(
              jsonEncode({
                'data': {
                  'id': '99999999-9999-4999-8999-999999999995',
                  'title': 'Wi-Fi IndiHome',
                  'amount': 385000,
                  'frequency': 'monthly',
                },
              }),
              201,
              headers: {
                Headers.contentTypeHeader: ['application/json'],
              },
            );
          }
          throw StateError('Unexpected call: ${options.method} ${options.path}');
        });

        final apiConfig = ClarafinApiConfig.fromUrl('http://127.0.0.1:8080');
        final dio = Dio(BaseOptions(baseUrl: apiConfig.normalizedBaseUrl));
        dio.httpClientAdapter = adapter;
        final apiClient = ClarafinApiClient(
          config: apiConfig,
          dio: dio,
          accessToken: 'test_jwt',
        );
        final syncService = TrackerRemoteSyncService(client: apiClient);

        final fakeRepo = _ControllableAiChatRepository();
        final container = await _createTestContainer(
          repository: fakeRepo,
          apiConfig: apiConfig,
          remoteSyncService: syncService,
        );
        addTearDown(container.dispose);

        final notifier = container.read(unifiedAiChatProvider.notifier);

        // Emit all 5 draft types from controllable stream.
        Future<String> emitAssistantMsg(UnifiedAiChatMessage msg) async {
          final prevCount = fakeRepo.calls.length;
          final sendFut = notifier.sendMessage(
            'test prompt ${msg.id}',
            surfaceMode: AiSurfaceMode.quickSheet,
          );
          while (fakeRepo.calls.length <= prevCount) {
            await Future<void>.delayed(const Duration(milliseconds: 5));
          }
          final call = fakeRepo.calls.last;
          call.controller.add(
            AiFinalResponseEvent(
              sessionId: call.sessionId,
              clientRequestId: call.clientRequestId,
              surfaceMode: AiSurfaceMode.quickSheet,
              message: msg,
            ),
          );
          await call.controller.close();
          await sendFut;
          return msg.id;
        }

        final walletMsgId = await emitAssistantMsg(
          UnifiedAiChatMessage(
            id: 'm-wallet-fail',
            sessionId: container.read(unifiedAiChatProvider).sessionId,
            text: 'Buat Bank Jago dulu.',
            isUser: false,
            walletCreationDraft: const AiWalletCreationDraft(
              institutionId: 'jago',
              institutionName: 'Bank Jago',
              walletType: 'bank',
            ),
            transactionDraftGroup: AiTransactionDraftGroup(
              clientMutationId: 'mut-tx-after-wallet',
              items: [
                AiTransactionDraftItem(
                  title: 'Makan Siang',
                  amount: 45000,
                  type: 'expense',
                  canonicalCategory: 'Food & Beverage • Restaurant',
                  walletId: '',
                  walletName: 'Bank Jago',
                  occurredAt: DateTime(2026, 11, 18, 12, 0),
                ),
              ],
            ),
          ),
        );

        // 1. Failing wallet creation must NOT add wallet or mark isCreated.
        await notifier.confirmWalletCreation(walletMsgId, initialBalance: 500000);
        expect(container.read(walletsProvider), isEmpty);
        final failedWalletMsg = container
            .read(unifiedAiChatProvider)
            .messages
            .singleWhere((m) => m.id == walletMsgId);
        expect(failedWalletMsg.walletCreationDraft!.isCreated, isFalse);
        expect(failedWalletMsg.transactionDraftGroup, isNull);
        expect(
          container.read(unifiedAiChatProvider).errorMessage,
          equals('Server sedang sibuk. Data belum tersimpan.'),
        );

        // Retry after backend recovers -> succeeds!
        shouldFail = false;
        await notifier.confirmWalletCreation(walletMsgId, initialBalance: 500000);
        expect(container.read(walletsProvider).length, equals(1));
        expect(container.read(unifiedAiChatProvider).errorMessage, isNull);

        // 2. Failing transaction confirmation must NOT add tx or mark isConfirmed.
        shouldFail = true;
        await notifier.confirmTransactionDraft(walletMsgId);
        expect(container.read(transactionsProvider), isEmpty);
        expect(container.read(walletsProvider).single.balance, equals(500000));
        final failedTxMsg = container
            .read(unifiedAiChatProvider)
            .messages
            .singleWhere((m) => m.id == walletMsgId);
        expect(failedTxMsg.transactionDraftGroup!.isConfirmed, isFalse);
        expect(failedTxMsg.transactionDraftGroup!.isSubmitting, isFalse);
        expect(
          container.read(unifiedAiChatProvider).errorMessage,
          equals('Server sedang sibuk. Data belum tersimpan.'),
        );

        // Retry tx after backend recovers -> succeeds!
        shouldFail = false;
        await notifier.confirmTransactionDraft(walletMsgId);
        expect(container.read(transactionsProvider).length, equals(1));
        expect(container.read(walletsProvider).single.balance, equals(455000));

        // 3. Failing goal, budget, and bill drafts must NOT mutate local state.
        shouldFail = true;
        final goalMsgId = await emitAssistantMsg(
          UnifiedAiChatMessage(
            id: 'm-goal-fail',
            sessionId: container.read(unifiedAiChatProvider).sessionId,
            text: 'Draf goal',
            isUser: false,
            goalDraft: const AiGoalDraft(
              clientMutationId: 'mut-goal-fail',
              name: 'Dana Darurat',
              targetAmount: 15000000,
            ),
          ),
        );
        await notifier.confirmGoalDraft(goalMsgId);
        expect(container.read(goalsProvider), isEmpty);
        expect(
          container
              .read(unifiedAiChatProvider)
              .messages
              .singleWhere((m) => m.id == goalMsgId)
              .goalDraft!
              .isConfirmed,
          isFalse,
        );
        expect(container.read(unifiedAiChatProvider).errorMessage, isNotNull);

        final budgetMsgId = await emitAssistantMsg(
          UnifiedAiChatMessage(
            id: 'm-budget-fail',
            sessionId: container.read(unifiedAiChatProvider).sessionId,
            text: 'Draf budget',
            isUser: false,
            budgetDraft: const AiBudgetDraft(
              clientMutationId: 'mut-budget-fail',
              category: 'Makanan',
              limitAmount: 1500000,
            ),
          ),
        );
        await notifier.confirmBudgetDraft(budgetMsgId);
        expect(container.read(budgetsProvider), isEmpty);
        expect(
          container
              .read(unifiedAiChatProvider)
              .messages
              .singleWhere((m) => m.id == budgetMsgId)
              .budgetDraft!
              .isConfirmed,
          isFalse,
        );
        expect(container.read(unifiedAiChatProvider).errorMessage, isNotNull);

        final billMsgId = await emitAssistantMsg(
          UnifiedAiChatMessage(
            id: 'm-bill-fail',
            sessionId: container.read(unifiedAiChatProvider).sessionId,
            text: 'Draf tagihan',
            isUser: false,
            billDraft: const AiBillDraft(
              clientMutationId: 'mut-bill-fail',
              title: 'Wi-Fi IndiHome',
              amount: 385000,
              dueDay: 30,
            ),
          ),
        );
        await notifier.confirmBillDraft(billMsgId);
        expect(container.read(billsProvider), isEmpty);
        expect(
          container
              .read(unifiedAiChatProvider)
              .messages
              .singleWhere((m) => m.id == billMsgId)
              .billDraft!
              .isConfirmed,
          isFalse,
        );
        expect(container.read(unifiedAiChatProvider).errorMessage, isNotNull);

        // Retry goal, budget, and bill after backend recovers -> all succeed!
        shouldFail = false;
        await notifier.confirmGoalDraft(goalMsgId);
        await notifier.confirmBudgetDraft(budgetMsgId);
        await notifier.confirmBillDraft(billMsgId);
        expect(container.read(goalsProvider).length, equals(1));
        expect(container.read(budgetsProvider).length, equals(1));
        expect(container.read(billsProvider).length, equals(1));
        expect(container.read(unifiedAiChatProvider).errorMessage, isNull);
      },
    );

    test(
      'ignores late events from superseded same-session stream and surfaces STREAM_INTERRUPTED on premature close',
      () async {
        final fakeRepo = _ControllableAiChatRepository();
        final container = await _createTestContainer(repository: fakeRepo);
        addTearDown(container.dispose);

        final notifier = container.read(unifiedAiChatProvider.notifier);

        // Start stream 1 in current session.
        final fut1 = notifier.sendMessage(
          'pertanyaan pertama',
          surfaceMode: AiSurfaceMode.quickSheet,
        );
        await Future<void>.delayed(Duration.zero);
        final call1 = fakeRepo.calls[0];

        // Start stream 2 in the SAME session before stream 1 completes.
        final fut2 = notifier.sendMessage(
          'pertanyaan kedua',
          surfaceMode: AiSurfaceMode.quickSheet,
        );
        await Future<void>.delayed(Duration.zero);
        final call2 = fakeRepo.calls[1];

        expect(call2.sessionId, equals(call1.sessionId));
        expect(call2.clientRequestId, isNot(equals(call1.clientRequestId)));
        expect(call1.cancelToken?.isCancelled, isTrue);

        // Stream 1 emits a late response -> MUST be ignored in same session!
        call1.controller.add(
          AiFinalResponseEvent(
            sessionId: call1.sessionId,
            clientRequestId: call1.clientRequestId,
            surfaceMode: AiSurfaceMode.quickSheet,
            message: UnifiedAiChatMessage(
              id: 'late-same-session',
              sessionId: call1.sessionId,
              text: 'Balasan stream 1 yang usang',
              isUser: false,
            ),
          ),
        );
        await call1.controller.close();
        await fut1;

        expect(
          container
              .read(unifiedAiChatProvider)
              .messages
              .any((m) => m.id == 'late-same-session'),
          isFalse,
        );
        expect(container.read(unifiedAiChatProvider).isStreaming, isTrue);

        // Stream 2 closes abruptly without final_response or error -> must surface STREAM_INTERRUPTED!
        await call2.controller.close();
        await fut2;

        final state = container.read(unifiedAiChatProvider);
        expect(state.isStreaming, isFalse);
        expect(state.errorMessage, isNotNull);
        expect(state.messages.last.errorCode, equals('STREAM_INTERRUPTED'));
        expect(state.messages.last.failedPrompt, equals('pertanyaan kedua'));
      },
    );

    test(
      'excludes error bubbles from buildSanitizedHistory(), preserves dueDay 30 on bills, and guards post-confirm wallet rebind',
      () async {
        final bca = WalletModel(
          id: 'w-bca',
          name: 'BCA Utama',
          type: 'Bank',
          balance: 1000000,
          institutionId: 'bca',
        );
        final gopay = WalletModel(
          id: 'w-gopay',
          name: 'GoPay',
          type: 'E-Wallet',
          balance: 500000,
          institutionId: 'gopay',
        );
        final fakeRepo = _ControllableAiChatRepository();
        final container = await _createTestContainer(
          repository: fakeRepo,
          initialWallets: [bca, gopay],
        );
        addTearDown(container.dispose);

        final notifier = container.read(unifiedAiChatProvider.notifier);

        // 1. Emit an error turn and ensure it does not pollute buildSanitizedHistory().
        final errFut = notifier.sendMessage(
          'gagal cek',
          surfaceMode: AiSurfaceMode.quickSheet,
        );
        await Future<void>.delayed(Duration.zero);
        fakeRepo.calls.last.controller.add(
          const AiErrorEvent(
            errorCode: 'STREAM_ERROR',
            message: 'Koneksi putus',
          ),
        );
        await fakeRepo.calls.last.controller.close();
        await errFut;

        final historyWithErr = notifier.buildSanitizedHistory();
        expect(
          historyWithErr.any((t) => t['text'] == 'Koneksi putus'),
          isFalse,
        );

        // 2. Emit bill draft with dueDay 30 and ensure dueDate keeps day >= 28 (e.g., 30 in 30/31-day months, or Feb max).
        final billFut = notifier.sendMessage(
          'tagihan listrik 300rb tgl 30',
          surfaceMode: AiSurfaceMode.quickSheet,
        );
        await Future<void>.delayed(Duration.zero);
        fakeRepo.calls.last.controller.add(
          AiFinalResponseEvent(
            sessionId: fakeRepo.calls.last.sessionId,
            clientRequestId: fakeRepo.calls.last.clientRequestId,
            surfaceMode: AiSurfaceMode.quickSheet,
            message: UnifiedAiChatMessage(
              id: 'm-bill-30',
              sessionId: fakeRepo.calls.last.sessionId,
              text: 'Draf tagihan tanggal 30',
              isUser: false,
              billDraft: const AiBillDraft(
                clientMutationId: 'mut-bill-30',
                title: 'Listrik PLN',
                amount: 300000,
                dueDay: 30,
              ),
            ),
          ),
        );
        await fakeRepo.calls.last.controller.close();
        await billFut;

        await notifier.confirmBillDraft('m-bill-30');
        final savedBill = container.read(billsProvider).single;
        final maxDaysInSavedMonth =
            DateTime(savedBill.dueDate!.year, savedBill.dueDate!.month + 1, 0)
                .day;
        expect(
          savedBill.dueDate!.day,
          equals(maxDaysInSavedMonth >= 30 ? 30 : maxDaysInSavedMonth),
        );

        // 3. Emit walletCreationDraft, rebind to BCA, confirm tx, then try rebinding to GoPay -> MUST be blocked!
        final txFut = notifier.sendMessage(
          'makan 50rb pake bank jago',
          surfaceMode: AiSurfaceMode.quickSheet,
        );
        await Future<void>.delayed(Duration.zero);
        fakeRepo.calls.last.controller.add(
          AiFinalResponseEvent(
            sessionId: fakeRepo.calls.last.sessionId,
            clientRequestId: fakeRepo.calls.last.clientRequestId,
            surfaceMode: AiSurfaceMode.quickSheet,
            message: UnifiedAiChatMessage(
              id: 'm-rebind-guard',
              sessionId: fakeRepo.calls.last.sessionId,
              text: 'Dompet belum ada',
              isUser: false,
              walletCreationDraft: const AiWalletCreationDraft(
                institutionId: 'jago',
                institutionName: 'Bank Jago',
                walletType: 'bank',
              ),
            ),
          ),
        );
        await fakeRepo.calls.last.controller.close();
        await txFut;

        notifier.selectExistingWalletForPendingTx('m-rebind-guard', bca);
        await notifier.confirmTransactionDraft('m-rebind-guard');
        notifier.selectExistingWalletForPendingTx('m-rebind-guard', gopay);

        final msgAfterPostConfirmRebind = container
            .read(unifiedAiChatProvider)
            .messages
            .singleWhere((m) => m.id == 'm-rebind-guard');
        expect(msgAfterPostConfirmRebind.transactionDraftGroup!.isConfirmed, isTrue);
        expect(
          msgAfterPostConfirmRebind.transactionDraftGroup!.items.single.walletId,
          equals('w-bca'),
        );
      },
    );

    test(
      'refreshQuota() syncs live quota from GET /v1/ai/quota and surfaces errors without throwing',
      () async {
        var failQuota = false;
        final adapter = _FakeHttpClientAdapter((options, _, _) async {
          expect(options.method, equals('GET'));
          expect(options.path, equals('/v1/ai/quota'));
          if (failQuota) {
            return ResponseBody.fromString(
              jsonEncode({
                'error': {
                  'code': 'QUOTA_READ_FAILED',
                  'message': 'Gagal memuat kuota AI.',
                },
              }),
              500,
              headers: {
                Headers.contentTypeHeader: ['application/json'],
              },
            );
          }
          return ResponseBody.fromString(
            jsonEncode({
              'data': {
                'plan_type': 'pro_monthly',
                'quota_total': 400,
                'quota_used': 88,
                'quota_remaining': 312,
                'renewal_date': '2026-12-18T00:00:00+07:00',
              },
            }),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        });

        final apiConfig = ClarafinApiConfig.fromUrl('http://127.0.0.1:8080');
        final dio = Dio(BaseOptions(baseUrl: apiConfig.normalizedBaseUrl));
        dio.httpClientAdapter = adapter;
        final syncService = TrackerRemoteSyncService(
          client: ClarafinApiClient(
            config: apiConfig,
            dio: dio,
            accessToken: 'test_jwt',
          ),
        );

        final container = await _createTestContainer(
          apiConfig: apiConfig,
          remoteSyncService: syncService,
        );
        addTearDown(container.dispose);

        final notifier = container.read(unifiedAiChatProvider.notifier);
        await notifier.refreshQuota();

        final quota = container.read(aiQuotaProvider);
        expect(quota.planType, equals('pro_monthly'));
        expect(quota.quotaTotal, equals(400));
        expect(quota.quotaRemaining, equals(312));
        expect(quota.displayQuotaBadge, equals('312/400'));
        expect(container.read(unifiedAiChatProvider).errorMessage, isNull);

        failQuota = true;
        await notifier.refreshQuota();
        expect(
          container.read(unifiedAiChatProvider).errorMessage,
          equals('Gagal memuat kuota AI.'),
        );
        notifier.clearError();
        expect(container.read(unifiedAiChatProvider).errorMessage, isNull);
      },
    );

    test(
      'retryFailedMessage() generates a brand-new clientRequestId, cleans duplicate user turns, and never reuses failed request IDs',
      () async {
        final fakeRepo = _ControllableAiChatRepository();
        final container = await _createTestContainer(repository: fakeRepo);
        addTearDown(container.dispose);

        final notifier = container.read(unifiedAiChatProvider.notifier);

        // Prior successful turn so multi-turn context is preserved cleanly.
        final initFut = notifier.sendMessage(
          'Halo',
          surfaceMode: AiSurfaceMode.fullScreen,
        );
        await Future<void>.delayed(Duration.zero);
        final initCall = fakeRepo.calls[0];
        initCall.controller.add(
          AiFinalResponseEvent(
            sessionId: initCall.sessionId,
            clientRequestId: initCall.clientRequestId,
            surfaceMode: AiSurfaceMode.fullScreen,
            message: UnifiedAiChatMessage(
              id: 'm-init-ok',
              sessionId: initCall.sessionId,
              text: 'Halo! Ada yang bisa dibantu?',
              isUser: false,
            ),
          ),
        );
        await initCall.controller.close();
        await initFut;

        final sendFut1 = notifier.sendMessage(
          'analisa cashflow Q4',
          surfaceMode: AiSurfaceMode.fullScreen,
        );
        await Future<void>.delayed(Duration.zero);
        final call1 = fakeRepo.calls[1];
        call1.controller.add(
          const AiErrorEvent(
            errorCode: 'INTERNAL_ERROR',
            message: 'Timeout saat analisa.',
          ),
        );
        await call1.controller.close();
        await sendFut1;

        final errMsg = container.read(unifiedAiChatProvider).messages.last;
        expect(errMsg.failedPrompt, equals('analisa cashflow Q4'));

        final retryFut = notifier.retryFailedMessage(
          errMsg.id,
          surfaceMode: AiSurfaceMode.fullScreen,
        );
        await Future<void>.delayed(Duration.zero);
        final call2 = fakeRepo.calls[2];

        expect(call2.prompt, equals('analisa cashflow Q4'));
        expect(call2.sessionId, equals(call1.sessionId));
        expect(call2.clientRequestId, isNot(equals(call1.clientRequestId)));
        // Retried sessionHistory must not resend the failed user prompt as a prior turn.
        expect(
          call2.sessionHistory.map((m) => m.text).toList(),
          equals(['Halo', 'Halo! Ada yang bisa dibantu?']),
        );

        call2.controller.add(
          AiFinalResponseEvent(
            sessionId: call2.sessionId,
            clientRequestId: call2.clientRequestId,
            surfaceMode: AiSurfaceMode.fullScreen,
            message: UnifiedAiChatMessage(
              id: 'm-retry-ok',
              sessionId: call2.sessionId,
              text: 'Analisa Q4 selesai.',
              isUser: false,
            ),
          ),
        );
        await call2.controller.close();
        await retryFut;

        final finalState = container.read(unifiedAiChatProvider);
        expect(finalState.errorMessage, isNull);
        expect(
          finalState.messages.last.text,
          equals('Analisa Q4 selesai.'),
        );
        expect(
          finalState.messages.where((m) => m.errorCode != null),
          isEmpty,
        );
        expect(
          finalState.messages.where((m) => m.isUser).map((m) => m.text).toList(),
          equals(['Halo', 'analisa cashflow Q4']),
        );

        final sanitized = notifier.buildSanitizedHistory();
        expect(
          sanitized,
          equals([
            {'role': 'user', 'text': 'Halo'},
            {'role': 'model', 'text': 'Halo! Ada yang bisa dibantu?'},
            {'role': 'user', 'text': 'analisa cashflow Q4'},
            {'role': 'model', 'text': 'Analisa Q4 selesai.'},
          ]),
        );
      },
    );

    test(
      'partial remote transaction batch failure retries remaining item without double-charging first item locally',
      () async {
        var txPostCount = 0;
        final postedMutationIds = <String>[];

        final adapter = _FakeHttpClientAdapter((options, _, _) async {
          if (options.method != 'POST' || options.path != '/v1/transactions') {
            throw StateError('Initial pre-chat sync skipped');
          }
          expect(options.path, equals('/v1/transactions'));
          txPostCount++;
          final body = jsonDecode(jsonEncode(options.data)) as Map<String, dynamic>;
          postedMutationIds.add(body['client_mutation_id'] as String);

          if (txPostCount == 2) {
            return ResponseBody.fromString(
              jsonEncode({
                'error': {
                  'code': 'UPSTREAM_TIMEOUT',
                  'message': 'Item kedua gagal disimpan sementara.',
                },
              }),
              504,
              headers: {
                Headers.contentTypeHeader: ['application/json'],
              },
            );
          }

          return ResponseBody.fromString(
            jsonEncode({
              'data': {
                'transaction': {
                  'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa$txPostCount',
                  'wallet_id': '11111111-1111-4111-8111-111111111111',
                },
                'idempotent_replay': false,
                'wallet_balance_idr': 220000,
              },
            }),
            201,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        });

        final apiConfig = ClarafinApiConfig.fromUrl('http://127.0.0.1:8080');
        final dio = Dio(BaseOptions(baseUrl: apiConfig.normalizedBaseUrl));
        dio.httpClientAdapter = adapter;
        final syncService = TrackerRemoteSyncService(
          client: ClarafinApiClient(
            config: apiConfig,
            dio: dio,
            accessToken: 'test_jwt',
          ),
        );

        final gopay = WalletModel(
          id: '11111111-1111-4111-8111-111111111111',
          name: 'GoPay',
          type: 'E-Wallet',
          balance: 250000,
          institutionId: 'gopay',
        );
        final fakeRepo = _ControllableAiChatRepository();
        final container = await _createTestContainer(
          repository: fakeRepo,
          initialWallets: [gopay],
          apiConfig: apiConfig,
          remoteSyncService: syncService,
        );
        addTearDown(container.dispose);

        final notifier = container.read(unifiedAiChatProvider.notifier);
        final sendFut = notifier.sendMessage(
          'kopi 25k + parkir 5k pake gopay',
          surfaceMode: AiSurfaceMode.quickSheet,
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));
        final call = fakeRepo.calls.single;
        call.controller.add(
          AiFinalResponseEvent(
            sessionId: call.sessionId,
            clientRequestId: call.clientRequestId,
            surfaceMode: AiSurfaceMode.quickSheet,
            message: UnifiedAiChatMessage(
              id: 'm-batch-partial',
              sessionId: call.sessionId,
              text: 'Draf 2 transaksi siap.',
              isUser: false,
              transactionDraftGroup: AiTransactionDraftGroup(
                clientMutationId: '',
                items: [
                  AiTransactionDraftItem(
                    title: 'Kopi Kenangan',
                    amount: 25000,
                    type: 'expense',
                    canonicalCategory: 'kopi kenangan',
                    walletId: gopay.id,
                    walletName: 'GoPay',
                    occurredAt: DateTime(2026, 11, 18, 9, 0),
                  ),
                  AiTransactionDraftItem(
                    title: 'Parkir',
                    amount: 5000,
                    type: 'expense',
                    canonicalCategory: 'parkir',
                    walletId: gopay.id,
                    walletName: 'GoPay',
                    occurredAt: DateTime(2026, 11, 18, 9, 5),
                  ),
                ],
              ),
            ),
          ),
        );
        await call.controller.close();
        await sendFut;

        // Attempt 1: item 0 succeeds, item 1 fails remotely.
        await notifier.confirmTransactionDraft('m-batch-partial');
        expect(container.read(transactionsProvider).length, equals(1));
        expect(container.read(walletsProvider).single.balance, equals(225000.0));
        expect(
          container
              .read(unifiedAiChatProvider)
              .messages
              .singleWhere((m) => m.id == 'm-batch-partial')
              .transactionDraftGroup!
              .isConfirmed,
          isFalse,
        );
        expect(
          container.read(unifiedAiChatProvider).errorMessage,
          equals('Item kedua gagal disimpan sementara.'),
        );

        // Attempt 2: item 0 reuses exact same idempotency key and is NOT re-added locally!
        await notifier.confirmTransactionDraft('m-batch-partial');
        final txs = container.read(transactionsProvider);
        expect(txs.length, equals(2));
        expect(
          txs.map((t) => t.category).toSet(),
          equals({
            'Food & Beverage • Coffee Shop',
            'Transportation • Parking & Toll',
          }),
        );
        expect(container.read(walletsProvider).single.balance, equals(220000.0));
        expect(postedMutationIds[0], equals(postedMutationIds[2]));
        expect(postedMutationIds[1], equals(postedMutationIds[3]));
        expect(
          container
              .read(unifiedAiChatProvider)
              .messages
              .singleWhere((m) => m.id == 'm-batch-partial')
              .transactionDraftGroup!
              .isConfirmed,
          isTrue,
        );
      },
    );

    test(
      'prepareConsultantBooking updates matchExpertProvider & bookingProvider, validates invalid drafts, and survives mid-stream disposal',
      () async {
        final fakeRepo = _ControllableAiChatRepository();
        final container = await _createTestContainer(repository: fakeRepo);

        final notifier = container.read(unifiedAiChatProvider.notifier);

        // 1. Validation guards for negative wallet initialBalance & zero-amount tx.
        final sendFut = notifier.sendMessage(
          'test booking & validation',
          surfaceMode: AiSurfaceMode.fullScreen,
        );
        await Future<void>.delayed(Duration.zero);
        final call = fakeRepo.calls.single;

        const package = AiPackageRecommendation(
          packageCode: 'couple_pre_marriage',
          categoryTag: 'Couple Advisory • Pre-Marriage',
          packageTitle: 'Siap Menikah Tanpa Drama Finansial',
          priceIdr: 349000,
        );
        const consultant = AiConsultantRecommendation(
          consultantId: 'c1',
          name: 'Chrysan Gomargana, S.E., CFP®',
          tierLabel: 'Medium',
          selectedPackageCode: 'couple_pre_marriage',
          unitPrice: 349000,
          recommendedTopics: ['Keuangan Pranikah', 'Budget Nikah'],
          prefilledDescription: 'Ingin merancang rekening pasutri.',
          prefilledExpectations: 'Punya struktur rekening bersama.',
        );

        call.controller.add(
          AiFinalResponseEvent(
            sessionId: call.sessionId,
            clientRequestId: call.clientRequestId,
            surfaceMode: AiSurfaceMode.fullScreen,
            message: UnifiedAiChatMessage(
              id: 'm-consult-and-guard',
              sessionId: call.sessionId,
              text: 'Rekomendasi praktisi siap.',
              isUser: false,
              recommendedPackage: package,
              recommendedConsultants: const [consultant],
              walletCreationDraft: const AiWalletCreationDraft(
                institutionId: 'jago',
                institutionName: 'Bank Jago',
                walletType: 'bank',
              ),
              transactionDraftGroup: AiTransactionDraftGroup(
                clientMutationId: 'mut-zero',
                items: [
                  AiTransactionDraftItem(
                    title: 'Invalid Zero',
                    amount: 0,
                    type: 'expense',
                    canonicalCategory: 'Others • General Uncategorized',
                    walletId: '',
                    walletName: 'Bank Jago',
                    occurredAt: DateTime(2026, 11, 18),
                  ),
                ],
              ),
            ),
          ),
        );
        await call.controller.close();
        await sendFut;

        // Invalid negative wallet balance must surface error and not create wallet.
        await notifier.confirmWalletCreation(
          'm-consult-and-guard',
          initialBalance: -50000,
        );
        expect(container.read(walletsProvider), isEmpty);
        expect(container.read(unifiedAiChatProvider).errorMessage, isNotNull);

        // Zero-amount tx draft must not confirm, and cancelGoal/Budget/Bill must mark cancelled.
        final zeroFut = notifier.sendMessage(
          'test zero & cancel',
          surfaceMode: AiSurfaceMode.quickSheet,
        );
        await Future<void>.delayed(Duration.zero);
        final zeroCall = fakeRepo.calls.last;
        zeroCall.controller.add(
          AiFinalResponseEvent(
            sessionId: zeroCall.sessionId,
            clientRequestId: zeroCall.clientRequestId,
            surfaceMode: AiSurfaceMode.quickSheet,
            message: UnifiedAiChatMessage(
              id: 'm-zero-and-cancel',
              sessionId: zeroCall.sessionId,
              text: 'Draf testing.',
              isUser: false,
              transactionDraftGroup: AiTransactionDraftGroup(
                clientMutationId: 'mut-zero',
                items: [
                  AiTransactionDraftItem(
                    title: 'Invalid Zero',
                    amount: 0,
                    type: 'expense',
                    canonicalCategory: 'Others • General Uncategorized',
                    walletId: 'w-1',
                    walletName: 'BCA',
                    occurredAt: DateTime(2026, 11, 18),
                  ),
                ],
              ),
              goalDraft: const AiGoalDraft(
                clientMutationId: 'mut-g-cancel',
                name: 'Dana Liburan',
                targetAmount: 10000000,
              ),
              budgetDraft: const AiBudgetDraft(
                clientMutationId: 'mut-b-cancel',
                category: 'Shopping',
                limitAmount: 1000000,
              ),
              billDraft: const AiBillDraft(
                clientMutationId: 'mut-bill-cancel',
                title: 'Air PDAM',
                amount: 120000,
              ),
            ),
          ),
        );
        await zeroCall.controller.close();
        await zeroFut;

        await notifier.confirmTransactionDraft('m-zero-and-cancel');
        expect(container.read(transactionsProvider), isEmpty);
        final zeroMsg = container
            .read(unifiedAiChatProvider)
            .messages
            .singleWhere((m) => m.id == 'm-zero-and-cancel');
        expect(zeroMsg.transactionDraftGroup!.isConfirmed, isFalse);
        expect(container.read(unifiedAiChatProvider).errorMessage, isNotNull);

        notifier.cancelGoalDraft('m-zero-and-cancel');
        notifier.cancelBudgetDraft('m-zero-and-cancel');
        notifier.cancelBillDraft('m-zero-and-cancel');
        await notifier.confirmGoalDraft('m-zero-and-cancel');
        await notifier.confirmBudgetDraft('m-zero-and-cancel');
        await notifier.confirmBillDraft('m-zero-and-cancel');
        expect(container.read(goalsProvider), isEmpty);
        expect(container.read(budgetsProvider), isEmpty);
        expect(container.read(billsProvider), isEmpty);
        final cancelledMsg = container
            .read(unifiedAiChatProvider)
            .messages
            .singleWhere((m) => m.id == 'm-zero-and-cancel');
        expect(cancelledMsg.goalDraft!.isCancelled, isTrue);
        expect(cancelledMsg.budgetDraft!.isCancelled, isTrue);
        expect(cancelledMsg.billDraft!.isCancelled, isTrue);

        final quotaBeforeBook = container.read(aiQuotaProvider).quotaRemaining;
        notifier.prepareConsultantBooking(consultant, fallbackPackage: package);
        expect(
          container.read(matchExpertProvider).selectedConsultantId,
          equals('c1'),
        );
        final booking = container.read(bookingProvider);
        expect(booking.isPrefilledFromAi, isTrue);
        expect(booking.selectedPackageCode, equals('couple_pre_marriage'));
        expect(booking.totalPrice, equals(349000.0));
        expect(
          booking.prefilledTopics,
          equals(['Keuangan Pranikah', 'Budget Nikah']),
        );
        expect(
          booking.description,
          equals('Ingin merancang rekening pasutri.'),
        );
        expect(
          container.read(aiQuotaProvider).quotaRemaining,
          equals(quotaBeforeBook),
        );

        // 2. Disposal mid-stream must cancel token cleanly without throwing.
        final stream2Fut = notifier.sendMessage(
          'stream saat dispose',
          surfaceMode: AiSurfaceMode.quickSheet,
        );
        await Future<void>.delayed(Duration.zero);
        final call2 = fakeRepo.calls.last;
        container.dispose();
        await stream2Fut;
        expect(call2.cancelToken?.isCancelled, isTrue);
        await call2.controller.close();
      },
    );

    test(
      'ignores trailing AiErrorEvent and stream addError emitted after AiFinalResponseEvent',
      () async {
        final fakeRepo = _ControllableAiChatRepository();
        final container = await _createTestContainer(repository: fakeRepo);
        addTearDown(container.dispose);

        final notifier = container.read(unifiedAiChatProvider.notifier);

        // Part A: Trailing AiErrorEvent & AiThinkingStepEvent via onData after AiFinalResponseEvent.
        final fut1 = notifier.sendMessage(
          'analisa pengeluaran bulan ini',
          surfaceMode: AiSurfaceMode.fullScreen,
        );
        await Future<void>.delayed(Duration.zero);
        final call1 = fakeRepo.calls[0];

        call1.controller.add(
          AiThinkingStepEvent(
            stepNumber: 1,
            id: 'step-1',
            title: 'Mengambil ringkasan',
            status: 'in_progress',
            isDone: false,
            sessionId: call1.sessionId,
            clientRequestId: call1.clientRequestId,
          ),
        );
        call1.controller.add(
          AiFinalResponseEvent(
            sessionId: call1.sessionId,
            clientRequestId: call1.clientRequestId,
            surfaceMode: AiSurfaceMode.fullScreen,
            message: UnifiedAiChatMessage(
              id: 'm-clean-after-eof-err',
              sessionId: call1.sessionId,
              text: 'Ringkasan pengeluaran berhasil disusun.',
              isUser: false,
            ),
          ),
        );
        // Simulate proxy reset caught by RemoteAiChatRepository after final_response flushed.
        call1.controller.add(
          const AiErrorEvent(
            errorCode: 'STREAM_ERROR',
            message: 'Connection reset before TCP EOF',
          ),
        );
        call1.controller.add(
          AiThinkingStepEvent(
            stepNumber: 2,
            id: 'step-late',
            title: 'Langkah terlambat setelah final',
            status: 'completed',
            isDone: true,
            sessionId: call1.sessionId,
            clientRequestId: call1.clientRequestId,
          ),
        );
        await call1.controller.close();
        await fut1;

        final stateAfterPartA = container.read(unifiedAiChatProvider);
        expect(stateAfterPartA.isStreaming, isFalse);
        expect(stateAfterPartA.activeThinkingTrace, isNull);
        expect(stateAfterPartA.errorMessage, isNull);
        expect(stateAfterPartA.messages.length, equals(2));
        expect(
          stateAfterPartA.messages.last.id,
          equals('m-clean-after-eof-err'),
        );
        expect(
          stateAfterPartA.messages.where((m) => m.errorCode != null),
          isEmpty,
        );

        // Part B: Trailing stream onError after AiFinalResponseEvent.
        final fut2 = notifier.sendMessage(
          'cek kondisi dompet',
          surfaceMode: AiSurfaceMode.quickSheet,
        );
        await Future<void>.delayed(Duration.zero);
        final call2 = fakeRepo.calls[1];

        call2.controller.add(
          AiFinalResponseEvent(
            sessionId: call2.sessionId,
            clientRequestId: call2.clientRequestId,
            surfaceMode: AiSurfaceMode.quickSheet,
            message: UnifiedAiChatMessage(
              id: 'm-clean-after-onerror',
              sessionId: call2.sessionId,
              text: 'Semua dompet terpantau sehat.',
              isUser: false,
            ),
          ),
        );
        call2.controller.addError(StateError('Socket closed unexpectedly'));
        await call2.controller.close();
        await fut2;

        final stateAfterPartB = container.read(unifiedAiChatProvider);
        expect(stateAfterPartB.isStreaming, isFalse);
        expect(stateAfterPartB.activeThinkingTrace, isNull);
        expect(stateAfterPartB.errorMessage, isNull);
        expect(stateAfterPartB.messages.length, equals(4));
        expect(
          stateAfterPartB.messages.last.id,
          equals('m-clean-after-onerror'),
        );
        expect(
          stateAfterPartB.messages.where((m) => m.errorCode != null),
          isEmpty,
        );
      },
    );

    test(
      'rejects [25000, 0] transaction batch and non-finite amounts across tx, goal, budget, and bill drafts before .round() or provider mutation',
      () async {
        var remoteCalls = 0;
        final adapter = _FakeHttpClientAdapter((options, _, _) async {
          if (options.method == 'GET' && options.path == '/v1/wallets') {
            throw StateError('Pre-chat initial sync skipped in invalid-draft test');
          }
          remoteCalls++;
          throw StateError(
            'Remote sync must not be called for invalid draft: ${options.path}',
          );
        });
        final apiConfig = ClarafinApiConfig.fromUrl('http://127.0.0.1:8080');
        final dio = Dio(BaseOptions(baseUrl: apiConfig.normalizedBaseUrl));
        dio.httpClientAdapter = adapter;
        final syncService = TrackerRemoteSyncService(
          client: ClarafinApiClient(
            config: apiConfig,
            dio: dio,
            accessToken: 'test_jwt',
          ),
        );

        final gopay = WalletModel(
          id: 'w-gopay',
          name: 'GoPay',
          type: 'E-Wallet',
          balance: 250000,
          institutionId: 'gopay',
        );
        final fakeRepo = _ControllableAiChatRepository();
        final container = await _createTestContainer(
          repository: fakeRepo,
          initialWallets: [gopay],
          apiConfig: apiConfig,
          remoteSyncService: syncService,
        );
        addTearDown(container.dispose);

        final notifier = container.read(unifiedAiChatProvider.notifier);

        Future<void> emitDraftMessage(UnifiedAiChatMessage msg) async {
          final fut = notifier.sendMessage(
            'draft ${msg.id}',
            surfaceMode: AiSurfaceMode.quickSheet,
          );
          await Future<void>.delayed(const Duration(milliseconds: 10));
          final call = fakeRepo.calls.last;
          call.controller.add(
            AiFinalResponseEvent(
              sessionId: call.sessionId,
              clientRequestId: call.clientRequestId,
              surfaceMode: AiSurfaceMode.quickSheet,
              message: msg,
            ),
          );
          await call.controller.close();
          await fut;
        }

        // 1. Mixed [25000, 0] tx batch must reject the entire group without silent partial commit.
        await emitDraftMessage(
          UnifiedAiChatMessage(
            id: 'm-tx-mixed-zero',
            sessionId: container.read(unifiedAiChatProvider).sessionId,
            text: 'Draf campuran 25rb dan 0',
            isUser: false,
            transactionDraftGroup: AiTransactionDraftGroup(
              clientMutationId: 'mut-mixed-zero',
              items: [
                AiTransactionDraftItem(
                  title: 'Kopi',
                  amount: 25000,
                  type: 'expense',
                  canonicalCategory: 'Food & Beverage • Coffee Shop',
                  walletId: 'w-gopay',
                  walletName: 'GoPay',
                  occurredAt: DateTime(2026, 11, 18),
                ),
                AiTransactionDraftItem(
                  title: 'Parkir Nol',
                  amount: 0,
                  type: 'expense',
                  canonicalCategory: 'Transportation • Parking & Toll',
                  walletId: 'w-gopay',
                  walletName: 'GoPay',
                  occurredAt: DateTime(2026, 11, 18),
                ),
              ],
            ),
          ),
        );
        await notifier.confirmTransactionDraft('m-tx-mixed-zero');
        expect(container.read(transactionsProvider), isEmpty);
        expect(container.read(walletsProvider).single.balance, equals(250000));
        expect(
          container
              .read(unifiedAiChatProvider)
              .messages
              .singleWhere((m) => m.id == 'm-tx-mixed-zero')
              .transactionDraftGroup!
              .isConfirmed,
          isFalse,
        );
        expect(container.read(unifiedAiChatProvider).errorMessage, isNotNull);

        // 2. Non-finite double.infinity tx item must be rejected before .round().
        await emitDraftMessage(
          UnifiedAiChatMessage(
            id: 'm-tx-inf',
            sessionId: container.read(unifiedAiChatProvider).sessionId,
            text: 'Draf infinity',
            isUser: false,
            transactionDraftGroup: AiTransactionDraftGroup(
              clientMutationId: 'mut-tx-inf',
              items: [
                AiTransactionDraftItem(
                  title: 'Infinity Tx',
                  amount: double.infinity,
                  type: 'expense',
                  canonicalCategory: 'Others • General Uncategorized',
                  walletId: 'w-gopay',
                  walletName: 'GoPay',
                  occurredAt: DateTime(2026, 11, 18),
                ),
              ],
            ),
          ),
        );
        await notifier.confirmTransactionDraft('m-tx-inf');
        expect(container.read(transactionsProvider), isEmpty);
        expect(
          container
              .read(unifiedAiChatProvider)
              .messages
              .singleWhere((m) => m.id == 'm-tx-inf')
              .transactionDraftGroup!
              .isConfirmed,
          isFalse,
        );
        expect(container.read(unifiedAiChatProvider).errorMessage, isNotNull);

        // 3. Non-finite goal, budget, and bill amounts must be rejected before .round().
        await emitDraftMessage(
          UnifiedAiChatMessage(
            id: 'm-goal-inf',
            sessionId: container.read(unifiedAiChatProvider).sessionId,
            text: 'Goal infinity',
            isUser: false,
            goalDraft: const AiGoalDraft(
              clientMutationId: 'mut-goal-inf',
              name: 'Dana Darurat',
              targetAmount: double.infinity,
            ),
          ),
        );
        await notifier.confirmGoalDraft('m-goal-inf');
        expect(container.read(goalsProvider), isEmpty);
        expect(container.read(unifiedAiChatProvider).errorMessage, isNotNull);

        await emitDraftMessage(
          UnifiedAiChatMessage(
            id: 'm-budget-inf',
            sessionId: container.read(unifiedAiChatProvider).sessionId,
            text: 'Budget infinity',
            isUser: false,
            budgetDraft: const AiBudgetDraft(
              clientMutationId: 'mut-budget-inf',
              category: 'Food & Beverage',
              limitAmount: double.infinity,
            ),
          ),
        );
        await notifier.confirmBudgetDraft('m-budget-inf');
        expect(container.read(budgetsProvider), isEmpty);
        expect(container.read(unifiedAiChatProvider).errorMessage, isNotNull);

        await emitDraftMessage(
          UnifiedAiChatMessage(
            id: 'm-bill-inf',
            sessionId: container.read(unifiedAiChatProvider).sessionId,
            text: 'Bill infinity',
            isUser: false,
            billDraft: const AiBillDraft(
              clientMutationId: 'mut-bill-inf',
              title: 'Listrik',
              amount: double.infinity,
            ),
          ),
        );
        await notifier.confirmBillDraft('m-bill-inf');
        expect(container.read(billsProvider), isEmpty);
        expect(container.read(unifiedAiChatProvider).errorMessage, isNotNull);

        expect(remoteCalls, equals(0));
      },
    );

    test(
      'normalizes uppercase/padded item.type (" TRANSFER ") during confirmTransactionDraft',
      () async {
        final gopay = WalletModel(
          id: 'w-gopay',
          name: 'GoPay',
          type: 'E-Wallet',
          balance: 250000,
          institutionId: 'gopay',
        );
        final bca = WalletModel(
          id: 'w-bca',
          name: 'BCA Utama',
          type: 'Bank',
          balance: 1000000,
          institutionId: 'bca',
        );
        final fakeRepo = _ControllableAiChatRepository();
        final container = await _createTestContainer(
          repository: fakeRepo,
          initialWallets: [gopay, bca],
        );
        addTearDown(container.dispose);

        final notifier = container.read(unifiedAiChatProvider.notifier);
        final fut = notifier.sendMessage(
          'transfer 50rb dari gopay ke bca',
          surfaceMode: AiSurfaceMode.quickSheet,
        );
        await Future<void>.delayed(Duration.zero);
        final call = fakeRepo.calls.single;
        call.controller.add(
          AiFinalResponseEvent(
            sessionId: call.sessionId,
            clientRequestId: call.clientRequestId,
            surfaceMode: AiSurfaceMode.quickSheet,
            message: UnifiedAiChatMessage(
              id: 'm-transfer-upper',
              sessionId: call.sessionId,
              text: 'Draf transfer siap.',
              isUser: false,
              transactionDraftGroup: AiTransactionDraftGroup(
                clientMutationId: 'mut-transfer-upper',
                items: [
                  AiTransactionDraftItem(
                    title: 'Transfer GoPay ke BCA',
                    amount: 50000,
                    type: ' TRANSFER ',
                    canonicalCategory: 'Transfer',
                    walletId: 'w-gopay',
                    walletName: 'GoPay',
                    targetWalletId: 'BCA Utama',
                    occurredAt: DateTime(2026, 11, 18),
                  ),
                ],
              ),
            ),
          ),
        );
        await call.controller.close();
        await fut;

        await notifier.confirmTransactionDraft('m-transfer-upper');
        final savedTx = container.read(transactionsProvider).single;
        expect(savedTx.type, equals('transfer'));
        expect(savedTx.category, equals('Transfer'));
        expect(savedTx.targetWalletId, equals('w-bca'));

        final wallets = container.read(walletsProvider);
        expect(
          wallets.singleWhere((w) => w.id == 'w-gopay').balance,
          equals(200000.0),
        );
        expect(
          wallets.singleWhere((w) => w.id == 'w-bca').balance,
          equals(1050000.0),
        );
      },
    );
  });

  group('Review Focus #8: Go-Flutter Wire Contract & Pre-Chat Snapshot Sync', () {
    test(
      'tapping remote UUID typo-recovery wallet chip resolves local BCA wallet by name/institution and rebinds Go pending_items',
      () async {
        const remoteBcaUuid = '11111111-2222-4333-8444-555555555555';
        final localBca = WalletModel(
          id: 'w-local-bca',
          name: 'BCA Tabungan',
          type: 'Bank',
          balance: 2000000,
          institutionId: 'bca',
        );
        final fakeRepo = _ControllableAiChatRepository();
        final container = await _createTestContainer(
          repository: fakeRepo,
          initialWallets: [localBca],
        );
        addTearDown(container.dispose);

        final notifier = container.read(unifiedAiChatProvider.notifier);
        final sendFuture = notifier.sendMessage(
          'makan siang pake bank jago',
          surfaceMode: AiSurfaceMode.quickSheet,
        );
        await Future<void>.delayed(Duration.zero);

        final call = fakeRepo.calls.single;
        final rawGoResponse = UnifiedAiChatMessage.fromJson({
          'id': 'msg-go-missing-wallet',
          'session_id': call.sessionId,
          'narrative': 'Dompet Bank Jago belum terdaftar di akunmu.',
          'thinking_summary': [
            {
              'step_number': 1,
              'title': 'Cek dompet Bank Jago',
              'detail': 'Tidak ditemukan, menampilkan opsi dompet aktif',
              'status': 'completed',
            },
          ],
          'wallet_creation_draft': {
            'institution_id': 'jago',
            'institution_name': 'Bank Jago',
            'institution_type': 'bank',
            'existing_wallets': [
              {
                'id': remoteBcaUuid,
                'name': 'BCA',
                'type': 'bank',
                'institution_code': 'bca',
                'balance_idr': 2000000,
              },
            ],
            'pending_items': [
              {
                'title': 'Makan Siang Spesial',
                'amount_idr': 65000,
                'type': 'expense',
                'canonical_category': 'Food & Beverage • Restaurant / Dining',
                'canonical_main_category': 'Food & Beverage',
              },
            ],
          },
          'transaction_draft': null,
        });

        call.controller.add(
          AiFinalResponseEvent(
            sessionId: call.sessionId,
            clientRequestId: call.clientRequestId,
            surfaceMode: AiSurfaceMode.quickSheet,
            message: rawGoResponse,
          ),
        );
        await call.controller.close();
        await sendFuture;

        final assistantMsg = container
            .read(unifiedAiChatProvider)
            .messages
            .lastWhere((m) => !m.isUser);
        expect(assistantMsg.transactionDraftGroup, isNull);
        expect(assistantMsg.walletCreationDraft, isNotNull);

        final existingNames =
            assistantMsg.walletCreationDraft!.existingWalletNames;
        expect(existingNames[remoteBcaUuid], equals('BCA'));

        // Verify resolveChatWalletLabel returns local wallet name instead of raw UUID.
        final label = resolveChatWalletLabel(
          container.read(walletsProvider),
          remoteBcaUuid,
          existingWalletNames: existingNames,
        );
        expect(label, equals('BCA Tabungan'));

        // Simulate tapping the remote UUID chip via matchChatLocalWallet or remote WalletModel.
        final matchedLocal = matchChatLocalWallet(
          container.read(walletsProvider),
          remoteBcaUuid,
          existingWalletNames: existingNames,
        );
        expect(matchedLocal, isNotNull);
        expect(matchedLocal!.id, equals('w-local-bca'));

        notifier.selectExistingWalletForPendingTx(
          assistantMsg.id,
          WalletModel(
            id: remoteBcaUuid,
            name: 'BCA',
            type: 'Bank',
            balance: 2000000,
          ),
        );

        final reboundMsg = container
            .read(unifiedAiChatProvider)
            .messages
            .lastWhere((m) => !m.isUser);
        expect(reboundMsg.transactionDraftGroup, isNotNull);
        final reboundItem = reboundMsg.transactionDraftGroup!.items.single;
        expect(reboundItem.title, equals('Makan Siang Spesial'));
        expect(reboundItem.amount, equals(65000.0));
        expect(
          reboundItem.canonicalCategory,
          equals('Food & Beverage • Restaurant / Dining'),
        );
        expect(reboundItem.walletId, equals('w-local-bca'));
        expect(reboundItem.walletName, equals('BCA Tabungan'));
      },
    );

    test(
      'pre-chat syncInitialSnapshot runs when isRemoteEnabled is true and reconciles wallet balances after syncing transactions',
      () async {
        const remoteWalletUuid = 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee';
        final localBca = WalletModel(
          id: 'w-bca-local',
          name: 'BCA',
          type: 'Bank',
          balance: 1950000,
          institutionId: 'bca',
        );
        final httpCalls = <String>[];
        int? patchedBalance;

        final adapter = _FakeHttpClientAdapter((options, _, _) async {
          httpCalls.add('${options.method} ${options.path}');
          if (options.method == 'GET' && options.path == '/v1/wallets') {
            return ResponseBody.fromString(
              jsonEncode({
                'data': {'wallets': <dynamic>[], 'total_balance_idr': 0},
              }),
              200,
              headers: {
                Headers.contentTypeHeader: ['application/json'],
              },
            );
          }
          if (options.method == 'POST' && options.path == '/v1/wallets') {
            final body =
                jsonDecode(jsonEncode(options.data)) as Map<String, dynamic>;
            return ResponseBody.fromString(
              jsonEncode({
                'data': {
                  'id': remoteWalletUuid,
                  'name': body['name'],
                  'type': body['type'],
                  'institution_code': body['institution_code'],
                  'balance': body['balance'],
                },
              }),
              201,
              headers: {
                Headers.contentTypeHeader: ['application/json'],
              },
            );
          }
          if (options.method == 'POST' && options.path == '/v1/transactions') {
            final body =
                jsonDecode(jsonEncode(options.data)) as Map<String, dynamic>;
            return ResponseBody.fromString(
              jsonEncode({
                'data': {
                  'transaction': {
                    'id': '77777777-7777-4777-8777-777777777777',
                    'wallet_id': remoteWalletUuid,
                    'type': body['type'],
                    'category': body['category'],
                    'amount': body['amount'],
                    'title': body['title'],
                  },
                  'idempotent_replay': false,
                  'wallet_balance_idr': 1900000,
                },
              }),
              201,
              headers: {
                Headers.contentTypeHeader: ['application/json'],
              },
            );
          }
          if (options.method == 'PATCH' &&
              options.path == '/v1/wallets/$remoteWalletUuid') {
            final body =
                jsonDecode(jsonEncode(options.data)) as Map<String, dynamic>;
            patchedBalance = (body['balance'] as num?)?.toInt();
            return ResponseBody.fromString(
              jsonEncode({
                'data': {
                  'id': remoteWalletUuid,
                  'name': body['name'],
                  'type': body['type'],
                  'institution_code': body['institution_code'],
                  'balance': body['balance'],
                },
              }),
              200,
              headers: {
                Headers.contentTypeHeader: ['application/json'],
              },
            );
          }
          if (options.method == 'GET' && options.path == '/v1/goals') {
            return ResponseBody.fromString(
              jsonEncode({
                'data': {'goals': <dynamic>[]},
              }),
              200,
              headers: {
                Headers.contentTypeHeader: ['application/json'],
              },
            );
          }
          if (options.method == 'GET' && options.path == '/v1/bills') {
            return ResponseBody.fromString(
              jsonEncode({
                'data': {'bills': <dynamic>[]},
              }),
              200,
              headers: {
                Headers.contentTypeHeader: ['application/json'],
              },
            );
          }
          throw StateError('Unexpected request: ${options.method} ${options.path}');
        });

        final apiConfig = ClarafinApiConfig.fromUrl('http://127.0.0.1:8080');
        final dio = Dio(BaseOptions(baseUrl: apiConfig.normalizedBaseUrl));
        dio.httpClientAdapter = adapter;
        final apiClient = ClarafinApiClient(
          config: apiConfig,
          dio: dio,
          accessToken: 'jwt_prechat_test',
        );
        final syncService = TrackerRemoteSyncService(
          client: apiClient,
          storageScopeKey: 'raka@clarafin.test',
        );

        final fakeRepo = _ControllableAiChatRepository();
        final container = await _createTestContainer(
          repository: fakeRepo,
          initialWallets: [localBca],
          apiConfig: apiConfig,
          remoteSyncService: syncService,
        );
        addTearDown(container.dispose);

        container.read(transactionsProvider.notifier).addTransaction(
              TransactionModel(
                id: 'tx_hist_1',
                title: 'Kopi Pagi',
                category: 'Food & Beverage • Coffee Shop',
                amount: 50000,
                date: DateTime(2026, 11, 18, 8, 0),
                type: 'expense',
                walletId: 'w-bca-local',
              ),
            );

        final notifier = container.read(unifiedAiChatProvider.notifier);
        final sendFuture = notifier.sendMessage(
          'cek saldo dompetku',
          surfaceMode: AiSurfaceMode.quickSheet,
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(fakeRepo.calls.length, equals(1));
        final call = fakeRepo.calls.single;
        call.controller.add(
          AiFinalResponseEvent(
            sessionId: call.sessionId,
            clientRequestId: call.clientRequestId,
            surfaceMode: AiSurfaceMode.quickSheet,
            message: UnifiedAiChatMessage(
              id: 'm-synced-reply',
              sessionId: call.sessionId,
              text: 'Saldo BCA kamu Rp 1.950.000.',
              isUser: false,
            ),
          ),
        );
        await call.controller.close();
        await sendFuture;

        expect(httpCalls, contains('GET /v1/wallets'));
        expect(httpCalls, contains('POST /v1/wallets'));
        expect(httpCalls, contains('POST /v1/transactions'));
        expect(
          httpCalls,
          contains('PATCH /v1/wallets/$remoteWalletUuid'),
        );
        expect(patchedBalance, equals(1900000));
      },
    );
  });

  group('Balance Guard & Per-Wallet Receipt Splitting', () {
    test(
      'confirmTransactionDraft blocks -Rp 30.000 overdraft when GoPay balance is Rp 0',
      () async {
        final fakeRepo = _ControllableAiChatRepository();
        final container = await _createTestContainer(
          repository: fakeRepo,
          initialWallets: [
            WalletModel(
              id: 'w-gopay',
              name: 'GoPay',
              type: 'E-Wallet',
              balance: 0,
              institutionId: 'gopay',
            ),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(unifiedAiChatProvider.notifier);
        final sendFuture = notifier.sendMessage(
          'kopi kenangan 25k + parkir 5k pake gopay',
          surfaceMode: AiSurfaceMode.quickSheet,
        );
        await Future<void>.delayed(Duration.zero);

        final call = fakeRepo.calls.single;
        call.controller.add(
          AiFinalResponseEvent(
            sessionId: call.sessionId,
            clientRequestId: call.clientRequestId,
            surfaceMode: AiSurfaceMode.quickSheet,
            message: UnifiedAiChatMessage(
              id: 'm-overdraft',
              sessionId: call.sessionId,
              text: 'Ini struknya.',
              isUser: false,
              transactionDraftGroup: AiTransactionDraftGroup(
                clientMutationId: 'mut-overdraft',
                items: [
                  AiTransactionDraftItem(
                    title: 'Kopi Kenangan',
                    amount: 25000,
                    type: 'expense',
                    canonicalCategory: 'Food & Beverage • Coffee Shop',
                    walletId: 'w-gopay',
                    walletName: 'GoPay',
                    occurredAt: DateTime(2026, 11, 18),
                  ),
                  AiTransactionDraftItem(
                    title: 'Parkir',
                    amount: 5000,
                    type: 'expense',
                    canonicalCategory: 'Transportation • Parking & Toll',
                    walletId: 'w-gopay',
                    walletName: 'GoPay',
                    occurredAt: DateTime(2026, 11, 18),
                  ),
                ],
              ),
            ),
          ),
        );
        await call.controller.close();
        await sendFuture;

        await notifier.confirmTransactionDraft('m-overdraft');

        final st = container.read(unifiedAiChatProvider);
        expect(st.messages.last.transactionDraftGroup!.isConfirmed, isFalse);
        expect(
          st.errorMessage,
          equals(
            'Saldo GoPay (Rp 0) tidak mencukupi untuk transaksi Rp 30.000. '
            'Silakan ubah saldo dompet atau pilih dompet lain via Edit Rinci.',
          ),
        );
        expect(container.read(walletsProvider).single.balance, equals(0));
        expect(container.read(transactionsProvider), isEmpty);
      },
    );

    test(
      'keeps same-wallet items in 1 Struk group and splits cross-wallet items into 2 independent Struk groups',
      () async {
        final fakeRepo = _ControllableAiChatRepository();
        final container = await _createTestContainer(
          repository: fakeRepo,
          initialWallets: [
            WalletModel(
              id: 'w-cash',
              name: 'Cash',
              type: 'Cash',
              balance: 100000,
            ),
            WalletModel(
              id: 'w-gopay',
              name: 'GoPay',
              type: 'E-Wallet',
              balance: 500000,
              institutionId: 'gopay',
            ),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(unifiedAiChatProvider.notifier);

        // 1. Same-wallet items -> 1 group
        final sameFuture = notifier.sendMessage(
          'kopi 20k + roti 15k pake cash',
          surfaceMode: AiSurfaceMode.quickSheet,
        );
        await Future<void>.delayed(Duration.zero);
        final c1 = fakeRepo.calls.last;
        c1.controller.add(
          AiFinalResponseEvent(
            sessionId: c1.sessionId,
            clientRequestId: c1.clientRequestId,
            surfaceMode: AiSurfaceMode.quickSheet,
            message: UnifiedAiChatMessage(
              id: 'm-same',
              sessionId: c1.sessionId,
              text: '1 struk Cash.',
              isUser: false,
              transactionDraftGroup: AiTransactionDraftGroup(
                clientMutationId: 'mut-same',
                items: [
                  AiTransactionDraftItem(
                    title: 'Kopi',
                    amount: 20000,
                    type: 'expense',
                    canonicalCategory: 'Food & Beverage • Coffee Shop',
                    walletId: 'w-cash',
                    walletName: 'Cash',
                    occurredAt: DateTime(2026, 11, 18),
                  ),
                  AiTransactionDraftItem(
                    title: 'Roti',
                    amount: 15000,
                    type: 'expense',
                    canonicalCategory: 'Food & Beverage • Snacks',
                    walletId: 'w-cash',
                    walletName: 'Cash',
                    occurredAt: DateTime(2026, 11, 18),
                  ),
                ],
              ),
            ),
          ),
        );
        await c1.controller.close();
        await sameFuture;

        final sameMsg = container.read(unifiedAiChatProvider).messages.last;
        expect(sameMsg.transactionDraftGroups.length, equals(1));
        expect(sameMsg.transactionDraftGroups.first.items.length, equals(2));

        // 2. Cross-wallet items -> 2 independent groups
        final splitFuture = notifier.sendMessage(
          'beli kopi 25k pake cash dan beli baju 150k pake gopay',
          surfaceMode: AiSurfaceMode.quickSheet,
        );
        await Future<void>.delayed(Duration.zero);
        final c2 = fakeRepo.calls.last;
        c2.controller.add(
          AiFinalResponseEvent(
            sessionId: c2.sessionId,
            clientRequestId: c2.clientRequestId,
            surfaceMode: AiSurfaceMode.quickSheet,
            message: UnifiedAiChatMessage(
              id: 'm-cross',
              sessionId: c2.sessionId,
              text: '2 struk per dompet.',
              isUser: false,
              transactionDraftGroup: AiTransactionDraftGroup(
                clientMutationId: 'mut-cross',
                items: [
                  AiTransactionDraftItem(
                    title: 'Kopi',
                    amount: 25000,
                    type: 'expense',
                    canonicalCategory: 'Food & Beverage • Coffee Shop',
                    walletId: 'w-cash',
                    walletName: 'Cash',
                    occurredAt: DateTime(2026, 11, 18),
                  ),
                  AiTransactionDraftItem(
                    title: 'Baju',
                    amount: 150000,
                    type: 'expense',
                    canonicalCategory: 'Lifestyle • Shopping',
                    walletId: 'w-gopay',
                    walletName: 'GoPay',
                    occurredAt: DateTime(2026, 11, 18),
                  ),
                ],
              ),
            ),
          ),
        );
        await c2.controller.close();
        await splitFuture;

        final crossMsg = container.read(unifiedAiChatProvider).messages.last;
        expect(crossMsg.transactionDraftGroups.length, equals(2));
        expect(crossMsg.transactionDraftGroups[0].items.single.walletId, equals('w-cash'));
        expect(crossMsg.transactionDraftGroups[1].items.single.walletId, equals('w-gopay'));

        // Confirm group 0 (Cash) and cancel group 1 (GoPay) independently
        await notifier.confirmTransactionDraft('m-cross', groupIndex: 0);
        notifier.cancelTransactionDraft('m-cross', groupIndex: 1);

        final updatedCross = container.read(unifiedAiChatProvider).messages.last;
        expect(updatedCross.transactionDraftGroups[0].isConfirmed, isTrue);
        expect(updatedCross.transactionDraftGroups[0].isCancelled, isFalse);
        expect(updatedCross.transactionDraftGroups[1].isConfirmed, isFalse);
        expect(updatedCross.transactionDraftGroups[1].isCancelled, isTrue);

        final walletsAfter = container.read(walletsProvider);
        expect(walletsAfter.firstWhere((w) => w.id == 'w-cash').balance, equals(75000));
        expect(walletsAfter.firstWhere((w) => w.id == 'w-gopay').balance, equals(500000));
      },
    );

    test(
      'confirmWalletCreation reuses existing GoPay in walletsProvider instead of creating a duplicate GoPay',
      () async {
        final fakeRepo = _ControllableAiChatRepository();
        final container = await _createTestContainer(
          repository: fakeRepo,
          initialWallets: [
            WalletModel(
              id: 'w-existing-gopay',
              name: 'GoPay',
              type: 'E-Wallet',
              balance: 300000,
              institutionId: 'gopay',
            ),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(unifiedAiChatProvider.notifier);
        final sendFuture = notifier.sendMessage(
          'beli kopi 25rb pake gopay',
          surfaceMode: AiSurfaceMode.quickSheet,
        );
        await Future<void>.delayed(Duration.zero);
        final call = fakeRepo.calls.last;
        call.controller.add(
          AiFinalResponseEvent(
            sessionId: call.sessionId,
            clientRequestId: call.clientRequestId,
            surfaceMode: AiSurfaceMode.quickSheet,
            message: UnifiedAiChatMessage(
              id: 'msg-dup-gopay',
              sessionId: call.sessionId,
              text: 'Silakan buat dompet GoPay.',
              isUser: false,
              walletCreationDraft: const AiWalletCreationDraft(
                institutionId: 'gopay',
                institutionName: 'gopay',
                walletType: 'E-Wallet',
              ),
            ),
          ),
        );
        await call.controller.close();
        await sendFuture;

        final msg = container
            .read(unifiedAiChatProvider)
            .messages
            .lastWhere((m) => !m.isUser);
        await notifier.confirmWalletCreation(msg.id, initialBalance: 100000);

        final walletsAfter = container.read(walletsProvider);
        expect(walletsAfter.length, equals(1));
        expect(walletsAfter.single.id, equals('w-existing-gopay'));
        expect(walletsAfter.single.balance, equals(300000));

        final updatedMsg = container
            .read(unifiedAiChatProvider)
            .messages
            .singleWhere((m) => m.id == msg.id);
        expect(updatedMsg.walletCreationDraft!.isCreated, isTrue);
        expect(
          updatedMsg.walletCreationDraft!.createdWalletId,
          equals('w-existing-gopay'),
        );
        expect(updatedMsg.transactionDraftGroup, isNotNull);
        expect(
          updatedMsg.transactionDraftGroup!.items.single.walletId,
          equals('w-existing-gopay'),
        );
        expect(
          updatedMsg.transactionDraftGroup!.items.single.walletName,
          equals('GoPay'),
        );
      },
    );
  });
}
