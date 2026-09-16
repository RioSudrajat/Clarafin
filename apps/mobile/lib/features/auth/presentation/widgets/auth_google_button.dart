import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class AuthGoogleButton extends StatefulWidget {
  final VoidCallback? onPressed;

  const AuthGoogleButton({
    super.key,
    this.onPressed,
  });

  @override
  State<AuthGoogleButton> createState() => _AuthGoogleButtonState();
}

class _AuthGoogleButtonState extends State<AuthGoogleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 48,
        transform: Matrix4.translationValues(0, _isPressed ? 2.0 : 0.0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
          border: NeoBrutalism.border(width: 2.0),
          boxShadow: _isPressed ? [] : NeoBrutalism.shadow(yOffset: 2.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/google_logo.png',
              height: 20,
              width: 20,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.g_mobiledata_rounded,
                size: 24,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Google',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: NeoBrutalism.dark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
