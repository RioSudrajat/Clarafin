import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/ai_chat_models.dart';
import 'ai_analytical_card_helpers.dart';
import 'ai_money_flow_painter.dart';

/// Full-width Neo-Brutalist horizontal proportion bars used when cashflow
/// has only one side (e.g. expense-only period with Rp 0 income).
class AiMoneyFlowHorizontalBars extends StatelessWidget {
  final List<AiMoneyFlowNode> nodes;
  final double fallbackTotal;
  final String currencyCode;
  final String sectionTitle;

  const AiMoneyFlowHorizontalBars({
    super.key,
    required this.nodes,
    required this.fallbackTotal,
    required this.currencyCode,
    required this.sectionTitle,
  });

  String _buildSemanticLabel(double total) {
    final parts = nodes.map((n) {
      final label = n.label.trim().isEmpty ? '-' : n.label.trim();
      final amt = safeFlowAmount(n.amount);
      final pct = _resolvePercentage(n, amt, total);
      final formatted = CurrencyFormatter.format(amt, currencyCode: currencyCode);
      return '$label ${pct.toStringAsFixed(0)}%, $formatted';
    }).join('; ');
    return '$sectionTitle: $parts';
  }

  double _resolvePercentage(AiMoneyFlowNode node, double amt, double total) {
    if (node.percentage.isFinite && node.percentage > 0) {
      return node.percentage.clamp(0.0, 100.0).toDouble();
    }
    if (total > 0) return ((amt / total) * 100.0).clamp(0.0, 100.0).toDouble();
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final nodeSum = nodes.fold<double>(0.0, (s, n) => s + safeFlowAmount(n.amount));
    final total = nodeSum > 0 ? nodeSum : safeFlowAmount(fallbackTotal);

    return Semantics(
      container: true,
      label: _buildSemanticLabel(total),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < nodes.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _buildBarRow(nodes[i], i, total),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBarRow(AiMoneyFlowNode node, int index, double total) {
    final label = node.label.trim().isEmpty ? '-' : node.label.trim();
    final amt = safeFlowAmount(node.amount);
    final pct = _resolvePercentage(node, amt, total);
    final fraction = total > 0 ? (amt / total).clamp(0.0, 1.0).toDouble() : 0.0;
    final fillColor = index.isEven ? NeoBrutalism.teal : NeoBrutalism.lime;
    final amountText = CurrencyFormatter.format(amt, currencyCode: currencyCode);
    final pctText = '${pct.toStringAsFixed(0)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 2,
            children: [
              Text(
                label,
                style: analyticalFont(12.5, FontWeight.w700, NeoBrutalism.dark),
              ),
              Text(
                '$pctText | $amountText',
                style: analyticalFont(12, FontWeight.w800, NeoBrutalism.dark),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: 14,
          width: double.infinity,
          decoration: BoxDecoration(
            color: NeoBrutalism.surfaceWarm,
            borderRadius: BorderRadius.circular(6),
            border: NeoBrutalism.border(width: 1.5),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fraction > 0 ? math.max(fraction, 0.04) : 0.0,
              child: Container(
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(4),
                  border: fraction > 0 && fraction < 0.99
                      ? const Border(
                          right: BorderSide(color: Colors.black, width: 1.5),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
