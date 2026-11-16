import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/mock_providers.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import '../widgets/budget_progress_card.dart';
import '../widgets/consultation_hero_card.dart';
import '../widgets/edit_user_name_dialog.dart';
import '../widgets/expert_help_banner_carousel.dart';
import '../widgets/gmail_drafts_prompt_sheet.dart';
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
  bool _gmailPromptShown = false;
  bool _showMigrationBanner = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_gmailPromptShown && mounted) {
        _gmailPromptShown = true;
        final isGmail = ref.read(userProfileProvider).isGmailConnected;
        if (isGmail) {
          GmailDraftsPromptSheet.show(context);
        }
      }
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  Widget _buildMigrationBanner(BuildContext context, String source) {
    final sourceName = source == 'spreadsheet' ? 'Excel / Spreadsheet' : 'Aplikasi Lain';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEFFCC7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 2.0),
          boxShadow: NeoBrutalism.shadow(yOffset: 3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: NeoBrutalism.lime,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.black, width: 1.2),
                  ),
                  child: const Text(
                    'MIGRASI DATA ONBOARDING',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _showMigrationBanner = false),
                  child: const Icon(Icons.close_rounded, size: 18, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Impor Riwayat Catatan dari $sourceName',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pindahkan file CSV / transaksi lamamu agar grafik analitik dan budget langsung sinkron!',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => context.push('/export'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black, width: 1.8),
                  boxShadow: NeoBrutalism.shadow(yOffset: 2),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.file_upload_outlined, size: 16, color: Colors.black),
                    SizedBox(width: 6),
                    Text(
                      'Buka Menu Impor CSV / Excel ➔',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = ref.watch(userNameProvider);
    final profile = ref.watch(userProfileProvider);
    final hasMigration = profile.trackingHistorySource == 'other_app' ||
        profile.trackingHistorySource == 'spreadsheet';

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Migration Alert Banner (If user selected other_app or spreadsheet during Onboarding)
                  if (_showMigrationBanner && hasMigration)
                    _buildMigrationBanner(context, profile.trackingHistorySource),

                  // Layanan Section (Grid 2 Baris x 4 Kolom, Notion Style)
                  const ServicesGridWidget(),

                  const SizedBox(height: 24),

                  // Section: Expert Help Banner Carousel
                  const ExpertHelpBannerCarousel(),

                  const SizedBox(height: 24),

                  // Section: Keuangan Bulan Ini
                  const BudgetProgressCard(),

                  const SizedBox(height: 24),

                  // Section: Recent Activity
                  const RecentActivitySection(),

                  const SizedBox(height: 120), // Generous padding above floating bottom nav bar
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
