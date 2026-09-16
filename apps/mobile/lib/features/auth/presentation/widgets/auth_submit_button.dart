import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class AuthSubmitButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isEnabled;

  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isEnabled = true,
  });

  @override
  State<AuthSubmitButton> createState() => _AuthSubmitButtonState();
}

class _AuthSubmitButtonState extends State<AuthSubmitButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.isEnabled && widget.onPressed != null;

    return GestureDetector(
      onTapDown: active ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: active ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: active ? () => setState(() => _isPressed = false) : null,
      onTap: active ? widget.onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 52,
        transform: Matrix4.translationValues(0, _isPressed ? 2.0 : 0.0, 0),
        decoration: BoxDecoration(
          color: active ? NeoBrutalism.lime : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
          border: NeoBrutalism.border(
            width: 2.0,
            color: active ? NeoBrutalism.borderBlack : const Color(0xFF9CA3AF),
          ),
          boxShadow: active && !_isPressed
              ? NeoBrutalism.shadow(yOffset: 3.5)
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: active ? NeoBrutalism.borderBlack : const Color(0xFF9CA3AF),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_rounded,
              size: 20,
              color: active ? NeoBrutalism.borderBlack : const Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}
