import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/financial_health_model.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

final financialHealthProvider = Provider<FinancialHealthModel>((ref) {
  return const FinancialHealthModel(
    score: 82,
    maxScore: 100,
    statusLabel: 'Sangat Sehat',
    summary:
        'Kondisi finansialmu berada di kuadran sangat sehat! Cadangan dana darurat aman dan beban cicilan jauh di bawah batas risiko (18% < 30%).',
    emergencyFundRatio: 1.0,
    emergencyFundText: '6 / 6 Bulan Aman (Rp 36.000.000)',
    debtRatio: 0.18,
    debtRatioText: '18% dari Pendapatan Bulanan',
    savingsRatio: 0.25,
    savingsRatioText: '25% dari Total Pemasukan',
    insuranceStatusText: 'BPJS Kesehatan & Asuransi Jiwa Terproteksi',
    recommendations: [
      FinancialRecommendation(
        id: 'rec_invest',
        title: 'Optimalisasi Portofolio Investasi',
        description:
            'Alokasi dana daruratmu sudah terpenuhi. Saatnya memindahkan porsi surplus ke instrumen reksadana indeks atau obligasi negara.',
        icon: Icons.trending_up_rounded,
        actionLabel: 'Tanya Konsultan',
        actionRoute: '/consult',
        accentColor: NeoBrutalism.lime,
      ),
      FinancialRecommendation(
        id: 'rec_goal',
        title: 'Target Tabungan Baru',
        description:
            'Tetapkan rencana jangka panjang seperti dana pensiun mandiri atau kepemilikan rumah impian dengan tracking otomatis.',
        icon: Icons.flag_rounded,
        actionLabel: 'Buat Target',
        actionRoute: '/goal/add',
        accentColor: Color(0xFFE0F2FE),
      ),
    ],
  );
});
