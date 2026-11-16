import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class KprSimulationScreen extends StatefulWidget {
  const KprSimulationScreen({super.key});

  @override
  State<KprSimulationScreen> createState() => _KprSimulationScreenState();
}

class _KprSimulationScreenState extends State<KprSimulationScreen> {
  final _propertyPriceController = TextEditingController(text: '850000000');
  final _incomeController = TextEditingController(text: '18000000');
  double _dpPercent = 20.0;
  double _fixedRate = 4.75;
  final int _fixedYears = 3;
  double _floatingRate = 10.5;
  int _tenorYears = 15;

  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    _propertyPriceController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  double _calculateMonthlyInstallment(double principal, double annualRate, int totalMonths) {
    if (principal <= 0 || totalMonths <= 0) return 0;
    final r = (annualRate / 100) / 12;
    if (r == 0) return principal / totalMonths;
    return (principal * (r * pow(1 + r, totalMonths))) / (pow(1 + r, totalMonths) - 1);
  }

  @override
  Widget build(BuildContext context) {
    final propertyPrice = double.tryParse(_propertyPriceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 850000000.0;
    final monthlyIncome = double.tryParse(_incomeController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 18000000.0;
    final dpAmount = propertyPrice * (_dpPercent / 100);
    final loanPrincipal = (propertyPrice - dpAmount).clamp(0.0, double.infinity);

    final totalMonths = _tenorYears * 12;
    final fixedMonths = _fixedYears * 12;
    final fixedInstallment = _calculateMonthlyInstallment(loanPrincipal, _fixedRate, totalMonths);

    // Remaining principal after fixed period approx
    final rFixed = (_fixedRate / 100) / 12;
    double remainingPrincipal = loanPrincipal;
    if (rFixed > 0 && fixedMonths < totalMonths) {
      final balanceFactor = (pow(1 + rFixed, totalMonths) - pow(1 + rFixed, fixedMonths)) / (pow(1 + rFixed, totalMonths) - 1);
      remainingPrincipal = loanPrincipal * balanceFactor;
    }
    final remainingMonths = totalMonths - fixedMonths;
    final floatingInstallment = remainingMonths > 0
        ? _calculateMonthlyInstallment(remainingPrincipal, _floatingRate, remainingMonths)
        : fixedInstallment;

    final dsrPercent = monthlyIncome > 0 ? (fixedInstallment / monthlyIncome) * 100 : 0.0;

    Color dsrColor;
    String dsrStatus;
    if (dsrPercent <= 30) {
      dsrColor = const Color(0xFF10B981);
      dsrStatus = 'Aman (< 30% dari gaji)';
    } else if (dsrPercent <= 40) {
      dsrColor = const Color(0xFFF59E0B);
      dsrStatus = 'Waspada (30% - 40% dari gaji)';
    } else {
      dsrColor = const Color(0xFFDC2626);
      dsrStatus = 'Berisiko Tinggi (> 40% dari gaji)';
    }

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
                      'Simulasi KPR',
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Result Highlight Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F4F8),
                            borderRadius: BorderRadius.circular(16),
                            border: NeoBrutalism.border(width: 2.0),
                            boxShadow: NeoBrutalism.shadow(yOffset: 3.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estimasi Cicilan Fixed (Tahun 1–$_fixedYears)',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F758A)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${currencyFormat.format(fixedInstallment)} / bln',
                                style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Estimasi Masa Floating: ${currencyFormat.format(floatingInstallment)} / bln ($_floatingRate% p.a.)',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1, color: Colors.black12),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: dsrColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: dsrColor, width: 1.2),
                                    ),
                                    child: Text(
                                      'DSR: ${dsrPercent.toStringAsFixed(1)}%',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: dsrColor),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      dsrStatus,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Form Inputs
                        Text('Parameter KPR', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),

                        // Property Price
                        _buildInputField('Harga Properti (Rp)', _propertyPriceController),
                        const SizedBox(height: 12),

                        // Monthly Income
                        _buildInputField('Penghasilan Bulanan Bersih (Rp)', _incomeController),
                        const SizedBox(height: 16),

                        // DP Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Uang Muka (DP)', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
                            Text('${_dpPercent.toInt()}% (${currencyFormat.format(dpAmount)})', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF0F758A))),
                          ],
                        ),
                        Slider(
                          value: _dpPercent,
                          min: 5,
                          max: 50,
                          divisions: 9,
                          activeColor: const Color(0xFF0F758A),
                          inactiveColor: Colors.black12,
                          onChanged: (v) => setState(() => _dpPercent = v),
                        ),

                        // Tenor Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Jangka Waktu (Tenor)', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
                            Text('$_tenorYears Tahun', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF0F758A))),
                          ],
                        ),
                        Slider(
                          value: _tenorYears.toDouble(),
                          min: 5,
                          max: 25,
                          divisions: 20,
                          activeColor: const Color(0xFF0F758A),
                          inactiveColor: Colors.black12,
                          onChanged: (v) => setState(() => _tenorYears = v.toInt()),
                        ),

                        // Rates Row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Bunga Fixed (% p.a.)', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    initialValue: _fixedRate.toString(),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: _inputDecoration(),
                                    onChanged: (v) => setState(() => _fixedRate = double.tryParse(v) ?? 4.75),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Bunga Floating (% p.a.)', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    initialValue: _floatingRate.toString(),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: _inputDecoration(),
                                    onChanged: (v) => setState(() => _floatingRate = double.tryParse(v) ?? 10.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // CTA Button to Consult
                        GestureDetector(
                          onTap: () => context.push('/consult?category=Individu'),
                          child: Container(
                            width: double.infinity,
                            height: 48,
                            decoration: BoxDecoration(
                              color: NeoBrutalism.lime,
                              borderRadius: BorderRadius.circular(14),
                              border: NeoBrutalism.border(width: 2.0),
                              boxShadow: NeoBrutalism.shadow(yOffset: 3.0),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.support_agent_rounded, size: 20, color: Colors.black),
                                const SizedBox(width: 8),
                                Text(
                                  'Konsultasikan KPR Ini Bareng Ahli (CFP®)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration(),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0F758A), width: 2.0)),
    );
  }
}
