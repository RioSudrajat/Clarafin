import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/consult_list_provider.dart';
import '../widgets/consult_category_filter_row.dart';
import '../widgets/consult_empty_state.dart';
import '../widgets/consult_match_expert_banner.dart';
import '../widgets/consult_search_bar.dart';
import '../widgets/consult_top_app_bar.dart';
import '../widgets/consultant_card.dart';

/// Primary screen orchestrator for the Consultation feature.
/// Strictly follows Code Guidelines: lightweight orchestrator (< 150 lines)
/// delegating visual presentation to isolated, modular widgets.
class ConsultListScreen extends ConsumerWidget {
  const ConsultListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredConsultants = ref.watch(filteredConsultantsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Top Bar (Header Title + Chat Action) ──
            const SliverToBoxAdapter(
              child: ConsultTopAppBar(),
            ),

            // ── Search Bar ──
            const SliverToBoxAdapter(
              child: ConsultSearchBar(),
            ),

            // ── Category Filter Pills ──
            const SliverToBoxAdapter(
              child: ConsultCategoryFilterRow(),
            ),

            // ── Match Expert AI Banner ──
            const SliverToBoxAdapter(
              child: ConsultMatchExpertBanner(),
            ),

            // ── Section Title ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Daftar Konsultan',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '${filteredConsultants.length} Ditemukan',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Consultant Cards List or Empty State ──
            if (filteredConsultants.isEmpty)
              const SliverToBoxAdapter(
                child: ConsultEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.builder(
                  itemCount: filteredConsultants.length,
                  itemBuilder: (context, index) {
                    final consultant = filteredConsultants[index];
                    return ConsultantCard(
                      key: ValueKey(consultant.id),
                      consultant: consultant,
                    );
                  },
                ),
              ),

            // ── Bottom Spacing for Floating Navbar ──
            const SliverToBoxAdapter(
              child: SizedBox(height: 120),
            ),
          ],
        ),
      ),
    );
  }
}
