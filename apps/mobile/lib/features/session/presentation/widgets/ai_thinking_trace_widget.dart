import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../domain/models/ai_chat_models.dart';

/// Expandable Neo-Brutalist trace showing live AI steps or collapsed summary.
class AiThinkingTraceWidget extends StatefulWidget {
  final AiThinkingTrace trace;
  final bool initiallyExpanded;

  const AiThinkingTraceWidget({
    super.key,
    required this.trace,
    this.initiallyExpanded = false,
  });

  @override
  State<AiThinkingTraceWidget> createState() => _AiThinkingTraceWidgetState();
}

class _AiThinkingTraceWidgetState extends State<AiThinkingTraceWidget> {
  static TextStyle _textStyle(double size, FontWeight weight,
          {Color color = NeoBrutalism.dark, double height = 1.35}) =>
      TextStyle(fontSize: size, fontWeight: weight, color: color, height: height);

  late bool _isExpanded;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant AiThinkingTraceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Collapse back to default once final response arrives from live stream.
    final finishedStream = oldWidget.trace.isLive && !widget.trace.isLive;
    if (finishedStream || oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      _isExpanded = widget.initiallyExpanded;
    }
  }

  String _headerLabel() {
    final steps = widget.trace.steps;
    if (widget.trace.isLive) {
      if (steps.isEmpty) return 'Sedang memproses...';
      final active = steps.lastWhere((s) => !s.isDone, orElse: () => steps.last);
      final label = active.label.trim();
      return label.isNotEmpty ? label : 'Sedang memproses...';
    }
    final duration = _formatDuration(widget.trace.durationMs);
    return duration != null
        ? 'Selesai berpikir $duration • ${steps.length} langkah'
        : 'Selesai berpikir • ${steps.length} langkah';
  }

  String? _formatDuration(int durationMs) {
    if (durationMs <= 0) return null;
    if (durationMs >= 59950) {
      final totalSecs = (durationMs / 1000).round();
      final mins = totalSecs ~/ 60;
      final secs = totalSecs % 60;
      return secs == 0 ? '$mins mnt' : '$mins mnt $secs dtk';
    }
    final secs = durationMs < 100 ? 0.1 : durationMs / 1000.0;
    return '${secs.toStringAsFixed(1).replaceAll('.', ',')} dtk';
  }

  @override
  Widget build(BuildContext context) {
    final headerLabel = _headerLabel();
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final expandedBody = _isExpanded ? _buildExpandedSteps() : const SizedBox.shrink();

    return Container(
      key: const Key('ai_thinking_trace_card'),
      decoration: BoxDecoration(
        color: NeoBrutalism.surfaceWarm,
        borderRadius: BorderRadius.circular(10),
        border: NeoBrutalism.border(width: 1.5),
        boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(headerLabel),
            // Bypass AnimatedSize when motion is disabled to avoid zero-duration relayouts.
            disableAnimations
                ? expandedBody
                : AnimatedSize(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: expandedBody,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String headerLabel) {
    final chevron = _isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded;
    final headerRadius = _isExpanded
        ? const BorderRadius.vertical(top: Radius.circular(8.5))
        : BorderRadius.circular(8.5);
    final leadingIcon = ExcludeSemantics(
      child: widget.trace.isLive
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2.0, valueColor: AlwaysStoppedAnimation<Color>(NeoBrutalism.dark)),
            )
          : const Icon(Icons.check_circle_outline_rounded, size: 18, color: NeoBrutalism.dark),
    );

    return Semantics(
      container: true,
      button: true,
      expanded: _isExpanded,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('ai_thinking_trace_toggle'),
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          // Paint focus fill and ring in Container so contrast holds across touch/key modes.
          focusColor: Colors.transparent,
          hoverColor: NeoBrutalism.primaryLight.withValues(alpha: 0.45),
          borderRadius: headerRadius,
          onFocusChange: (focused) {
            if (_isFocused != focused) setState(() => _isFocused = focused);
          },
          child: Container(
            key: const Key('ai_thinking_trace_header'),
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.only(left: 12, right: 2),
            decoration: _isFocused
                ? BoxDecoration(color: NeoBrutalism.darkTeal.withValues(alpha: 0.12), borderRadius: headerRadius)
                : null,
            foregroundDecoration: _isFocused
                ? BoxDecoration(borderRadius: headerRadius, border: Border.all(color: NeoBrutalism.darkTeal, width: 2.0))
                : null,
            child: Row(
              children: [
                leadingIcon,
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(headerLabel, style: _textStyle(12, FontWeight.w700))),
                ),
                const SizedBox(width: 4),
                Container(
                  key: const Key('ai_thinking_trace_chevron'),
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  child: ExcludeSemantics(child: Icon(chevron, size: 20, color: NeoBrutalism.dark)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedSteps() {
    final steps = widget.trace.steps;
    final emptyMsg = widget.trace.isLive
        ? 'Sedang menyiapkan langkah analisa...'
        : 'Belum ada rincian langkah yang tercatat.';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(height: 1.0, color: NeoBrutalism.borderBlack),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: steps.isEmpty
              ? Text(emptyMsg, style: _textStyle(11.5, FontWeight.w500, color: const Color(0xFF374151)))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [for (var i = 0; i < steps.length; i++) _buildStepRow(i, steps[i], isLast: i == steps.length - 1)],
                ),
        ),
      ],
    );
  }

  Widget _buildStepRow(int index, AiThinkingStep step, {required bool isLast}) {
    final isDone = step.isDone || !widget.trace.isLive;
    final numText = '${index + 1}';
    final label = step.label.trim().isNotEmpty ? step.label.trim() : 'Langkah $numText';
    final detail = step.detail?.trim();

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: isDone ? 'Langkah $numText selesai' : 'Langkah $numText sedang diproses',
            excludeSemantics: true,
            child: Container(
              key: Key('ai_thinking_step_dot_$index'),
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDone ? NeoBrutalism.lime : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: isDone ? NeoBrutalism.borderBlack : NeoBrutalism.darkTeal, width: isDone ? 1.5 : 2.0),
              ),
              child: isDone
                  ? const Icon(Icons.check_rounded, size: 13, color: NeoBrutalism.dark)
                  : FittedBox(fit: BoxFit.scaleDown, child: Text(numText, style: _textStyle(10.5, FontWeight.w800, height: 1.0))),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _textStyle(12.5, FontWeight.w700)),
                if (detail != null && detail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(detail, style: _textStyle(11.5, FontWeight.w500, color: const Color(0xFF374151))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
