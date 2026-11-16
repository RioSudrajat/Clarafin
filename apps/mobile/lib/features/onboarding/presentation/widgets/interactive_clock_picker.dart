import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class InteractiveClockPicker extends StatefulWidget {
  final String initialTime; // 'HH:mm' e.g. '20:00'
  final ValueChanged<String> onTimeChanged;

  const InteractiveClockPicker({
    super.key,
    required this.initialTime,
    required this.onTimeChanged,
  });

  @override
  State<InteractiveClockPicker> createState() => _InteractiveClockPickerState();
}

class _InteractiveClockPickerState extends State<InteractiveClockPicker> {
  late int _hour;
  late int _minute;
  double? _lastAngle;
  int _accumulatedMinutes = 0;

  @override
  void initState() {
    super.initState();
    _parseTime(widget.initialTime);
    _accumulatedMinutes = _hour * 60 + _minute;
  }

  @override
  void didUpdateWidget(covariant InteractiveClockPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTime != widget.initialTime) {
      _parseTime(widget.initialTime);
      _accumulatedMinutes = _hour * 60 + _minute;
    }
  }

  void _parseTime(String time) {
    final parts = time.split(':');
    _hour = int.tryParse(parts[0]) ?? 20;
    _minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
  }

  double _getAngle(Offset localPosition, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final dx = localPosition.dx - centerX;
    final dy = localPosition.dy - centerY;
    // Angle clockwise from 12 o'clock
    double theta = atan2(dy, dx) + (pi / 2);
    if (theta < 0) theta += 2 * pi;
    return theta;
  }

  void _onPanStart(Offset localPosition, Size size) {
    _lastAngle = _getAngle(localPosition, size);
    _accumulatedMinutes = _hour * 60 + _minute;
  }

  void _onPanUpdate(Offset localPosition, Size size) {
    final currentAngle = _getAngle(localPosition, size);
    if (_lastAngle == null) {
      _lastAngle = currentAngle;
      return;
    }

    double deltaAngle = currentAngle - _lastAngle!;
    // Normalize delta across the 0/2*pi boundary
    while (deltaAngle > pi) {
      deltaAngle -= 2 * pi;
    }
    while (deltaAngle < -pi) {
      deltaAngle += 2 * pi;
    }

    // A full 360 rotation is 12 hours (720 minutes)
    final deltaMinutes = (deltaAngle / (2 * pi)) * 720.0;
    _accumulatedMinutes += deltaMinutes.round();

    // Clamp / wrap smoothly within 0..1439 (24 hours)
    int totalMinutes = _accumulatedMinutes % 1440;
    if (totalMinutes < 0) totalMinutes += 1440;

    // Snap to 15-minute steps for easy user selection
    final snappedMinutes = (((totalMinutes + 7) ~/ 15) * 15) % 1440;
    final newHour = snappedMinutes ~/ 60;
    final newMinute = snappedMinutes % 60;

    if (newHour != _hour || newMinute != _minute) {
      setState(() {
        _hour = newHour;
        _minute = newMinute;
      });
      final formattedHour = _hour.toString().padLeft(2, '0');
      final formattedMinute = _minute.toString().padLeft(2, '0');
      widget.onTimeChanged('$formattedHour:$formattedMinute');
    }

    _lastAngle = currentAngle;
  }

  void _onPanEnd() {
    _lastAngle = null;
    _accumulatedMinutes = _hour * 60 + _minute;
  }

  @override
  Widget build(BuildContext context) {
    final hour12 = _hour % 12;
    final hourFraction = hour12 + (_minute / 60.0);
    final handAngle = (hourFraction / 12.0) * 2 * pi - (pi / 2);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NeoBrutalism.radiusXl),
        border: NeoBrutalism.border(width: 2.0),
        boxShadow: NeoBrutalism.shadow(yOffset: 4.0),
      ),
      child: Column(
        children: [
          // Drag instruction banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: NeoBrutalism.mint,
              borderRadius: BorderRadius.circular(NeoBrutalism.radiusPill),
              border: NeoBrutalism.border(width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.touch_app_rounded, size: 15, color: NeoBrutalism.dark),
                const SizedBox(width: 6),
                Text(
                  'Tahan & putar jarum jam langsung',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: NeoBrutalism.dark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Interactive Circular Clock Dial with Opaque Hit Testing
          SizedBox(
            width: 220,
            height: 220,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanDown: (details) => _onPanStart(details.localPosition, size),
                  onPanStart: (details) => _onPanStart(details.localPosition, size),
                  onPanUpdate: (details) => _onPanUpdate(details.localPosition, size),
                  onPanEnd: (_) => _onPanEnd(),
                  onPanCancel: () => _onPanEnd(),
                  child: CustomPaint(
                    size: size,
                    painter: _ClockPainter(
                      handAngle: handAngle,
                      activeHour: _hour,
                      activeMinute: _minute,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Digital Display Pill (Anti-Slop: Lime fill with 2px black border, NOT solid black!)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: NeoBrutalism.lime,
              borderRadius: BorderRadius.circular(14),
              border: NeoBrutalism.border(width: 2.0),
              boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
            ),
            child: Text(
              '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')} WIB',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: NeoBrutalism.dark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  final double handAngle;
  final int activeHour;
  final int activeMinute;

  _ClockPainter({
    required this.handAngle,
    required this.activeHour,
    required this.activeMinute,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Dial background
    final bgPaint = Paint()
      ..color = const Color(0xFFF8FAFC)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 2, bgPaint);

    // Dial border (Neo-Brutalist 2.5px solid black)
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius - 2, borderPaint);

    // Inner Lime ring track
    final trackPaint = Paint()
      ..color = NeoBrutalism.lime.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16.0;
    canvas.drawCircle(center, radius - 24, trackPaint);

    // 12 Hour Marker ticks & numbers
    for (int i = 1; i <= 12; i++) {
      final angle = (i / 12.0) * 2 * pi - (pi / 2);
      final tickStart = Offset(
        center.dx + (radius - 12) * cos(angle),
        center.dy + (radius - 12) * sin(angle),
      );
      final tickEnd = Offset(
        center.dx + (radius - 22) * cos(angle),
        center.dy + (radius - 22) * sin(angle),
      );

      final isMajor = (i % 3 == 0);
      final tickPaint = Paint()
        ..color = isMajor ? Colors.black : const Color(0xFF94A3B8)
        ..strokeWidth = isMajor ? 2.5 : 1.5;
      canvas.drawLine(tickStart, tickEnd, tickPaint);

      // Evening/night markers
      String label = '•';
      if (i == 12) label = '00';
      if (i == 3) label = '06';
      if (i == 6) label = '12';
      if (i == 9) label = '18';
      if (i == 10) label = '20';
      if (i == 11) label = '22';

      final textSpan = TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.black,
          fontSize: isMajor ? 11 : 9,
          fontWeight: FontWeight.w900,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final textPos = Offset(
        center.dx + (radius - 38) * cos(angle) - textPainter.width / 2,
        center.dy + (radius - 38) * sin(angle) - textPainter.height / 2,
      );
      textPainter.paint(canvas, textPos);
    }

    // Clock Hand
    final handLength = radius - 30;
    final handEnd = Offset(
      center.dx + handLength * cos(handAngle),
      center.dy + handLength * sin(handAngle),
    );

    final handPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, handEnd, handPaint);

    // Knob at the tip of the hand (draggable touch target)
    final knobBgPaint = Paint()
      ..color = NeoBrutalism.lime
      ..style = PaintingStyle.fill;
    canvas.drawCircle(handEnd, 14, knobBgPaint);

    final knobBorderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(handEnd, 14, knobBorderPaint);

    // Center pivot dot
    final centerPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 7, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _ClockPainter oldDelegate) {
    return oldDelegate.handAngle != handAngle ||
        oldDelegate.activeHour != activeHour ||
        oldDelegate.activeMinute != activeMinute;
  }
}
