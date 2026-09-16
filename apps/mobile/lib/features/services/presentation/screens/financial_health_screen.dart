import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/financial_health_provider.dart';
import '../widgets/financial_ratios_bento_grid.dart';
import '../widgets/financial_recommendations_card.dart';
import '../widgets/financial_score_gauge_card.dart';

/// Screen displaying the user's comprehensive Financial Health Score & 4-pillar ratios.
/// Clean, modular orchestrator adhering strictly to < 150 lines.
class FinancialHealthScreen extends ConsumerWidget {
  const FinancialHealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthModel = ref.watch(financialHealthProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(
          bottom: BorderSide(color: Colors.black, width: 2.0),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(0, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back, size: 18, color: Colors.black),
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Kesehatan Finansial',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FinancialScoreGaugeCard(model: healthModel),
            const SizedBox(height: 24),
            FinancialRatiosBentoGrid(model: healthModel),
            const SizedBox(height: 24),
            FinancialRecommendationsCard(
              recommendations: healthModel.recommendations,
            ),
          ],
        ),
      ),
    );
  }
}
