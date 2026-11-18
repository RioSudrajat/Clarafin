import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/models/wallet_model.dart';
import 'package:mobile/core/providers/ai_quota_provider.dart';
import 'package:mobile/core/services/local_storage_service.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/consult/presentation/providers/booking_provider.dart';
import 'package:mobile/features/session/data/ai_chat_repository.dart';
import 'package:mobile/features/session/domain/models/ai_chat_models.dart';
import 'package:mobile/features/session/presentation/providers/unified_ai_chat_provider.dart';
import 'package:mobile/features/session/presentation/screens/ai_chat_screen.dart';
import 'package:mobile/features/session/presentation/screens/quick_action_sheets.dart';
import 'package:mobile/features/session/presentation/widgets/ai_chat_bubble.dart';
import 'package:mobile/features/session/presentation/widgets/ai_money_flow_card.dart';
import 'package:mobile/features/session/presentation/widgets/ai_planning_action_card.dart';
import 'package:mobile/features/session/presentation/widgets/ai_recommended_consultants_section.dart';
import 'package:mobile/features/session/presentation/widgets/ai_spending_breakdown_table_card.dart';
import 'package:mobile/features/session/presentation/widgets/ai_thinking_trace_widget.dart';
import 'package:mobile/features/session/presentation/widgets/ai_transaction_draft_card.dart';
import 'package:mobile/features/session/presentation/widgets/ai_wallet_creation_draft_card.dart';
import 'package:mobile/features/session/presentation/widgets/clarafin_ai_quick_sheet.dart';
import 'package:mobile/router/app_router.dart';
import 'package:mobile/shared/widgets/saas_upgrade_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ScriptedAiChatRepository implements AiChatRepository {
  final List<Stream<AiSseEvent> Function(String prompt, AiSurfaceMode mode)>
      handlers;
  final List<({String prompt, AiSurfaceMode mode})> recordedCalls = [];
  int _index = 0;

  _ScriptedAiChatRepository(this.handlers);

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
    recordedCalls.add((prompt: prompt, mode: surfaceMode));
    final handler = handlers[_index < handlers.length ? _index : handlers.length - 1];
    _index++;
    return handler(prompt, surfaceMode);
  }
}

Future<ProviderContainer> _createSurfaceContainer({
  AiChatRepository? repository,
  List<WalletModel>? wallets,
}) async {
  const userId = 'u_surface_55';
  final userMap = {
    'id': userId,
    'name': 'Raka Surface',
    'email': 'raka@clarafin.test',
    'password': 'secret',
    'avatarUrl': 'assets/images/avatars/avatar_1.png',
  };
  final seededWallets = wallets ??
      [
        WalletModel(
          id: 'w_bca',
          name: 'BCA Utama',
          type: 'Bank',
          balance: 2000000,
          institutionId: 'bca',
        ),
        WalletModel(
          id: 'w_gopay',
          name: 'GoPay',
          type: 'E-Wallet',
          balance: 350000,
          institutionId: 'gopay',
        ),
      ];

  SharedPreferences.setMockInitialValues({
    'clarafin_registered_accounts': [jsonEncode(userMap)],
    'clarafin_is_logged_in': true,
    'clarafin_active_user_id': userId,
    'clarafin_wallets_$userId':
        seededWallets.map((w) => jsonEncode(w.toJson())).toList(),
    'clarafin_transactions_$userId': <String>[],
  });
  final prefs = await SharedPreferences.getInstance();

  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      if (repository != null) aiChatRepositoryProvider.overrideWithValue(repository),
    ],
  );
}

void _assertNoSlopUi(WidgetTester tester) {
  expect(find.byIcon(Icons.smart_toy_rounded), findsNothing);
  expect(find.byIcon(Icons.smart_toy_outlined), findsNothing);
  expect(find.byIcon(Icons.auto_awesome), findsNothing);
  for (final textWidget in tester.widgetList<Text>(find.byType(Text))) {
    final value = textWidget.data ?? textWidget.textSpan?.toPlainText() ?? '';
    expect(value.contains('\u2014'), isFalse, reason: 'Em dash forbidden: $value');
    expect(value.contains('🤖'), isFalse, reason: 'Robot emoji forbidden: $value');
    expect(value.contains('🚀'), isFalse, reason: 'Rocket emoji forbidden: $value');
  }
}

void _assertHitTargetMin44(WidgetTester tester, Key key) {
  final finder = find.byKey(key);
  expect(finder, findsOneWidget, reason: 'Missing widget for $key');
  final size = tester.getSize(finder);
  expect(size.width, greaterThanOrEqualTo(44.0), reason: '$key width < 44: ${size.width}');
  expect(size.height, greaterThanOrEqualTo(44.0), reason: '$key height < 44: ${size.height}');
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Task 5.5 Unified Clarafin AI Surface', () {
    testWidgets('AiChatScreen renders Clarafin AI header, Online, [40/40], New Chat, and suggested prompts', (tester) async {
      final container = await _createSurfaceContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AiChatScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Clarafin AI'), findsWidgets);
      expect(find.text('Online'), findsOneWidget);
      expect(find.text('40/40'), findsOneWidget);
      expect(find.byIcon(Icons.flash_on_rounded), findsOneWidget);
      expect(find.byKey(const Key('ai_chat_new_chat_btn')), findsOneWidget);
      expect(find.byKey(const Key('ai_chat_quota_badge')), findsOneWidget);
      expect(find.byKey(const Key('ai_input_scan_btn')), findsOneWidget);
      expect(find.byKey(const Key('ai_input_voice_btn')), findsOneWidget);
      expect(find.text('Tanya Clarafin AI...'), findsOneWidget);
      _assertNoSlopUi(tester);

      await tester.tap(find.byKey(const Key('ai_chat_quota_badge')));
      await tester.pumpAndSettle();
      expect(find.byType(SaasUpgradeBottomSheet), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    });

    testWidgets('Quick Sheet multi-item draft -> Lanjutkan di Layar Penuh -> AiChatScreen preserves thread -> New Chat resets at 0 quota cost', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = await _createSurfaceContainer();

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: Consumer(
                builder: (context, ref, _) => ElevatedButton(
                  onPressed: () => showAiChatQuickSheet(context, ref),
                  child: const Text('Buka Quick Sheet'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/ai-chat',
            builder: (context, state) => const AiChatScreen(),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buka Quick Sheet'));
      await tester.pumpAndSettle();

      expect(find.byType(ClarafinAiQuickSheet), findsOneWidget);
      expect(find.byKey(const Key('ai_chat_expand_btn')), findsOneWidget);
      expect(find.byKey(const Key('ai_chat_close_btn')), findsOneWidget);
      expect(find.byKey(const Key('ai_chat_expand_pill')), findsNothing);

      await tester.enterText(
        find.byKey(const Key('ai_input_text_field')),
        'kopi kenangan 25k + parkir goceng pake gopay',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('ai_input_send_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(AiThinkingTraceWidget), findsOneWidget);
      expect(find.byType(AiTransactionDraftCard), findsOneWidget);
      expect(find.text('Draf Transaksi (2 item)'), findsOneWidget);
      expect(find.text('Food & Beverage • Coffee Shop'), findsOneWidget);
      expect(find.text('Transportation • Parking & Toll'), findsOneWidget);
      expect(find.byKey(const Key('ai_chat_expand_pill')), findsOneWidget);
      expect(find.text('Lanjutkan di Layar Penuh'), findsOneWidget);

      final sessionIdBeforeExpand = container.read(unifiedAiChatProvider).sessionId;
      final quotaAfterTurn = container.read(aiQuotaProvider).quotaRemaining;
      expect(quotaAfterTurn, equals(39));

      await tester.tap(find.byKey(const Key('ai_chat_expand_pill')));
      await tester.pumpAndSettle();

      expect(find.byType(AiChatScreen), findsOneWidget);
      expect(find.byType(ClarafinAiQuickSheet), findsNothing);
      expect(
        container.read(unifiedAiChatProvider).sessionId,
        equals(sessionIdBeforeExpand),
      );
      expect(find.byType(AiTransactionDraftCard), findsOneWidget);
      expect(find.text('Draf Transaksi (2 item)'), findsOneWidget);

      await tester.tap(find.byKey(const Key('ai_chat_new_chat_btn')));
      await tester.pumpAndSettle();

      expect(container.read(unifiedAiChatProvider).messages, isEmpty);
      expect(
        container.read(unifiedAiChatProvider).sessionId,
        isNot(equals(sessionIdBeforeExpand)),
      );
      expect(container.read(aiQuotaProvider).quotaRemaining, equals(39));

      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    });

    testWidgets('Quick Sheet [⤢] header button also transfers active session to /ai-chat', (tester) async {
      final container = await _createSurfaceContainer();

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: Consumer(
                builder: (context, ref, _) => ElevatedButton(
                  onPressed: () => showAiChatQuickSheet(context, ref),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/ai-chat',
            builder: (context, state) => const AiChatScreen(),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('ai_input_text_field')), 'Halo pagi');
      await tester.pump();
      await tester.tap(find.byKey(const Key('ai_input_send_btn')));
      await tester.pumpAndSettle();

      final msgCount = container.read(unifiedAiChatProvider).messages.length;
      expect(msgCount, equals(2));

      await tester.tap(find.byKey(const Key('ai_chat_expand_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(AiChatScreen), findsOneWidget);
      expect(container.read(unifiedAiChatProvider).messages.length, equals(2));

      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    });

    testWidgets('QUOTA_EXCEEDED error shows Upgrade Plan CTA opening SaasUpgradeBottomSheet, and STREAM_INTERRUPTED retries via Coba Lagi', (tester) async {
      final repo = _ScriptedAiChatRepository([
        (prompt, mode) => Stream.fromIterable([
              const AiErrorEvent(
                errorCode: 'QUOTA_EXCEEDED',
                statusCode: 402,
                message: 'Kuota AI bulanan kamu sudah habis.',
                planType: 'free',
                quotaRemaining: 0,
              ),
            ]),
        (prompt, mode) => Stream.fromIterable([
              const AiErrorEvent(
                errorCode: 'STREAM_INTERRUPTED',
                message: 'Koneksi terputus sementara.',
              ),
            ]),
        (prompt, mode) => Stream.fromIterable([
              AiFinalResponseEvent(
                sessionId: 's1',
                clientRequestId: 'r3',
                surfaceMode: mode,
                quotaRemaining: 39,
                planType: 'free',
                message: UnifiedAiChatMessage(
                  id: 'ok-msg',
                  sessionId: 's1',
                  text: 'Berhasil tersambung kembali.',
                  isUser: false,
                ),
              ),
            ]),
      ]);

      final container = await _createSurfaceContainer(repository: repo);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AiChatScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('ai_input_text_field')), 'cek saldo');
      await tester.pump();
      await tester.tap(find.byKey(const Key('ai_input_send_btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ai_error_upgrade_btn')), findsOneWidget);
      expect(find.text('Upgrade Plan'), findsOneWidget);

      await tester.tap(find.byKey(const Key('ai_error_upgrade_btn')));
      await tester.pumpAndSettle();
      expect(find.byType(SaasUpgradeBottomSheet), findsOneWidget);

      Navigator.of(tester.element(find.byType(SaasUpgradeBottomSheet))).pop();
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('ai_input_text_field')), 'coba lagi dong');
      await tester.pump();
      await tester.tap(find.byKey(const Key('ai_input_send_btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ai_error_retry_btn')), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);

      await tester.tap(find.byKey(const Key('ai_error_retry_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Berhasil tersambung kembali.'), findsOneWidget);
      expect(repo.recordedCalls.length, equals(3));

      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    });

    testWidgets('AiChatBubble composes wallet, planning, analytical, and consultant cards + booking handoff', (tester) async {
      final container = await _createSurfaceContainer();

      String? navigatedBookingPath;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    AiChatBubble(
                      message: UnifiedAiChatMessage(
                        id: 'msg_all',
                        sessionId: 's_smoke',
                        text: 'Ringkasan lengkap siap.',
                        isUser: false,
                        thinkingTrace: const AiThinkingTrace(
                          steps: [
                            AiThinkingStep(id: '1', label: 'Analisa selesai', isDone: true),
                          ],
                          durationMs: 420,
                        ),
                        walletCreationDraft: const AiWalletCreationDraft(
                          institutionId: 'jago',
                          institutionName: 'Bank Jago',
                          walletType: 'bank',
                          existingWalletIds: ['w_bca'],
                        ),
                        goalDraft: const AiGoalDraft(
                          clientMutationId: 'goal_1',
                          name: 'Dana Darurat',
                          targetAmount: 10000000,
                        ),
                        moneyFlowCard: const AiMoneyFlowData(
                          periodLabel: 'Nov 2026',
                          totalIncome: 10000000,
                          totalExpense: 3000000,
                          netCashflow: 7000000,
                          transactionCount: 5,
                          incomeSources: [AiMoneyFlowNode(label: 'Gaji', amount: 10000000)],
                          expenseCategories: [AiMoneyFlowNode(label: 'Makan', amount: 3000000)],
                        ),
                        spendingTableCard: const AiSpendingTableData(
                          title: 'Pengeluaran Kopi',
                          totalTransactions: 2,
                          totalAmount: 55000,
                          rows: [
                            AiSpendingMerchantRow(merchant: 'Kopi Kenangan', transactionCount: 2, totalAmount: 55000),
                          ],
                        ),
                        recommendedPackage: const AiPackageRecommendation(
                          packageCode: 'debt_plan',
                          packageTitle: 'Paket Bebas Utang',
                          categoryTag: 'Debt Management',
                          priceIdr: 299000,
                          sessionCount: 2,
                          durationMinutes: 60,
                        ),
                        recommendedConsultants: const [
                          AiConsultantRecommendation(
                            consultantId: 'c_rizky',
                            name: 'Rizky Pratama',
                            certifications: ['CFP®'],
                            tierLabel: 'Medium Tier',
                            matchReason: 'Spesialis manajemen utang',
                            selectedPackageCode: 'debt_plan',
                            unitPrice: 299000,
                            recommendedTopics: ['Pelunasan Paylater'],
                            prefilledDescription: 'Cicilan 40% gaji',
                          ),
                        ],
                      ),
                      onSelectConsultant: (consultant, pkg) {
                        container.read(unifiedAiChatProvider.notifier).prepareConsultantBooking(
                              consultant,
                              fallbackPackage: pkg,
                            );
                        GoRouter.of(context).push('/booking/${consultant.consultantId}/service');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/booking/:id/service',
            builder: (context, state) {
              navigatedBookingPath = state.uri.toString();
              return const Scaffold(body: Text('Booking Step 1'));
            },
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AiThinkingTraceWidget), findsOneWidget);
      expect(find.byType(AiWalletCreationDraftCard), findsOneWidget);
      expect(find.byType(AiPlanningActionCard), findsOneWidget);
      expect(find.byType(AiMoneyFlowCard), findsOneWidget);
      expect(find.byType(AiSpendingBreakdownTableCard), findsOneWidget);
      expect(find.byType(AiRecommendedConsultantsSection), findsOneWidget);

      await tester.ensureVisible(find.text('Pilih & Jadwalkan'));
      await tester.tap(find.text('Pilih & Jadwalkan'));
      await tester.pumpAndSettle();

      expect(navigatedBookingPath, equals('/booking/c_rizky/service'));
      final booking = container.read(bookingProvider);
      expect(booking.selectedPackageCode, equals('debt_plan'));
      expect(booking.prefilledTopics, contains('Pelunasan Paylater'));

      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    });

    testWidgets('360x640 viewport at 1.25x text scale has zero overflow and all interactive controls >= 44x44', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = await _createSurfaceContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (context) => MediaQuery.withClampedTextScaling(
                minScaleFactor: 1.25,
                maxScaleFactor: 1.25,
                child: const AiChatScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      _assertNoSlopUi(tester);
      _assertHitTargetMin44(tester, const Key('ai_chat_back_btn'));
      _assertHitTargetMin44(tester, const Key('ai_chat_quota_badge'));
      _assertHitTargetMin44(tester, const Key('ai_chat_new_chat_btn'));
      _assertHitTargetMin44(tester, const Key('ai_input_scan_btn'));
      _assertHitTargetMin44(tester, const Key('ai_input_voice_btn'));
      _assertHitTargetMin44(tester, const Key('ai_input_send_btn'));

      // Also verify Quick Sheet at 360x640 and 1.25x scale with floating pill visible.
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: MediaQuery.withClampedTextScaling(
              minScaleFactor: 1.25,
              maxScaleFactor: 1.25,
              child: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) => ElevatedButton(
                    onPressed: () => showAiChatQuickSheet(context, ref),
                    child: const Text('Buka'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      _assertHitTargetMin44(tester, const Key('ai_chat_quota_badge'));
      _assertHitTargetMin44(tester, const Key('ai_chat_new_chat_btn'));
      _assertHitTargetMin44(tester, const Key('ai_chat_expand_btn'));
      _assertHitTargetMin44(tester, const Key('ai_chat_close_btn'));
      _assertHitTargetMin44(tester, const Key('ai_input_scan_btn'));
      _assertHitTargetMin44(tester, const Key('ai_input_voice_btn'));
      _assertHitTargetMin44(tester, const Key('ai_input_send_btn'));

      await tester.enterText(
        find.byKey(const Key('ai_input_text_field')),
        'kopi kenangan 25k + parkir goceng pake gopay',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('ai_input_send_btn')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      _assertHitTargetMin44(tester, const Key('ai_chat_expand_pill'));

      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    });

    testWidgets('Quick Sheet [Scan] & [Bicara] open OCR and Voice modals cleanly without Navigator errors', (tester) async {
      final container = await _createSurfaceContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => ElevatedButton(
                  onPressed: () => showAiChatQuickSheet(context, ref),
                  child: const Text('Buka'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('ai_input_scan_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Scan Struk / Nota (OCR)'), findsOneWidget);
      Navigator.of(tester.element(find.text('Scan Struk / Nota (OCR)'))).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('ai_input_voice_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Voice AI Action'), findsOneWidget);
      Navigator.of(tester.element(find.text('Voice AI Action'))).pop();
      await tester.pumpAndSettle();

      // Verify AiChatScreen [Scan] and [Bicara] also open modals cleanly.
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AiChatScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('ai_input_scan_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Scan Struk / Nota (OCR)'), findsOneWidget);
      Navigator.of(tester.element(find.text('Scan Struk / Nota (OCR)'))).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('ai_input_voice_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Voice AI Action'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    });

    testWidgets('goRouterProvider /draft/review passes extra to AiDraftReviewScreen directly', (tester) async {
      final container = await _createSurfaceContainer();

      final router = container.read(goRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      router.push(
        '/draft/review',
        extra: {
          'prefillItems': [
            {
              'title': 'Kopi Kenangan Tebet',
              'amount': 25000,
              'isExpense': true,
              'category': 'Food & Beverage • Coffee Shop',
              'walletId': 'w_gopay',
              'walletName': 'GoPay',
            },
          ],
        },
      );
      await tester.pumpAndSettle();

      expect(find.text('Kopi Kenangan Tebet'), findsOneWidget);
      expect(find.text('25.000'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    });
  });
}
