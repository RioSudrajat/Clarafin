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
      body: Stack(
        children: [
          // ── 1. Top Gradient Background ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 320,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F758A), // Deep teal from Figma
                    Color(0xFF198696),
                    Color(0xFF8AD830),
                    Color(0xFFBFFF00), // Bright Lime Green
                  ],
                  stops: [0.0, 0.25, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // ── 2. Fixed / Absolute Header & Scrollable Body ──
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Fixed / Pinned Header (Stays in place, does not scroll) ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // User Greeting & Name (Tap to edit)
                      GestureDetector(
                        onTap: () => _showEditNameDialog(context, ref, userName),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        offset: Offset(0, 2),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.edit_outlined, size: 14, color: Colors.white70),
                              ],
                            ),
                          ],
                        ),
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
                  ),
                ),

                const SizedBox(height: 8),

                // ── Scrollable Body ──
                Expanded(
                  child: ScrollConfiguration(
                    behavior: const ScrollBehavior().copyWith(
                      overscroll: false,
                      physics: const ClampingScrollPhysics(),
                    ),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // ── Full-Width White Sheet Container (Edge-to-Edge) ──
                          Container(
                            margin: const EdgeInsets.only(top: 85),
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                              border: Border(
                                top: BorderSide(color: Colors.black, width: 2),
                              ),
                            ),
                            padding: const EdgeInsets.only(top: 155, bottom: 24),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
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
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                              child: _buildMatchExpertBanner(
                                                tag: 'EXPERT HELP',
                                                title: 'Bingung mencari konsultan?',
                                                buttonText: 'MATCH',
                                                onTap: () => context.go('/consult'),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Budget Header
                                            Row(
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

                                            const SizedBox(height: 12),

                                            // Progress Bar
                                            Container(
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

                                            const SizedBox(height: 10),

                                            RichText(
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

                                            const Padding(
                                              padding: EdgeInsets.symmetric(vertical: 14),
                                              child: Divider(
                                                height: 1,
                                                thickness: 1,
                                                color: Colors.black,
                                              ),
                                            ),

                                            // Bot Button + Prompt Pills
                                            Row(
                                              children: [
                                                GestureDetector(
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
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: SingleChildScrollView(
                                                    scrollDirection: Axis.horizontal,
                                                    physics: const ClampingScrollPhysics(),
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
                                              ],
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

                          // ── Hero PageView (Index 0: Konsultasi Finansial Card | Index 1: Total Balance Card) ──
                          Positioned(
                            top: 0,
                            left: 20,
                            right: 20,
                            child: SizedBox(
                              height: 220,
                              child: PageView(
                                controller: _heroController,
                                clipBehavior: Clip.none,
                                physics: const PageScrollPhysics(),
                                onPageChanged: (i) => setState(() => _heroPage = i),
                                children: [
                                  // ── Slide 0: Konsultasi Finansial Card (Deep Teal from Gradient) ──
                                  _buildConsultationHeroCard(userName),

                                  // ── Slide 1: Total Balance Card (Restored exact composition & positioning) ──
                                  _buildTotalBalanceHeroCard(totalBalance, dailyPnl, pnlPercentage, isPnlPositive, currencyFormat, wallets),
                                ],
                              ),
                            ),
                          ),

                          // ── Hero Page Indicator Dots (Positioned directly below the Hero Card) ──
                          Positioned(
                            top: 228,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                2,
                                (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  width: _heroPage == i ? 16 : 6,
                                  height: 6,
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: BoxDecoration(
                                    color: _heroPage == i ? NeoBrutalism.dark : const Color(0xFFD1D5DB),
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Card 1: Konsultasi Finansial (Deep Teal / Blue from Gradient) ──

  Widget _buildConsultationHeroCard(String userName) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F758A), // Deep teal from header gradient
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: NeoBrutalism.shadow(yOffset: 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Content Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Greeting
                  Text(
                    'Hi, $userName',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Financial Consultation Copywriting
                  const Text(
                    'Bagaimana kondisi finansialmu, baik secara pribadi, keluarga, pasangan maupun bisnis. Kamu bisa konsultasikan disini, yuk booking jadwalnya!',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),

          // Bottom Full-Width CTA Strip (Neon Lime with Black Border)
          GestureDetector(
            onTap: () => context.go('/consult'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                color: NeoBrutalism.lime,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
                border: Border(
                  top: BorderSide(color: Colors.black, width: 2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Mulai Konseling',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward, size: 14, color: Colors.black),
                ],
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
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Lime Balance Card Body
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            color: NeoBrutalism.lime,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: NeoBrutalism.shadow(yOffset: 4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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

              const SizedBox(height: 14),

              // Row 4: Sub-wallets Horizontal List
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
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
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(color: Colors.black, width: 2),
                          boxShadow: NeoBrutalism.shadow(yOffset: 2),
                        ),
                        child: const Icon(Icons.add, size: 18, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Portfolio Pill Button (Positioned Overlapping Top-Right Corner: protruding TOP and RIGHT!) ──
        Positioned(
          top: -12,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: NeoBrutalism.shadow(yOffset: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black54, width: 1),
              ),
              child: Icon(icon ?? Icons.account_balance, size: 11, color: Colors.black),
            ),
            const SizedBox(width: 6),
            Text(
              name,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              balance,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: NeoBrutalism.dark,
              ),
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
