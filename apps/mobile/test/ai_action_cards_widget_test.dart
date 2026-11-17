import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/institutions/institution_logo_widget.dart';
import 'package:mobile/features/session/domain/models/ai_chat_models.dart';
import 'package:mobile/features/session/presentation/widgets/ai_planning_action_card.dart';
import 'package:mobile/features/session/presentation/widgets/ai_transaction_draft_card.dart';
import 'package:mobile/features/session/presentation/widgets/ai_wallet_creation_draft_card.dart';

Widget _wrapViewport360(Widget child) {
  return MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(size: Size(360, 640)),
      child: Scaffold(
        body: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    ),
  );
}

void _expectNoEmDash(WidgetTester tester) {
  for (final widget in tester.widgetList<Text>(find.byType(Text))) {
    final text = widget.data ?? widget.textSpan?.toPlainText() ?? '';
    expect(text.contains('\u2014'), isFalse, reason: 'Found em dash in: $text');
  }
}

void _expectMinTouchTarget(WidgetTester tester, Finder finder) {
  expect(finder, findsOneWidget);
  final size = tester.getSize(finder);
  expect(size.height, greaterThanOrEqualTo(44.0));
  expect(size.width, greaterThanOrEqualTo(44.0));
}

void main() {
  group('AiWalletCreationDraftCard', () {
    const baseDraft = AiWalletCreationDraft(
      institutionId: 'jago',
      institutionName: 'Bank Jago',
      walletType: 'bank',
      existingWalletIds: ['w-bca', 'w-gopay'],
      initialBalance: 0,
    );

    testWidgets(
      'renders institution logo, balance input, typo chips, and invokes callbacks without 360px overflow',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        double? createdBalance;
        String? selectedExistingId;

        await tester.pumpWidget(
          _wrapViewport360(
            AiWalletCreationDraftCard(
              draft: baseDraft,
              walletLabelResolver: (id) =>
                  id == 'w-bca' ? 'BCA Utama' : 'GoPay',
              onCreateWallet: (balance) => createdBalance = balance,
              onUseExistingWallet: (walletId) => selectedExistingId = walletId,
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byType(InstitutionLogoWidget), findsOneWidget);
        expect(find.text('Bank Jago'), findsOneWidget);
        expect(find.textContaining('Bank'), findsWidgets);
        expect(find.text('Atau pakai dompet yang ada:'), findsOneWidget);
        expect(find.text('BCA Utama'), findsOneWidget);
        expect(find.text('GoPay'), findsOneWidget);

        _expectMinTouchTarget(
          tester,
          find.byKey(const Key('wallet_create_button')),
        );
        _expectMinTouchTarget(
          tester,
          find.byKey(const Key('wallet_existing_chip_w-bca')),
        );
        _expectMinTouchTarget(
          tester,
          find.byKey(const Key('wallet_existing_chip_w-gopay')),
        );

        await tester.tap(find.byKey(const Key('wallet_create_button')));
        await tester.pump();
        expect(createdBalance, equals(0.0));

        await tester.enterText(find.byType(TextField), '250000');
        await tester.pump();
        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.controller?.text, equals('250.000'));

        await tester.tap(find.byKey(const Key('wallet_create_button')));
        await tester.pump();
        expect(createdBalance, equals(250000.0));

        await tester.tap(find.byKey(const Key('wallet_existing_chip_w-gopay')));
        await tester.pump();
        expect(selectedExistingId, equals('w-gopay'));
        _expectNoEmDash(tester);
      },
    );

    testWidgets('shows mint state and disables create button once created', (
      tester,
    ) async {
      var tapCount = 0;
      await tester.pumpWidget(
        _wrapViewport360(
          AiWalletCreationDraftCard(
            draft: baseDraft.copyWith(
              initialBalance: 500000,
              isCreated: true,
              createdWalletId: 'w-jago-1',
            ),
            onCreateWallet: (_) => tapCount++,
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Dompet Bank Jago dibuat'), findsOneWidget);
      await tester.tap(find.byKey(const Key('wallet_create_button')));
      await tester.pump();
      expect(tapCount, equals(0));
      _expectNoEmDash(tester);
    });
  });

  group('AiTransactionDraftCard', () {
    final twoItemDraft = AiTransactionDraftGroup(
      clientMutationId: 'mut-tx-1',
      items: [
        AiTransactionDraftItem(
          title: 'Kopi Kenangan',
          amount: 28000,
          type: 'expense',
          canonicalCategory: 'Food & Beverage • Coffee Shop',
          walletId: 'w-gopay',
          walletName: 'GoPay',
          occurredAt: DateTime(2026, 10, 31, 8, 30),
        ),
        AiTransactionDraftItem(
          title: 'Ojek Online',
          amount: 15000,
          type: 'expense',
          canonicalCategory: 'Transportation • Ride Hailing / Taxi',
          walletId: 'w-gopay',
          walletName: 'GoPay',
          occurredAt: DateTime(2026, 10, 31, 8, 45),
        ),
      ],
    );

    testWidgets(
      'renders 2 items simultaneously and enforces >= 44px targets at 360x640',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        var confirmed = false;
        var cancelled = false;
        var edited = false;

        await tester.pumpWidget(
          _wrapViewport360(
            AiTransactionDraftCard(
              draft: twoItemDraft,
              onConfirm: () => confirmed = true,
              onCancel: () => cancelled = true,
              onEditDetail: () => edited = true,
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text('Kopi Kenangan'), findsOneWidget);
        expect(find.text('Ojek Online'), findsOneWidget);
        expect(find.textContaining('28.000'), findsOneWidget);
        expect(find.textContaining('15.000'), findsOneWidget);
        expect(find.text('Food & Beverage • Coffee Shop'), findsOneWidget);
        expect(find.text('Transportation • Ride Hailing / Taxi'), findsOneWidget);
        expect(find.text('GoPay'), findsNWidgets(2));

        _expectMinTouchTarget(tester, find.byKey(const Key('tx_confirm_btn')));
        _expectMinTouchTarget(tester, find.byKey(const Key('tx_cancel_btn')));
        _expectMinTouchTarget(tester, find.byKey(const Key('tx_edit_btn')));

        await tester.tap(find.byKey(const Key('tx_confirm_btn')));
        await tester.tap(find.byKey(const Key('tx_cancel_btn')));
        await tester.tap(find.byKey(const Key('tx_edit_btn')));
        await tester.pump();

        expect(confirmed, isTrue);
        expect(cancelled, isTrue);
        expect(edited, isTrue);
        _expectNoEmDash(tester);
      },
    );

    testWidgets('locks confirm button with spinner while isSubmitting == true', (
      tester,
    ) async {
      var confirmCalls = 0;
      await tester.pumpWidget(
        _wrapViewport360(
          AiTransactionDraftCard(
            draft: twoItemDraft.copyWith(isSubmitting: true),
            onConfirm: () => confirmCalls++,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byKey(const Key('tx_confirm_btn')));
      await tester.pump();
      expect(confirmCalls, equals(0));
    });

    testWidgets('shows confirmed mint and cancelled coral states cleanly', (
      tester,
    ) async {
      var confirmCalls = 0;
      await tester.pumpWidget(
        _wrapViewport360(
          AiTransactionDraftCard(
            draft: twoItemDraft.copyWith(isConfirmed: true),
            onConfirm: () => confirmCalls++,
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Tercatat'), findsOneWidget);
      await tester.tap(find.byKey(const Key('tx_confirm_btn')));
      expect(confirmCalls, equals(0));

      await tester.pumpWidget(
        _wrapViewport360(
          AiTransactionDraftCard(
            draft: twoItemDraft.copyWith(isCancelled: true),
            onConfirm: () => confirmCalls++,
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Dibatalkan'), findsOneWidget);
      await tester.tap(find.byKey(const Key('tx_confirm_btn')));
      expect(confirmCalls, equals(0));
    });

    testWidgets('Edit Rinci fallback pushes /draft/review with prefillItems', (
      tester,
    ) async {
      Object? pushedExtra;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: AiTransactionDraftCard(draft: twoItemDraft),
            ),
          ),
          GoRoute(
            path: '/draft/review',
            builder: (context, state) {
              pushedExtra = state.extra;
              return const Scaffold(body: Text('Review Page'));
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('tx_edit_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Review Page'), findsOneWidget);
      final map = pushedExtra as Map<String, dynamic>;
      final items = map['prefillItems'] as List<dynamic>;
      expect(items.length, equals(2));
      expect((items[0] as Map)['title'], equals('Kopi Kenangan'));
      expect((items[0] as Map)['amount'], equals(28000.0));
      expect((items[0] as Map)['isExpense'], isTrue);
      expect(
        (items[0] as Map)['category'],
        equals('Food & Beverage • Coffee Shop'),
      );
      expect((items[0] as Map)['walletId'], equals('w-gopay'));
      expect((items[0] as Map)['walletName'], equals('GoPay'));
    });
  });

  group('AiPlanningActionCard', () {
    final goalDraft = AiGoalDraft(
      clientMutationId: 'mut-goal',
      name: 'Dana Nikah',
      targetAmount: 50000000,
      deadline: DateTime(2027, 12, 31),
      linkedWalletId: 'w-bca',
      monthlySavingEstimate: 3571429,
    );

    const budgetDraft = AiBudgetDraft(
      clientMutationId: 'mut-budget',
      category: 'Food & Beverage',
      limitAmount: 1500000,
      avg30dSpend: 1850000,
      isUpdate: true,
    );

    final billDraft = AiBillDraft(
      clientMutationId: 'mut-bill',
      title: 'Indihome',
      amount: 385000,
      dueDay: 20,
      dueDate: DateTime(2026, 11, 20),
      frequency: 'monthly',
      category: 'Bills & Utilities • Internet & Wi-Fi',
    );

    testWidgets('renders Goal variant with estimate, actions, and GoRouter fallback', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var confirmed = false;
      Object? goalExtra;

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: AiPlanningActionCard(
                  goalDraft: goalDraft,
                  walletLabelResolver: (_) => 'BCA Utama',
                  onConfirmGoal: () => confirmed = true,
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/goal/add',
            builder: (context, state) {
              goalExtra = state.extra;
              return const Scaffold(body: Text('Goal Add Page'));
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Dana Nikah'), findsOneWidget);
      expect(find.textContaining('50.000.000'), findsOneWidget);
      expect(find.textContaining('3.571.429'), findsOneWidget);
      expect(find.textContaining('BCA Utama'), findsOneWidget);
      expect(find.text('+ Buat Goal Ini'), findsOneWidget);
      expect(find.text('Atur Detail'), findsOneWidget);

      _expectMinTouchTarget(tester, find.byKey(const Key('goal_confirm_btn')));
      _expectMinTouchTarget(tester, find.byKey(const Key('goal_edit_btn')));

      await tester.tap(find.byKey(const Key('goal_confirm_btn')));
      await tester.pump();
      expect(confirmed, isTrue);

      await tester.tap(find.byKey(const Key('goal_edit_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Goal Add Page'), findsOneWidget);
      expect((goalExtra as Map)['name'], equals('Dana Nikah'));
      expect((goalExtra as Map)['targetAmount'], equals(50000000.0));
      _expectNoEmDash(tester);
    });

    testWidgets('renders Budget variant with avg30dSpend and GoRouter fallbacks', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var confirmed = false;
      String? budgetTabParam;
      Object? budgetExtra;

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: AiPlanningActionCard(
                  budgetDraft: budgetDraft,
                  onConfirmBudget: () => confirmed = true,
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/budget',
            builder: (context, state) {
              budgetTabParam = state.uri.queryParameters['tab'];
              return const Scaffold(body: Text('Budget Page'));
            },
          ),
          GoRoute(
            path: '/budget/add',
            builder: (context, state) {
              budgetExtra = state.extra;
              return const Scaffold(body: Text('Budget Add Page'));
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Food & Beverage'), findsOneWidget);
      expect(find.textContaining('1.500.000'), findsOneWidget);
      expect(find.textContaining('1.850.000'), findsOneWidget);
      expect(find.text('+ Pasang Budget'), findsOneWidget);
      expect(find.text('Lihat Budget'), findsOneWidget);
      expect(find.text('Edit Rinci'), findsOneWidget);

      _expectMinTouchTarget(
        tester,
        find.byKey(const Key('budget_confirm_btn')),
      );
      _expectMinTouchTarget(tester, find.byKey(const Key('budget_view_btn')));
      _expectMinTouchTarget(tester, find.byKey(const Key('budget_edit_btn')));

      await tester.tap(find.byKey(const Key('budget_confirm_btn')));
      await tester.pump();
      expect(confirmed, isTrue);

      await tester.tap(find.byKey(const Key('budget_view_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Budget Page'), findsOneWidget);
      expect(budgetTabParam, equals('1'));

      router.pop();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('budget_edit_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Budget Add Page'), findsOneWidget);
      expect((budgetExtra as Map)['category'], equals('Food & Beverage'));
      expect((budgetExtra as Map)['limitAmount'], equals(1500000.0));
      _expectNoEmDash(tester);
    });

    testWidgets('renders Bill variant, handles submitting/confirmed/cancelled, and fallback', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var confirmed = false;
      Object? billExtra;

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: AiPlanningActionCard(
                  billDraft: billDraft,
                  onConfirmBill: () => confirmed = true,
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/bill/add',
            builder: (context, state) {
              billExtra = state.extra;
              return const Scaffold(body: Text('Bill Add Page'));
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Indihome'), findsOneWidget);
      expect(find.textContaining('385.000'), findsOneWidget);
      expect(find.text('+ Aktifkan Pengingat'), findsOneWidget);
      expect(find.text('Atur Tagihan'), findsOneWidget);

      _expectMinTouchTarget(tester, find.byKey(const Key('bill_confirm_btn')));
      _expectMinTouchTarget(tester, find.byKey(const Key('bill_edit_btn')));

      await tester.tap(find.byKey(const Key('bill_confirm_btn')));
      await tester.pump();
      expect(confirmed, isTrue);

      await tester.tap(find.byKey(const Key('bill_edit_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Bill Add Page'), findsOneWidget);
      expect((billExtra as Map)['title'], equals('Indihome'));
      expect((billExtra as Map)['amount'], equals(385000.0));
      expect((billExtra as Map)['dueDay'], equals(20));
      expect((billExtra as Map)['frequency'], equals('monthly'));

      var submittingConfirmCalls = 0;
      await tester.pumpWidget(
        _wrapViewport360(
          AiPlanningActionCard.bill(
            billDraft: billDraft.copyWith(isSubmitting: true),
            onConfirmBill: () => submittingConfirmCalls++,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byKey(const Key('bill_confirm_btn')));
      expect(submittingConfirmCalls, equals(0));

      await tester.pumpWidget(
        _wrapViewport360(
          AiPlanningActionCard.goal(
            goalDraft: goalDraft.copyWith(isConfirmed: true),
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('dibuat'), findsOneWidget);

      await tester.pumpWidget(
        _wrapViewport360(
          AiPlanningActionCard.budget(
            budgetDraft: budgetDraft.copyWith(isCancelled: true),
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('dibatalkan'), findsOneWidget);
      _expectNoEmDash(tester);
    });

    testWidgets('handles income/transfer/empty tx drafts, default wallet chips, and empty planning state', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapViewport360(
          const AiWalletCreationDraftCard(
            draft: AiWalletCreationDraft(
              institutionId: 'jenius',
              institutionName: 'Jenius',
              walletType: 'e_wallet',
              existingWalletIds: ['w-bca', 'w-gopay'],
              initialBalance: 500000,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('BCA'), findsOneWidget);
      expect(find.text('GoPay'), findsOneWidget);
      expect(find.text('E-Wallet'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        equals('500.000'),
      );

      await tester.pumpWidget(
        _wrapViewport360(
          AiTransactionDraftCard(
            draft: AiTransactionDraftGroup(
              clientMutationId: 'mut-mix',
              items: [
                AiTransactionDraftItem(
                  title: 'Gaji Bulanan',
                  amount: 8500000,
                  type: 'income',
                  canonicalCategory: 'Income • Salary',
                  walletId: 'w-bca',
                  walletName: 'BCA',
                  occurredAt: DateTime(2026, 11, 1),
                ),
                AiTransactionDraftItem(
                  title: 'Topup GoPay',
                  amount: 100000,
                  type: 'transfer',
                  canonicalCategory: 'Transfer',
                  walletId: 'w-bca',
                  walletName: 'BCA',
                  targetWalletId: 'w-gopay',
                  occurredAt: DateTime(2026, 11, 1),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Pemasukan'), findsOneWidget);
      expect(find.text('Transfer'), findsNWidgets(2));
      expect(find.text('BCA -> w-gopay'), findsOneWidget);

      await tester.pumpWidget(
        _wrapViewport360(
          const AiTransactionDraftCard(
            draft: AiTransactionDraftGroup(clientMutationId: 'mut-empty'),
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Belum ada item transaksi'), findsOneWidget);

      await tester.pumpWidget(_wrapViewport360(const AiPlanningActionCard()));
      await tester.pump();
      expect(find.text('Draf perencanaan belum tersedia.'), findsOneWidget);
      _expectNoEmDash(tester);
    });
  });
}
