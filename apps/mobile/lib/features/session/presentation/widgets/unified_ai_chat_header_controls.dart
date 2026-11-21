import 'package:flutter/material.dart';

import '../../../../core/theme/neo_brutalism_decorations.dart';

/// Tappable `[⚡ X/Y]` AI quota pill with >= 44x44 hit target and #0E6976 focus ring.
class HeaderQuotaBadge extends StatefulWidget {
  final String quotaText;
  final bool isExhausted;
  final VoidCallback? onTap;
  final TextStyle style;

  const HeaderQuotaBadge({
    super.key,
    required this.quotaText,
    required this.isExhausted,
    required this.onTap,
    required this.style,
  });

  @override
  State<HeaderQuotaBadge> createState() => _HeaderQuotaBadgeState();
}

class _HeaderQuotaBadgeState extends State<HeaderQuotaBadge> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isExhausted ? NeoBrutalism.coral : NeoBrutalism.lime;
    return MergeSemantics(
      child: Semantics(
        button: widget.onTap != null,
        label: 'Kuota AI ${widget.quotaText}',
        child: Tooltip(
          message: 'Kuota AI: ${widget.quotaText}',
          excludeFromSemantics: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('ai_chat_quota_badge'),
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onTap,
              onFocusChange: (f) {
                if (_isFocused != f) setState(() => _isFocused = f);
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(10),
                        border: NeoBrutalism.border(width: 1.8),
                        boxShadow: NeoBrutalism.shadow(yOffset: 1.5),
                      ),
                      foregroundDecoration: _isFocused
                          ? BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: NeoBrutalism.darkTeal, width: 2.5),
                            )
                          : null,
                      child: ExcludeSemantics(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.flash_on_rounded, size: 13, color: NeoBrutalism.dark),
                            const SizedBox(width: 2),
                            Text(widget.quotaText, maxLines: 1, style: widget.style),
                          ],
                        ),
                      ),
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

/// Circular Neo-Brutalist header icon button with >= 44x44 hit target and focus ring.
class HeaderCircleButton extends StatefulWidget {
  final Key buttonKey;
  final IconData? icon;
  final Widget? iconWidget;
  final String semanticLabel;
  final String tooltip;
  final VoidCallback? onTap;

  const HeaderCircleButton({
    super.key,
    required this.buttonKey,
    this.icon,
    this.iconWidget,
    required this.semanticLabel,
    required this.tooltip,
    required this.onTap,
  }) : assert(icon != null || iconWidget != null);

  @override
  State<HeaderCircleButton> createState() => _HeaderCircleButtonState();
}

class _HeaderCircleButtonState extends State<HeaderCircleButton> {
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: enabled,
        label: widget.semanticLabel,
        child: Tooltip(
          message: widget.tooltip,
          excludeFromSemantics: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: widget.buttonKey,
              borderRadius: BorderRadius.circular(22),
              onTap: widget.onTap,
              onFocusChange: (f) {
                if (_isFocused != f) setState(() => _isFocused = f);
              },
              onHighlightChanged: (p) {
                if (_isPressed != p) setState(() => _isPressed = p);
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                child: Center(
                  child: Transform.translate(
                    offset: Offset(0, _isPressed && enabled ? 1.5 : 0),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: NeoBrutalism.border(width: 1.8),
                        boxShadow: _isPressed ? null : NeoBrutalism.shadow(yOffset: 1.5),
                      ),
                      foregroundDecoration: _isFocused
                          ? BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: NeoBrutalism.darkTeal, width: 2.5),
                            )
                          : null,
                      child: ExcludeSemantics(
                        child: Center(
                          child: widget.iconWidget ??
                              Icon(widget.icon, size: 17, color: NeoBrutalism.dark),
                        ),
                      ),
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

/// Gemini-web-style compose / new-chat icon (open rounded square + diagonal pen).
class GeminiNewChatIcon extends StatelessWidget {
  final double size;
  final Color color;

  const GeminiNewChatIcon({
    super.key,
    this.size = 17,
    this.color = NeoBrutalism.dark,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _GeminiNewChatPainter(color: color),
    );
  }
}

class _GeminiNewChatPainter extends CustomPainter {
  final Color color;

  const _GeminiNewChatPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.85
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Open rounded square: top-middle -> top-left -> bottom-left -> bottom-right -> right-middle
    final boxPath = Path()
      ..moveTo(w * 0.54, h * 0.18)
      ..lineTo(w * 0.24, h * 0.18)
      ..quadraticBezierTo(w * 0.12, h * 0.18, w * 0.12, h * 0.30)
      ..lineTo(w * 0.12, h * 0.76)
      ..quadraticBezierTo(w * 0.12, h * 0.88, w * 0.24, h * 0.88)
      ..lineTo(w * 0.70, h * 0.88)
      ..quadraticBezierTo(w * 0.82, h * 0.88, w * 0.82, h * 0.76)
      ..lineTo(w * 0.82, h * 0.46);
    canvas.drawPath(boxPath, paint);

    // Diagonal pen from top-right into the square
    final penPath = Path()
      ..moveTo(w * 0.78, h * 0.12)
      ..lineTo(w * 0.88, h * 0.22)
      ..lineTo(w * 0.49, h * 0.61)
      ..lineTo(w * 0.36, h * 0.64)
      ..lineTo(w * 0.39, h * 0.51)
      ..close();
    canvas.drawPath(penPath, paint);
  }

  @override
  bool shouldRepaint(covariant _GeminiNewChatPainter oldDelegate) =>
      oldDelegate.color != color;
}
