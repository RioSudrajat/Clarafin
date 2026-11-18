import 'package:flutter/material.dart';

import '../../../../core/theme/neo_brutalism_decorations.dart';
import 'ai_action_card_primitives.dart';

/// Shared Neo-Brutalist tactile button used for Scan, Bicara, and Send controls.
class AiInputTactileControl extends StatefulWidget {
  final Key buttonKey;
  final IconData icon;
  final String? label;
  final String semanticLabel;
  final Color activeColor;
  final double borderWidth;
  final double radius;
  final VoidCallback? onTap;

  const AiInputTactileControl({
    super.key,
    required this.buttonKey,
    required this.icon,
    this.label,
    required this.semanticLabel,
    required this.activeColor,
    required this.borderWidth,
    required this.radius,
    required this.onTap,
  });

  @override
  State<AiInputTactileControl> createState() => _AiInputTactileControlState();
}

class _AiInputTactileControlState extends State<AiInputTactileControl> {
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.onTap != null;
    final fg = active ? NeoBrutalism.dark : const Color(0xFF4B5563);
    final hasLabel = widget.label != null && widget.label!.isNotEmpty;

    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: active,
        label: widget.semanticLabel,
        child: Transform.translate(
          offset: Offset(0, _isPressed && active ? 1.5 : 0),
          child: Container(
            decoration: BoxDecoration(
              color: active ? widget.activeColor : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(widget.radius),
              border: NeoBrutalism.border(width: widget.borderWidth),
              boxShadow:
                  active && !_isPressed ? NeoBrutalism.shadow(yOffset: 2.0) : null,
            ),
            foregroundDecoration: _isFocused && active
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.radius),
                    border: Border.all(color: NeoBrutalism.darkTeal, width: 2.5),
                  )
                : null,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: widget.buttonKey,
                borderRadius: BorderRadius.circular(widget.radius - 1.5),
                onTap: widget.onTap,
                onFocusChange: (f) {
                  if (_isFocused != f) setState(() => _isFocused = f);
                },
                onHighlightChanged: (p) {
                  if (_isPressed != p) setState(() => _isPressed = p);
                },
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  child: hasLabel
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 8,
                          ),
                          child: ExcludeSemantics(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(widget.icon, size: 16, color: fg),
                                const SizedBox(width: 6),
                                Text(
                                  widget.label!,
                                  style: aiActionTextStyle(
                                    context,
                                    12,
                                    FontWeight.w800,
                                    fg,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Center(
                          child: ExcludeSemantics(
                            child: Icon(widget.icon, size: 22, color: fg),
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
