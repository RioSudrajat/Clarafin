import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

/// Neo-Brutalism input fields for Budget category name and amounts.
class BudgetFormInputs extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController totalAmountController;
  final TextEditingController spentAmountController;

  const BudgetFormInputs({
    super.key,
    required this.nameController,
    required this.totalAmountController,
    required this.spentAmountController,
  });

  Widget _buildFieldLabel(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: Color(0xFF374151),
        letterSpacing: 0.5,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {Widget? prefix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefix,
      hintStyle: const TextStyle(
        color: Color(0xFF9CA3AF),
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.black, width: 2.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.black, width: 2.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.black, width: 2.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2.5),
      ),
    );
  }

  Widget _buildPrefixBadge() {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: NeoBrutalism.lime,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: const Text(
        'Rp',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 13,
          color: Colors.black,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Category Name
        _buildFieldLabel('NAMA KATEGORI ANGGARAN'),
        const SizedBox(height: 8),
        TextFormField(
          controller: nameController,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          decoration: _inputDecoration('Contoh: Makanan & Minuman'),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Nama kategori wajib diisi';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),

        // 2. Total Amount
        _buildFieldLabel('TOTAL PLAFON ANGGARAN'),
        const SizedBox(height: 8),
        TextFormField(
          controller: totalAmountController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _RupiahDotFormatter(),
          ],
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          decoration: _inputDecoration('5.000.000', prefix: _buildPrefixBadge()),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Nominal plafon wajib diisi';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),

        // 3. Spent Amount (Demo simulation)
        _buildFieldLabel('REALISASI TERPAKAI (SIMULASI DEMO)'),
        const SizedBox(height: 8),
        TextFormField(
          controller: spentAmountController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _RupiahDotFormatter(),
          ],
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          decoration: _inputDecoration('0', prefix: _buildPrefixBadge()),
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
