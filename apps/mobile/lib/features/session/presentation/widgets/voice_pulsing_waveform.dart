import 'package:flutter/material.dart';

import '../../../../core/theme/neo_brutalism_decorations.dart';

/// Pulsing Neo-Brutalist microphone waveform that respects reduced-motion settings.
class VoicePulsingWaveform extends StatefulWidget {
  final bool isListening;
  const VoicePulsingWaveform({super.key, required this.isListening});

  @override
  State<VoicePulsingWaveform> createState() => _VoicePulsingWaveformState();
}

class _VoicePulsingWaveformState extends State<VoicePulsingWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant VoicePulsingWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    final disableAnim = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.isListening && !disableAnim) {
      if (!_ctrl.isAnimating) _ctrl.repeat(reverse: true);
    } else {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final scale = 1.0 + (widget.isListening ? 0.25 * _ctrl.value : 0.0);
        return Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isListening)
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: NeoBrutalism.lime.withValues(alpha: 0.3),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                transform: Matrix4.diagonal3Values(scale, scale, 1.0),
              ),
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: NeoBrutalism.lime,
                border: Border.all(color: Colors.black, width: 2.5),
                boxShadow: NeoBrutalism.shadow(yOffset: 4.0),
              ),
              child: const Icon(Icons.mic_rounded, color: Colors.black, size: 38),
            ),
          ],
        );
      },
    );
  }
}
