import 'package:flutter/material.dart';

import '../../../../core/theme/neo_brutalism_decorations.dart';
import 'ai_action_card_primitives.dart';

/// Camera viewfinder simulation box rendered by [OcrScanModalSheet].
class OcrViewfinderBox extends StatelessWidget {
  final bool isScanning;
  final bool scanningOcr;

  const OcrViewfinderBox({
    super.key,
    required this.isScanning,
    required this.scanningOcr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: NeoBrutalism.cardDecoration(
        backgroundColor: const Color(0xFFF9FAFB),
        borderRadius: 16,
        shadowOffset: 4.0,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ..._cornerBrackets(),
          if (scanningOcr)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.black),
                const SizedBox(height: 14),
                Text(
                  'Menjalankan OCR & Pemindaian...',
                  style: aiActionTextStyle(context, 13, FontWeight.w700),
                ),
              ],
            )
          else if (isScanning) ...[
            const _ScannerAnimation(),
            Positioned(
              bottom: 24,
              child: Text(
                'Menyelaraskan struktur struk...',
                style: aiActionTextStyle(context, 12, FontWeight.w900),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: NeoBrutalism.circleDecoration(
                      backgroundColor: NeoBrutalism.lime,
                      shadowOffset: 3.0,
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 40,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Posisikan struk di dalam bingkai',
                    textAlign: TextAlign.center,
                    style: aiActionTextStyle(context, 14, FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pastikan nama toko dan nominal terlihat jelas',
                    textAlign: TextAlign.center,
                    style: aiActionTextStyle(
                      context,
                      12,
                      FontWeight.w500,
                      const Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _cornerBrackets() {
    const side = BorderSide(color: Colors.black, width: 3.5);
    return [
      Positioned(
        top: 16,
        left: 16,
        child: Container(width: 24, height: 24, decoration: const BoxDecoration(border: Border(top: side, left: side))),
      ),
      Positioned(
        top: 16,
        right: 16,
        child: Container(width: 24, height: 24, decoration: const BoxDecoration(border: Border(top: side, right: side))),
      ),
      Positioned(
        bottom: 16,
        left: 16,
        child: Container(width: 24, height: 24, decoration: const BoxDecoration(border: Border(bottom: side, left: side))),
      ),
      Positioned(
        bottom: 16,
        right: 16,
        child: Container(width: 24, height: 24, decoration: const BoxDecoration(border: Border(bottom: side, right: side))),
      ),
    ];
  }
}

class _ScannerAnimation extends StatefulWidget {
  const _ScannerAnimation();

  @override
  State<_ScannerAnimation> createState() => _ScannerAnimationState();
}

class _ScannerAnimationState extends State<_ScannerAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnim = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disableAnim) {
      _ctrl.stop();
      _ctrl.value = 0.5;
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
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
        return Stack(
          children: [
            Positioned(
              top: _ctrl.value * 220.0,
              left: 20,
              right: 20,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: NeoBrutalism.lime,
                  border: Border.all(color: Colors.black, width: 1.0),
                  boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
