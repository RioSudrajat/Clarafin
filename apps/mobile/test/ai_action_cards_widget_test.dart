import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/institutions/institution_logo_widget.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/theme/neo_brutalism_decorations.dart';
import 'package:mobile/features/session/domain/models/ai_chat_models.dart';
import 'package:mobile/features/session/presentation/widgets/ai_chat_bubble.dart';
import 'package:mobile/features/session/presentation/widgets/ai_planning_action_card.dart';
import 'package:mobile/features/session/presentation/widgets/ai_transaction_draft_card.dart';
import 'package:mobile/features/session/presentation/widgets/ai_wallet_creation_draft_card.dart';

Widget _wrapViewport360(Widget child, {double textScale = 1.0}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(360, 640),
        textScaler: TextScaler.linear(textScale),
      ),
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

void _expectSingleButtonSemantics(
  WidgetTester tester,
  Finder finder,
  String expectedLabel, {
  required bool enabled,
}) {
  final data = tester.getSemantics(finder).getSemanticsData();
  expect(data.label, equals(expectedLabel));
  expect(data.flagsCollection.isButton, isTrue);
  expect(
    data.flagsCollection.isEnabled,
    equals(enabled ? Tristate.isTrue : Tristate.isFalse),
  );
  expect(data.hasAction(SemanticsAction.tap), equals(enabled));
}

bool _hasFocusRing(WidgetTester tester, Finder descendantFinder) {
  final containers = tester.widgetList<Container>(
    find.ancestor(of: descendantFinder, matching: find.byType(Container)),
  );
  for (final container in containers) {
    final fg = container.foregroundDecoration;
    if (fg is BoxDecoration && fg.border is Border) {
      final border = fg.border! as Border;
      if (border.top.color == NeoBrutalism.teal && border.top.width >= 2.0) {
        return true;
      }
    }
  }
  return false;
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AiWalletCreationDraftCard', () {
    const baseDraft = AiWalletCreationDraft(
      institutionId: 'jago',
      institutionName: 'Bank Jago',
      walletType: 'bank',
      existingWalletIds: ['w-bca', 'w-gopay'],
      initialBalance: 0,
    );

    testWidgets(
      'renders institution logo, clean borderless TextField under AppTheme, single semantics, focus ring, and callbacks at 360px',
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
        expect(find.text('Atau pakai dompet yang ada:'), findsOneWidget);
        expect(find.text('BCA Utama'), findsOneWidget);
        expect(find.text('GoPay'), findsOneWidget);

        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.decoration?.enabledBorder, equals(InputBorder.none));
        expect(field.decoration?.focusedBorder, equals(InputBorder.none));

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
        _expectSingleButtonSemantics(
          tester,
          find.byKey(const Key('wallet_create_button')),
          '+ Buat Dompet Bank Jago',
          enabled: true,
        );
        _expectSingleButtonSemantics(
          tester,
          find.byKey(const Key('wallet_existing_chip_w-bca')),
          'BCA Utama',
          enabled: true,
        );

        await tester.tap(find.byType(TextField));
        await tester.pump();
        expect(_hasFocusRing(tester, find.byType(TextField)), isTrue);

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(
          _hasFocusRing(tester, find.byKey(const Key('wallet_create_button'))),
          isTrue,
        );

        await tester.tap(find.byKey(const Key('wallet_create_button')));
        await tester.pump();
        expect(createdBalance, equals(0.0));

        await tester.enterText(find.byType(TextField), '250000');
        await tester.pump();
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller?.text,
          equals('250.000'),
        );

        await tester.tap(find.byKey(const Key('wallet_create_button')));
        await tester.pump();
        expect(createdBalance, equals(250000.0));

        await tester.tap(find.byKey(const Key('wallet_existing_chip_w-gopay')));
        await tester.pump();
        expect(selectedExistingId, equals('w-gopay'));
        _expectNoEmDash(tester);
      },
    );

    testWidgets(
      'hides input & chips when created, disables button, and resets controller when isCreated transitions back to false',
      (tester) async {
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
        expect(find.byType(TextField), findsNothing);
        expect(find.text('Atau pakai dompet yang ada:'), findsNothing);
        _expectSingleButtonSemantics(
          tester,
          find.byKey(const Key('wallet_create_button')),
          '+ Buat Dompet Bank Jago',
          enabled: false,
        );

        await tester.tap(find.byKey(const Key('wallet_create_button')));
        await tester.pump();
        expect(tapCount, equals(0));

        await tester.pumpWidget(
          _wrapViewport360(
            AiWalletCreationDraftCard(
              draft: baseDraft.copyWith(initialBalance: 0, isCreated: false),
              onCreateWallet: (_) => tapCount++,
            ),
          ),
        );
        await tester.pump();
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller?.text,
          isEmpty,
        );
        _expectNoEmDash(tester);
      },
    );

    testWidgets('normalizes web3_wallet type cleanly', (tester) async {
      await tester.pumpWidget(
        _wrapViewport360(
          const AiWalletCreationDraftCard(
            draft: AiWalletCreationDraft(
              institutionId: 'metamask',
              institutionName: 'MetaMask',
              walletType: 'web3_wallet',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Web3 Wallet'), findsOneWidget);
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
      'renders 2 items simultaneously, uses 1.5px micro pill borders, and enforces >= 44px targets at 360x640',
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
        expect(find.text('STRUK TRANSAKSI'), findsOneWidget);
        expect(find.text('GOPAY'), findsOneWidget);
        expect(find.text('2 item'), findsOneWidget);
        expect(find.text('TOTAL'), findsOneWidget);
        expect(find.textContaining('43.000'), findsOneWidget);

        final pillBox = tester.widget<Container>(
          find
              .ancestor(
                of: find.text('Food & Beverage • Coffee Shop'),
                matching: find.byType(Container),
              )
              .first,
        );
        final pillBorder = (pillBox.decoration as BoxDecoration).border as Border;
        expect(pillBorder.top.width, equals(1.5));

        _expectMinTouchTarget(tester, find.byKey(const Key('tx_confirm_btn')));
        _expectMinTouchTarget(tester, find.byKey(const Key('tx_cancel_btn')));
        _expectMinTouchTarget(tester, find.byKey(const Key('tx_edit_btn')));
        _expectSingleButtonSemantics(
          tester,
          find.byKey(const Key('tx_confirm_btn')),
          'Konfirmasi & Catat',
          enabled: true,
        );

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

    testWidgets(
      'locks confirm, cancel, and edit buttons with spinner while isSubmitting == true, and disables Edit Rinci when items empty',
      (tester) async {
        var confirmCalls = 0;
        var cancelCalls = 0;
        var editCalls = 0;
        await tester.pumpWidget(
          _wrapViewport360(
            AiTransactionDraftCard(
              draft: twoItemDraft.copyWith(isSubmitting: true),
              onConfirm: () => confirmCalls++,
              onCancel: () => cancelCalls++,
              onEditDetail: () => editCalls++,
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        _expectSingleButtonSemantics(
          tester,
          find.byKey(const Key('tx_confirm_btn')),
          'Konfirmasi & Catat',
          enabled: false,
        );
        _expectSingleButtonSemantics(
          tester,
          find.byKey(const Key('tx_cancel_btn')),
          'Batal',
          enabled: false,
        );
        _expectSingleButtonSemantics(
          tester,
          find.byKey(const Key('tx_edit_btn')),
          'Edit Rinci',
          enabled: false,
        );

        await tester.tap(find.byKey(const Key('tx_confirm_btn')));
        await tester.tap(find.byKey(const Key('tx_cancel_btn')));
        await tester.tap(find.byKey(const Key('tx_edit_btn')));
        await tester.pump();
        expect(confirmCalls, equals(0));
        expect(cancelCalls, equals(0));
        expect(editCalls, equals(0));

        await tester.pumpWidget(
          _wrapViewport360(
            AiTransactionDraftCard(
              draft: const AiTransactionDraftGroup(clientMutationId: 'mut-empty'),
              onCancel: () => cancelCalls++,
              onEditDetail: () => editCalls++,
            ),
          ),
        );
        await tester.pump();
        expect(find.textContaining('Belum ada item transaksi'), findsOneWidget);
        _expectSingleButtonSemantics(
          tester,
          find.byKey(const Key('tx_edit_btn')),
          'Edit Rinci',
          enabled: false,
        );
        await tester.tap(find.byKey(const Key('tx_edit_btn')));
        await tester.pump();
        expect(editCalls, equals(0));
      },
    );

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

      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
      );
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

    testWidgets('resolves income, transfer targets, and walletLabelResolver', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapViewport360(
          AiTransactionDraftCard(
            walletLabelResolver: (id) =>
                id == 'w-gopay' ? 'GoPay Utama' : 'BCA Tabungan',
            draft: AiTransactionDraftGroup(
              clientMutationId: 'mut-mix',
              items: [
                AiTransactionDraftItem(
                  title: 'Gaji Bulanan',
                  amount: 8500000,
                  type: ' INCOME ',
                  canonicalCategory: 'Income • Salary',
                  walletId: 'w-bca',
                  walletName: '',
                  occurredAt: DateTime(2026, 11, 1),
                ),
                AiTransactionDraftItem(
                  title: 'Topup GoPay',
                  amount: 100000,
                  type: ' Transfer ',
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
      expect(find.text('BCA TABUNGAN'), findsOneWidget);
      expect(find.text('BCA Tabungan -> GoPay Utama'), findsOneWidget);
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
      dueDay: null,
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

      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Dana Nikah'), findsOneWidget);
      expect(find.textContaining('50.000.000'), findsOneWidget);
      expect(find.textContaining('3.571.429'), findsOneWidget);
      expect(find.textContaining('BCA Utama'), findsOneWidget);

      _expectMinTouchTarget(tester, find.byKey(const Key('goal_confirm_btn')));
      _expectMinTouchTarget(tester, find.byKey(const Key('goal_edit_btn')));
      _expectSingleButtonSemantics(
        tester,
        find.byKey(const Key('goal_confirm_btn')),
        '+ Buat Goal Ini',
        enabled: true,
      );

      await tester.tap(find.byKey(const Key('goal_confirm_btn')));
      await tester.pump();
      expect(confirmed, isTrue);

      await tester.tap(find.byKey(const Key('goal_edit_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Goal Add Page'), findsOneWidget);
      final map = goalExtra as Map<String, dynamic>;
      expect(map['name'], equals('Dana Nikah'));
      expect(map['targetAmount'], equals(50000000.0));
      expect(map['deadline'], equals(DateTime(2027, 12, 31).toIso8601String()));
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

      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Food & Beverage'), findsOneWidget);
      expect(find.textContaining('1.500.000'), findsOneWidget);
      expect(find.textContaining('1.850.000'), findsOneWidget);

      _expectMinTouchTarget(tester, find.byKey(const Key('budget_confirm_btn')));
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

    testWidgets(
      'renders Bill variant with dueDay fallback, submitting/confirmed/cancelled, and empty state',
      (tester) async {
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

        await tester.pumpWidget(
          MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Indihome'), findsOneWidget);
        expect(find.textContaining('385.000'), findsOneWidget);

        _expectMinTouchTarget(tester, find.byKey(const Key('bill_confirm_btn')));
        _expectMinTouchTarget(tester, find.byKey(const Key('bill_edit_btn')));

        await tester.tap(find.byKey(const Key('bill_confirm_btn')));
        await tester.pump();
        expect(confirmed, isTrue);

        await tester.tap(find.byKey(const Key('bill_edit_btn')));
        await tester.pumpAndSettle();
        expect(find.text('Bill Add Page'), findsOneWidget);
        final billMap = billExtra as Map<String, dynamic>;
        expect(billMap['title'], equals('Indihome'));
        expect(billMap['amount'], equals(385000.0));
        expect(billMap['dueDay'], equals(20));
        expect(billMap['dueDate'], equals(DateTime(2026, 11, 20).toIso8601String()));
        expect(billMap['frequency'], equals('monthly'));
        expect(billMap['category'], equals('Bills & Utilities • Internet & Wi-Fi'));

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
            AiPlanningActionCard.goal(goalDraft: goalDraft.copyWith(isConfirmed: true)),
          ),
        );
        await tester.pump();
        expect(find.textContaining('dibuat'), findsOneWidget);

        await tester.pumpWidget(
          _wrapViewport360(
            AiPlanningActionCard.budget(budgetDraft: budgetDraft.copyWith(isCancelled: true)),
          ),
        );
        await tester.pump();
        expect(find.textContaining('dibatalkan'), findsOneWidget);

        await tester.pumpWidget(_wrapViewport360(const AiPlanningActionCard()));
        await tester.pump();
        expect(find.text('Draf perencanaan belum tersedia.'), findsOneWidget);
        _expectNoEmDash(tester);
      },
    );

    testWidgets('renders all cards cleanly at 2.0x text scale on 360px viewport without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrapViewport360(
          Column(
            children: [
              const AiWalletCreationDraftCard(
                draft: AiWalletCreationDraft(
                  institutionId: 'jago',
                  institutionName: 'Bank Jago Digital',
                  walletType: 'bank',
                  existingWalletIds: ['w-bca', 'w-gopay'],
                ),
              ),
              const SizedBox(height: 12),
              AiTransactionDraftCard(
                draft: AiTransactionDraftGroup(
                  clientMutationId: 'm-scale',
                  items: [
                    AiTransactionDraftItem(
                      title: 'Belanja Bulanan Keluarga',
                      amount: 1250000,
                      type: 'expense',
                      canonicalCategory: 'Household Needs • Groceries',
                      walletId: 'w-bca',
                      walletName: 'BCA Utama',
                      occurredAt: DateTime(2026, 11, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AiPlanningActionCard(
                goalDraft: goalDraft,
                budgetDraft: budgetDraft,
                billDraft: billDraft,
              ),
            ],
          ),
          textScale: 2.0,
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      _expectNoEmDash(tester);
    });

    testWidgets(
      'shows insufficient-balance warning banner when walletBalanceResolver < totalOutgoing and hides when confirmed',
      (tester) async {
        final draft = AiTransactionDraftGroup(
          clientMutationId: 'mut-low-bal',
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
        );

        await tester.pumpWidget(
          _wrapViewport360(
            AiTransactionDraftCard(
              draft: draft,
              walletLabelResolver: (_) => 'GoPay',
              walletBalanceResolver: (_) => 0,
            ),
          ),
        );
        await tester.pump();

        expect(find.byKey(const Key('tx_insufficient_balance_banner')), findsOneWidget);
        expect(find.textContaining('Saldo GoPay (Rp 0) kurang untuk Rp 30.000'), findsOneWidget);

        await tester.pumpWidget(
          _wrapViewport360(
            AiTransactionDraftCard(
              draft: draft.copyWith(isConfirmed: true),
              walletLabelResolver: (_) => 'GoPay',
              walletBalanceResolver: (_) => 0,
            ),
          ),
        );
        await tester.pump();
        expect(find.byKey(const Key('tx_insufficient_balance_banner')), findsNothing);
      },
    );

    testWidgets(
      'AiChatBubble renders 2 independent Struk receipt cards when transactionDraftGroups has 2 wallet groups',
      (tester) async {
        final confirmedIndices = <int>[];
        final cancelledIndices = <int>[];
        final msg = UnifiedAiChatMessage(
          id: 'msg-split',
          sessionId: 'sess-1',
          text: 'Dua struk dipisah per dompet.',
          isUser: false,
          transactionDraftGroups: [
            AiTransactionDraftGroup(
              clientMutationId: 'mut-cash',
              items: [
                AiTransactionDraftItem(
                  title: 'Kopi Pagi',
                  amount: 15000,
                  type: 'expense',
                  canonicalCategory: 'Food & Beverage • Coffee Shop',
                  walletId: 'w-cash',
                  walletName: 'Cash',
                  occurredAt: DateTime(2026, 11, 18),
                ),
              ],
            ),
            AiTransactionDraftGroup(
              clientMutationId: 'mut-gopay',
              items: [
                AiTransactionDraftItem(
                  title: 'Baju Baru',
                  amount: 120000,
                  type: 'expense',
                  canonicalCategory: 'Lifestyle • Shopping',
                  walletId: 'w-gopay',
                  walletName: 'GoPay',
                  occurredAt: DateTime(2026, 11, 18),
                ),
              ],
            ),
          ],
        );

        await tester.pumpWidget(
          _wrapViewport360(
            AiChatBubble(
              message: msg,
              onConfirmTransactionGroup: confirmedIndices.add,
              onCancelTransactionGroup: cancelledIndices.add,
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(AiTransactionDraftCard), findsNWidgets(2));
        expect(find.text('STRUK TRANSAKSI'), findsNWidgets(2));
        expect(find.text('CASH'), findsOneWidget);
        expect(find.text('GOPAY'), findsOneWidget);

        await tester.tap(find.byKey(const Key('tx_confirm_btn')).first);
        final lastCancelBtn = find.byKey(const Key('tx_cancel_btn')).last;
        await tester.ensureVisible(lastCancelBtn);
        await tester.tap(lastCancelBtn);
        await tester.pump();

        expect(confirmedIndices, equals([0]));
        expect(cancelledIndices, equals([1]));
      },
    );

    testWidgets(
      'AiTransactionDraftCard never shows raw unresolved UUID and renders InstitutionLogoWidget in header pill',
      (tester) async {
        final draft = AiTransactionDraftGroup(
          clientMutationId: 'mut-uuid-fallback',
          items: [
            AiTransactionDraftItem(
              title: 'Gaji Bulanan',
              amount: 1200000,
              type: 'income',
              canonicalCategory: 'Income • Salary',
              walletId: 'E4B89FD2-2622-4C6E-9CC1-3A3989366C11',
              walletName: 'GoPay',
              occurredAt: DateTime(2026, 11, 18),
            ),
          ],
        );

        await tester.pumpWidget(
          _wrapViewport360(
            AiTransactionDraftCard(
              draft: draft,
              walletLabelResolver: (id) => id,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('GOPAY'), findsOneWidget);
        expect(find.textContaining('E4B89FD2'), findsNothing);
        expect(find.byType(InstitutionLogoWidget), findsOneWidget);
      },
    );
  });
}
