import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/services/local_storage_service.dart';
import 'package:mobile/core/theme/neo_brutalism_decorations.dart';
import 'package:mobile/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:mobile/features/session/domain/models/ai_chat_models.dart';
import 'package:mobile/features/session/presentation/widgets/ai_money_flow_card.dart';
import 'package:mobile/features/session/presentation/widgets/ai_money_flow_painter.dart';
import 'package:mobile/features/session/presentation/widgets/ai_spending_breakdown_table_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<SharedPreferences> createMockPrefs() async {
    SharedPreferences.setMockInitialValues({});
    return SharedPreferences.getInstance();
  }

  Widget wrapAtPhoneWidth({
    required SharedPreferences prefs,
    required Widget child,
  }) {
    return ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(360, 640)),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SizedBox(width: 328, child: child),
            ),
          ),
        ),
      ),
    );
  }

  const sampleFlow = AiMoneyFlowData(
    periodLabel: 'Okt 2026',
    totalIncome: 10320000,
    totalExpense: 5942000,
    netCashflow: 4378000,
    transactionCount: 67,
    incomeSources: [
      AiMoneyFlowNode(
        label: 'Gaji Bulanan Utama',
        amount: 10230000,
        colorHex: '#10B981',
        percentage: 99.1,
      ),
      AiMoneyFlowNode(
        label: 'Bunga Tabungan',
        amount: 90000,
        colorHex: '#0F758A',
        percentage: 0.9,
      ),
    ],
    expenseCategories: [
      AiMoneyFlowNode(
        label: 'Kos / Sewa Apartemen',
        amount: 2450000,
        colorHex: '#F59E0B',
        percentage: 41.2,
      ),
      AiMoneyFlowNode(
        label: 'Makan Luar & Kopi',
        amount: 3492000,
        colorHex: '#DC2626',
        percentage: 58.8,
      ),
    ],
    flows: [
      AiMoneyFlowEdge(sourceIndex: 0, targetIndex: 0, amount: 2450000),
      AiMoneyFlowEdge(sourceIndex: 0, targetIndex: 1, amount: 3402000),
      AiMoneyFlowEdge(sourceIndex: 1, targetIndex: 1, amount: 90000),
    ],
    breakdownSummary: 'Kos / Sewa menjadi pos pengeluaran terbesar (41.2%).',
  );

  group('AiMoneyFlowCard', () {
    testWidgets(
      'renders at 360px width without overflow and triggers onViewReporting with >= 44px hit target',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final prefs = await createMockPrefs();
        var tappedReporting = false;

        await tester.pumpWidget(
          wrapAtPhoneWidth(
            prefs: prefs,
            child: AiMoneyFlowCard(
              data: sampleFlow,
              onViewReporting: () => tappedReporting = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Money Flow'), findsOneWidget);
        expect(find.text('Okt 2026'), findsOneWidget);
        expect(find.textContaining('10.320.000'), findsOneWidget);
        expect(find.textContaining('5.942.000'), findsOneWidget);
        expect(find.text('Spending Breakdown'), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);

        final reportingTrigger = find.byKey(
          const Key('money_flow_reporting_link'),
        );
        expect(reportingTrigger, findsOneWidget);
        final triggerSize = tester.getSize(reportingTrigger);
        expect(triggerSize.height, greaterThanOrEqualTo(44.0));
        expect(triggerSize.width, greaterThanOrEqualTo(44.0));

        await tester.tap(reportingTrigger);
        await tester.pump();
        expect(tappedReporting, isTrue);
      },
    );

    testWidgets(
      'guards empty nodes, zero income/expense, NaN amounts, and out-of-bounds edges without exceptions',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final prefs = await createMockPrefs();

        const emptyFlow = AiMoneyFlowData(
          periodLabel: 'Nov 2026',
          totalIncome: 0,
          totalExpense: 0,
          netCashflow: 0,
          transactionCount: 0,
        );

        await tester.pumpWidget(
          wrapAtPhoneWidth(
            prefs: prefs,
            child: const AiMoneyFlowCard(data: emptyFlow),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.textContaining('Belum ada aliran dana'), findsOneWidget);

        const dirtyFlow = AiMoneyFlowData(
          periodLabel: 'Des 2026',
          totalIncome: 0,
          totalExpense: 0,
          netCashflow: 0,
          transactionCount: 2,
          incomeSources: [
            AiMoneyFlowNode(
              label: 'Nol',
              amount: 0,
              colorHex: 'invalid-hex',
            ),
          ],
          expenseCategories: [
            AiMoneyFlowNode(
              label: 'Negatif',
              amount: -50,
              colorHex: '#10B981',
            ),
          ],
          flows: [
            AiMoneyFlowEdge(sourceIndex: -1, targetIndex: 0, amount: 100),
            AiMoneyFlowEdge(sourceIndex: 0, targetIndex: 99, amount: 100),
            AiMoneyFlowEdge(sourceIndex: 5, targetIndex: 2, amount: 0),
            AiMoneyFlowEdge(sourceIndex: 0, targetIndex: 0, amount: double.nan),
          ],
        );

        await tester.pumpWidget(
          wrapAtPhoneWidth(
            prefs: prefs,
            child: const AiMoneyFlowCard(data: dirtyFlow),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        final painter = AiMoneyFlowPainter(
          data: dirtyFlow,
          currencyCode: 'IDR',
        );
        expect(painter.shouldRepaint(painter), isFalse);
      },
    );

    testWidgets(
      'uses GoRouter /reporting fallback and formats currency from userProfileProvider',
      (tester) async {
        final prefs = await createMockPrefs();
        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);
        container.read(userProfileProvider.notifier).setCurrency('USD');

        final router = GoRouter(
          initialLocation: '/chat',
          routes: [
            GoRoute(
              path: '/chat',
              builder: (_, _) => const Scaffold(
                body: SingleChildScrollView(
                  child: AiMoneyFlowCard(data: sampleFlow),
                ),
              ),
            ),
            GoRoute(
              path: '/reporting',
              builder: (_, _) =>
                  const Scaffold(body: Text('Reporting Screen')),
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

        expect(find.textContaining(r'$645'), findsOneWidget);

        await tester.tap(find.byKey(const Key('money_flow_reporting_link')));
        await tester.pumpAndSettle();
        expect(find.text('Reporting Screen'), findsOneWidget);
      },
    );
  });

  group('AiSpendingBreakdownTableCard', () {
    const sampleTable = AiSpendingTableData(
      title: 'Rincian pengeluaran kopi (1-31 Okt 2026)',
      rows: [
        AiSpendingMerchantRow(
          merchant:
              'Kopi Kenangan Super Flagship Store Sudirman Central Business District Jakarta Selatan',
          transactionCount: 9,
          totalAmount: 195000,
        ),
        AiSpendingMerchantRow(
          merchant: 'Fore Coffee',
          transactionCount: 3,
          totalAmount: 84000,
        ),
      ],
      totalAmount: 279000,
      totalTransactions: 12,
      footnote: 'Dibayar lewat GoPay dan BCA pada kategori Food & Beverage.',
    );

    testWidgets(
      'renders long merchant names without 360px overflow, shows Total, and meets >= 44px hit target',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final prefs = await createMockPrefs();
        var tappedHistory = false;

        await tester.pumpWidget(
          wrapAtPhoneWidth(
            prefs: prefs,
            child: AiSpendingBreakdownTableCard(
              data: sampleTable,
              onViewHistory: () => tappedHistory = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          find.text('Rincian pengeluaran kopi (1-31 Okt 2026)'),
          findsOneWidget,
        );
        expect(find.text('MERCHANT'), findsOneWidget);
        expect(find.text('TRANSAKSI'), findsOneWidget);
        expect(find.text('TOTAL'), findsOneWidget);
        expect(find.text('Total'), findsOneWidget);
        expect(find.text('12'), findsOneWidget);
        expect(find.textContaining('279.000'), findsOneWidget);
        expect(
          find.text(
            'Dibayar lewat GoPay dan BCA pada kategori Food & Beverage.',
          ),
          findsOneWidget,
        );

        final historyLink = find.byKey(const Key('spending_table_history_link'));
        expect(historyLink, findsOneWidget);
        final linkSize = tester.getSize(historyLink);
        expect(linkSize.height, greaterThanOrEqualTo(44.0));
        expect(linkSize.width, greaterThanOrEqualTo(44.0));

        await tester.tap(historyLink);
        await tester.pump();
        expect(tappedHistory, isTrue);
      },
    );

    testWidgets(
      'handles empty rows safely and navigates to /transaction/history via GoRouter fallback',
      (tester) async {
        final prefs = await createMockPrefs();
        const emptyTable = AiSpendingTableData(
          title: 'Pengeluaran Bulan Ini',
          rows: [],
          totalAmount: 0,
          totalTransactions: 0,
          footnote: 'Belum ada catatan transaksi.',
        );

        final router = GoRouter(
          initialLocation: '/chat',
          routes: [
            GoRoute(
              path: '/chat',
              builder: (_, _) => const Scaffold(
                body: SingleChildScrollView(
                  child: AiSpendingBreakdownTableCard(data: emptyTable),
                ),
              ),
            ),
            GoRoute(
              path: '/transaction/history',
              builder: (_, _) =>
                  const Scaffold(body: Text('Transaction History Screen')),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.textContaining('Belum ada transaksi'), findsOneWidget);

        await tester.tap(find.byKey(const Key('spending_table_history_link')));
        await tester.pumpAndSettle();
        expect(find.text('Transaction History Screen'), findsOneWidget);
      },
    );

    testWidgets(
      'supports 2.0x text scaling at 360px width, asymmetric flow nodes, and unconfigured ProviderScope fallback',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        const incomeOnly = AiMoneyFlowData(
          periodLabel: 'Jan 2027',
          totalIncome: 5000000,
          totalExpense: 0,
          netCashflow: 5000000,
          transactionCount: 1,
          incomeSources: [
            AiMoneyFlowNode(label: 'Bonus Proyek', amount: 5000000, colorHex: '#0F758A', percentage: 100),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: MediaQuery(
                data: const MediaQueryData(
                  size: Size(360, 640),
                  textScaler: TextScaler.linear(2.0),
                ),
                child: Scaffold(
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: const [
                        AiMoneyFlowCard(data: incomeOnly),
                        SizedBox(height: 16),
                        AiSpendingBreakdownTableCard(data: sampleTable),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Money Flow'), findsOneWidget);
        expect(find.text('Total'), findsOneWidget);
      },
    );

    testWidgets(
      'paints Sankey title and amount separately, resolves theme fontFamily, and checks shouldRepaint',
      (tester) async {
        final prefs = await createMockPrefs();
        const themeFont = 'CustomThemeFamily';

        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MaterialApp(
              theme: ThemeData(fontFamily: themeFont),
              home: const Scaffold(
                body: SingleChildScrollView(child: AiMoneyFlowCard(data: sampleFlow)),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final customPaint = tester.widget<CustomPaint>(
          find.descendant(
            of: find.byType(AiMoneyFlowCard),
            matching: find.byWidgetPredicate(
              (w) => w is CustomPaint && w.painter is AiMoneyFlowPainter,
            ),
          ),
        );
        final painter = customPaint.painter! as AiMoneyFlowPainter;
        expect(painter.fontFamily, equals(themeFont));

        final (titleTp, amountTp) = painter.buildNodeLabelPainters(
          const AiMoneyFlowNode(
            label: 'Gaji Bulanan Utama Perusahaan Teknologi Sangat Panjang',
            amount: 10230000,
          ),
          true,
          62.0,
        );
        expect(titleTp.maxLines, equals(1));
        expect(titleTp.didExceedMaxLines, isTrue);
        expect(titleTp.text?.style?.fontFamily, equals(themeFont));
        expect(amountTp.maxLines, equals(1));
        expect((amountTp.text! as TextSpan).toPlainText(), contains('10.230.000'));
        expect(amountTp.text?.style?.fontFamily, equals(themeFont));
        expect(amountTp.height, greaterThan(0));

        expect(
          painter.shouldRepaint(
            AiMoneyFlowPainter(
              data: sampleFlow,
              currencyCode: 'USD',
              fontFamily: themeFont,
            ),
          ),
          isTrue,
        );
        expect(
          painter.shouldRepaint(
            const AiMoneyFlowPainter(
              data: AiMoneyFlowData(
                periodLabel: 'Nov 2026',
                totalIncome: 1,
                totalExpense: 0,
                netCashflow: 1,
                transactionCount: 1,
              ),
              currencyCode: 'IDR',
              fontFamily: themeFont,
            ),
          ),
          isTrue,
        );
        expect(
          painter.shouldRepaint(
            AiMoneyFlowPainter(
              data: sampleFlow,
              currencyCode: 'IDR',
              fontFamily: 'OtherFont',
            ),
          ),
          isTrue,
        );

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        painter.paint(canvas, const Size(140, 100));
        painter.paint(canvas, const Size(200, 30));
        recorder.endRecording();

        expect(
          parseFlowNodeColor('+112233', fallback: NeoBrutalism.teal),
          equals(NeoBrutalism.teal),
        );
        expect(
          parseFlowNodeColor('#0F758A'),
          equals(const Color(0xFF0F758A)),
        );
      },
    );

    testWidgets(
      'normalizes -0.0 netCashflow, clamps negative counts, exposes non-duplicated Semantics, and shows high-contrast focus ring',
      (tester) async {
        final prefs = await createMockPrefs();
        const negativeZeroFlow = AiMoneyFlowData(
          periodLabel: 'Feb 2027',
          totalIncome: 0,
          totalExpense: 0,
          netCashflow: -0.0,
          transactionCount: -5,
          incomeSources: [
            AiMoneyFlowNode(label: 'Gaji', amount: 1000000, colorHex: '#0F758A'),
          ],
          expenseCategories: [
            AiMoneyFlowNode(label: 'Makan', amount: 400000, colorHex: '#DC2626'),
          ],
        );
        const negativeCountTable = AiSpendingTableData(
          title: 'Tabel Uji',
          rows: [
            AiSpendingMerchantRow(
              merchant: 'Warung Kopi',
              transactionCount: -2,
              totalAmount: 25000,
            ),
          ],
          totalAmount: 25000,
          totalTransactions: -4,
        );

        final handle = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            wrapAtPhoneWidth(
              prefs: prefs,
              child: Column(
                children: const [
                  AiMoneyFlowCard(data: negativeZeroFlow),
                  SizedBox(height: 16),
                  AiSpendingBreakdownTableCard(data: negativeCountTable),
                ],
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Net +Rp 0'), findsOneWidget);
          expect(find.text('Net -Rp 0'), findsNothing);
          expect(find.textContaining('-5 transaksi'), findsNothing);
          expect(find.text('-2'), findsNothing);
          expect(find.text('-4'), findsNothing);
          expect(find.text('0'), findsNWidgets(2));

          final reportingNode = tester.getSemantics(
            find.byKey(const Key('money_flow_reporting_link')),
          );
          expect(
            reportingNode.label,
            equals(
              'Lihat detail laporan Money Flow: Pemasukan +Rp 0, Pengeluaran Rp 0',
            ),
          );
          expect(reportingNode.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

          final historyNode = tester.getSemantics(
            find.byKey(const Key('spending_table_history_link')),
          );
          expect(historyNode.label, equals('Lihat Riwayat transaksi'));
          expect(historyNode.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

          final sankeySemantics = find.bySemanticsLabel(
            RegExp(r'Diagram aliran dana: Pemasukan .*Gaji.* ke Pengeluaran .*Makan'),
          );
          expect(sankeySemantics, findsOneWidget);

          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();

          final reportingMaterial = tester.widget<Material>(
            find.ancestor(
              of: find.byKey(const Key('money_flow_reporting_link')),
              matching: find.byType(Material),
            ).first,
          );
          final reportingShape = reportingMaterial.shape! as RoundedRectangleBorder;
          expect(reportingShape.side.color, equals(NeoBrutalism.darkTeal));
          expect(reportingShape.side.width, equals(2.5));
          expect(
            reportingMaterial.color,
            equals(
              Color.alphaBlend(
                NeoBrutalism.teal.withValues(alpha: 0.12),
                NeoBrutalism.surfaceWarm,
              ),
            ),
          );

          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();

          final historyMaterial = tester.widget<Material>(
            find.ancestor(
              of: find.byKey(const Key('spending_table_history_link')),
              matching: find.byType(Material),
            ).first,
          );
          final historyShape = historyMaterial.shape! as RoundedRectangleBorder;
          expect(historyShape.side.color, equals(NeoBrutalism.darkTeal));
          expect(historyShape.side.width, equals(2.5));
          expect(
            historyMaterial.color,
            equals(NeoBrutalism.teal.withValues(alpha: 0.12)),
          );
        } finally {
          handle.dispose();
        }
      },
    );
  });
}
