import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../core/providers/mock_providers.dart';
import 'package:intl/intl.dart';

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
                                // ── Quick Actions Row ──
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const ClampingScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Row(
                                    children: [
                                      _buildFeatureAction(
                                        icon: Icons.smart_toy_outlined,
                                        label: 'AI Budget',
                                        onTap: () => context.push('/session'),
                                      ),
                                      _buildFeatureAction(
                                        icon: Icons.history,
                                        label: 'History',
                                        onTap: () => context.push('/transaction/history'),
                                      ),
                                      _buildFeatureAction(
                                        icon: Icons.credit_card_outlined,
                                        label: 'Score',
                                        onTap: () => context.go('/budget'),
                                      ),
                                      _buildFeatureAction(
                                        icon: Icons.bar_chart_outlined,
                                        label: 'Report',
                                        onTap: () => context.push('/reporting'),
                                      ),
                                      _buildFeatureAction(
                                        icon: Icons.receipt_long_outlined,
                                        label: 'Bills',
                                        onTap: () => context.go('/budget'),
                                      ),
                                      _buildFeatureAction(
                                        icon: Icons.account_balance_wallet_outlined,
                                        label: 'E-Wallet',
                                        onTap: () => context.go('/wallet'),
                                      ),
                                    ],
                                  ),
                                ),

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
        // Halofin Brand Logo & Name
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: NeoBrutalism.lime,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: NeoBrutalism.shadow(yOffset: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/logo_halofin.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'halofin',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1.0,
                shadows: [
                  Shadow(
                    color: Colors.black38,
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
    final isCollapsed = progress >= 0.35;

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: isCollapsed ? 12 : 18,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0E6976), // Deep teal matching reference image
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: NeoBrutalism.shadow(yOffset: isCollapsed ? 2 : 4),
      ),
      child: isCollapsed
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showEditNameDialog(context, ref, userName),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'Hi, $userName',
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit_outlined, size: 12, color: Colors.white70),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
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
              ],
            )
          : FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 330,
                height: 162,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Row: Hi, [userName] + Title on left, Lime group icon circle on right
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => _showEditNameDialog(context, ref, userName),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Hi, $userName',
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.edit_outlined, size: 11, color: Colors.white70),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
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
    final isCollapsed = progress >= 0.35;

    if (isCollapsed) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: NeoBrutalism.lime,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: NeoBrutalism.shadow(yOffset: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'TOTAL: ',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: NeoBrutalism.dark,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _obscureBalance = !_obscureBalance),
                    child: Icon(
                      _obscureBalance ? Icons.visibility_off : Icons.visibility,
                      size: 15,
                      color: NeoBrutalism.dark,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _obscureBalance
                          ? '••••••••'
                          : currencyFormat.format(totalBalance),
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                        color: NeoBrutalism.dark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
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
          ],
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Lime Balance Card Body
        Container(
          width: double.infinity,
          height: double.infinity,
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.only(top: 18, bottom: 12),
          decoration: BoxDecoration(
            color: NeoBrutalism.lime,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: NeoBrutalism.shadow(yOffset: 4),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 330,
              height: 164,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Rows 1-3 with 18px horizontal padding
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Row 1: TOTAL BALANCE + Toggle Eye
                        Row(
                          children: [
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
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => setState(() => _obscureBalance = !_obscureBalance),
                              child: Icon(
                                _obscureBalance ? Icons.visibility_off : Icons.visibility,
                                size: 16,
                                color: NeoBrutalism.dark,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Row 2: Big Balance Amount
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const Text(
                              'Rp ',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: NeoBrutalism.dark,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _obscureBalance
                                    ? '••••••••'
                                    : currencyFormat.format(totalBalance).replaceAll('Rp ', ''),
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.4,
                                  color: NeoBrutalism.dark,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

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

                  // Row 4: Sub-wallets Horizontal List (Bounded cleanly to card edges without spilling)
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

        // ── Portfolio Pill Button (Positioned Overlapping Top-Right Corner: protruding TOP and RIGHT!) ──
        Positioned(
          top: 15,
          right: -10,
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

  Widget _buildFeatureAction({required IconData icon, required String label, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 14),
        child: Column(
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: NeoBrutalism.shadow(yOffset: 3),
              ),
              child: Icon(icon, color: NeoBrutalism.dark, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: NeoBrutalism.dark,
              ),
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
    final whiteSheetTop = lerpDouble(cardTop + 100.0, cardTop + 68.0, progress)!;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. Dark Teal Gradient Background
        Positioned.fill(
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

        // 2. White Sheet Top Boundary (Moves up with scroll, pins at collapsed limit)
        Positioned(
          top: whiteSheetTop,
          left: 0,
          right: 0,
          bottom: -2,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(color: Colors.black, width: 2),
              ),
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
