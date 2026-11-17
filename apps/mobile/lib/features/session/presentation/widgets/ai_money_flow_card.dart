import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/ai_chat_models.dart';
import 'ai_analytical_card_helpers.dart';
import 'ai_money_flow_painter.dart';

/// Neo-Brutalist analytical Money Flow Sankey card rendered inside AI chat.
class AiMoneyFlowCard extends ConsumerWidget {
  final AiMoneyFlowData data;
  final VoidCallback? onViewReporting;
  final String? currencyCode;

  const AiMoneyFlowCard({super.key, required this.data, this.onViewReporting, this.currencyCode});

  static const Color _incomeInk = Color(0xFF047857);
  static const Color _mutedInk = Color(0xFF4B5563);

  void _openReporting(BuildContext context) {
    if (onViewReporting != null) {
      onViewReporting!();
      return;
    }
    GoRouter.maybeOf(context)?.push('/reporting');
  }

  String _buildSankeySemanticLabel(String currency) {
    String describe(List<AiMoneyFlowNode> nodes) => nodes
        .map((n) => '${n.label.trim().isEmpty ? '-' : n.label.trim()} ${CurrencyFormatter.format(safeFlowAmount(n.amount), currencyCode: currency)}')
        .join(', ');
    final incPart = data.incomeSources.isEmpty ? 'kosong' : describe(data.incomeSources);
    final expPart = data.expenseCategories.isEmpty ? 'kosong' : describe(data.expenseCategories);
    return 'Diagram aliran dana: Pemasukan $incPart ke Pengeluaran $expPart';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = resolveAnalyticalCurrency(ref, currencyCode);
    final safeInc = safeFlowAmount(data.totalIncome);
    final safeExp = safeFlowAmount(data.totalExpense);
    final rawNet = data.netCashflow.isFinite ? data.netCashflow : (safeInc - safeExp);
    final safeNet = normalizeAnalyticalZero(rawNet);
    final hasNodes = data.incomeSources.isNotEmpty || data.expenseCategories.isNotEmpty;
    final maxNodes = math.max(data.incomeSources.length, data.expenseCategories.length);
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: NeoBrutalism.cardDecoration(backgroundColor: Colors.white, borderRadius: 14.0, shadowOffset: 3.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTitleRow(),
          const SizedBox(height: 10),
          _buildReportingStrip(context, currency, safeInc, safeExp),
          const SizedBox(height: 12),
          if (!hasNodes)
            _buildEmptyFlowState()
          else
            Semantics(
              container: true,
              label: _buildSankeySemanticLabel(currency),
              child: SizedBox(
                width: double.infinity,
                height: (maxNodes * 46.0).clamp(124.0, 220.0).toDouble(),
                child: CustomPaint(
                  painter: AiMoneyFlowPainter(data: data, currencyCode: currency, fontFamily: fontFamily),
                ),
              ),
            ),
          const Divider(height: 22, thickness: 1.2, color: AppColors.divider),
          _buildBreakdownSection(currency, safeNet),
        ],
      ),
    );
  }

  Widget _buildTitleRow() {
    final period = data.periodLabel.trim();
    final safeTxCount = data.transactionCount < 0 ? 0 : data.transactionCount;
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text('Money Flow', style: analyticalFont(16, FontWeight.w800, NeoBrutalism.dark)),
              if (period.isNotEmpty) Text(period, style: analyticalFont(12, FontWeight.w600, _mutedInk)),
            ],
          ),
          if (safeTxCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: NeoBrutalism.surfaceWarm,
                borderRadius: BorderRadius.circular(8),
                border: NeoBrutalism.border(width: 1.2),
              ),
              child: Text('$safeTxCount transaksi', style: analyticalFont(11, FontWeight.w700, NeoBrutalism.dark)),
            ),
        ],
      ),
    );
  }

  Widget _buildReportingStrip(BuildContext context, String currency, double inc, double exp) {
    final incText = '+${CurrencyFormatter.format(inc, currencyCode: currency)}';
    final expText = CurrencyFormatter.format(exp, currencyCode: currency);
    return AnalyticalActionSurface(
      buttonKey: const Key('money_flow_reporting_link'),
      semanticLabel: 'Lihat detail laporan Money Flow: Pemasukan $incText, Pengeluaran $expText',
      onTap: () => _openReporting(context),
      baseColor: NeoBrutalism.surfaceWarm,
      borderRadius: BorderRadius.circular(10),
      defaultBorder: const BorderSide(color: Colors.black, width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                Text(incText, style: analyticalFont(13, FontWeight.w800, _incomeInk)),
                const Icon(Icons.arrow_forward_rounded, size: 14, color: NeoBrutalism.dark),
                Text(expText, style: analyticalFont(13, FontWeight.w800, AppColors.error)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, size: 18, color: NeoBrutalism.dark),
        ],
      ),
    );
  }

  Widget _buildEmptyFlowState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: NeoBrutalism.surfaceWarm, borderRadius: BorderRadius.circular(10), border: NeoBrutalism.border(width: 1.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.swap_horiz_rounded, size: 20, color: NeoBrutalism.teal),
              const SizedBox(width: 8),
              Expanded(child: Text('Belum ada aliran dana tercatat', style: analyticalFont(13, FontWeight.w700, NeoBrutalism.dark))),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Catat pemasukan atau pengeluaran untuk melihat ringkasan arus kas pada periode ini.',
            style: analyticalFont(12, FontWeight.w500, _mutedInk, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownSection(String currency, double safeNet) {
    final prefix = safeNet >= 0 ? '+' : '';
    final netLabel = 'Net $prefix${CurrencyFormatter.format(safeNet, currencyCode: currency)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text('Spending Breakdown', style: analyticalFont(13, FontWeight.w800, NeoBrutalism.dark)),
              Text(netLabel, style: analyticalFont(12, FontWeight.w800, safeNet >= 0 ? _incomeInk : AppColors.error)),
            ],
          ),
        ),
        if (data.breakdownSummary.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(data.breakdownSummary.trim(), style: analyticalFont(12, FontWeight.w500, _mutedInk, height: 1.4)),
        ],
        for (final node in data.expenseCategories.take(3)) ...[const SizedBox(height: 6), _buildCategoryRow(node, currency)],
      ],
    );
  }

  Widget _buildCategoryRow(AiMoneyFlowNode node, String currency) {
    final dotColor = parseFlowNodeColor(node.colorHex, fallback: AppColors.error);
    final amountText = CurrencyFormatter.format(safeFlowAmount(node.amount), currencyCode: currency);
    final label = node.label.trim().isEmpty ? '-' : node.label.trim();
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle, border: NeoBrutalism.border(width: 1.2))),
        const SizedBox(width: 8),
        Expanded(flex: 3, child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: analyticalFont(12, FontWeight.w600, NeoBrutalism.dark))),
        if (node.percentage.isFinite && node.percentage > 0) ...[
          const SizedBox(width: 6),
          Text('${node.percentage.toStringAsFixed(0)}%', style: analyticalFont(11.5, FontWeight.w600, _mutedInk)),
        ],
        const SizedBox(width: 8),
        Flexible(flex: 2, child: Text(amountText, maxLines: 1, overflow: TextOverflow.ellipsis, style: analyticalFont(12, FontWeight.w700, NeoBrutalism.dark))),
      ],
    );
  }
}
