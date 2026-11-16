import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class InteractiveCalculatorBottomSheet extends StatefulWidget {
  final String title;

  const InteractiveCalculatorBottomSheet({
    super.key,
    this.title = 'Simulasi KPR & Pinjaman',
  });

  static Future<void> show(
    BuildContext context, {
    String title = 'Simulasi KPR & Pinjaman',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InteractiveCalculatorBottomSheet(title: title),
    );
  }

  @override
  State<InteractiveCalculatorBottomSheet> createState() =>
      _InteractiveCalculatorBottomSheetState();
}

class _InteractiveCalculatorBottomSheetState
    extends State<InteractiveCalculatorBottomSheet> {
  double _loanAmount = 500000000; // Rp 500.000.000
  int _tenorYears = 15;
  double _interestRate = 7.5; // 7.5% per tahun

  final _currencyFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  double get _monthlyInstallment {
    final r = (_interestRate / 100) / 12;
    final n = _tenorYears * 12;
    if (r == 0) return _loanAmount / n;
    final factor = math.pow(1 + r, n);
    return _loanAmount * (r * factor) / (factor - 1);
  }

  double get _totalPayment => _monthlyInstallment * (_tenorYears * 12);
  double get _totalInterest => _totalPayment - _loanAmount;
  double get _recommendedIncome => _monthlyInstallment / 0.3; // 30% DSR Rule

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: const Border(
          top: BorderSide(color: Colors.black, width: 2.5),
          left: BorderSide(color: Colors.black, width: 2),
          right: BorderSide(color: Colors.black, width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              ),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: NeoBrutalism.lime,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black, width: 2),
                          boxShadow: NeoBrutalism.shadow(yOffset: 2),
                        ),
                        child: const Icon(
                          Icons.calculate_outlined,
                          size: 20,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: NeoBrutalism.dark,
                            ),
                          ),
                          const Text(
                            'Kalkulator anuitas suku bunga efektif',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: NeoBrutalism.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                        boxShadow: NeoBrutalism.shadow(yOffset: 2),
                      ),
                      child: const Icon(Icons.close, size: 16, color: Colors.black),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Result Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: NeoBrutalism.primaryLight,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: NeoBrutalism.shadow(yOffset: 3),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ESTIMASI CICILAN BULANAN',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: NeoBrutalism.dark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_currencyFormatter.format(_monthlyInstallment)} / bln',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: NeoBrutalism.dark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.black26, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatCol(
                          'Total Bunga',
                          _currencyFormatter.format(_totalInterest),
                        ),
                        _buildStatCol(
                          'Total Bayar',
                          _currencyFormatter.format(_totalPayment),
                        ),
                        _buildStatCol(
                          'Saran Min. Gaji',
                          _currencyFormatter.format(_recommendedIncome),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Input 1: Plafon Pinjaman
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Plafon Pinjaman',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _currencyFormatter.format(_loanAmount),
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: NeoBrutalism.secondary,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _loanAmount,
                min: 50000000,
                max: 3000000000,
                divisions: 59,
                activeColor: Colors.black,
                inactiveColor: Colors.grey.shade300,
                onChanged: (val) => setState(() => _loanAmount = val),
              ),
              Wrap(
                spacing: 8,
                children: [
                  _buildPresetChip('Rp 250Jt', 250000000, _loanAmount == 250000000,
                      (v) => setState(() => _loanAmount = v)),
                  _buildPresetChip('Rp 500Jt', 500000000, _loanAmount == 500000000,
                      (v) => setState(() => _loanAmount = v)),
                  _buildPresetChip('Rp 750Jt', 750000000, _loanAmount == 750000000,
                      (v) => setState(() => _loanAmount = v)),
                  _buildPresetChip('Rp 1M', 1000000000, _loanAmount == 1000000000,
                      (v) => setState(() => _loanAmount = v)),
                ],
              ),
              const SizedBox(height: 18),

              // Input 2: Tenor (Tahun)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Jangka Waktu (Tenor)',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '$_tenorYears Tahun (${_tenorYears * 12} bln)',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: NeoBrutalism.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [5, 10, 15, 20, 25].map((years) {
                  final isSelected = _tenorYears == years;
                  return GestureDetector(
                    onTap: () => setState(() => _tenorYears = years),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black, width: 1.8),
                        boxShadow: isSelected
                            ? null
                            : NeoBrutalism.shadow(yOffset: 2),
                      ),
                      child: Text(
                        '$years Thn',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Input 3: Bunga per tahun
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Suku Bunga Efektif (% / thn)',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${_interestRate.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: NeoBrutalism.secondary,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _interestRate,
                min: 3.0,
                max: 18.0,
                divisions: 30,
                activeColor: Colors.black,
                inactiveColor: Colors.grey.shade300,
                onChanged: (val) => setState(() => _interestRate = val),
              ),
              const SizedBox(height: 12),

              // Recommendation note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: NeoBrutalism.surfaceWarm,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.lightbulb_outline, size: 18, color: Colors.black),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rasio cicilan aman maksimal 30% dari penghasilan bulanan agar cashflow tetap stabil.',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: NeoBrutalism.dark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // CTA Action
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/consult');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: NeoBrutalism.lime,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(48),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.black, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadowColor: Colors.black,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.support_agent, size: 20, color: Colors.black),
                    SizedBox(width: 8),
                    Text(
                      'Konsultasikan Hasil Ini ke CFP',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: NeoBrutalism.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: NeoBrutalism.dark,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(
    String label,
    double value,
    bool isSelected,
    ValueChanged<double> onSelected,
  ) {
    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 1.2),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}


