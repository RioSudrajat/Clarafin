import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class ConsultationHeroCard extends StatelessWidget {
  final double progress;
  final String userName;
  final VoidCallback onEditName;

  const ConsultationHeroCard({
    super.key,
    required this.progress,
    required this.userName,
    required this.onEditName,
  });

  double _evaluateProgressInterval(
    double progress,
    double begin,
    double end, {
    Curve curve = Curves.easeInOut,
  }) {
    if (progress <= begin) return 0.0;
    if (progress >= end) return 1.0;
    final t = (progress - begin) / (end - begin);
    return curve.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    // ── 1. Curtain Animation (Delay 0.10, moves upward -32px and fades out by 0.52) ──
    final curtainProgress = _evaluateProgressInterval(progress, 0.10, 0.52, curve: Curves.easeIn);
    final curtainOpacity = (1.0 - curtainProgress).clamp(0.0, 1.0);
    final curtainTranslationY = -32.0 * curtainProgress;

    // ── 2. Collapsed Action Button Animation (Slides from right +16px and fades in 0.35 to 0.75) ──
    final actionProgress = _evaluateProgressInterval(progress, 0.35, 0.75, curve: Curves.easeOut);
    final actionOpacity = actionProgress.clamp(0.0, 1.0);
    final actionTranslationX = 16.0 * (1.0 - actionProgress);

    // ── 3. Anchored Persistent Greeting (Absolute position, scales font & keeps crisp anchor) ──
    final greetingTop = lerpDouble(18.0, 20.0, progress)!;
    const greetingLeft = 20.0;
    final greetingFontSize = lerpDouble(13.0, 16.0, progress)!;
    final greetingFontWeight = progress >= 0.45 ? FontWeight.w900 : FontWeight.w800;
    final greetingLetterSpacing = lerpDouble(0.4, -0.5, progress)!;
    final editIconSize = lerpDouble(11.0, 13.0, progress)!;
    final greetingRightBound = lerpDouble(70.0, 155.0, progress)!;

    return Container(
      width: double.infinity,
      height: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: NeoBrutalism.darkTeal,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: NeoBrutalism.shadow(yOffset: lerpDouble(4.0, 2.0, progress)!),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Curtain Layer: Disappearing content that rolls upward like a curtain ──
          if (curtainOpacity > 0.001)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 198,
              child: IgnorePointer(
                ignoring: curtainOpacity < 0.5,
                child: Opacity(
                  opacity: curtainOpacity,
                  child: Transform.translate(
                    offset: Offset(0, curtainTranslationY),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top Row: Spacer for anchored greeting + Title on left, Lime group icon on right
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    SizedBox(height: 20),
                                    SizedBox(height: 6),
                                    Text(
                                      'Atur uangmu\nbareng ahlinya.',
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        height: 1.15,
                                        letterSpacing: -0.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: NeoBrutalism.lime,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black, width: 2),
                                  boxShadow: NeoBrutalism.shadow(yOffset: 2),
                                ),
                                child: const Icon(
                                  Icons.groups_rounded,
                                  size: 26,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),

                          // Bottom Row: Subtitle on left, Lime 'MULAI' pill button on right
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Cocokkan dengan konsultan\nyang paham tujuanmu.',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => context.push('/match-expert'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: NeoBrutalism.lime,
                                    borderRadius: BorderRadius.circular(9999),
                                    border: Border.all(color: Colors.black, width: 2),
                                    boxShadow: NeoBrutalism.shadow(yOffset: 2),
                                  ),
                                  child: const Text(
                                    'MULAI',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ── Anchored Persistent Greeting: Hi, [userName] ──
          Positioned(
            top: greetingTop,
            left: greetingLeft,
            right: greetingRightBound,
            child: GestureDetector(
              onTap: onEditName,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'Hi, $userName',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: greetingFontSize,
                        fontWeight: greetingFontWeight,
                        color: Colors.white,
                        letterSpacing: greetingLetterSpacing,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.edit_outlined, size: editIconSize, color: Colors.white70),
                ],
              ),
            ),
          ),

          // ── Collapsed Action Button: Mulai Konseling > (Slides in from right) ──
          if (actionOpacity > 0.001)
            Positioned(
              top: 0,
              bottom: 0,
              right: 16,
              child: IgnorePointer(
                ignoring: actionOpacity < 0.5,
                child: Opacity(
                  opacity: actionOpacity,
                  child: Transform.translate(
                    offset: Offset(actionTranslationX, 0),
                    child: Center(
                      child: GestureDetector(
                        onTap: () => context.go('/consult'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: NeoBrutalism.lime,
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(color: Colors.black, width: 2),
                            boxShadow: NeoBrutalism.shadow(yOffset: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Mulai Konseling',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(width: 3),
                              Icon(Icons.chevron_right, size: 14, color: Colors.black),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
