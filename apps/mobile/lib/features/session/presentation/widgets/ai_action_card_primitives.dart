import 'package:flutter/material.dart';

import '../../../../core/theme/neo_brutalism_decorations.dart';

/// Resolves theme-driven typography so cards inherit Plus Jakarta Sans cleanly.
TextStyle aiActionTextStyle(
  BuildContext context,
  double fontSize,
  FontWeight fontWeight, [
  Color color = NeoBrutalism.dark,
]) {
  final base = Theme.of(context).textTheme.bodyMedium;
  return (base ?? const TextStyle()).copyWith(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
  );
}

/// Shared Neo-Brutalist outer container for AI action draft cards.
class AiActionCardShell extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final double shadowOffset;

  const AiActionCardShell({
    super.key,
    required this.child,
    this.backgroundColor = Colors.white,
    this.shadowOffset = 3.5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: NeoBrutalism.cardDecoration(
        backgroundColor: backgroundColor,
        borderRadius: NeoBrutalism.radiusLg,
        shadowOffset: shadowOffset,
      ),
      child: child,
    );
  }
}

/// Shared Mint or Coral status banner rendered after draft confirmation/cancellation.
class AiActionStatusBanner extends StatelessWidget {
  final Color backgroundColor;
  final IconData icon;
  final String message;

  const AiActionStatusBanner({
    super.key,
    required this.backgroundColor,
    required this.icon,
    required this.message,
  });

  const AiActionStatusBanner.mint({super.key, required this.message})
      : backgroundColor = NeoBrutalism.mint,
        icon = Icons.check_circle_rounded;

  const AiActionStatusBanner.coral({super.key, required this.message})
      : backgroundColor = NeoBrutalism.coral,
        icon = Icons.cancel_rounded;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
        border: NeoBrutalism.border(width: 2.0),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: aiActionTextStyle(context, 12.5, FontWeight.w900, Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tactile Neo-Brutalist button with single Semantics node and >= 3:1 focus ring.
class AiActionTactileButton extends StatefulWidget {
  final Key? buttonKey;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isPrimary;
  final bool isLoading;
  final bool fullWidth;
  final double minHeight;
  final double borderWidth;
  final double shadowOffset;
  final IconData? icon;
  final double? fontSize;
  final FontWeight? fontWeight;

  const AiActionTactileButton({
    super.key,
    this.buttonKey,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.onTap,
    this.enabled = true,
    this.isPrimary = false,
    this.isLoading = false,
    this.fullWidth = false,
    this.minHeight = 44.0,
    this.borderWidth = 2.0,
    this.shadowOffset = 2.0,
    this.icon,
    this.fontSize,
    this.fontWeight,
  });

  @override
  State<AiActionTactileButton> createState() => _AiActionTactileButtonState();
}

class _AiActionTactileButtonState extends State<AiActionTactileButton> {
  bool _isPressed = false;
  bool _isFocused = false;

  bool get _effectiveEnabled => widget.enabled && widget.onTap != null;

  @override
  void didUpdateWidget(covariant AiActionTactileButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_effectiveEnabled && (_isFocused || _isPressed)) {
      _isFocused = false;
      _isPressed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _effectiveEnabled;
    final disabledBg = widget.isPrimary ? const Color(0xFFE5E7EB) : Colors.white;
    final disabledBorder = widget.isPrimary ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
    final fg = active ? widget.textColor : const Color(0xFF4B5563);
    final size = widget.fontSize ?? (widget.isPrimary ? 13.0 : 12.5);
    final weight = widget.fontWeight ?? (widget.isPrimary ? FontWeight.w900 : FontWeight.w800);
    final showFocusRing = _isFocused && active;

    return MergeSemantics(
      child: Semantics(
        container: true,
        button: true,
        enabled: active,
        child: Transform.translate(
          offset: (_isPressed && active) ? const Offset(0, 2) : Offset.zero,
          child: Container(
            width: widget.fullWidth ? double.infinity : null,
            decoration: BoxDecoration(
              color: active ? widget.backgroundColor : disabledBg,
              borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
              border: NeoBrutalism.border(
                width: widget.borderWidth,
                color: active ? Colors.black : disabledBorder,
              ),
              boxShadow: (active && !_isPressed)
                  ? NeoBrutalism.shadow(yOffset: widget.shadowOffset)
                  : null,
            ),
            foregroundDecoration: showFocusRing
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
                    border: Border.all(color: NeoBrutalism.teal, width: 2.5),
                  )
                : null,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: widget.buttonKey,
                borderRadius: BorderRadius.circular(10),
                onFocusChange: (focused) {
                  if (mounted) setState(() => _isFocused = focused);
                },
                onTapDown: active ? (_) => setState(() => _isPressed = true) : null,
                onTapUp: active ? (_) => setState(() => _isPressed = false) : null,
                onTapCancel: () {
                  if (_isPressed && mounted) setState(() => _isPressed = false);
                },
                onTap: active ? widget.onTap : null,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: widget.minHeight, minWidth: 44),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.isLoading) ...[
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.black),
                          ),
                          const SizedBox(width: 8),
                        ] else if (widget.icon != null) ...[
                          Icon(widget.icon, size: 16, color: fg),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: aiActionTextStyle(context, size, weight, fg),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
