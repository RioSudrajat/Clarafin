import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

/// Neo-Brutalist input fields for Bill name, amount, and due date.
class BillFormInputs extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController amountController;
  final DateTime dueDate;
  final VoidCallback onSelectDueDate;

  const BillFormInputs({
    super.key,
    required this.nameController,
    required this.amountController,
    required this.dueDate,
    required this.onSelectDueDate,
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
    final daysLeft = dueDate.difference(DateTime.now()).inDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Bill Name
        _buildFieldLabel('NAMA TAGIHAN RUTIN'),
        const SizedBox(height: 8),
        TextFormField(
          controller: nameController,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          decoration: _inputDecoration('Contoh: Netflix Premium / Indihome / PLN'),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Nama tagihan wajib diisi';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),

        // 2. Bill Amount
        _buildFieldLabel('NOMINAL TAGIHAN'),
        const SizedBox(height: 8),
        TextFormField(
          controller: amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _RupiahDotFormatter(),
          ],
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          decoration: _inputDecoration('186.000', prefix: _buildPrefixBadge()),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Nominal tagihan wajib diisi';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),

        // 3. Due Date Picker Card
        _buildFieldLabel('JATUH TEMPO BERIKUTNYA'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onSelectDueDate,
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
                  Icons.calendar_today_rounded,
                  size: 20,
                  color: Colors.black,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateFormat('d MMMM yyyy').format(dueDate),
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
                    color: daysLeft <= 3 ? const Color(0xFFFFDAD6) : NeoBrutalism.lime,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: Text(
                    daysLeft < 0
                        ? 'Lewat ${-daysLeft} hari'
                        : (daysLeft == 0 ? 'Hari ini' : '$daysLeft hari lagi'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: daysLeft <= 3 ? const Color(0xFFBA1A1A) : Colors.black,
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
