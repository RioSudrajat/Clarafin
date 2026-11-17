import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile/core/theme/neo_brutalism_decorations.dart';
import 'package:mobile/features/consult/presentation/providers/booking_provider.dart';
import 'package:mobile/features/session/domain/models/ai_chat_models.dart';
import 'package:mobile/features/session/presentation/widgets/ai_recommended_consultant_card.dart';
import 'package:mobile/features/session/presentation/widgets/ai_recommended_consultants_section.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('id_ID', null);
  });

  const samplePackage = AiPackageRecommendation(
    packageCode: 'couple_pre_marriage',
    categoryTag: 'Couple Advisory • Pre-Marriage',
    packageTitle: 'Siap Menikah Tanpa Drama Finansial',
    priceIdr: 349000,
    durationMinutes: 60,
    sessionCount: 1,
  );

  final sampleConsultants = [
    AiConsultantRecommendation(
      consultantId: 'c1',
      name: 'Chrysan Gomargana, S.E., CFP®',
      certifications: const ['CFP®'],
      avatarUrl: 'assets/images/avatars/missing_avatar_test.png',
      tierLabel: 'Medium',
      ratingAvg: 4.95,
      totalSessionsCompleted: 380,
      matchReason:
          'Spesialis keuangan pranikah dan penataan rekening pasangan muda.',
      nextAvailableSlotAt: DateTime(2026, 11, 18, 19, 0),
      nextAvailableSlotLabel: 'Besok, 19:00 WIB',
      isStaffPinned: true,
      selectedPackageCode: 'couple_pre_marriage',
      unitPrice: 349000,
      recommendedTopics: const ['Keuangan Pranikah', 'Dana Nikah'],
      prefilledDescription: 'Ingin menyusun dana nikah Rp 50 jt.',
      prefilledExpectations: 'Pembagian rekening pasutri yang adil.',
    ),
    const AiConsultantRecommendation(
      consultantId: 'c5',
      name: 'Nadia Kusuma, S.Psi., CFP®, AEPP®',
      certifications: ['CFP®', 'AEPP®'],
      avatarUrl: '',
      tierLabel: 'Premium',
      ratingAvg: 4.96,
      totalSessionsCompleted: 610,
      matchReason: 'Berpengalaman mendampingi perencanaan aset keluarga.',
      nextAvailableSlotLabel: 'Jumat, 14:00 WIB',
      isStaffPinned: false,
      selectedPackageCode: 'couple_pre_marriage',
      unitPrice: 349000,
      recommendedTopics: ['Keuangan Keluarga'],
      prefilledDescription: 'Diskusi anggaran rumah tangga.',
      prefilledExpectations: 'Rencana proteksi keluarga.',
    ),
  ];

  group('AiRecommendedConsultantsSection Widget Tests', () {
    testWidgets(
      'renders 1 package banner and 2 consultant cards on 360x640 with zero overflow and >=44px tap targets',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final overflowErrors = <FlutterErrorDetails>[];
        final previousOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.exceptionAsString().contains('overflowed') ||
              details.exceptionAsString().contains('RenderFlex')) {
            overflowErrors.add(details);
          }
          previousOnError?.call(details);
        };
        addTearDown(() => FlutterError.onError = previousOnError);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: AiRecommendedConsultantsSection(
                    recommendedPackage: samplePackage,
                    consultants: sampleConsultants,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(overflowErrors, isEmpty);

        // Catalog Package Context Banner assertions
        expect(find.text('Couple Advisory • Pre-Marriage'), findsOneWidget);
        expect(find.text('Siap Menikah Tanpa Drama Finansial'), findsOneWidget);
        expect(find.textContaining('Rp 349.000'), findsOneWidget);
        expect(find.textContaining('60 menit'), findsOneWidget);
        expect(find.textContaining('1 sesi'), findsOneWidget);

        // Consultant Cards assertions
        expect(find.text('Chrysan Gomargana, S.E., CFP®'), findsOneWidget);
        expect(find.text('Nadia Kusuma, S.Psi., CFP®, AEPP®'), findsOneWidget);
        expect(find.text('Medium'), findsOneWidget);
        expect(find.text('Premium'), findsOneWidget);
        expect(find.text('Staff Curated'), findsOneWidget);
        expect(find.textContaining('4.95'), findsOneWidget);
        expect(find.textContaining('380 sesi'), findsOneWidget);
        expect(
          find.textContaining('Slot terdekat: Besok, 19:00 WIB'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Slot terdekat: Jumat, 14:00 WIB'),
          findsOneWidget,
        );

        // Missing/empty avatar fallback renders initials cleanly
        expect(find.text('CG'), findsOneWidget);
        expect(find.text('NK'), findsOneWidget);

        // Action buttons >= 44x44 tap target size
        final viewProfileButtons = find.widgetWithText(InkWell, 'Lihat Profil');
        final scheduleButtons = find.widgetWithText(
          InkWell,
          'Pilih & Jadwalkan',
        );
        expect(viewProfileButtons, findsNWidgets(2));
        expect(scheduleButtons, findsNWidgets(2));

        for (var i = 0; i < 2; i++) {
          final viewSize = tester.getSize(viewProfileButtons.at(i));
          final scheduleSize = tester.getSize(scheduleButtons.at(i));
          expect(viewSize.height, greaterThanOrEqualTo(44.0));
          expect(viewSize.width, greaterThanOrEqualTo(44.0));
          expect(scheduleSize.height, greaterThanOrEqualTo(44.0));
          expect(scheduleSize.width, greaterThanOrEqualTo(44.0));
        }
      },
    );

    testWidgets(
      'tapping Pilih & Jadwalkan populates bookingProvider and triggers schedule callback',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        AiConsultantRecommendation? scheduledConsultant;
        String? viewedConsultantId;

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: AiRecommendedConsultantsSection(
                    recommendedPackage: samplePackage,
                    consultants: sampleConsultants,
                    onViewProfile: (id) => viewedConsultantId = id,
                    onSchedule: (c) => scheduledConsultant = c,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final viewFirst = find.text('Lihat Profil').first;
        await tester.ensureVisible(viewFirst);
        await tester.tap(viewFirst);
        await tester.pump();
        expect(viewedConsultantId, equals('c1'));

        final scheduleFirst = find.text('Pilih & Jadwalkan').first;
        await tester.ensureVisible(scheduleFirst);
        await tester.tap(scheduleFirst);
        await tester.pump();

        expect(scheduledConsultant?.consultantId, equals('c1'));

        final booking = container.read(bookingProvider);
        expect(booking.isPrefilledFromAi, isTrue);
        expect(booking.selectedPackageCode, equals('couple_pre_marriage'));
        expect(booking.selectedTier, equals('Medium'));
        expect(booking.totalPrice, equals(349000.0));
        expect(
          booking.prefilledTopics,
          equals(['Keuangan Pranikah', 'Dana Nikah']),
        );
        expect(booking.description, equals('Ingin menyusun dana nikah Rp 50 jt.'));
        expect(
          booking.expectations,
          equals('Pembagian rekening pasutri yang adil.'),
        );
      },
    );

    testWidgets(
      'falls back to recommendedPackage packageCode, packageTitle, and priceIdr when consultant fields are empty and routes via GoRouter',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        const fallbackConsultant = AiConsultantRecommendation(
          consultantId: 'c3',
          name: 'Rian Pratama, S.Ak., QWP®, AWP®',
          certifications: ['QWP®', 'AWP®'],
          avatarUrl: 'https://invalid.example/broken-avatar.png',
          tierLabel: '',
          ratingAvg: 4.88,
          totalSessionsCompleted: 190,
          matchReason: 'Cocok untuk fondasi arus kas dan utang konsumtif.',
          nextAvailableSlotLabel: 'Hari ini, 16:00 WIB',
          selectedPackageCode: '',
          unitPrice: 0,
          recommendedTopics: ['Arus Kas', 'Utang'],
          prefilledDescription: 'Butuh rencana pelunasan PayLater.',
        );

        const fallbackPackage = AiPackageRecommendation(
          packageCode: 'personal_basic',
          categoryTag: 'Personal Advisory • Basic',
          packageTitle: 'Fondasi Arus Kas & Utang',
          priceIdr: 199000,
          durationMinutes: 60,
          sessionCount: 1,
        );

        String? pushedLocation;
        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: AiRecommendedConsultantsSection(
                    recommendedPackage: fallbackPackage,
                    consultants: const [fallbackConsultant],
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/booking/:consultantId/service',
              builder: (context, state) {
                pushedLocation = state.uri.toString();
                return const Scaffold(body: Text('Booking Service Target'));
              },
            ),
            GoRoute(
              path: '/consult/:id',
              builder: (context, state) {
                pushedLocation = state.uri.toString();
                return Scaffold(
                  body: Text('Profile ${state.pathParameters['id']}'),
                );
              },
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('RP'), findsOneWidget);

        // Verify Lihat Profil default GoRouter navigation
        final viewBtn = find.text('Lihat Profil');
        await tester.ensureVisible(viewBtn);
        await tester.tap(viewBtn);
        await tester.pumpAndSettle();
        expect(pushedLocation, equals('/consult/c3'));
        expect(find.text('Profile c3'), findsOneWidget);

        router.pop();
        await tester.pumpAndSettle();

        // Verify Pilih & Jadwalkan prefill + GoRouter navigation
        final scheduleBtn = find.text('Pilih & Jadwalkan');
        await tester.ensureVisible(scheduleBtn);
        await tester.tap(scheduleBtn);
        await tester.pumpAndSettle();

        final booking = container.read(bookingProvider);
        expect(booking.isPrefilledFromAi, isTrue);
        expect(booking.selectedPackageCode, equals('personal_basic'));
        expect(booking.selectedTier, equals('Fondasi Arus Kas & Utang'));
        expect(booking.totalPrice, equals(199000.0));
        expect(booking.prefilledTopics, equals(['Arus Kas', 'Utang']));
        expect(booking.description, equals('Butuh rencana pelunasan PayLater.'));
        expect(pushedLocation, equals('/booking/c3/service'));
        expect(find.text('Booking Service Target'), findsOneWidget);
      },
    );

    testWidgets(
      'caps rendered cards at 3, handles slot fallbacks, narrow 280px width, and empty states',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final overflowErrors = <FlutterErrorDetails>[];
        final previousOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.exceptionAsString().contains('overflowed') ||
              details.exceptionAsString().contains('RenderFlex')) {
            overflowErrors.add(details);
          }
          previousOnError?.call(details);
        };
        addTearDown(() => FlutterError.onError = previousOnError);

        final fourConsultants = [
          ...sampleConsultants,
          AiConsultantRecommendation(
            consultantId: 'c4',
            name: 'Dr. Hendra Wijaya, MBA, CFA®, CFP®',
            tierLabel: 'Premium',
            nextAvailableSlotAt: DateTime(2026, 11, 20, 10, 30),
          ),
          const AiConsultantRecommendation(
            consultantId: 'c6',
            name: 'Budi Santoso, S.E., Ak., CPA, CFP®',
            tierLabel: 'Medium',
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: SizedBox(
                    width: 280,
                    child: AiRecommendedConsultantsSection(
                      recommendedPackage: samplePackage,
                      consultants: fourConsultants,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(overflowErrors, isEmpty);
        expect(find.byType(AiRecommendedConsultantCard), findsNWidgets(3));
        expect(find.text('Dr. Hendra Wijaya, MBA, CFA®, CFP®'), findsOneWidget);
        expect(find.text('HW'), findsOneWidget);
        expect(find.text('Budi Santoso, S.E., Ak., CPA, CFP®'), findsNothing);
        expect(
          find.textContaining('Slot terdekat: 20/11, 10:30 WIB'),
          findsOneWidget,
        );

        // Empty consultants with non-null package renders explicit empty state
        String? pushedEmptyAction;
        final emptyRouter = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const Scaffold(
                body: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: AiRecommendedConsultantsSection(
                    recommendedPackage: samplePackage,
                    consultants: [],
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/consult',
              builder: (context, state) {
                pushedEmptyAction = state.uri.toString();
                return const Scaffold(body: Text('All Consultants List'));
              },
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(routerConfig: emptyRouter),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Belum ada konsultan tersedia'), findsOneWidget);
        final exploreBtn = find.widgetWithText(InkWell, 'Lihat Semua Konsultan');
        expect(tester.getSize(exploreBtn).height, greaterThanOrEqualTo(44.0));
        await tester.tap(exploreBtn);
        await tester.pumpAndSettle();
        expect(pushedEmptyAction, equals('/consult'));
      },
    );

    testWidgets(
      'renders with zero overflow and >=44x44 targets at 360x640 with 2.0x text scale',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final overflowErrors = <FlutterErrorDetails>[];
        final previousOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.exceptionAsString().contains('overflowed') ||
              details.exceptionAsString().contains('RenderFlex')) {
            overflowErrors.add(details);
          }
          previousOnError?.call(details);
        };
        addTearDown(() => FlutterError.onError = previousOnError);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              builder: (context, child) {
                final mq = MediaQuery.of(context);
                return MediaQuery(
                  data: mq.copyWith(textScaler: const TextScaler.linear(2.0)),
                  child: child!,
                );
              },
              home: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      AiRecommendedConsultantsSection(
                        recommendedPackage: samplePackage,
                        consultants: sampleConsultants,
                      ),
                      const SizedBox(height: 16),
                      const AiRecommendedConsultantsSection(
                        recommendedPackage: samplePackage,
                        consultants: [],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(overflowErrors, isEmpty);

        final allButtons = find.byType(AiNeoActionButton);
        expect(allButtons, findsNWidgets(5));
        for (var i = 0; i < 5; i++) {
          final inkWell = find.descendant(
            of: allButtons.at(i),
            matching: find.byType(InkWell),
          );
          final size = tester.getSize(inkWell);
          expect(size.width, greaterThanOrEqualTo(44.0));
          expect(size.height, greaterThanOrEqualTo(44.0));
        }
      },
    );

    testWidgets(
      'exposes single non-duplicated Semantics and high-contrast darkTeal focus ring on keyboard Tab + Enter',
      (tester) async {
        final semanticsHandle = tester.ensureSemantics();
        try {
          String? viewedId;
          AiConsultantRecommendation? scheduled;

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                home: Scaffold(
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: AiRecommendedConsultantsSection(
                      recommendedPackage: null,
                      consultants: [sampleConsultants.first],
                      onViewProfile: (id) => viewedId = id,
                      onSchedule: (c) => scheduled = c,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // When recommendedPackage is null, no banner is shown and card renders.
          expect(find.text('Couple Advisory • Pre-Marriage'), findsNothing);
          expect(find.text('Chrysan Gomargana, S.E., CFP®'), findsOneWidget);

          // Verify clean single-node Semantics without duplicate label announcements.
          final viewInkWell = find.widgetWithText(InkWell, 'Lihat Profil');
          final scheduleInkWell = find.widgetWithText(
            InkWell,
            'Pilih & Jadwalkan',
          );
          final viewSemantics = tester.getSemantics(viewInkWell);
          final scheduleSemantics = tester.getSemantics(scheduleInkWell);

          expect(viewSemantics.label, equals('Lihat Profil'));
          expect(scheduleSemantics.label, equals('Pilih & Jadwalkan'));
          final viewData = viewSemantics.getSemanticsData();
          final scheduleData = scheduleSemantics.getSemanticsData();
          expect(viewData.flagsCollection.isButton, isTrue);
          expect(scheduleData.flagsCollection.isButton, isTrue);
          expect(viewData.hasAction(SemanticsAction.tap), isTrue);
          expect(scheduleData.hasAction(SemanticsAction.tap), isTrue);

          // Tab onto Lihat Profil and verify high-contrast #0E6976 focus ring.
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();

          final firstBtnContainer = tester.widget<Container>(
            find
                .descendant(
                  of: find.byType(AiNeoActionButton).first,
                  matching: find.byType(Container),
                )
                .first,
          );
          final firstBorder =
              (firstBtnContainer.decoration as BoxDecoration).border as Border;
          expect(firstBorder.top.color, equals(NeoBrutalism.darkTeal));

          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pump();
          expect(viewedId, equals('c1'));

          // Tab to Pilih & Jadwalkan and verify focus ring + Enter activation.
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();

          final secondBtnContainer = tester.widget<Container>(
            find
                .descendant(
                  of: find.byType(AiNeoActionButton).last,
                  matching: find.byType(Container),
                )
                .first,
          );
          final secondBorder =
              (secondBtnContainer.decoration as BoxDecoration).border as Border;
          expect(secondBorder.top.color, equals(NeoBrutalism.darkTeal));

          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pump();
          expect(scheduled?.consultantId, equals('c1'));
        } finally {
          semanticsHandle.dispose();
        }
      },
    );

    testWidgets(
      'collapses to SizedBox.shrink when both recommendedPackage is null and consultants is empty',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: AiRecommendedConsultantsSection(
                  recommendedPackage: null,
                  consultants: [],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AiRecommendedConsultantCard), findsNothing);
        expect(find.text('Belum ada konsultan tersedia'), findsNothing);
      },
    );
  });
}
