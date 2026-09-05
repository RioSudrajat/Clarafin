import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../core/providers/mock_providers.dart';
import 'package:intl/intl.dart';
import '../widgets/services_grid_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _obscureBalance = false;
  int _heroPage = 0;
  int _bannerPage = 0;
  late final PageController _heroController = PageController();
  late final PageController _bannerController = PageController();

  @override
  void dispose() {
    _heroController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  double _evaluateProgressInterval(
    double progress,
    double begin,
    double end, {
    Curve curve = Curves.easeInOut,
  }) {
    if (progress <= begin) return 0.0;
    if (progress >= end) return 1.0;
    final t = (progress - begin) / (end - begin);
    return curve.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    final userName = ref.watch(userNameProvider);
    final transactions = ref.watch(transactionsProvider);
    final wallets = ref.watch(walletsProvider);
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final totalBalance = wallets.fold<double>(0, (sum, w) => sum + w.balance);

    // Dynamic PnL calculation
    final now = DateTime.now();
    final todayTransactions = transactions.where((t) {
      return t.date.year == now.year && t.date.month == now.month && t.date.day == now.day;
    }).toList();
    final todayIncome = todayTransactions.where((t) => t.type == 'income').fold<double>(0, (sum, t) => sum + t.amount);
    final todayExpense = todayTransactions.where((t) => t.type == 'expense' || t.type == 'transfer').fold<double>(0, (sum, t) => sum + t.amount);
    final dailyPnl = todayIncome - todayExpense;
    final pnlPercentage = totalBalance > 0 ? (dailyPnl / totalBalance * 100) : 0.0;
    final isPnlPositive = dailyPnl >= 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // ── Pinned Collapsible Hero Header (Halofin Logo + Hero Card) ──
          SliverPersistentHeader(
            pinned: true,
            delegate: _HomeHeroHeaderDelegate(
              topSafeArea: MediaQuery.of(context).padding.top,
              heroPage: _heroPage,
              topBar: _buildTopBar(),
              cardBuilder: (context, progress) {
                return PageView(
                  controller: _heroController,
                  clipBehavior: Clip.none,
                  physics: const PageScrollPhysics(),
                  onPageChanged: (i) => setState(() => _heroPage = i),
                  children: [
                    // ── Slide 0: Konsultasi Finansial Card ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _buildConsultationHeroCard(progress, userName),
                    ),

                    // ── Slide 1: Total Balance Card ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _buildTotalBalanceHeroCard(
                        totalBalance,
                        dailyPnl,
                        pnlPercentage,
                        isPnlPositive,
                        currencyFormat,
                        wallets,
                        progress,
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
                                // ── Layanan Section (Grid 2 Baris x 4 Kolom, Notion Style) ──
                                const ServicesGridWidget(),

                                const SizedBox(height: 24),

                                // ── Section: Expert Help Banner ──
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        height: 162,
                                        child: PageView(
                                          controller: _bannerController,
                                          clipBehavior: Clip.none,
                                          physics: const PageScrollPhysics(),
                                          onPageChanged: (i) => setState(() => _bannerPage = i),
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              child: _buildMatchExpertBanner(
                                                tag: 'EXPERT HELP',
                                                title: 'Bingung mencari konsultan?',
                                                buttonText: 'MATCH',
                                                onTap: () => context.go('/consult'),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              child: _buildMatchExpertBanner(
                                                tag: 'AI ADVISOR',
                                                title: 'Analisis budgeting kamu dengan AI',
                                                buttonText: 'TRY NOW',
                                                onTap: () => context.push('/session'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Banner Indicators
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: List.generate(
                                          2,
                                          (i) => AnimatedContainer(
                                            duration: const Duration(milliseconds: 250),
                                            width: _bannerPage == i ? 16 : 6,
                                            height: 6,
                                            margin: const EdgeInsets.symmetric(horizontal: 3),
                                            decoration: BoxDecoration(
                                              color: _bannerPage == i ? NeoBrutalism.dark : const Color(0xFFD1D5DB),
                                              borderRadius: BorderRadius.circular(9999),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // ── Section: Keuangan Bulan Ini ──
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Keuangan Bulan Ini',
                                        style: TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: NeoBrutalism.dark,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: NeoBrutalism.surfaceWarm,
                                          borderRadius: BorderRadius.circular(24),
                                          border: Border.all(color: Colors.black, width: 2),
                                          boxShadow: NeoBrutalism.shadow(yOffset: 4),
                                        ),
                                        padding: const EdgeInsets.only(top: 20, bottom: 20),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Budget Header
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 20),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: const [
                                                  Text(
                                                    'Budget',
                                                    style: TextStyle(
                                                      fontFamily: 'Plus Jakarta Sans',
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w700,
                                                      color: NeoBrutalism.dark,
                                                    ),
                                                  ),
                                                  Text(
                                                    '75%',
                                                    style: TextStyle(
                                                      fontFamily: 'Plus Jakarta Sans',
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w900,
                                                      color: NeoBrutalism.dark,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            const SizedBox(height: 12),

                                            // Progress Bar
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 20),
                                              child: Container(
                                                height: 14,
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(9999),
                                                  border: Border.all(color: Colors.black, width: 2),
                                                ),
                                                child: FractionallySizedBox(
                                                  alignment: Alignment.centerLeft,
                                                  widthFactor: 0.75,
                                                  child: Container(
                                                    decoration: const BoxDecoration(
                                                      color: NeoBrutalism.lime,
                                                      borderRadius: BorderRadius.horizontal(
                                                        left: Radius.circular(9999),
                                                        right: Radius.circular(9999),
                                                      ),
                                                      border: Border(
                                                        right: BorderSide(color: Colors.black, width: 2),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),

                                            const SizedBox(height: 10),

                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 20),
                                              child: RichText(
                                                text: const TextSpan(
                                                  style: TextStyle(
                                                    fontFamily: 'Plus Jakarta Sans',
                                                    fontSize: 12,
                                                    color: Color(0xFF4B5563),
                                                  ),
                                                  children: [
                                                    TextSpan(text: 'terpakai '),
                                                    TextSpan(
                                                      text: 'Rp 7.500.000',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w700,
                                                        color: NeoBrutalism.dark,
                                                      ),
                                                    ),
                                                    TextSpan(text: ' / Rp 10.000.000'),
                                                  ],
                                                ),
                                              ),
                                            ),

                                            const Padding(
                                              padding: EdgeInsets.fromLTRB(20, 14, 20, 14),
                                              child: Divider(
                                                height: 1,
                                                thickness: 1,
                                                color: Colors.black,
                                              ),
                                            ),

                                            // Bot Button + Prompt Pills (Stack: pills on layer 0, bot button on layer 1)
                                            SizedBox(
                                              height: 48,
                                              child: Stack(
                                                alignment: Alignment.centerLeft,
                                                children: [
                                                  // Layer 0: Prompt Pills (bounded to right edge of card, disappears under bot icon)
                                                  Positioned(
                                                    left: 35,
                                                    right: 4,
                                                    top: 0,
                                                    bottom: 0,
                                                    child: ClipRect(
                                                      child: SingleChildScrollView(
                                                        scrollDirection: Axis.horizontal,
                                                        physics: const ClampingScrollPhysics(),
                                                        clipBehavior: Clip.none,
                                                        padding: const EdgeInsets.only(
                                                          left: 35,
                                                          right: 16,
                                                          top: 4,
                                                          bottom: 6,
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            _buildAssistantPromptPill('Target nabung realistis?', onTap: () => context.push('/session')),
                                                            const SizedBox(width: 8),
                                                            _buildAssistantPromptPill('Cara naikkan tabungan?', onTap: () => context.push('/session')),
                                                            const SizedBox(width: 8),
                                                            _buildAssistantPromptPill('Tips hemat akhir bulan', onTap: () => context.push('/session')),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),

                                                  // Layer 1: Bot Button (Pinned at left: 20, on top of pills)
                                                  Positioned(
                                                    left: 20,
                                                    top: 2,
                                                    child: GestureDetector(
                                                      onTap: () => context.push('/session'),
                                                      child: Container(
                                                        width: 40,
                                                        height: 40,
                                                        decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          shape: BoxShape.circle,
                                                          border: Border.all(color: Colors.black, width: 2),
                                                          boxShadow: NeoBrutalism.shadow(yOffset: 2),
                                                        ),
                                                        child: const Icon(
                                                          Icons.smart_toy_outlined,
                                                          size: 20,
                                                          color: NeoBrutalism.dark,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // ── Section: Recent Activity ──
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Recent Activity',
                                        style: TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: NeoBrutalism.dark,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => context.push('/transaction/history'),
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.black, width: 2),
                                            boxShadow: NeoBrutalism.shadow(yOffset: 2),
                                          ),
                                          child: const Icon(Icons.search, size: 16, color: NeoBrutalism.dark),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Transaction List Items
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    padding: EdgeInsets.zero,
                                    itemCount: transactions.take(3).length,
                                    itemBuilder: (context, index) {
                                      final tx = transactions[index];
                                      final isExpense = tx.type == 'expense' || tx.type == 'transfer';
                                      final amountText = '${isExpense ? "- " : "+ "}${currencyFormat.format(tx.amount)}';

                                      Color iconBg;
                                      Color iconColor;
                                      IconData txIcon;

                                      if (index == 0) {
                                        iconBg = NeoBrutalism.dark;
                                        iconColor = Colors.white;
                                        txIcon = Icons.directions_car;
                                      } else if (index == 1) {
                                        iconBg = NeoBrutalism.lime;
                                        iconColor = NeoBrutalism.dark;
                                        txIcon = Icons.coffee_outlined;
                                      } else {
                                        iconBg = NeoBrutalism.coral;
                                        iconColor = const Color(0xFFB91C1C);
                                        txIcon = Icons.play_circle_outline;
                                      }

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(24),
                                          border: Border.all(color: Colors.black, width: 2),
                                          boxShadow: NeoBrutalism.shadow(yOffset: 3),
                                        ),
                                        child: Row(
                                          children: [
                                            // Category Icon Badge
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: iconBg,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.black, width: 2),
                                              ),
                                              child: Icon(txIcon, size: 20, color: iconColor),
                                            ),
                                            const SizedBox(width: 14),
                                            // Title & Subtitle
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    tx.title,
                                                    style: const TextStyle(
                                                      fontFamily: 'Plus Jakarta Sans',
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w900,
                                                      color: NeoBrutalism.dark,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${DateFormat('h:mm a').format(tx.date)} • ${DateFormat('d MMM').format(tx.date)}',
                                                    style: const TextStyle(
                                                      fontFamily: 'Plus Jakarta Sans',
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      color: NeoBrutalism.textMuted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Amount
                                            Text(
                                              amountText,
                                              style: const TextStyle(
                                                fontFamily: 'Plus Jakarta Sans',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w900,
                                                color: NeoBrutalism.dark,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                const SizedBox(height: 120), // Generous padding above floating bottom nav bar
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Clarafin Brand Logo & Name
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo_clarafin_symbol.png',
              height: 34,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Text(
              'clarafin',
              style: GoogleFonts.quicksand(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
                shadows: const [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),

        // Notification Bell & Profile Avatar
        Row(
          children: [
            // Notification Bell
            GestureDetector(
              onTap: () {},
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: NeoBrutalism.circleDecoration(
                      backgroundColor: Colors.white,
                      shadowOffset: 2,
                      borderWidth: 2,
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      size: 20,
                      color: Colors.black,
                    ),
                  ),
                  // Lime Notification Badge Dot
                  Positioned(
                    top: -1,
                    right: -1,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: NeoBrutalism.lime,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // User Profile Avatar
            GestureDetector(
              onTap: () => context.push('/profile'),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1.5),
                    image: const DecorationImage(
                      image: NetworkImage('https://i.pravatar.cc/150?img=11'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Hero Card 1: Konsultasi Finansial (Matches reference design & collapsible) ──

  Widget _buildConsultationHeroCard(double progress, String userName) {
    // ── 1. Curtain Animation (Delay 0.0-0.10, moves upward -32px and fades out by 0.52) ──
    final curtainProgress = _evaluateProgressInterval(progress, 0.10, 0.52, curve: Curves.easeIn);
    final curtainOpacity = (1.0 - curtainProgress).clamp(0.0, 1.0);
    final curtainTranslationY = -32.0 * curtainProgress;

    // ── 2. Collapsed Action Button Animation (Slides from right +16px and fades in 0.35 to 0.75) ──
    final actionProgress = _evaluateProgressInterval(progress, 0.35, 0.75, curve: Curves.easeOut);
    final actionOpacity = actionProgress.clamp(0.0, 1.0);
    final actionTranslationX = 16.0 * (1.0 - actionProgress);

    // ── 3. Anchored Persistent Greeting (Absolute position, scales font & keeps crisp anchor) ──
    final greetingTop = lerpDouble(18.0, 20.0, progress)!;
    final greetingLeft = 20.0;
    final greetingFontSize = lerpDouble(13.0, 16.0, progress)!;
    final greetingFontWeight = progress >= 0.45 ? FontWeight.w900 : FontWeight.w800;
    final greetingLetterSpacing = lerpDouble(0.4, -0.5, progress)!;
    final editIconSize = lerpDouble(11.0, 13.0, progress)!;
    final greetingRightBound = lerpDouble(70.0, 155.0, progress)!;

    return Container(
      width: double.infinity,
      height: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF0E6976), // Deep teal matching reference image
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: NeoBrutalism.shadow(yOffset: lerpDouble(4.0, 2.0, progress)!),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Curtain Layer: Disappearing content that rolls upward like a curtain ──
          if (curtainOpacity > 0.001)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 198,
              child: IgnorePointer(
                ignoring: curtainOpacity < 0.5,
                child: Opacity(
                  opacity: curtainOpacity,
                  child: Transform.translate(
                    offset: Offset(0, curtainTranslationY),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top Row: Spacer for anchored greeting + Title on left, Lime group icon on right
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    // Spacing matching the anchored Hi, [userName] height
                                    SizedBox(height: 20),
                                    SizedBox(height: 6),
                                    Text(
                                      'Atur uangmu\nbareng ahlinya.',
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        height: 1.15,
                                        letterSpacing: -0.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: NeoBrutalism.lime,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black, width: 2),
                                  boxShadow: NeoBrutalism.shadow(yOffset: 2),
                                ),
                                child: const Icon(
                                  Icons.groups_rounded,
                                  size: 26,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),

                          // Bottom Row: Subtitle on left, Lime 'MULAI' pill button on right
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Cocokkan dengan konsultan\nyang paham tujuanmu.',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => context.go('/consult'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: NeoBrutalism.lime,
                                    borderRadius: BorderRadius.circular(9999),
                                    border: Border.all(color: Colors.black, width: 2),
                                    boxShadow: NeoBrutalism.shadow(yOffset: 2),
                                  ),
                                  child: const Text(
                                    'MULAI',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ── Anchored Persistent Greeting: Hi, [userName] (Never disappears, smoothly scales) ──
          Positioned(
            top: greetingTop,
            left: greetingLeft,
            right: greetingRightBound,
            child: GestureDetector(
              onTap: () => _showEditNameDialog(context, ref, userName),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'Hi, $userName',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: greetingFontSize,
                        fontWeight: greetingFontWeight,
                        color: Colors.white,
                        letterSpacing: greetingLetterSpacing,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.edit_outlined, size: editIconSize, color: Colors.white70),
                ],
              ),
            ),
          ),

          // ── Collapsed Action Button: Mulai Konseling > (Slides in from right) ──
          if (actionOpacity > 0.001)
            Positioned(
              top: 0,
              bottom: 0,
              right: 16,
              child: IgnorePointer(
                ignoring: actionOpacity < 0.5,
                child: Opacity(
                  opacity: actionOpacity,
                  child: Transform.translate(
                    offset: Offset(actionTranslationX, 0),
                    child: Center(
                      child: GestureDetector(
                        onTap: () => context.go('/consult'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: NeoBrutalism.lime,
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(color: Colors.black, width: 2),
                            boxShadow: NeoBrutalism.shadow(yOffset: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Mulai Konseling',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(width: 3),
                              Icon(Icons.chevron_right, size: 14, color: Colors.black),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Hero Card 2: Total Balance Card (100% Original Exact Composition & Placement Restored) ──

  Widget _buildTotalBalanceHeroCard(
    double totalBalance,
    double dailyPnl,
    double pnlPercentage,
    bool isPnlPositive,
    NumberFormat currencyFormat,
    List wallets,
    double progress,
  ) {
    // ── 1. Curtain Animation (Delay 0.0-0.10, moves upward -32px and fades out by 0.52) ──
    final curtainProgress = _evaluateProgressInterval(progress, 0.10, 0.52, curve: Curves.easeIn);
    final curtainOpacity = (1.0 - curtainProgress).clamp(0.0, 1.0);
    final curtainTranslationY = -32.0 * curtainProgress;

    // ── 2. Collapsed Action Button Animation (Slides from right +16px and fades in 0.35 to 0.75) ──
    final actionProgress = _evaluateProgressInterval(progress, 0.35, 0.75, curve: Curves.easeOut);
    final actionOpacity = actionProgress.clamp(0.0, 1.0);
    final actionTranslationX = 16.0 * (1.0 - actionProgress);

    // ── 3. Anchored Persistent Balance Amount (Absolute position, scales font & keeps crisp anchor) ──
    // In expanded: below TOTAL BALANCE, so top: 40.0, left: 18.0.
    // In collapsed: vertically centered in 64px card, so top: 19.0, left: 18.0.
    final nominalTop = lerpDouble(40.0, 19.0, progress)!;
    final nominalLeft = 18.0;
    final nominalFontSize = lerpDouble(30.0, 16.5, progress)!;
    final rpFontSize = lerpDouble(15.0, 13.0, progress)!;
    final eyeIconSize = lerpDouble(17.0, 15.0, progress)!;
    final nominalRightBound = lerpDouble(75.0, 125.0, progress)!;

    final formattedAmount = _obscureBalance
        ? '••••••••'
        : currencyFormat.format(totalBalance).replaceAll('Rp ', '');

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Lime Balance Card Body
        Container(
          width: double.infinity,
          height: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: NeoBrutalism.lime,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: NeoBrutalism.shadow(yOffset: lerpDouble(4.0, 2.0, progress)!),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Curtain Layer: TOTAL BALANCE label, PnL pill, Sub-wallets ──
              if (curtainOpacity > 0.001)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 198,
                  child: IgnorePointer(
                    ignoring: curtainOpacity < 0.5,
                    child: Opacity(
                      opacity: curtainOpacity,
                      child: Transform.translate(
                        offset: Offset(0, curtainTranslationY),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 18, bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Rows 1-3 with 18px horizontal padding (100% exact structure restored from ca1f18d)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Row 1: TOTAL BALANCE (word 'TOTAL BALANCE' which disappears upon collapse)
                                    const Text(
                                      'TOTAL BALANCE',
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                        color: NeoBrutalism.dark,
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    // Space occupied by Row 2 (Rp + 30px nominal text height)
                                    const SizedBox(height: 38),

                                    const SizedBox(height: 10),

                                    // Row 3: Daily PnL Indicator Pill
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.92),
                                        borderRadius: BorderRadius.circular(9999),
                                        border: Border.all(color: Colors.black, width: 2),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'Hari ini ',
                                            style: TextStyle(
                                              fontFamily: 'Plus Jakarta Sans',
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: NeoBrutalism.dark,
                                            ),
                                          ),
                                          Icon(
                                            isPnlPositive ? Icons.trending_up : Icons.trending_down,
                                            size: 13,
                                            color: isPnlPositive ? const Color(0xFF10B981) : const Color(0xFFDC2626),
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${isPnlPositive ? "+" : ""}${currencyFormat.format(dailyPnl)} (${isPnlPositive ? "+" : ""}${pnlPercentage.toStringAsFixed(1)}%)',
                                            style: TextStyle(
                                              fontFamily: 'Plus Jakarta Sans',
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: isPnlPositive ? const Color(0xFF10B981) : const Color(0xFFDC2626),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Row 4: Sub-wallets Horizontal List
                              SizedBox(
                                width: double.infinity,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const ClampingScrollPhysics(),
                                  clipBehavior: Clip.none,
                                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
                                  child: Row(
                                    children: [
                                      ...wallets.take(3).map((w) {
                                        IconData wIcon = Icons.account_balance;
                                        if (w.type == 'E-Wallet') {
                                          wIcon = Icons.account_balance_wallet;
                                        } else if (w.type == 'Cash') {
                                          wIcon = Icons.shopping_bag_outlined;
                                        } else if (w.type == 'Crypto' || w.type == 'Stock' || w.type == 'Mutual Fund') {
                                          wIcon = Icons.show_chart;
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: _buildWalletPill(
                                            w.name,
                                            currencyFormat.format(w.balance),
                                            icon: wIcon,
                                            onTap: () => context.push('/wallet/${w.id}'),
                                          ),
                                        );
                                      }),

                                      // Plus Add Wallet Button
                                      GestureDetector(
                                        onTap: () => context.push('/wallet/add'),
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: Colors.black, width: 2),
                                            boxShadow: NeoBrutalism.shadow(yOffset: 2),
                                          ),
                                          child: const Icon(Icons.add, size: 20, color: Colors.black),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // ── Anchored Persistent Nominal: Rp [Nominal] [Eye Icon on Right] ──
              Positioned(
                top: nominalTop,
                left: nominalLeft,
                right: nominalRightBound,
                child: GestureDetector(
                  onTap: () => setState(() => _obscureBalance = !_obscureBalance),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Rp ',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: rpFontSize,
                          fontWeight: FontWeight.w700,
                          color: NeoBrutalism.dark,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          formattedAmount,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: nominalFontSize,
                            fontWeight: FontWeight.w900,
                            letterSpacing: lerpDouble(-1.4, -0.8, progress)!,
                            color: NeoBrutalism.dark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _obscureBalance ? Icons.visibility_off : Icons.visibility,
                        size: eyeIconSize,
                        color: NeoBrutalism.dark,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Collapsed Action Button: Portfolio > (Slides in from right) ──
              if (actionOpacity > 0.001)
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 16,
                  child: IgnorePointer(
                    ignoring: actionOpacity < 0.5,
                    child: Opacity(
                      opacity: actionOpacity,
                      child: Transform.translate(
                        offset: Offset(actionTranslationX, 0),
                        child: Center(
                          child: GestureDetector(
                            onTap: () => context.push('/reporting'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(9999),
                                border: Border.all(color: Colors.black, width: 2),
                                boxShadow: NeoBrutalism.shadow(yOffset: 1.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'Portfolio',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  Icon(Icons.chevron_right, size: 14, color: Colors.black),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ── Portfolio Pill Button (Protruding TOP-RIGHT in Expanded State, rolls up with curtain) ──
        if (curtainOpacity > 0.001)
          Positioned(
            top: 15,
            right: -10,
            child: IgnorePointer(
              ignoring: curtainOpacity < 0.5,
              child: Opacity(
                opacity: curtainOpacity,
                child: Transform.translate(
                  offset: Offset(0, curtainTranslationY),
                  child: GestureDetector(
                    onTap: () => context.push('/reporting'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(color: Colors.black, width: 2),
                        boxShadow: NeoBrutalism.shadow(yOffset: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.pie_chart_outline, size: 14, color: Colors.black),
                          SizedBox(width: 4),
                          Text(
                            'Portfolio',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Helper Widgets ──

  Widget _buildWalletPill(String name, String balance, {IconData? icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: NeoBrutalism.shadow(yOffset: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black54, width: 1),
              ),
              child: Icon(icon ?? Icons.account_balance, size: 13, color: Colors.black),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  balance,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: NeoBrutalism.dark,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildMatchExpertBanner({
    required String tag,
    required String title,
    required String buttonText,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeoBrutalism.mint,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: NeoBrutalism.shadow(yOffset: 4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 13, color: NeoBrutalism.dark),
                    const SizedBox(width: 4),
                    Text(
                      tag,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: NeoBrutalism.dark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: NeoBrutalism.dark,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: NeoBrutalism.lime,
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: NeoBrutalism.shadow(yOffset: 2),
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: NeoBrutalism.dark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Large White Circle Badge on the right
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: NeoBrutalism.shadow(yOffset: 2),
            ),
            child: const Icon(Icons.groups_outlined, size: 30, color: NeoBrutalism.dark),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantPromptPill(String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: NeoBrutalism.shadow(yOffset: 2),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: NeoBrutalism.dark,
          ),
        ),
      ),
    );
  }

  // ── Edit Name Dialog ──

  void _showEditNameDialog(BuildContext context, WidgetRef ref, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        title: const Text(
          'Edit Nama',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Masukkan nama kamu',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                ref.read(userNameProvider.notifier).state = newName;
              }
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: NeoBrutalism.lime,
              foregroundColor: Colors.black,
              elevation: 0,
              side: const BorderSide(color: Colors.black, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

// ── Sliver Persistent Header Delegate for Hero Section ──

class _HomeHeroHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double topSafeArea;
  final Widget topBar;
  final Widget Function(BuildContext context, double progress) cardBuilder;
  final int heroPage;

  _HomeHeroHeaderDelegate({
    required this.topSafeArea,
    required this.topBar,
    required this.cardBuilder,
    required this.heroPage,
  });

  @override
  double get maxExtent => topSafeArea + 296.0;

  @override
  double get minExtent => topSafeArea + 144.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final cardHeight = lerpDouble(198.0, 64.0, progress)!;
    final dotsOpacity = (1.0 - progress * 3.5).clamp(0.0, 1.0);
    final cardTop = topSafeArea + 62.0;
    final whiteSheetTop = cardTop + (cardHeight / 2);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. Dark Teal Gradient Background (Clipped to region ABOVE white sheet boundary)
        Positioned.fill(
          child: ClipPath(
            clipper: _TealHeaderClipper(whiteSheetTop: whiteSheetTop),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F758A), // Deep teal
                    Color(0xFF198696),
                    Color(0xFF8AD830),
                    Color(0xFFBFFF00), // Bright Lime Green
                  ],
                  stops: [0.0, 0.25, 0.65, 1.0],
                ),
              ),
            ),
          ),
        ),

        // 2. White Sheet Top Boundary Curve & 2px Black Border (No solid white fill below)
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _WhiteSheetBorderPainter(whiteSheetTop: whiteSheetTop),
            ),
          ),
        ),

        // 3. Top App Bar (Halofin Logo + Bell + Avatar)
        Positioned(
          top: topSafeArea + 8,
          left: 20,
          right: 20,
          height: 44,
          child: topBar,
        ),

        // 4. Hero Card (Shrinks from 198px to 64px)
        Positioned(
          top: cardTop,
          left: 12,
          right: 12,
          height: cardHeight,
          child: cardBuilder(context, progress),
        ),

        // 5. Indicator Dots (Fades out when scrolling)
        if (dotsOpacity > 0.01)
          Positioned(
            top: cardTop + cardHeight + 8,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: dotsOpacity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  2,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: heroPage == i ? 16 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: BoxDecoration(
                      color: heroPage == i ? NeoBrutalism.dark : const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  bool shouldRebuild(covariant _HomeHeroHeaderDelegate oldDelegate) => true;
}

// ── Teal Gradient Clipper: Clips exactly to region ABOVE the curved white sheet ──

class _TealHeaderClipper extends CustomClipper<Path> {
  final double whiteSheetTop;
  static const double cornerRadius = 28.0;

  const _TealHeaderClipper({
    required this.whiteSheetTop,
  });

  @override
  Path getClip(Size size) {
    final fullRect = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height + 2000));
    final whiteSheetRRect = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(
            0,
            whiteSheetTop,
            size.width,
            size.height + 2000,
          ),
          topLeft: const Radius.circular(cornerRadius),
          topRight: const Radius.circular(cornerRadius),
        ),
      );

    return Path.combine(PathOperation.difference, fullRect, whiteSheetRRect);
  }

  @override
  bool shouldReclip(covariant _TealHeaderClipper oldClipper) {
    return oldClipper.whiteSheetTop != whiteSheetTop;
  }
}

// ── White Sheet Top Border Painter: Draws 2px black line along the curve ──

class _WhiteSheetBorderPainter extends CustomPainter {
  final double whiteSheetTop;
  static const double cornerRadius = 28.0;

  const _WhiteSheetBorderPainter({
    required this.whiteSheetTop,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final r = cornerRadius;
    final y = whiteSheetTop;
    final w = size.width;

    final path = Path();
    path.moveTo(0, y + r);
    path.arcToPoint(
      Offset(r, y),
      radius: Radius.circular(r),
      clockwise: true,
    );
    path.lineTo(w - r, y);
    path.arcToPoint(
      Offset(w, y + r),
      radius: Radius.circular(r),
      clockwise: true,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WhiteSheetBorderPainter oldPainter) {
    return oldPainter.whiteSheetTop != whiteSheetTop;
  }
}
