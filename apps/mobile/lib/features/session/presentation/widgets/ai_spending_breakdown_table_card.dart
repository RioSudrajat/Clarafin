import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import '../../domain/models/ai_chat_models.dart';

/// Neo-Brutalist 3-column merchant spending breakdown table card for AI chat.
class AiSpendingBreakdownTableCard extends ConsumerWidget {
  final AiSpendingTableData data;
  final VoidCallback? onViewHistory;
  final String? currencyCode;
  final bool showHistoryLink;

  const AiSpendingBreakdownTableCard({
    super.key,
    required this.data,
    this.onViewHistory,
    this.currencyCode,
    this.showHistoryLink = true,
  });

  static const Color _mutedInk = Color(0xFF4B5563);

  TextStyle _font(double size, FontWeight w, Color c, {double? height, double? spacing}) =>
      GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: w, color: c, height: height, letterSpacing: spacing);

  String _resolveCurrency(WidgetRef ref) {
    if (currencyCode != null && currencyCode!.isNotEmpty) return currencyCode!;
    try {
      return ref.watch(userProfileProvider.select((p) => p.currency));
    } on Object catch (_) {
      return 'IDR';
    }
  }

  double _safeNonNeg(double v) => (v.isFinite && v > 0) ? v : 0.0;

  void _openHistory(BuildContext context) {
    if (onViewHistory != null) {
      onViewHistory!();
      return;
    }
    GoRouter.maybeOf(context)?.push('/transaction/history');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = _resolveCurrency(ref);
    final heading = data.title.trim().isNotEmpty ? data.title.trim() : 'Rincian Pengeluaran';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(heading, style: _font(13.5, FontWeight.w800, NeoBrutalism.dark)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: NeoBrutalism.cardDecoration(backgroundColor: Colors.white, borderRadius: 14.0, shadowOffset: 3.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const Divider(height: 1.5, thickness: 1.5, color: Colors.black),
                if (data.rows.isEmpty) _buildEmptyRow() else _buildRows(currency),
                const Divider(height: 1.5, thickness: 1.5, color: Colors.black),
                _buildFooter(currency),
              ],
            ),
          ),
        ),
        if (data.footnote.trim().isNotEmpty || showHistoryLink) ...[
          const SizedBox(height: 8),
          _buildFootnoteAndLink(context),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    final style = _font(10.5, FontWeight.w800, _mutedInk, spacing: 0.3);
    return Container(
      color: NeoBrutalism.surfaceWarm,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text('MERCHANT', maxLines: 1, overflow: TextOverflow.ellipsis, style: style)),
          Expanded(
            flex: 2,
            child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.center, child: Text('TRANSAKSI', style: style)),
          ),
          Expanded(
            flex: 3,
            child: Text('TOTAL', textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Text('Belum ada transaksi merchant tercatat pada periode ini.', style: _font(12, FontWeight.w500, _mutedInk)),
    );
  }

  Widget _buildRows(String currency) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < data.rows.length; i++) ...[
          if (i > 0) const Divider(height: 1, thickness: 1, color: AppColors.divider),
          _buildTableRow(
            label: data.rows[i].merchant.trim().isEmpty ? '-' : data.rows[i].merchant.trim(),
            countText: '${data.rows[i].transactionCount}',
            amountText: CurrencyFormatter.format(_safeNonNeg(data.rows[i].totalAmount), currencyCode: currency),
            isTotal: false,
          ),
        ],
      ],
    );
  }

  Widget _buildFooter(String currency) {
    return Container(
      color: AppColors.primaryLight,
      child: _buildTableRow(
        label: 'Total',
        countText: '${data.totalTransactions}',
        amountText: CurrencyFormatter.format(_safeNonNeg(data.totalAmount), currencyCode: currency),
        isTotal: true,
      ),
    );
  }

  Widget _buildTableRow({
    required String label,
    required String countText,
    required String amountText,
    required bool isTotal,
  }) {
    final s = isTotal ? 13.0 : 12.5;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: _font(s, isTotal ? FontWeight.w800 : FontWeight.w600, NeoBrutalism.dark)),
          ),
          Expanded(
            flex: 2,
            child: Text(countText, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: _font(s, isTotal ? FontWeight.w800 : FontWeight.w600, isTotal ? NeoBrutalism.dark : _mutedInk)),
          ),
          Expanded(
            flex: 3,
            child: Text(amountText, textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: _font(s, isTotal ? FontWeight.w900 : FontWeight.w700, NeoBrutalism.dark)),
          ),
        ],
      ),
    );
  }

  Widget _buildFootnoteAndLink(BuildContext context) {
    final footnote = data.footnote.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (footnote.isNotEmpty) Text(footnote, style: _font(12, FontWeight.w500, _mutedInk, height: 1.4)),
        if (showHistoryLink)
          Semantics(
            button: true,
            label: 'Lihat Riwayat transaksi',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: const Key('spending_table_history_link'),
                borderRadius: BorderRadius.circular(8),
                onTap: () => _openHistory(context),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'Lihat Riwayat',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _font(12.5, FontWeight.w800, NeoBrutalism.teal),
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.chevron_right_rounded, size: 18, color: NeoBrutalism.teal),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
