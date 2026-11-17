import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';

/// Shared typography helper for analytical AI chat cards.
TextStyle analyticalFont(
  double size,
  FontWeight weight,
  Color color, {
  double? height,
  double? spacing,
}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: spacing,
  );
}

/// Resolves currency code from optional override or [userProfileProvider] safely.
String resolveAnalyticalCurrency(WidgetRef ref, String? overrideCode) {
  if (overrideCode != null && overrideCode.isNotEmpty) return overrideCode;
  try {
    return ref.watch(userProfileProvider.select((p) => p.currency));
  } on Object catch (_) {
    return 'IDR';
  }
}

/// Normalizes negative zero or sub-cent dust to positive `0.0`.
double normalizeAnalyticalZero(double value) {
  if (!value.isFinite) return 0.0;
  return value.abs() < 0.005 ? 0.0 : value;
}

/// Focus-aware interactive button surface with consolidated Semantics and >= 44px hit target.
class AnalyticalActionSurface extends StatefulWidget {
  final Key buttonKey;
  final String semanticLabel;
  final VoidCallback onTap;
  final Color baseColor;
  final BorderRadius borderRadius;
  final BorderSide defaultBorder;
  final EdgeInsetsGeometry padding;
  final Widget child;

  const AnalyticalActionSurface({
    super.key,
    required this.buttonKey,
    required this.semanticLabel,
    required this.onTap,
    required this.baseColor,
    required this.borderRadius,
    required this.defaultBorder,
    required this.padding,
    required this.child,
  });

  @override
  State<AnalyticalActionSurface> createState() =>
      _AnalyticalActionSurfaceState();
}

class _AnalyticalActionSurfaceState extends State<AnalyticalActionSurface> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final activeSide = _isFocused
        ? const BorderSide(color: NeoBrutalism.darkTeal, width: 2.5)
        : widget.defaultBorder;
    final focusTint = NeoBrutalism.teal.withValues(alpha: 0.12);
    final bgColor = _isFocused
        ? (widget.baseColor.a == 0
              ? focusTint
              : Color.alphaBlend(focusTint, widget.baseColor))
        : widget.baseColor;

    return Semantics(
      container: true,
      button: true,
      label: widget.semanticLabel,
      child: Material(
        color: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: widget.borderRadius,
          side: activeSide,
        ),
        child: InkWell(
          key: widget.buttonKey,
          borderRadius: widget.borderRadius,
          onTap: widget.onTap,
          onFocusChange: (focused) {
            if (_isFocused != focused) setState(() => _isFocused = focused);
          },
          child: ExcludeSemantics(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
              child: Padding(padding: widget.padding, child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}
