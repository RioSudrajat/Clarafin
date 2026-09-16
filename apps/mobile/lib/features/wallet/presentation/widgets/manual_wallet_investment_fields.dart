import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/neo_brutalism_decorations.dart';

/// Investment extra fields (return % and dividend date picker) for ManualWalletEntryScreen.
class ManualWalletInvestmentFields extends StatelessWidget {
  final TextEditingController returnController;
  final DateTime? dividendDate;
  final bool isVolatile;
  final VoidCallback onPickDate;

  const ManualWalletInvestmentFields({
    super.key,
    required this.returnController,
    required this.dividendDate,
    required this.isVolatile,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Estimasi Imbal Hasil Tahunan (% p.a.)',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: NeoBrutalism.dark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: NeoBrutalism.cardDecoration(
            backgroundColor: Colors.white,
            borderRadius: 16,
            shadowOffset: 2.0,
            borderWidth: 2.0,
          ),
          child: TextField(
            controller: returnController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: NeoBrutalism.dark,
            ),
            decoration: InputDecoration(
              hintText: 'Misal: 5.5',
              hintStyle: GoogleFonts.plusJakartaSans(
                color: NeoBrutalism.textMuted,
                fontSize: 13,
              ),
              suffixText: '% p.a.',
              suffixStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                color: NeoBrutalism.dark,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Tanggal Dividen / Kupon (Opsional)',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: NeoBrutalism.dark,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onPickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: NeoBrutalism.cardDecoration(
              backgroundColor: Colors.white,
              borderRadius: 16,
              shadowOffset: 2.0,
              borderWidth: 2.0,
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded, size: 20, color: Colors.black),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    dividendDate == null
                        ? 'Pilih tanggal pencairan dividen'
                        : '${dividendDate!.day} / ${dividendDate!.month} / ${dividendDate!.year}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: dividendDate == null ? NeoBrutalism.textMuted : NeoBrutalism.dark,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black),
              ],
            ),
          ),
        ),
        if (isVolatile) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: NeoBrutalism.cardDecoration(
              backgroundColor: const Color(0xFFFEF3C7),
              borderRadius: 14,
              shadowOffset: 2.0,
              borderWidth: 2.0,
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Aset dengan volatilitas tinggi. Nilai pasar disimulasikan dinamis.',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF92400E),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
