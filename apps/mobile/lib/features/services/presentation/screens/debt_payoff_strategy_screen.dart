import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../consult/presentation/providers/booking_provider.dart';

class DebtPayoffStrategyScreen extends ConsumerStatefulWidget {
  const DebtPayoffStrategyScreen({super.key});

  @override
  ConsumerState<DebtPayoffStrategyScreen> createState() =>
      _DebtPayoffStrategyScreenState();
}

class _DebtPayoffStrategyScreenState
    extends ConsumerState<DebtPayoffStrategyScreen> {
  bool _isSnowball = true; // true: Snowball, false: Avalanche
  double _extraMonthlyPayment = 500000;

  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final List<Map<String, dynamic>> _debts = [
    {
      'name': 'PayLater E-Commerce',
      'balance': 2500000.0,
      'interestRate': 24.0, // 24% p.a.
      'minPayment': 300000.0,
    },
    {
      'name': 'Pinjol Legal (Multiguna)',
      'balance': 4000000.0,
      'interestRate': 36.0, // 36% p.a.
      'minPayment': 500000.0,
    },
    {
      'name': 'Kartu Kredit Bank',
      'balance': 8000000.0,
      'interestRate': 21.0, // 21% p.a.
      'minPayment': 800000.0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    double totalBalance = 0;
    double totalMinPayment = 0;
    for (var d in _debts) {
      totalBalance += d['balance'] as double;
      totalMinPayment += d['minPayment'] as double;
    }

    // Sorted for Snowball (smallest balance first) vs Avalanche (highest interest first)
    final sortedDebts = [..._debts];
    if (_isSnowball) {
      sortedDebts.sort((a, b) => (a['balance'] as double).compareTo(b['balance'] as double));
    } else {
      sortedDebts.sort((a, b) => (b['interestRate'] as double).compareTo(a['interestRate'] as double));
    }

    // Rough duration and interest estimates
    final totalMonthlyBudget = totalMinPayment + _extraMonthlyPayment;
    final estimatedMonths = totalMonthlyBudget > 0 ? (totalBalance / (totalMonthlyBudget * 0.9)).ceil() : 0;
    final estimatedInterestSaved = _isSnowball ? 1200000.0 : 1850000.0;

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
                      'Strategi Bebas Hutang',
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
                            color: const Color(0xFFEFFCC7),
                            borderRadius: BorderRadius.circular(16),
                            border: NeoBrutalism.border(width: 2.0),
                            boxShadow: NeoBrutalism.shadow(yOffset: 3.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Utang Aktif (${_debts.length} Pinjaman)',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F758A)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currencyFormat.format(totalBalance),
                                style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Estimasi Bebas Utang dalam ~$estimatedMonths Bulan • Hemat Bunga ~${currencyFormat.format(estimatedInterestSaved)}',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Strategy Selector (Snowball vs Avalanche)
                        Text('Pilih Metode Pelunasan', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isSnowball = true),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _isSnowball ? NeoBrutalism.lime : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: NeoBrutalism.border(width: 2.0),
                                    boxShadow: _isSnowball ? NeoBrutalism.shadow(yOffset: 3.0) : NeoBrutalism.shadow(yOffset: 1.5),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Debt Snowball', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w900)),
                                      const SizedBox(height: 2),
                                      Text('Saldo terkecil duluan (fokus motivasi cepat)', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: NeoBrutalism.textMuted)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isSnowball = false),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: !_isSnowball ? NeoBrutalism.lime : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: NeoBrutalism.border(width: 2.0),
                                    boxShadow: !_isSnowball ? NeoBrutalism.shadow(yOffset: 3.0) : NeoBrutalism.shadow(yOffset: 1.5),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Debt Avalanche', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w900)),
                                      const SizedBox(height: 2),
                                      Text('Bunga tertinggi duluan (hemat bunga maksimal)', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: NeoBrutalism.textMuted)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Extra Monthly Payment Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Ekstra Alokasi Pelunasan / Bln', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
                            Text(currencyFormat.format(_extraMonthlyPayment), style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF0F758A))),
                          ],
                        ),
                        Slider(
                          value: _extraMonthlyPayment,
                          min: 0,
                          max: 3000000,
                          divisions: 15,
                          activeColor: const Color(0xFF0F758A),
                          inactiveColor: Colors.black12,
                          onChanged: (v) => setState(() => _extraMonthlyPayment = v),
                        ),
                        const SizedBox(height: 10),

                        // Debt Priority List
                        Text('Urutan Eksekusi Pelunasan', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        ...List.generate(sortedDebts.length, (index) {
                          final d = sortedDebts[index];
                          final isFirst = index == 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isFirst ? const Color(0xFFFFF9E6) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black, width: isFirst ? 2.0 : 1.2),
                              boxShadow: isFirst ? NeoBrutalism.shadow(yOffset: 2.5) : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: isFirst ? NeoBrutalism.lime : const Color(0xFFF3F4F6),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black, width: 1.2),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(d['name'] as String, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800)),
                                      Text('Sisa: ${currencyFormat.format(d['balance'])} • Bunga: ${d['interestRate']}% p.a.', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: NeoBrutalism.textMuted)),
                                    ],
                                  ),
                                ),
                                if (isFirst)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: const Color(0xFFFFDAD6), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.black, width: 1)),
                                    child: Text('Fokus Utama', style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w900, color: const Color(0xFFDC2626))),
                                  ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 18),

                        // CTA Button to Personal Advisory Basic
                        GestureDetector(
                          onTap: () {
                            ref.read(bookingProvider.notifier).reset();
                            context.push('/booking/c3/service');
                          },
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
                                const Icon(Icons.bolt_rounded, size: 20, color: Colors.black),
                                const SizedBox(width: 8),
                                Text(
                                  'Ambil Paket: Fondasi Arus Kas & Utang',
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
}
