import 'dart:ui' show Tristate;
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

      expect(
        find.descendant(
          of: find.byKey(const Key('ai_thinking_step_dot_0')),
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('ai_thinking_step_dot_1')),
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );
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
      expect(
        find.descendant(
          of: find.byKey(const Key('ai_thinking_step_dot_0')),
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('ai_thinking_step_dot_1')),
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Memeriksa riwayat transaksi kategori makanan dan minuman selama 30 hari terakhir',
        ),
        findsOneWidget,
      );

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

    testWidgets('duration rounding handles 59950ms and 119500ms boundaries cleanly', (
      tester,
    ) async {
      const trace59950 = AiThinkingTrace(
        isLive: false,
        durationMs: 59950,
        steps: [AiThinkingStep(id: 's1', label: 'Cek', isDone: true)],
      );
      const trace119500 = AiThinkingTrace(
        isLive: false,
        durationMs: 119500,
        steps: [AiThinkingStep(id: 's1', label: 'Cek', isDone: true)],
      );
      const trace65400 = AiThinkingTrace(
        isLive: false,
        durationMs: 65400,
        steps: [AiThinkingStep(id: 's1', label: 'Cek', isDone: true)],
      );

      await tester.pumpWidget(_wrapWidget(const AiThinkingTraceWidget(trace: trace59950)));
      await tester.pumpAndSettle();
      expect(find.text('Selesai berpikir 1 mnt • 1 langkah'), findsOneWidget);

      await tester.pumpWidget(_wrapWidget(const AiThinkingTraceWidget(trace: trace119500)));
      await tester.pumpAndSettle();
      expect(find.text('Selesai berpikir 2 mnt • 1 langkah'), findsOneWidget);

      await tester.pumpWidget(_wrapWidget(const AiThinkingTraceWidget(trace: trace65400)));
      await tester.pumpAndSettle();
      expect(find.text('Selesai berpikir 1 mnt 5 dtk • 1 langkah'), findsOneWidget);
    });

    testWidgets('didUpdateWidget preserves expansion across intermediate live updates', (
      tester,
    ) async {
      const liveStep1 = AiThinkingTrace(
        isLive: true,
        steps: [
          AiThinkingStep(id: 's1', label: 'Memeriksa dompet aktif', isDone: false),
        ],
      );
      const liveStep2 = AiThinkingTrace(
        isLive: true,
        steps: [
          AiThinkingStep(id: 's1', label: 'Memeriksa dompet aktif', isDone: true),
          AiThinkingStep(id: 's2', label: 'Menghitung arus kas', isDone: false),
        ],
      );
      const doneTrace = AiThinkingTrace(
        isLive: false,
        durationMs: 1200,
        steps: [
          AiThinkingStep(id: 's1', label: 'Memeriksa dompet aktif', isDone: true),
          AiThinkingStep(id: 's2', label: 'Menghitung arus kas', isDone: true),
        ],
      );

      await tester.pumpWidget(_wrapWidget(const AiThinkingTraceWidget(trace: liveStep1)));
      await tester.pump();
      await tester.tap(find.byKey(const Key('ai_thinking_trace_toggle')));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('1'), findsOneWidget);

      await tester.pumpWidget(_wrapWidget(const AiThinkingTraceWidget(trace: liveStep2)));
      await tester.pump(const Duration(milliseconds: 200));

      // Expansion remains open while stream is still live.
      expect(find.text('Memeriksa dompet aktif'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      await tester.pumpWidget(_wrapWidget(const AiThinkingTraceWidget(trace: doneTrace)));
      await tester.pumpAndSettle();

      expect(find.text('Memeriksa dompet aktif'), findsNothing);
      expect(find.text('Selesai berpikir 1,2 dtk • 2 langkah'), findsOneWidget);
    });

    testWidgets('expanded live view distinguishes done vs pending step dots beyond color', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        const liveTrace = AiThinkingTrace(
          isLive: true,
          steps: [
            AiThinkingStep(id: 's1', label: 'Memeriksa dompet aktif', isDone: true),
            AiThinkingStep(id: 's2', label: 'Menghitung arus kas', isDone: false),
          ],
        );

        await tester.pumpWidget(
          _wrapWidget(const AiThinkingTraceWidget(trace: liveTrace, initiallyExpanded: true)),
        );
        await tester.pump();

        final doneDotFinder = find.byKey(const Key('ai_thinking_step_dot_0'));
        final pendingDotFinder = find.byKey(const Key('ai_thinking_step_dot_1'));

        final doneDot = tester.widget<Container>(doneDotFinder);
        final doneBox = doneDot.decoration! as BoxDecoration;
        expect(doneBox.color, equals(NeoBrutalism.lime));
        expect(
          find.descendant(of: doneDotFinder, matching: find.byIcon(Icons.check_rounded)),
          findsOneWidget,
        );

        final pendingDot = tester.widget<Container>(pendingDotFinder);
        final pendingBox = pendingDot.decoration! as BoxDecoration;
        final pendingBorder = pendingBox.border! as Border;
        expect(pendingBox.color, equals(Colors.white));
        expect(pendingBorder.top.color, equals(NeoBrutalism.darkTeal));
        expect(pendingBorder.top.width, equals(2.0));
        expect(find.descendant(of: pendingDotFinder, matching: find.text('2')), findsOneWidget);

        expect(tester.getSemantics(doneDotFinder).label, contains('Langkah 1 selesai'));
        expect(
          tester.getSemantics(pendingDotFinder).label,
          contains('Langkah 2 sedang diproses'),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('semantics excludes live spinner and avoids duplicating headerLabel', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        const liveTrace = AiThinkingTrace(
          isLive: true,
          steps: [
            AiThinkingStep(id: 's1', label: 'Menghitung arus kas', isDone: false),
          ],
        );

        await tester.pumpWidget(_wrapWidget(const AiThinkingTraceWidget(trace: liveTrace)));
        await tester.pump();

        final spinnerAncestorExclude = find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(ExcludeSemantics),
        );
        expect(spinnerAncestorExclude, findsWidgets);

        final toggleFinder = find.byKey(const Key('ai_thinking_trace_toggle'));
        final collapsedData = tester.getSemantics(toggleFinder).getSemanticsData();
        expect(collapsedData.flagsCollection.isButton, isTrue);
        expect(collapsedData.flagsCollection.isExpanded, equals(Tristate.isFalse));

        final matches = RegExp(RegExp.escape('Menghitung arus kas')).allMatches(collapsedData.label);
        expect(matches.length, equals(1));
        var childLabelCount = 0;
        tester.getSemantics(toggleFinder).visitChildren((child) {
          if (child.label.contains('Menghitung arus kas')) {
            childLabelCount++;
          }
          return true;
        });
        expect(childLabelCount, equals(0));

        await tester.tap(toggleFinder);
        await tester.pump();

        final expandedData = tester.getSemantics(toggleFinder).getSemanticsData();
        expect(expandedData.flagsCollection.isExpanded, equals(Tristate.isTrue));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('finished state excludes done icon and chevron from semantics without duplicating label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        const doneTrace = AiThinkingTrace(
          isLive: false,
          durationMs: 1200,
          steps: [
            AiThinkingStep(id: 's1', label: 'Memeriksa dompet aktif', isDone: true),
          ],
        );

        await tester.pumpWidget(_wrapWidget(const AiThinkingTraceWidget(trace: doneTrace)));
        await tester.pumpAndSettle();

        expect(
          find.ancestor(
            of: find.byIcon(Icons.check_circle_outline_rounded),
            matching: find.byType(ExcludeSemantics),
          ),
          findsWidgets,
        );
        expect(
          find.ancestor(
            of: find.byIcon(Icons.keyboard_arrow_right_rounded),
            matching: find.byType(ExcludeSemantics),
          ),
          findsWidgets,
        );

        const expectedLabel = 'Selesai berpikir 1,2 dtk • 1 langkah';
        final toggleSemantics = tester.getSemantics(
          find.byKey(const Key('ai_thinking_trace_toggle')),
        );
        final matches = RegExp(RegExp.escape(expectedLabel)).allMatches(toggleSemantics.label);
        expect(matches.length, equals(1));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('renders high-contrast darkTeal focus ring and supports Space activation', (
      tester,
    ) async {
      const trace = AiThinkingTrace(
        isLive: false,
        durationMs: 1200,
        steps: [
          AiThinkingStep(id: 's1', label: 'Memeriksa dompet aktif', isDone: true),
        ],
      );

      await tester.pumpWidget(
        _wrapWidget(
          Column(
            children: [
              const AiThinkingTraceWidget(trace: trace),
              TextButton(onPressed: () {}, child: const Text('Berikutnya')),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final inkWell = tester.widget<InkWell>(
        find.byKey(const Key('ai_thinking_trace_toggle')),
      );
      expect(inkWell.focusColor, isNot(equals(NeoBrutalism.lime.withValues(alpha: 0.35))));

      final headerBefore = tester.widget<Container>(
        find.byKey(const Key('ai_thinking_trace_header')),
      );
      expect(headerBefore.foregroundDecoration, isNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      final headerFocused = tester.widget<Container>(
        find.byKey(const Key('ai_thinking_trace_header')),
      );
      final focusBg = headerFocused.decoration! as BoxDecoration;
      expect(focusBg.color, equals(NeoBrutalism.darkTeal.withValues(alpha: 0.12)));
      final focusRing = headerFocused.foregroundDecoration! as BoxDecoration;
      final focusBorder = focusRing.border! as Border;
      expect(focusBorder.top.color, equals(NeoBrutalism.darkTeal));
      expect(focusBorder.top.width, equals(2.0));

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.text('Memeriksa dompet aktif'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.text('Memeriksa dompet aktif'), findsNothing);

      // Moving focus away clears the focus highlight and ring.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final headerBlurred = tester.widget<Container>(
        find.byKey(const Key('ai_thinking_trace_header')),
      );
      expect(headerBlurred.decoration, isNull);
      expect(headerBlurred.foregroundDecoration, isNull);
    });

    testWidgets('respects MediaQuery.disableAnimations and inherits theme fontFamily', (
      tester,
    ) async {
      const trace = AiThinkingTrace(
        isLive: false,
        durationMs: 1200,
        steps: [
          AiThinkingStep(id: 's1', label: 'Memeriksa dompet aktif', isDone: true),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: AiThinkingTraceWidget(trace: trace),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AnimatedSize), findsNothing);

      final headerText = tester.widget<Text>(
        find.text('Selesai berpikir 1,2 dtk • 1 langkah'),
      );
      expect(headerText.style?.fontFamily, isNull);

      await tester.tap(find.byKey(const Key('ai_thinking_trace_toggle')));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Memeriksa dompet aktif'), findsOneWidget);

      await tester.tap(find.byKey(const Key('ai_thinking_trace_toggle')));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Memeriksa dompet aktif'), findsNothing);
    });
  });
}
