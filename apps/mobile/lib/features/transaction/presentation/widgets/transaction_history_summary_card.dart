import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class TransactionHistorySummaryCard extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;

  const TransactionHistorySummaryCard({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final netCashflow = totalIncome - totalExpense;
    final isSurplus = netCashflow >= 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NeoBrutalism.radiusLg),
        border: Border.all(
          color: NeoBrutalism.borderBlack,
          width: 2.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: NeoBrutalism.borderBlack,
            offset: Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  label: 'TOTAL PEMASUKAN',
                  amount: '+${currencyFormat.format(totalIncome)}',
                  textColor: const Color(0xFF10B981),
                  icon: Icons.arrow_downward_rounded,
                  iconBg: const Color(0xFFE5F9E0),
                ),
              ),
              Container(
                width: 2,
                height: 44,
                color: NeoBrutalism.borderBlack,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              Expanded(
                child: _buildMetricItem(
                  label: 'TOTAL PENGELUARAN',
                  amount: '-${currencyFormat.format(totalExpense)}',
                  textColor: const Color(0xFFDC2626),
                  icon: Icons.arrow_upward_rounded,
                  iconBg: const Color(0xFFFFDAD6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSurplus ? const Color(0xFFEFFCC7) : const Color(0xFFFFECEB),
              borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
              border: Border.all(
                color: NeoBrutalism.borderBlack,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isSurplus ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      size: 18,
                      color: NeoBrutalism.dark,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Arus Kas Bersih:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: NeoBrutalism.dark,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${isSurplus ? '+' : ''}${currencyFormat.format(netCashflow)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: isSurplus ? const Color(0xFF0F758A) : const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String amount,
    required Color textColor,
    required IconData icon,
    required Color iconBg,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: NeoBrutalism.borderBlack,
                  width: 1.5,
                ),
              ),
              child: Icon(icon, size: 12, color: NeoBrutalism.dark),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: NeoBrutalism.textMuted,
                  letterSpacing: 0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          amount,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
