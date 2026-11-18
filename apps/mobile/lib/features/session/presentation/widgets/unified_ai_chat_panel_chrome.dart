import 'package:flutter/material.dart';

import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../home/presentation/widgets/notion_doodle_icons.dart';
import '../../domain/models/ai_chat_models.dart';
import 'ai_action_card_primitives.dart';
import 'ai_thinking_trace_widget.dart';

/// Live thinking trace row rendered at the bottom of the chat while streaming.
class LiveThinkingTraceRow extends StatelessWidget {
  final AiThinkingTrace trace;
  const LiveThinkingTraceRow({super.key, required this.trace});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: NeoBrutalism.lime,
              shape: BoxShape.circle,
              border: NeoBrutalism.border(width: 1.8),
              boxShadow: NeoBrutalism.shadow(yOffset: 1.5),
            ),
            child: Center(
              child: NotionDoodleWidget(
                svgString: NotionDoodleIcons.aiChat,
                size: 19,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AiThinkingTraceWidget(trace: trace, initiallyExpanded: true),
          ),
        ],
      ),
    );
  }
}

/// Dismissible Neo-Brutalist banner for non-SSE mutation/sync failures.
class MutationErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const MutationErrorBanner({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NeoBrutalism.coral,
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: aiActionTextStyle(
                context,
                11.5,
                FontWeight.w700,
                const Color(0xFF9F1239),
              ),
            ),
          ),
          IconButton(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: const Icon(Icons.close, size: 18, color: NeoBrutalism.dark),
            tooltip: 'Tutup pesan error',
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

/// Contextual floating CTA escalating Quick Sheet threads into `/ai-chat`.
class ExpandFullScreenPill extends StatefulWidget {
  final VoidCallback onTap;
  const ExpandFullScreenPill({super.key, required this.onTap});

  @override
  State<ExpandFullScreenPill> createState() => _ExpandFullScreenPillState();
}

class _ExpandFullScreenPillState extends State<ExpandFullScreenPill> {
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: 'Lanjutkan di Layar Penuh',
        child: Transform.translate(
          offset: Offset(0, _isPressed ? 2.0 : 0.0),
          child: Container(
            decoration: BoxDecoration(
              color: NeoBrutalism.lime,
              borderRadius: BorderRadius.circular(NeoBrutalism.radiusPill),
              border: NeoBrutalism.border(width: 2.0),
              boxShadow: _isPressed ? null : NeoBrutalism.shadow(yOffset: 2.5),
            ),
            foregroundDecoration: _isFocused
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(NeoBrutalism.radiusPill),
                    border: Border.all(color: NeoBrutalism.darkTeal, width: 2.5),
                  )
                : null,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: const Key('ai_chat_expand_pill'),
                borderRadius: BorderRadius.circular(NeoBrutalism.radiusPill),
                onTap: widget.onTap,
                onFocusChange: (f) {
                  if (_isFocused != f) setState(() => _isFocused = f);
                },
                onHighlightChanged: (p) {
                  if (_isPressed != p) setState(() => _isPressed = p);
                },
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: ExcludeSemantics(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.open_in_full_rounded,
                            size: 15,
                            color: NeoBrutalism.dark,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Lanjutkan di Layar Penuh',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: aiActionTextStyle(
                                context,
                                12,
                                FontWeight.w900,
                              ),
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
      ),
    );
  }
}
