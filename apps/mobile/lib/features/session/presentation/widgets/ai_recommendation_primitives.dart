import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../domain/models/ai_chat_models.dart';

/// Resolves theme typography so GoogleFonts (Plus Jakarta Sans) is inherited
/// from [Theme.of(context)] without hardcoding fontFamily strings.
TextStyle aiCardTextStyle(
  BuildContext context, {
  required double fontSize,
  FontWeight fontWeight = FontWeight.w500,
  Color color = NeoBrutalism.dark,
  double? height,
  double? letterSpacing,
}) {
  final base = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
  return base.copyWith(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

/// Returns a safe normalized text scale factor for responsive stacking checks.
double aiEffectiveTextScale(BuildContext context) {
  return MediaQuery.textScalerOf(context).scale(14.0) / 14.0;
}

/// Formats nearest consultant schedule slot using explicit label or UTC+7 WIB.
String aiResolveSlotLabel(AiConsultantRecommendation consultant) {
  final explicit = consultant.nextAvailableSlotLabel.trim();
  if (explicit.isNotEmpty) return explicit;
  final slotAt = consultant.nextAvailableSlotAt;
  if (slotAt != null) {
    final wib = slotAt.toUtc().add(const Duration(hours: 7));
    final dd = wib.day.toString().padLeft(2, '0');
    final mm = wib.month.toString().padLeft(2, '0');
    final hh = wib.hour.toString().padLeft(2, '0');
    final min = wib.minute.toString().padLeft(2, '0');
    return '$dd/$mm, $hh:$min WIB';
  }
  return 'Cek jadwal di profil';
}

/// Neo-Brutalist badge whose label wraps safely inside constrained widths.
class AiNeoBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? leadingIcon;
  final FontWeight fontWeight;

  const AiNeoBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    this.textColor = NeoBrutalism.dark,
    this.leadingIcon,
    this.fontWeight = FontWeight.w800,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: NeoBrutalism.border(width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: aiCardTextStyle(
                context,
                fontSize: 10.5,
                fontWeight: fontWeight,
                color: textColor,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tactile Neo-Brutalist button with >= 44x44 hit target, clean single-node
/// Semantics, and a high-contrast darkTeal (#0E6976) keyboard focus ring.
class AiNeoActionButton extends StatefulWidget {
  final String label;
  final Color backgroundColor;
  final VoidCallback? onTap;

  const AiNeoActionButton({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  State<AiNeoActionButton> createState() => _AiNeoActionButtonState();
}

class _AiNeoActionButtonState extends State<AiNeoActionButton> {
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onTap != null;
    // High-contrast #0E6976 ring (6.36:1 on white, 6.07:1 on warm surface).
    final focusRingColor =
        (_isFocused && isEnabled) ? NeoBrutalism.darkTeal : Colors.transparent;
    final fillColor =
        isEnabled ? widget.backgroundColor : const Color(0xFFE5E7EB);
    // #4B5563 on #E5E7EB passes WCAG AA at 6.10:1 when disabled.
    final labelColor =
        isEnabled ? NeoBrutalism.dark : const Color(0xFF4B5563);

    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: isEnabled,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm + 3),
            border: Border.all(color: focusRingColor, width: 2.5),
          ),
          child: Transform.translate(
            offset: Offset(0, (_isPressed && isEnabled) ? 2.0 : 0.0),
            child: Container(
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
                border: NeoBrutalism.border(width: 2.0),
                boxShadow: (_isPressed || !isEnabled)
                    ? null
                    : NeoBrutalism.shadow(yOffset: 2.0),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  focusColor: NeoBrutalism.darkTeal.withValues(alpha: 0.14),
                  hoverColor: NeoBrutalism.darkTeal.withValues(alpha: 0.08),
                  onFocusChange: isEnabled
                      ? (focused) {
                          if (mounted) setState(() => _isFocused = focused);
                        }
                      : null,
                  onHighlightChanged: isEnabled
                      ? (pressed) {
                          if (mounted) setState(() => _isPressed = pressed);
                        }
                      : null,
                  onTap: widget.onTap,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: 44,
                      minWidth: 44,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      child: Center(
                        child: Text(
                          widget.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: aiCardTextStyle(
                            context,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: labelColor,
                            height: 1.2,
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
      ),
    );
  }
}
