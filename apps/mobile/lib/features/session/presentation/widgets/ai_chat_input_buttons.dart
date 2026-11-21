import 'package:flutter/material.dart';

import '../../../../core/theme/neo_brutalism_decorations.dart';

/// Borderless inline icon button (Scan / Voice) inside the pill input bar.
class AiInputInlineIconButton extends StatefulWidget {
  final Key buttonKey;
  final IconData icon;
  final String semanticLabel;
  final String tooltip;
  final VoidCallback? onTap;

  const AiInputInlineIconButton({
    super.key,
    required this.buttonKey,
    required this.icon,
    required this.semanticLabel,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<AiInputInlineIconButton> createState() =>
      _AiInputInlineIconButtonState();
}

class _AiInputInlineIconButtonState extends State<AiInputInlineIconButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.onTap != null;
    final iconColor = active ? NeoBrutalism.dark : const Color(0xFF9CA3AF);

    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: active,
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
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: _isFocused && active
                        ? BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: NeoBrutalism.darkTeal,
                              width: 2.0,
                            ),
                          )
                        : null,
                    child: ExcludeSemantics(
                      child: Icon(widget.icon, size: 22, color: iconColor),
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

/// Circular lime send button (`→`) inside the pill input bar.
class AiInputCircleSendButton extends StatefulWidget {
  final Key buttonKey;
  final VoidCallback? onTap;

  const AiInputCircleSendButton({
    super.key,
    required this.buttonKey,
    required this.onTap,
  });

  @override
  State<AiInputCircleSendButton> createState() =>
      _AiInputCircleSendButtonState();
}

class _AiInputCircleSendButtonState extends State<AiInputCircleSendButton> {
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.onTap != null;
    final bg = active
        ? NeoBrutalism.lime
        : NeoBrutalism.lime.withValues(alpha: 0.45);
    final fg = active
        ? NeoBrutalism.dark
        : NeoBrutalism.dark.withValues(alpha: 0.45);

    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: active,
        label: 'Kirim pesan',
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
                child: AnimatedScale(
                  scale: _isPressed && active ? 0.92 : 1.0,
                  duration: const Duration(milliseconds: 90),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: bg,
                      shape: BoxShape.circle,
                    ),
                    foregroundDecoration: _isFocused && active
                        ? BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: NeoBrutalism.darkTeal,
                              width: 2.5,
                            ),
                          )
                        : null,
                    child: ExcludeSemantics(
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: fg,
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
