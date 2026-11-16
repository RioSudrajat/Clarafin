import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../widgets/ikhtisar_tab.dart';
import '../widgets/cashflow_tab.dart';
import '../widgets/pemasukan_tab.dart';
import '../widgets/pengeluaran_tab.dart';

class ReportDashboardScreen extends ConsumerStatefulWidget {
  const ReportDashboardScreen({super.key});

  @override
  ConsumerState<ReportDashboardScreen> createState() => _ReportDashboardScreenState();
}

class _ReportDashboardScreenState extends ConsumerState<ReportDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F758A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: NeoBrutalism.brandGradient,
        ),
        child: Column(
          children: [
            // Pinned Neo-Brutalist Header
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: NeoBrutalism.border(width: 2.0),
                          boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
                        ),
                        child: const Center(
                          child: Icon(Icons.arrow_back_rounded, size: 22, color: NeoBrutalism.dark),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Portfolio Keuangan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main White Container with Curvature
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(
                    top: BorderSide(color: Colors.black, width: 2.0),
                    left: BorderSide(color: Colors.black, width: 2.0),
                    right: BorderSide(color: Colors.black, width: 2.0),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  child: Column(
                    children: [
                      // Styled Neo-Brutalist Tab Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: NeoBrutalism.surfaceWarm,
                            borderRadius: BorderRadius.circular(14),
                            border: NeoBrutalism.border(width: 2.0),
                            boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            dividerColor: Colors.transparent,
                            indicator: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: NeoBrutalism.secondary,
                              border: NeoBrutalism.border(width: 1.5),
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelColor: Colors.white,
                            unselectedLabelColor: const Color(0xFF4B5563),
                            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                            labelStyle: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                            unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                            tabs: const [
                              Tab(text: 'Ikhtisar'),
                              Tab(text: 'Cashflow'),
                              Tab(text: 'Pemasukan'),
                              Tab(text: 'Pengeluaran'),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1.5, color: Colors.black12, thickness: 1.5),

                      // Tab Views
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: const [
                            IkhtisarTab(),
                            CashflowTab(),
                            PemasukanTab(),
                            PengeluaranTab(),
                          ],
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
    );
  }
}
