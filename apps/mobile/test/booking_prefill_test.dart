import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/core/services/local_storage_service.dart';
import 'package:mobile/features/bills/presentation/screens/add_edit_bill_screen.dart';
import 'package:mobile/features/budget/presentation/screens/add_edit_budget_screen.dart';
import 'package:mobile/features/consult/domain/models/consultant.dart';
import 'package:mobile/features/consult/presentation/providers/booking_provider.dart';
import 'package:mobile/features/consult/presentation/screens/booking_flow_screen.dart';
import 'package:mobile/features/consult/presentation/widgets/booking_intake_description_box.dart';
import 'package:mobile/features/consult/presentation/widgets/booking_intake_topics_grid.dart';
import 'package:mobile/features/consult/presentation/widgets/booking_service_tier_card.dart';
import 'package:mobile/features/consult/presentation/widgets/consult_detail_bottom_bar.dart';
import 'package:mobile/features/consult/presentation/widgets/sticky_booking_bottom_bar.dart';
import 'package:mobile/features/goals/presentation/screens/add_edit_goal_screen.dart';
import 'package:mobile/features/match_expert/presentation/providers/match_expert_provider.dart';
import 'package:mobile/features/match_expert/presentation/screens/match_expert_screen.dart';
import 'package:mobile/features/services/presentation/screens/debt_payoff_strategy_screen.dart';
import 'package:mobile/features/services/presentation/screens/financial_test_catalog_screen.dart';
import 'package:mobile/router/app_router.dart';

Widget _scaleForAhem(BuildContext context, Widget? child) {
  final mq = MediaQuery.of(context);
  return MediaQuery(
    data: mq.copyWith(textScaler: const TextScaler.linear(0.55)),
    child: child ?? const SizedBox.shrink(),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('id_ID', null);
  });

  group('BookingNotifier prefillFromAi & reset', () {
    test('prefillFromAi populates AI fields and reset clears them cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(bookingProvider.notifier).prefillFromAi(
            packageCode: 'couple_pre_marriage',
            selectedTierLabel: 'Paket Pasutri & Pranikah',
            unitPrice: 349000,
            serviceType: 'Online',
            topics: ['Transparansi Uang Pranikah'],
            description: 'Diskusi rekening pasutri sebelum nikah',
            expectations: 'Sepakat model rekening keluarga',
          );

      final prefilled = container.read(bookingProvider);
      expect(prefilled.isPrefilledFromAi, isTrue);
      expect(prefilled.selectedPackageCode, equals('couple_pre_marriage'));
      expect(prefilled.selectedTier, equals('Paket Pasutri & Pranikah'));
      expect(prefilled.totalPrice, equals(349000));
      expect(prefilled.serviceType, equals('Online'));
      expect(prefilled.prefilledTopics, equals(['Transparansi Uang Pranikah']));
      expect(prefilled.topic, equals('Transparansi Uang Pranikah'));
      expect(prefilled.description, equals('Diskusi rekening pasutri sebelum nikah'));
      expect(prefilled.expectations, equals('Sepakat model rekening keluarga'));

      container.read(bookingProvider.notifier).reset();

      final resetState = container.read(bookingProvider);
      expect(resetState.isPrefilledFromAi, isFalse);
      expect(resetState.selectedPackageCode, isNull);
      expect(resetState.prefilledTopics, isEmpty);
      expect(resetState.topic, isEmpty);
      expect(resetState.description, isEmpty);
      expect(resetState.expectations, isEmpty);
      expect(resetState.selectedTier, isEmpty);
      expect(resetState.totalPrice, equals(0.0));
    });
  });

  group('BookingFlowScreen AI Prefill Hydration', () {
    testWidgets(
      'Step 1 preserves AI prefill, selects couple_pre_marriage, enables Selanjutnya, and Step 3 shows prefilled topic and description',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(bookingProvider.notifier).prefillFromAi(
              packageCode: 'couple_pre_marriage',
              selectedTierLabel: 'Paket Pasutri & Pranikah',
              unitPrice: 349000,
              topics: ['Transparansi Uang Pranikah'],
              description: 'Diskusi rekening pasutri sebelum nikah',
              expectations: 'Sepakat model rekening 1 pintu',
            );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              builder: _scaleForAhem,
              home: BookingFlowScreen(consultantId: 'c1'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Step 1 must NOT wipe AI prefill context
        final stateAfterStep1Mount = container.read(bookingProvider);
        expect(stateAfterStep1Mount.isPrefilledFromAi, isTrue);
        expect(stateAfterStep1Mount.selectedPackageCode, equals('couple_pre_marriage'));
        expect(
          stateAfterStep1Mount.description,
          equals('Diskusi rekening pasutri sebelum nikah'),
        );

        // Prefilled package card is selected
        final cards = tester
            .widgetList<BookingServiceTierCard>(find.byType(BookingServiceTierCard))
            .toList();
        final coupleCard = cards.firstWhere(
          (c) => c.service.packageCode == 'couple_pre_marriage',
        );
        expect(coupleCard.isSelected, isTrue);

        // Selanjutnya button on Step 1 is enabled immediately
        final step1BottomBar = tester.widget<StickyBookingBottomBar>(
          find.byType(StickyBookingBottomBar),
        );
        expect(step1BottomBar.onTap, isNotNull);
        expect(step1BottomBar.price, equals(349000));

        // Advance to Step 2
        await tester.tap(find.text('Selanjutnya'));
        await tester.pumpAndSettle();
        expect(find.text('Pilih Jadwal Konsultasi'), findsOneWidget);

        // Pick a schedule slot and advance to Step 3
        final slotFinder = find.text('09:00 - 10:00');
        await tester.ensureVisible(slotFinder);
        await tester.tap(slotFinder);
        await tester.pumpAndSettle();

        final step2BottomBar = tester.widget<StickyBookingBottomBar>(
          find.byType(StickyBookingBottomBar),
        );
        expect(step2BottomBar.onTap, isNotNull);

        await tester.tap(find.text('Selanjutnya'));
        await tester.pumpAndSettle();
        expect(find.text('Pre-Assessment Konsultasi'), findsOneWidget);

        // Step 3 shows prefilled topic selected and description in BookingIntakeDescriptionBox
        final topicsGrid = tester.widget<BookingIntakeTopicsGrid>(
          find.byType(BookingIntakeTopicsGrid),
        );
        expect(
          topicsGrid.selectedTopics,
          contains('Transparansi Uang Pranikah'),
        );

        final descBox = tester.widget<BookingIntakeDescriptionBox>(
          find.byType(BookingIntakeDescriptionBox),
        );
        expect(
          descBox.controller.text,
          equals('Diskusi rekening pasutri sebelum nikah'),
        );
        expect(
          descBox.expectationsController.text,
          equals('Sepakat model rekening 1 pintu'),
        );
        expect(
          find.descendant(
            of: find.byType(BookingIntakeDescriptionBox),
            matching: find.text('Diskusi rekening pasutri sebelum nikah'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Cross-consultant prefill prioritizes couple_pre_marriage and pins custom topic on c3',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(bookingProvider.notifier).prefillFromAi(
              packageCode: 'couple_pre_marriage',
              selectedTierLabel: 'Paket Pasutri & Pranikah',
              unitPrice: 349000,
              topics: ['Transparansi Uang Pranikah'],
              description: 'Diskusi keuangan pasangan muda',
            );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              builder: _scaleForAhem,
              home: BookingFlowScreen(consultantId: 'c3', initialStep: 2),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final topicsGrid = tester.widget<BookingIntakeTopicsGrid>(
          find.byType(BookingIntakeTopicsGrid),
        );
        expect(topicsGrid.selectedTopics, contains('Transparansi Uang Pranikah'));
        expect(find.text('Transparansi Uang Pranikah'), findsOneWidget);
        expect(find.text('Diskusi keuangan pasangan muda'), findsOneWidget);
      },
    );
  });

  group('Organic Booking Entry Points Reset Stale AI State', () {
    Future<void> seedAiPrefill(ProviderContainer container) async {
      container.read(bookingProvider.notifier).prefillFromAi(
            packageCode: 'couple_pre_marriage',
            selectedTierLabel: 'Paket Pasutri & Pranikah',
            unitPrice: 349000,
            topics: ['Transparansi Uang Pranikah'],
            description: 'Diskusi rekening pasutri sebelum nikah',
          );
    }

    GoRouter createTestBookingRouter(Widget home) {
      return GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => home,
          ),
          GoRoute(
            path: '/booking/:consultantId/service',
            builder: (context, state) => BookingFlowScreen(
              consultantId: state.pathParameters['consultantId']!,
              initialStep: 0,
            ),
          ),
        ],
      );
    }

    testWidgets('ConsultDetailBottomBar resets bookingProvider before push', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await seedAiPrefill(container);

      final consultant = ConsultantRepository.initialConsultants.first;
      final router = createTestBookingRouter(
        Scaffold(bottomNavigationBar: ConsultDetailBottomBar(consultant: consultant)),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            builder: _scaleForAhem,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pesan Sekarang'));
      await tester.pumpAndSettle();

      final state = container.read(bookingProvider);
      expect(state.isPrefilledFromAi, isFalse);
      expect(state.selectedPackageCode, isNull);
      expect(state.description, isEmpty);
    });

    testWidgets('DebtPayoffStrategyScreen resets bookingProvider before push', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await seedAiPrefill(container);

      final router = createTestBookingRouter(const DebtPayoffStrategyScreen());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            builder: _scaleForAhem,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final ctaFinder = find.text('Ambil Paket: Fondasi Arus Kas & Utang');
      await tester.ensureVisible(ctaFinder);
      await tester.tap(ctaFinder);
      await tester.pumpAndSettle();

      final state = container.read(bookingProvider);
      expect(state.isPrefilledFromAi, isFalse);
      expect(state.selectedPackageCode, isNull);
      expect(state.description, isEmpty);
    });

    testWidgets('FinancialTestCatalogScreen resets bookingProvider before push', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await seedAiPrefill(container);

      final router = createTestBookingRouter(const FinancialTestCatalogScreen());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            builder: _scaleForAhem,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final ctaFinder = find.textContaining('Pesan Sesi Check-Up');
      await tester.ensureVisible(ctaFinder);
      await tester.tap(ctaFinder);
      await tester.pumpAndSettle();

      final state = container.read(bookingProvider);
      expect(state.isPrefilledFromAi, isFalse);
      expect(state.selectedPackageCode, isNull);
      expect(state.description, isEmpty);
    });

    testWidgets('MatchExpertScreen resets bookingProvider before push', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await seedAiPrefill(container);

      // Advance MatchExpertNotifier from step 0 to result step 13
      for (var i = 0; i < 13; i++) {
        container.read(matchExpertProvider.notifier).nextStep();
      }

      final router = createTestBookingRouter(const MatchExpertScreen());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            builder: _scaleForAhem,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final ctaFinder = find.text('Pilih Jadwal Konsultasi');
      await tester.ensureVisible(ctaFinder);
      await tester.tap(ctaFinder);
      await tester.pumpAndSettle();

      final state = container.read(bookingProvider);
      expect(state.isPrefilledFromAi, isFalse);
      expect(state.selectedPackageCode, isNull);
      expect(state.description, isEmpty);
    });
  });

  group('Planning Draft Route Prefill via GoRouter extra', () {
    Future<SharedPreferences> createAuthenticatedPrefs() async {
      final userJson = jsonEncode({
        'id': 'usr_test_1',
        'name': 'Tester Clarafin',
        'email': 'tester@clarafin.id',
        'password': 'secret',
      });
      SharedPreferences.setMockInitialValues({
        'clarafin_is_logged_in': true,
        'clarafin_active_user_id': 'usr_test_1',
        'clarafin_registered_accounts': [userJson],
      });
      return SharedPreferences.getInstance();
    }

    Future<void> pumpAppRouterAndClearSplash(
      WidgetTester tester,
      ProviderContainer container,
      GoRouter router,
    ) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            builder: _scaleForAhem,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    }

    testWidgets('/goal/add prefills AddEditGoalScreen from extra map', (tester) async {
      tester.view.physicalSize = const Size(500, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final prefs = await createAuthenticatedPrefs();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final router = container.read(goRouterProvider);
      await pumpAppRouterAndClearSplash(tester, container, router);

      router.push('/goal/add', extra: {
        'name': 'Dana Darurat 6 Bulan',
        'targetAmount': 30000000.0,
        'deadline': '2027-06-30',
      });
      await tester.pumpAndSettle();

      expect(find.byType(AddEditGoalScreen), findsOneWidget);
      expect(find.text('Dana Darurat 6 Bulan'), findsOneWidget);
      expect(find.text('30.000.000'), findsOneWidget);
      expect(find.text('30 June 2027'), findsOneWidget);
    });

    testWidgets('/bill/add prefills AddEditBillScreen from extra map', (tester) async {
      tester.view.physicalSize = const Size(500, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final prefs = await createAuthenticatedPrefs();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final router = container.read(goRouterProvider);
      await pumpAppRouterAndClearSplash(tester, container, router);

      router.push('/bill/add', extra: {
        'title': 'Indihome Fiber',
        'amount': 385000.0,
        'dueDay': 20,
        'frequency': 'monthly',
        'category': 'internet',
      });
      await tester.pumpAndSettle();

      expect(find.byType(AddEditBillScreen), findsOneWidget);
      expect(find.text('Indihome Fiber'), findsOneWidget);
      expect(find.text('385.000'), findsOneWidget);
      expect(find.textContaining('20 '), findsOneWidget);
    });

    testWidgets('/budget/add prefills AddEditBudgetScreen from extra map', (tester) async {
      tester.view.physicalSize = const Size(500, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final prefs = await createAuthenticatedPrefs();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final router = container.read(goRouterProvider);
      await pumpAppRouterAndClearSplash(tester, container, router);

      router.push('/budget/add', extra: {
        'category': 'Food & Beverage',
        'limitAmount': 1500000.0,
      });
      await tester.pumpAndSettle();

      expect(find.byType(AddEditBudgetScreen), findsOneWidget);
      expect(find.text('Food & Beverage'), findsOneWidget);
      expect(find.text('1.500.000'), findsOneWidget);
      expect(find.text('DAILY NEEDS'), findsOneWidget);
    });

    testWidgets('/budget/add resolves Indonesian category alias Makanan', (tester) async {
      tester.view.physicalSize = const Size(500, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final prefs = await createAuthenticatedPrefs();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final router = container.read(goRouterProvider);
      await pumpAppRouterAndClearSplash(tester, container, router);

      router.push('/budget/add', extra: {
        'category': 'Makanan',
        'limitAmount': 800000.0,
      });
      await tester.pumpAndSettle();

      expect(find.byType(AddEditBudgetScreen), findsOneWidget);
      expect(find.text('Food & Beverage'), findsOneWidget);
      expect(find.text('800.000'), findsOneWidget);
    });

    testWidgets('/goal/add without extra opens clean empty form', (tester) async {
      tester.view.physicalSize = const Size(500, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final prefs = await createAuthenticatedPrefs();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final router = container.read(goRouterProvider);
      await pumpAppRouterAndClearSplash(tester, container, router);

      router.push('/goal/add');
      await tester.pumpAndSettle();

      expect(find.byType(AddEditGoalScreen), findsOneWidget);
      final inputs = tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();
      expect(inputs.every((f) => (f.controller?.text ?? '').isEmpty), isTrue);
    });
  });
}
