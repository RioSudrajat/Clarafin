import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

/// Neo-Brutalist text inputs and date selector for Goal creation/edit.
class GoalFormInputs extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController targetAmountController;
  final DateTime targetDate;
  final VoidCallback onSelectDate;

  const GoalFormInputs({
    super.key,
    required this.nameController,
    required this.targetAmountController,
    required this.targetDate,
    required this.onSelectDate,
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
    final daysLeft = targetDate.difference(DateTime.now()).inDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Goal Name
        _buildFieldLabel('NAMA TARGET IMPIAN'),
        const SizedBox(height: 8),
        TextFormField(
          controller: nameController,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          decoration: _inputDecoration('Contoh: MacBook Pro M3 / Liburan Jepang'),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Nama target wajib diisi';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),

        // 2. Target Amount
        _buildFieldLabel('TARGET NOMINAL DANA'),
        const SizedBox(height: 8),
        TextFormField(
          controller: targetAmountController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _RupiahDotFormatter(),
          ],
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          decoration: _inputDecoration('25.000.000', prefix: _buildPrefixBadge()),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Target nominal wajib diisi';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),

        // 3. Target Date Picker Card
        _buildFieldLabel('TARGET WAKTU TERCAPAI'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onSelectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: NeoBrutalism.cardDecoration(
              backgroundColor: const Color(0xFFF9FAFB),
              borderRadius: 14,
              shadowOffset: 2.0,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  size: 20,
                  color: Colors.black,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateFormat('d MMMM yyyy').format(targetDate),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: daysLeft < 30 ? const Color(0xFFFFDAD6) : NeoBrutalism.lime,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: Text(
                    '$daysLeft hari lagi',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: daysLeft < 30 ? const Color(0xFFBA1A1A) : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
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
