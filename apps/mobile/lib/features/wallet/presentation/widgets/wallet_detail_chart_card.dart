import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class WalletDetailChartCard extends StatelessWidget {
  final double currentBalance;

  const WalletDetailChartCard({
    super.key,
    required this.currentBalance,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.compactCurrency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 1,
    );

    // Dynamic spots relative to current balance
    final base = currentBalance > 0 ? currentBalance : 1000000.0;
    final spots = [
      FlSpot(0, base * 0.92),
      FlSpot(1, base * 0.95),
      FlSpot(2, base * 0.88),
      FlSpot(3, base * 0.96),
      FlSpot(4, base * 0.85),
      FlSpot(5, base * 0.98),
      FlSpot(6, base),
    ];

    final maxVal = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final minVal = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tren Saldo (Bulan Ini)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: NeoBrutalism.dark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFFCC7),
                  borderRadius: BorderRadius.circular(NeoBrutalism.radiusPill),
                  border: Border.all(color: NeoBrutalism.borderBlack, width: 1.0),
                ),
                child: Text(
                  '30 Hari',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: NeoBrutalism.dark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        const labels = ['1', '5', '10', '15', '20', '25', '30'];
                        final idx = value.toInt();
                        if (idx >= 0 && idx < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              labels[idx],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: NeoBrutalism.textMuted,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: NeoBrutalism.dark,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, barData) => spot.x == 6,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 5,
                        color: NeoBrutalism.lime,
                        strokeWidth: 2,
                        strokeColor: NeoBrutalism.borderBlack,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: NeoBrutalism.lime.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatBadge('TERTINGGI', currencyFormat.format(maxVal), const Color(0xFF10B981)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatBadge('TERENDAH', currencyFormat.format(minVal), const Color(0xFFDC2626)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
        border: Border.all(color: NeoBrutalism.borderBlack, width: 1.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: NeoBrutalism.textMuted,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
