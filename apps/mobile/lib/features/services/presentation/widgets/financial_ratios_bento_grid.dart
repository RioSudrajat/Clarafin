import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../domain/models/financial_health_model.dart';

class FinancialRatiosBentoGrid extends StatelessWidget {
  final FinancialHealthModel model;

  const FinancialRatiosBentoGrid({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '4 Pilar Rasio Keuangan',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        // Row 1: Dana Darurat & Rasio Utang
        Row(
          children: [
            Expanded(
              child: _buildBentoCard(
                icon: Icons.shield_outlined,
                iconBg: const Color(0xFFD1FAE5),
                title: 'Dana Darurat',
                valueText: '6 / 6 Bln',
                statusTag: 'AMAN',
                statusColor: NeoBrutalism.lime,
                desc: 'Tercukupi Rp 36jt',
                progress: 1.0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBentoCard(
                icon: Icons.credit_card_outlined,
                iconBg: const Color(0xFFFEF3C7),
                title: 'Rasio Cicilan',
                valueText: '${(model.debtRatio * 100).toInt()}%',
                statusTag: 'SEHAT (<30%)',
                statusColor: const Color(0xFFD1FAE5),
                desc: 'Rp 2.7jt / bln',
                progress: model.debtRatio / 0.30,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 2: Rasio Menabung & Proteksi Asuransi
        Row(
          children: [
            Expanded(
              child: _buildBentoCard(
                icon: Icons.savings_outlined,
                iconBg: const Color(0xFFE0F2FE),
                title: 'Investasi & Nabung',
                valueText: '${(model.savingsRatio * 100).toInt()}%',
                statusTag: 'UNGGUL (>20%)',
                statusColor: NeoBrutalism.lime,
                desc: 'Rp 3.75jt / bln',
                progress: 1.0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBentoCard(
                icon: Icons.health_and_safety_outlined,
                iconBg: const Color(0xFFEDE9FE),
                title: 'Proteksi Risiko',
                valueText: 'Lengkap',
                statusTag: 'TERLINDUNGI',
                statusColor: const Color(0xFFD1FAE5),
                desc: 'BPJS + Jiwa UP 1M',
                progress: 1.0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoCard({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String valueText,
    required String statusTag,
    required Color statusColor,
    required String desc,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(0, 2.5),
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Icon(icon, size: 18, color: Colors.black),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: Colors.black, width: 1.2),
                ),
                child: Text(
                  statusTag,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            valueText,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                border: Border.all(color: Colors.black, width: 1.0),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(color: NeoBrutalism.lime),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
