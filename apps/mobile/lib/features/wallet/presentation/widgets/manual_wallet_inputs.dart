import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/neo_brutalism_decorations.dart';

/// Label for form fields in ManualWalletEntryScreen.
class WalletFieldLabel extends StatelessWidget {
  final String label;

  const WalletFieldLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          color: NeoBrutalism.dark,
        ),
      ),
    );
  }
}

/// Name and Balance inputs for ManualWalletEntryScreen.
class ManualWalletInputs extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController balanceController;

  const ManualWalletInputs({
    super.key,
    required this.nameController,
    required this.balanceController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WalletFieldLabel('Nama Dompet / Rekening'),
        Container(
          decoration: NeoBrutalism.cardDecoration(
            backgroundColor: Colors.white,
            borderRadius: 16,
            shadowOffset: 2.0,
          ),
          child: TextField(
            controller: nameController,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: NeoBrutalism.dark,
            ),
            decoration: InputDecoration(
              hintText: 'Contoh: Tabungan Utama, Dana Darurat',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: NeoBrutalism.textMuted,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const WalletFieldLabel('Saldo Saat Ini'),
        Container(
          decoration: NeoBrutalism.cardDecoration(
            backgroundColor: Colors.white,
            borderRadius: 16,
            shadowOffset: 2.0,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(14)),
                  border: Border(right: BorderSide(color: Colors.black, width: 2.0)),
                ),
                child: Text(
                  'Rp',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: NeoBrutalism.dark,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: balanceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _RupiahDotFormatter(),
                  ],
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: NeoBrutalism.dark,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: NeoBrutalism.textMuted,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RupiahDotFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('.', '');
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final buffer = StringBuffer();
    final len = text.length;
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
