import 'package:flutter/material.dart';

class NeoBrutalism {
  // Colors from Figma design & Brand Guide
  static const Color lime = Color(0xFF9ADC09); // Clarafin Brand Lime
  static const Color limeNeon = Color(0xFFCCFF00); // Neon Accent Lime
  static const Color darkTeal = Color(0xFF0E6976); // Hero deep teal
  static const Color mint = Color(0xFFE5F9E0);
  static const Color surfaceWarm = Color(0xFFFCF9F8);
  static const Color coral = Color(0xFFFFDAD6);
  static const Color dark = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color borderBlack = Colors.black;

  // Radius Tokens
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 24.0;
  static const double radiusBoundary = 28.0;
  static const double radiusPill = 9999.0;

  // Standard 2px solid black border
  static Border border({double width = 2.0, Color color = borderBlack}) {
    return Border.all(color: color, width: width);
  }

  // Neo-Brutalism flat hard shadow (no blur, crisp offset)
  static List<BoxShadow> shadow({
    double yOffset = 3.0,
    double xOffset = 0.0,
    Color color = borderBlack,
  }) {
    return [
      BoxShadow(
        color: color,
        offset: Offset(xOffset, yOffset),
        blurRadius: 0,
        spreadRadius: 0,
      ),
    ];
  }

  // Card box decoration
  static BoxDecoration cardDecoration({
    Color backgroundColor = Colors.white,
    double borderRadius = 24.0,
    double shadowOffset = 3.0,
    double borderWidth = 2.0,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: border(width: borderWidth),
      boxShadow: shadow(yOffset: shadowOffset),
    );
  }

  // Pill box decoration (e.g. for badges, chips, buttons)
  static BoxDecoration pillDecoration({
    Color backgroundColor = Colors.white,
    double shadowOffset = 2.0,
    double borderWidth = 2.0,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(9999),
      border: border(width: borderWidth),
      boxShadow: shadow(yOffset: shadowOffset),
    );
  }

  // Circular box decoration (e.g. for icon badges, avatars)
  static BoxDecoration circleDecoration({
    Color backgroundColor = Colors.white,
    double shadowOffset = 2.0,
    double borderWidth = 2.0,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      shape: BoxShape.circle,
      border: border(width: borderWidth),
      boxShadow: shadowOffset > 0 ? shadow(yOffset: shadowOffset) : null,
    );
  }
}
