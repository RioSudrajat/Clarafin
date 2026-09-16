import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class AuthTermsCheckbox extends StatelessWidget {
  final bool isChecked;
  final ValueChanged<bool> onChanged;

  const AuthTermsCheckbox({
    super.key,
    required this.isChecked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => onChanged(!isChecked),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: isChecked ? NeoBrutalism.lime : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: NeoBrutalism.border(width: 2.0),
              boxShadow: NeoBrutalism.shadow(yOffset: 1.5),
            ),
            child: isChecked
                ? const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: NeoBrutalism.borderBlack,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!isChecked),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF4B5563),
                  height: 1.45,
                ),
                children: [
                  const TextSpan(text: 'Saya menyetujui '),
                  TextSpan(
                    text: 'Syarat & Ketentuan',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      color: NeoBrutalism.dark,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: ' serta '),
                  TextSpan(
                    text: 'Kebijakan Privasi',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      color: NeoBrutalism.dark,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: ' Clarafin.'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
