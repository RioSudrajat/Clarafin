import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/neo_brutalism_decorations.dart';
import 'package:mobile/features/session/domain/models/ai_chat_models.dart';
import 'package:mobile/features/session/presentation/widgets/ai_thinking_trace_widget.dart';

Widget _wrapWidget(Widget child) {
  return MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    ),
  );
}

void main() {
  group('AiThinkingTraceWidget', () {
    testWidgets('live state renders spinner, active step label, and >= 44x44 toggle', (
      tester,
    ) async {
      const liveTrace = AiThinkingTrace(
        isLive: true,
        durationMs: 450,
        steps: [
          AiThinkingStep(
            id: 'step-1',
            label: 'Memeriksa dompet aktif',
            isDone: true,
          ),
          AiThinkingStep(
            id: 'step-2',
            label: 'Menghitung arus kas Oktober 2026',
            isDone: false,
          ),
        ],
      );

      await tester.pumpWidget(_wrapWidget(const AiThinkingTraceWidget(trace: liveTrace)));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Menghitung arus kas Oktober 2026'), findsOneWidget);
      expect(find.text('Memeriksa dompet aktif'), findsNothing);

      final toggleSize = tester.getSize(
        find.byKey(const Key('ai_thinking_trace_toggle')),
      );
      expect(toggleSize.width, greaterThanOrEqualTo(44.0));
      expect(toggleSize.height, greaterThanOrEqualTo(44.0));

      final chevronSize = tester.getSize(
        find.byKey(const Key('ai_thinking_trace_chevron')),
      );
      expect(chevronSize.width, greaterThanOrEqualTo(44.0));
      expect(chevronSize.height, greaterThanOrEqualTo(44.0));
    });

    testWidgets('live state with empty steps shows fallback status text', (
      tester,
    ) async {
      const emptyLiveTrace = AiThinkingTrace(isLive: true);

      await tester.pumpWidget(
        _wrapWidget(const AiThinkingTraceWidget(trace: emptyLiveTrace)),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Sedang memproses...'), findsOneWidget);
    });

    testWidgets('finished state starts collapsed with Indonesian duration and step count', (
      tester,
    ) async {
      const finishedTrace = AiThinkingTrace(
        isLive: false,
        durationMs: 1200,
        steps: [
          AiThinkingStep(
            id: 's1',
            label: 'Memeriksa dompet aktif',
            detail: 'BCA dan GoPay terdeteksi',
            isDone: true,
          ),
          AiThinkingStep(
            id: 's2',
            label: 'Menyusun ringkasan arus kas',
            isDone: true,
          ),
        ],
      );

      await tester.pumpWidget(
        _wrapWidget(const AiThinkingTraceWidget(trace: finishedTrace)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
      expect(find.text('Selesai berpikir 1,2 dtk • 2 langkah'), findsOneWidget);
      expect(find.text('Memeriksa dompet aktif'), findsNothing);
      expect(find.text('BCA dan GoPay terdeteksi'), findsNothing);
    });

    testWidgets('finished state omits zero duration instead of showing 0,0 dtk', (
      tester,
    ) async {
      const noDurationTrace = AiThinkingTrace(
        isLive: false,
        durationMs: 0,
        steps: [
          AiThinkingStep(id: 's1', label: 'Analisa cepat', isDone: true),
        ],
      );

      await tester.pumpWidget(
        _wrapWidget(const AiThinkingTraceWidget(trace: noDurationTrace)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Selesai berpikir • 1 langkah'), findsOneWidget);
    });

    testWidgets('tapping toggle expands Neo-Brutalist step list and collapses again', (
      tester,
    ) async {
      const trace = AiThinkingTrace(
        isLive: false,
        durationMs: 1420,
        steps: [
          AiThinkingStep(
            id: 's1',
            label: 'Memeriksa dompet aktif',
            detail: 'BCA dan GoPay terdeteksi',
            isDone: true,
          ),
          AiThinkingStep(
            id: 's2',
            label: 'Menghitung total pengeluaran kopi',
            isDone: true,
          ),
        ],
      );

      await tester.pumpWidget(_wrapWidget(const AiThinkingTraceWidget(trace: trace)));
      await tester.pumpAndSettle();

      expect(find.text('Selesai berpikir 1,4 dtk • 2 langkah'), findsOneWidget);
      expect(find.text('Memeriksa dompet aktif'), findsNothing);

      await tester.tap(find.byKey(const Key('ai_thinking_trace_toggle')));
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Memeriksa dompet aktif'), findsOneWidget);
      expect(find.text('BCA dan GoPay terdeteksi'), findsOneWidget);
      expect(find.text('Menghitung total pengeluaran kopi'), findsOneWidget);

      final container = tester.widget<Container>(
        find.byKey(const Key('ai_thinking_trace_card')),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, equals(NeoBrutalism.surfaceWarm));
      expect(decoration.borderRadius, equals(BorderRadius.circular(10)));
      final border = decoration.border! as Border;
      expect(border.top.width, equals(1.5));
      expect(border.top.color, equals(NeoBrutalism.borderBlack));
      expect(decoration.boxShadow, isNotNull);
      for (final shadow in decoration.boxShadow!) {
        expect(shadow.blurRadius, equals(0.0));
      }

      final dotContainer = tester.widget<Container>(
        find.byKey(const Key('ai_thinking_step_dot_0')),
      );
      final dotDecoration = dotContainer.decoration! as BoxDecoration;
      expect(dotDecoration.color, equals(NeoBrutalism.lime));
      expect(dotDecoration.shape, equals(BoxShape.circle));

      await tester.tap(find.byKey(const Key('ai_thinking_trace_toggle')));
      await tester.pumpAndSettle();

      expect(find.text('Memeriksa dompet aktif'), findsNothing);
    });

    testWidgets('collapses automatically when transitioning from live to finished', (
      tester,
    ) async {
      const liveTrace = AiThinkingTrace(
        isLive: true,
        steps: [
          AiThinkingStep(
            id: 's1',
            label: 'Memeriksa dompet aktif',
            isDone: false,
          ),
        ],
      );
      const doneTrace = AiThinkingTrace(
        isLive: false,
        durationMs: 1200,
        steps: [
          AiThinkingStep(
            id: 's1',
            label: 'Memeriksa dompet aktif',
            isDone: true,
          ),
        ],
      );

      await tester.pumpWidget(_wrapWidget(const AiThinkingTraceWidget(trace: liveTrace)));
      await tester.pump();
      await tester.tap(find.byKey(const Key('ai_thinking_trace_toggle')));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('1'), findsOneWidget);

      await tester.pumpWidget(_wrapWidget(const AiThinkingTraceWidget(trace: doneTrace)));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Selesai berpikir 1,2 dtk • 1 langkah'), findsOneWidget);
      expect(find.text('Memeriksa dompet aktif'), findsNothing);
    });

    testWidgets('renders cleanly without overflow on 360x640 mobile viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const longTrace = AiThinkingTrace(
        isLive: false,
        durationMs: 2800,
        steps: [
          AiThinkingStep(
            id: 's1',
            label:
                'Memeriksa riwayat transaksi kategori makanan dan minuman selama 30 hari terakhir',
            detail:
                'Ditemukan 18 transaksi pada dompet BCA Utama, GoPay, dan OVO Cash yang aktif.',
            isDone: true,
          ),
          AiThinkingStep(
            id: 's2',
            label: 'Membandingkan pengeluaran aktual terhadap batas anggaran bulanan',
            isDone: true,
          ),
        ],
      );

      await tester.pumpWidget(
        _wrapWidget(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SizedBox(width: 34, height: 34),
              SizedBox(width: 10),
              Expanded(child: AiThinkingTraceWidget(trace: longTrace)),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('ai_thinking_trace_toggle')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      final toggleSize = tester.getSize(
        find.byKey(const Key('ai_thinking_trace_toggle')),
      );
      expect(toggleSize.width, greaterThanOrEqualTo(44.0));
      expect(toggleSize.height, greaterThanOrEqualTo(44.0));
    });

    testWidgets('empty finished trace shows explicit empty state when expanded', (
      tester,
    ) async {
      const emptyDoneTrace = AiThinkingTrace(
        isLive: false,
        durationMs: 500,
        steps: [],
      );

      await tester.pumpWidget(
        _wrapWidget(const AiThinkingTraceWidget(trace: emptyDoneTrace)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Selesai berpikir 0,5 dtk • 0 langkah'), findsOneWidget);
      await tester.tap(find.byKey(const Key('ai_thinking_trace_toggle')));
      await tester.pumpAndSettle();

      expect(
        find.text('Belum ada rincian langkah yang tercatat.'),
        findsOneWidget,
      );
    });

    testWidgets('supports initiallyExpanded=true and keyboard Enter activation', (
      tester,
    ) async {
      const trace = AiThinkingTrace(
        isLive: false,
        durationMs: 1200,
        steps: [
          AiThinkingStep(
            id: 's1',
            label: 'Memeriksa dompet aktif',
            isDone: true,
          ),
        ],
      );

      await tester.pumpWidget(
        _wrapWidget(
          const AiThinkingTraceWidget(trace: trace, initiallyExpanded: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Memeriksa dompet aktif'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.text('Memeriksa dompet aktif'), findsNothing);
    });

    testWidgets('holds at 200% text scale on 360x640 viewport without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const trace = AiThinkingTrace(
        isLive: false,
        durationMs: 1200,
        steps: [
          AiThinkingStep(
            id: 's1',
            label: 'Memeriksa anggaran bulanan kategori transportasi',
            detail: 'Total transaksi terverifikasi pada bulan berjalan',
            isDone: true,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: const Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: AiThinkingTraceWidget(
                  trace: trace,
                  initiallyExpanded: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text('Memeriksa anggaran bulanan kategori transportasi'),
        findsOneWidget,
      );
    });
  });
}
