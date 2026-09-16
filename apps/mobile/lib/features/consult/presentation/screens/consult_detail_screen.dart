import 'package:flutter/material.dart';
import '../../domain/models/consultant.dart';
import '../widgets/consult_detail_about_section.dart';
import '../widgets/consult_detail_accordions.dart';
import '../widgets/consult_detail_bottom_bar.dart';
import '../widgets/consult_detail_hero_header.dart';
import '../widgets/consult_detail_reviews_section.dart';
import '../widgets/consult_detail_stats_row.dart';

/// Screen orchestrator for the Consultant Detail view.
/// Dynamically binds to the selected consultant ID from ConsultantRepository.
/// Strictly follows Code Guidelines: lightweight orchestrator (< 120 lines).
class ConsultDetailScreen extends StatelessWidget {
  final String consultantId;

  const ConsultDetailScreen({
    super.key,
    required this.consultantId,
  });

  @override
  Widget build(BuildContext context) {
    final consultant = ConsultantRepository.getById(consultantId) ??
        ConsultantRepository.initialConsultants.first;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero Avatar & Header ──
            ConsultDetailHeroHeader(consultant: consultant),

            // ── Curved White Sheet Boundary with 2px Black Border ──
            Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(
                    top: BorderSide(color: Colors.black, width: 2.0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),

                    // ── Stats Row ──
                    ConsultDetailStatsRow(consultant: consultant),

                    // ── About & Specializations ──
                    ConsultDetailAboutSection(consultant: consultant),

                    // ── Accordions (Sertifikasi, Track Record, Policy) ──
                    ConsultDetailAccordions(consultant: consultant),

                    // ── User Reviews Carousel ──
                    ConsultDetailReviewsSection(consultant: consultant),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ConsultDetailBottomBar(consultant: consultant),
    );
  }
}
