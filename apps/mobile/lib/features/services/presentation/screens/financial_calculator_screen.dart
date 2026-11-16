import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class FinancialCalculatorScreen extends StatefulWidget {
  const FinancialCalculatorScreen({super.key});

  @override
  State<FinancialCalculatorScreen> createState() => _FinancialCalculatorScreenState();
}

class _FinancialCalculatorScreenState extends State<FinancialCalculatorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Tab 1: Compound Investment
  double _initialInvestment = 10000000;
  double _monthlyContribution = 1500000;
  double _annualReturn = 10.0;
  int _investmentYears = 10;

  // Tab 2: Emergency Fund
  double _monthlyExpenses = 6000000;
  int _dependentMultiplier = 6; // 3, 6, 9, 12

  // Tab 3: Retirement / FIRE
  double _desiredMonthlyExpense = 12000000;
  int _currentAge = 26;
  int _retirementAge = 50;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        width: 40,
                        height: 40,
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
                      'Kalkulator Finansial',
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
            // Neo-Brutalist Tab Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 2.0),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: NeoBrutalism.lime,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.black87,
                  labelStyle: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w900),
                  unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700),
                  tabs: const [
                    Tab(text: 'Investasi'),
                    Tab(text: 'Dana Darurat'),
                    Tab(text: 'Pensiun FIRE'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Main White Container
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
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildInvestmentTab(),
                      _buildEmergencyFundTab(),
                      _buildRetirementTab(),
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

  // ── Tab 1: Investasi (Compound Interest) ──
  Widget _buildInvestmentTab() {
    final months = _investmentYears * 12;
    final r = (_annualReturn / 100) / 12;
    double futureValue = _initialInvestment * pow(1 + r, months);
    if (r > 0) {
      futureValue += _monthlyContribution * ((pow(1 + r, months) - 1) / r);
    } else {
      futureValue += _monthlyContribution * months;
    }
    final totalPrincipal = _initialInvestment + (_monthlyContribution * months);
    final totalProfit = futureValue - totalPrincipal;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultHero(
            title: 'Estimasi Nilai Investasi Akhir ($_investmentYears Tahun)',
            primaryAmount: currencyFormat.format(futureValue),
            subtitle: 'Total Modal: ${currencyFormat.format(totalPrincipal)} • Akumulasi Bunga: +${currencyFormat.format(totalProfit)}',
          ),
          const SizedBox(height: 18),
          _buildSliderRow('Investasi Awal', currencyFormat.format(_initialInvestment), _initialInvestment, 0, 100000000, 20, (v) => setState(() => _initialInvestment = v)),
          _buildSliderRow('Setoran Rutin Bulanan', currencyFormat.format(_monthlyContribution), _monthlyContribution, 100000, 20000000, 20, (v) => setState(() => _monthlyContribution = v)),
          _buildSliderRow('Ekspektasi Return (% p.a.)', '$_annualReturn%', _annualReturn, 3, 20, 17, (v) => setState(() => _annualReturn = v)),
          _buildSliderRow('Jangka Waktu (Tahun)', '$_investmentYears Tahun', _investmentYears.toDouble(), 1, 30, 29, (v) => setState(() => _investmentYears = v.toInt())),
          const SizedBox(height: 16),
          _buildConsultationCta(),
        ],
      ),
    );
  }

  // ── Tab 2: Dana Darurat Ideal ──
  Widget _buildEmergencyFundTab() {
    final targetEmergencyFund = _monthlyExpenses * _dependentMultiplier;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultHero(
            title: 'Kebutuhan Dana Darurat Ideal ($_dependentMultiplier Bulan)',
            primaryAmount: currencyFormat.format(targetEmergencyFund),
            subtitle: 'Alokasi aman: 50% Tabungan Fleksibel / RDPU + 50% Deposito 1 Bulan',
          ),
          const SizedBox(height: 18),
          _buildSliderRow('Pengeluaran Pokok Bulanan', currencyFormat.format(_monthlyExpenses), _monthlyExpenses, 2000000, 30000000, 28, (v) => setState(() => _monthlyExpenses = v)),
          const SizedBox(height: 10),
          Text('Status Tanggungan & Formula', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChoiceChip('Lajang (3x)', _dependentMultiplier == 3, () => setState(() => _dependentMultiplier = 3)),
              _buildChoiceChip('Lajang Mandiri (6x)', _dependentMultiplier == 6, () => setState(() => _dependentMultiplier = 6)),
              _buildChoiceChip('Menikah (9x)', _dependentMultiplier == 9, () => setState(() => _dependentMultiplier = 9)),
              _buildChoiceChip('Menikah + Anak / Usaha (12x)', _dependentMultiplier == 12, () => setState(() => _dependentMultiplier = 12)),
            ],
          ),
          const SizedBox(height: 20),
          _buildConsultationCta(),
        ],
      ),
    );
  }

  // ── Tab 3: Dana Pensiun (FIRE) ──
  Widget _buildRetirementTab() {
    final workingYears = (_retirementAge - _currentAge).clamp(1, 60);
    // 4% Safe Withdrawal Rule: Annual expenses * 25
    final annualExpense = _desiredMonthlyExpense * 12;
    final totalFireTarget = annualExpense * 25;
    // Monthly savings required at 7% real return (rule of thumb)
    final r = 0.07 / 12;
    final totalMonths = workingYears * 12;
    final requiredMonthly = (totalFireTarget * r) / (pow(1 + r, totalMonths) - 1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultHero(
            title: 'Target Dana Pensiun Bebas Bekerja (Rule of 25)',
            primaryAmount: currencyFormat.format(totalFireTarget),
            subtitle: 'Nabung disarankan: ${currencyFormat.format(requiredMonthly)} / bulan selama $workingYears tahun',
          ),
          const SizedBox(height: 18),
          _buildSliderRow('Target Pengeluaran Bulanan Pensiun', currencyFormat.format(_desiredMonthlyExpense), _desiredMonthlyExpense, 3000000, 50000000, 47, (v) => setState(() => _desiredMonthlyExpense = v)),
          _buildSliderRow('Usia Sekarang', '$_currentAge Tahun', _currentAge.toDouble(), 18, 55, 37, (v) => setState(() => _currentAge = v.toInt())),
          _buildSliderRow('Target Usia Pensiun', '$_retirementAge Tahun', _retirementAge.toDouble(), max(30, _currentAge + 1).toDouble(), 70, 40, (v) => setState(() => _retirementAge = v.toInt())),
          const SizedBox(height: 16),
          _buildConsultationCta(),
        ],
      ),
    );
  }

  Widget _buildResultHero({required String title, required String primaryAmount, required String subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4F8),
        borderRadius: BorderRadius.circular(16),
        border: NeoBrutalism.border(width: 2.0),
        boxShadow: NeoBrutalism.shadow(yOffset: 3.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F758A))),
          const SizedBox(height: 4),
          Text(primaryAmount, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black)),
          const SizedBox(height: 6),
          Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.3)),
        ],
      ),
    );
  }

  Widget _buildSliderRow(String label, String valueLabel, double currentVal, double min, double max, int divisions, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
            Text(valueLabel, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF0F758A))),
          ],
        ),
        Slider(
          value: currentVal.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          activeColor: const Color(0xFF0F758A),
          inactiveColor: Colors.black12,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? NeoBrutalism.lime : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 1.5),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildConsultationCta() {
    return GestureDetector(
      onTap: () => context.push('/consult?category=Individu'),
      child: Container(
        width: double.infinity,
        height: 46,
        decoration: BoxDecoration(
          color: NeoBrutalism.lime,
          borderRadius: BorderRadius.circular(14),
          border: NeoBrutalism.border(width: 2.0),
          boxShadow: NeoBrutalism.shadow(yOffset: 2.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.support_agent_rounded, size: 18, color: Colors.black),
            const SizedBox(width: 8),
            Text(
              'Rancang Portofolio Ini Bareng CFP®',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w900, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
