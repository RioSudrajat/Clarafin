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
  final IconData icon;
  final String semanticLabel;
  final String tooltip;
  final VoidCallback? onTap;

  const HeaderCircleButton({
    super.key,
    required this.buttonKey,
    required this.icon,
    required this.semanticLabel,
    required this.tooltip,
    required this.onTap,
  });

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
                        child: Icon(widget.icon, size: 17, color: NeoBrutalism.dark),
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
