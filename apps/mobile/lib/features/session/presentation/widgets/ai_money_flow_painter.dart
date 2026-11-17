import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/ai_chat_models.dart';

final RegExp _hexColorPattern = RegExp(r'^[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$');

/// Parses a CSS hex color string safely, falling back on malformed inputs.
Color parseFlowNodeColor(String hex, {Color fallback = NeoBrutalism.teal}) {
  final cleaned = hex.trim().replaceFirst('#', '');
  if (!_hexColorPattern.hasMatch(cleaned)) return fallback;
  final normalized = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
  return Color(int.parse(normalized, radix: 16));
}

/// Sanitizes finite positive numeric amounts to avoid NaN/negative math.
double safeFlowAmount(double v) => (v.isFinite && v > 0) ? v : 0.0;

/// CustomPainter rendering a Neo-Brutalist 2-column Sankey cashflow diagram.
class AiMoneyFlowPainter extends CustomPainter {
  final AiMoneyFlowData data;
  final String currencyCode;
  final String? fontFamily;

  const AiMoneyFlowPainter({
    required this.data,
    required this.currencyCode,
    this.fontFamily,
  });

  static const double _barWidth = 12.0;
  static const double _labelGap = 6.0;
  static const double _nodeGap = 8.0;
  static const double _vPad = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 40 || size.height <= 40) return;
    final sources = data.incomeSources;
    final targets = data.expenseCategories;
    if (sources.isEmpty && targets.isEmpty) return;

    // Scale label widths proportionally so center ribbon span never collapses.
    final maxLabels = math.max(0.0, size.width - (_barWidth + _labelGap) * 2 - 12.0);
    final desiredLeft = math.min(98.0, size.width * 0.28);
    final desiredRight = math.min(108.0, size.width * 0.31);
    final desiredSum = desiredLeft + desiredRight;
    final scale = (desiredSum > maxLabels && desiredSum > 0) ? (maxLabels / desiredSum) : 1.0;
    final leftLabelW = desiredLeft * scale;
    final rightLabelW = desiredRight * scale;

    final leftBarX = sources.isNotEmpty ? leftLabelW + _labelGap : 0.0;
    final rightBarX = targets.isNotEmpty
        ? size.width - rightLabelW - _labelGap - _barWidth
        : size.width - _barWidth;

    final availH = math.max(0.0, size.height - _vPad * 2);
    final srcRects = _layoutColumn(sources, leftBarX, availH);
    final dstRects = _layoutColumn(targets, rightBarX, availH);

    if (srcRects.isNotEmpty && dstRects.isNotEmpty) {
      _paintRibbons(canvas, sources, targets, srcRects, dstRects);
    }
    _paintNodes(canvas, size, sources, srcRects, true, leftLabelW, NeoBrutalism.teal);
    _paintNodes(canvas, size, targets, dstRects, false, rightLabelW, AppColors.error);
  }

  List<Rect> _layoutColumn(List<AiMoneyFlowNode> nodes, double barX, double availH) {
    if (nodes.isEmpty || availH <= 0) return const [];
    final gap = nodes.length > 1 ? math.min(_nodeGap, availH / (nodes.length * 2)) : 0.0;
    final usableH = math.max(0.0, availH - gap * (nodes.length - 1));
    final total = nodes.fold<double>(0.0, (s, n) => s + safeFlowAmount(n.amount));
    final minBarH = math.min(24.0, usableH / nodes.length);
    final flexH = math.max(0.0, usableH - minBarH * nodes.length);

    final rects = <Rect>[];
    var y = _vPad;
    for (final node in nodes) {
      final share = total > 0 ? (safeFlowAmount(node.amount) / total) : 0.0;
      final h = total > 0 ? minBarH + flexH * share : (usableH / nodes.length);
      rects.add(Rect.fromLTWH(barX, y, _barWidth, math.max(1.0, h)));
      y += h + gap;
    }
    return rects;
  }

  void _paintRibbons(
    Canvas canvas,
    List<AiMoneyFlowNode> sources,
    List<AiMoneyFlowNode> targets,
    List<Rect> srcRects,
    List<Rect> dstRects,
  ) {
    final validOut = List<double>.filled(sources.length, 0.0);
    final validIn = List<double>.filled(targets.length, 0.0);
    final validEdges = <AiMoneyFlowEdge>[];

    // Bounds-check edge indices and discard non-positive or NaN edges.
    for (final e in data.flows) {
      final sOk = e.sourceIndex >= 0 && e.sourceIndex < sources.length;
      final tOk = e.targetIndex >= 0 && e.targetIndex < targets.length;
      final amt = safeFlowAmount(e.amount);
      if (!sOk || !tOk || amt <= 0) continue;
      validOut[e.sourceIndex] += amt;
      validIn[e.targetIndex] += amt;
      validEdges.add(e);
    }

    final srcUsed = List<double>.filled(sources.length, 0.0);
    final dstUsed = List<double>.filled(targets.length, 0.0);

    for (final e in validEdges) {
      final s = e.sourceIndex;
      final t = e.targetIndex;
      final srcDenom = math.max(safeFlowAmount(sources[s].amount), validOut[s]);
      final dstDenom = math.max(safeFlowAmount(targets[t].amount), validIn[t]);
      if (srcDenom <= 0 || dstDenom <= 0) continue;

      final sRect = srcRects[s];
      final dRect = dstRects[t];
      final amt = safeFlowAmount(e.amount);
      final sAvail = math.max(0.0, sRect.height - srcUsed[s]);
      final dAvail = math.max(0.0, dRect.height - dstUsed[t]);
      if (sAvail <= 0 || dAvail <= 0) continue;

      final sThick = math.min(sAvail, math.max(math.min(1.5, sAvail), sRect.height * (amt / srcDenom)));
      final dThick = math.min(dAvail, math.max(math.min(1.5, dAvail), dRect.height * (amt / dstDenom)));
      final sTop = sRect.top + srcUsed[s];
      final dTop = dRect.top + dstUsed[t];
      srcUsed[s] += sThick;
      dstUsed[t] += dThick;

      final x0 = sRect.right;
      final x1 = dRect.left;
      final midX = (x0 + x1) / 2;
      final path = Path()
        ..moveTo(x0, sTop)
        ..cubicTo(midX, sTop, midX, dTop, x1, dTop)
        ..lineTo(x1, dTop + dThick)
        ..cubicTo(midX, dTop + dThick, midX, sTop + sThick, x0, sTop + sThick)
        ..close();

      final color = parseFlowNodeColor(targets[t].colorHex, fallback: AppColors.error);
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.28));
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }
  }

  /// Builds separate single-line painters so wrapping titles never hide amounts.
  @visibleForTesting
  (TextPainter, TextPainter) buildNodeLabelPainters(
    AiMoneyFlowNode node,
    bool isLeft,
    double labelW,
  ) {
    final title = node.label.trim().isEmpty ? '-' : node.label.trim();
    final amount = CurrencyFormatter.format(safeFlowAmount(node.amount), currencyCode: currencyCode);
    final align = isLeft ? TextAlign.right : TextAlign.left;

    final titleTp = TextPainter(
      text: TextSpan(
        text: title,
        style: TextStyle(fontFamily: fontFamily, fontSize: 10.5, fontWeight: FontWeight.w700, color: NeoBrutalism.dark, height: 1.15),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(minWidth: labelW, maxWidth: labelW);

    final amountTp = TextPainter(
      text: TextSpan(
        text: amount,
        style: TextStyle(fontFamily: fontFamily, fontSize: 9.5, fontWeight: FontWeight.w600, color: const Color(0xFF4B5563), height: 1.15),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(minWidth: labelW, maxWidth: labelW);

    return (titleTp, amountTp);
  }

  void _paintNodes(
    Canvas canvas,
    Size size,
    List<AiMoneyFlowNode> nodes,
    List<Rect> rects,
    bool isLeft,
    double labelW,
    Color fallback,
  ) {
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var i = 0; i < nodes.length && i < rects.length; i++) {
      final node = nodes[i];
      final rect = rects[i];
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
      final fillColor = parseFlowNodeColor(node.colorHex, fallback: fallback);
      canvas.drawRRect(rrect, Paint()..color = fillColor);
      canvas.drawRRect(rrect, borderPaint);
      if (labelW < 16.0) continue;

      final (titleTp, amountTp) = buildNodeLabelPainters(node, isLeft, labelW);
      const lineGap = 1.5;
      final totalH = titleTp.height + lineGap + amountTp.height;
      final dx = isLeft ? 0.0 : (rect.right + _labelGap);
      final dy = (rect.center.dy - totalH / 2).clamp(0.0, math.max<double>(0.0, size.height - totalH)).toDouble();
      titleTp.paint(canvas, Offset(dx, dy));
      amountTp.paint(canvas, Offset(dx, dy + titleTp.height + lineGap));
    }
  }

  @override
  bool shouldRepaint(covariant AiMoneyFlowPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.currencyCode != currencyCode || oldDelegate.fontFamily != fontFamily;
}
