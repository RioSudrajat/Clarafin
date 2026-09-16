import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/mock_providers.dart';
import '../widgets/budget_progress_card.dart';
import '../widgets/consultation_hero_card.dart';
import '../widgets/edit_user_name_dialog.dart';
import '../widgets/expert_help_banner_carousel.dart';
import '../widgets/home_hero_header_delegate.dart';
import '../widgets/home_top_app_bar.dart';
import '../widgets/recent_activity_section.dart';
import '../widgets/services_grid_widget.dart';
import '../widgets/total_balance_hero_card.dart';

/// The primary landing screen of Clarafin.
/// Acts as an orchestrator composing modular, feature-level widgets.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _obscureBalance = false;
  int _heroPage = 0;
  late final PageController _heroController = PageController();

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userName = ref.watch(userNameProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // ── Pinned Collapsible Hero Header (Clarafin Brand + Hero Cards) ──
          SliverPersistentHeader(
            pinned: true,
            delegate: HomeHeroHeaderDelegate(
              topSafeArea: MediaQuery.of(context).padding.top,
              heroPage: _heroPage,
              topBar: const HomeTopAppBar(),
              cardBuilder: (context, progress) {
                return PageView(
                  controller: _heroController,
                  clipBehavior: Clip.none,
                  physics: const PageScrollPhysics(),
                  onPageChanged: (i) => setState(() => _heroPage = i),
                  children: [
                    // Slide 0: Konsultasi Finansial Hero Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ConsultationHeroCard(
                        progress: progress,
                        userName: userName,
                        onEditName: () => EditUserNameDialog.show(context, ref, userName),
                      ),
                    ),

                    // Slide 1: Total Balance Hero Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: TotalBalanceHeroCard(
                        progress: progress,
                        obscureBalance: _obscureBalance,
                        onToggleObscure: () => setState(() => _obscureBalance = !_obscureBalance),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // ── Scrollable Body Content (Inside White Section) ──
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.only(top: 16),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Layanan Section (Grid 2 Baris x 4 Kolom, Notion Style)
                  ServicesGridWidget(),

                  SizedBox(height: 24),

                  // Section: Expert Help Banner Carousel
                  ExpertHelpBannerCarousel(),

                  SizedBox(height: 24),

                  // Section: Keuangan Bulan Ini
                  BudgetProgressCard(),

                  SizedBox(height: 24),

                  // Section: Recent Activity
                  RecentActivitySection(),

                  SizedBox(height: 120), // Generous padding above floating bottom nav bar
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
