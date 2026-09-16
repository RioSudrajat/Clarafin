import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../../core/theme/app_colors.dart';

class ChartData {
  final String label;
  final double value;
  final Color color;

  ChartData(this.label, this.value, this.color);
}

class InteractiveDonutChart extends StatefulWidget {
  final List<ChartData> data;
  final String centerTitle;
  final String centerAmount;

  const InteractiveDonutChart({
    super.key,
    required this.data,
    required this.centerTitle,
    required this.centerAmount,
  });

  // Generates monochromatic shades of the lime yellow brand color
  static List<Color> generateLimeShades(int count) {
    if (count <= 0) return [];
    if (count == 1) return [AppColors.primary];

    const double hue = 72.0;
    const double saturation = 0.9;

    final shades = <Color>[];
    for (int i = 0; i < count; i++) {
      double factor = count > 1 ? i / (count - 1) : 0.0;
      // Interpolate lightness from 0.85 (lightest) down to 0.15 (darkest)
      double lightness = 0.85 - (factor * 0.70);
      shades.add(HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor());
    }
    return shades;
  }

  @override
  State<InteractiveDonutChart> createState() => _InteractiveDonutChartState();
}

class _InteractiveDonutChartState extends State<InteractiveDonutChart> {
  int _touchedIndex = -1;
  double _rotationAngle = -math.pi / 2; // Start from -90 degrees equivalent
  double _lastAngle = 0.0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : 270.0;
        final center = Offset(constraints.maxWidth / 2, chartHeight / 2);

        return GestureDetector(
          onPanStart: (details) {
            final touchPoint = details.localPosition;
            _lastAngle = math.atan2(touchPoint.dy - center.dy, touchPoint.dx - center.dx);
          },
          onPanUpdate: (details) {
            final touchPoint = details.localPosition;
            final currentAngle = math.atan2(touchPoint.dy - center.dy, touchPoint.dx - center.dx);
            var diff = currentAngle - _lastAngle;
            // Handle boundary wrap-around across -pi / pi
            if (diff > math.pi) diff -= 2 * math.pi;
            if (diff < -math.pi) diff += 2 * math.pi;
            setState(() {
              _rotationAngle += diff;
              _lastAngle = currentAngle;
            });
          },
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Shadow for 3D effect
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 20,
                      spreadRadius: 4,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              ),
              Transform.rotate(
                angle: _rotationAngle,
                child: SizedBox(
                  height: 270,
                  width: 270,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          if (event is FlTapUpEvent) {
                            setState(() {
                              if (pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                _touchedIndex = -1;
                                return;
                              }
                              final index = pieTouchResponse.touchedSection!.touchedSectionIndex;
                              if (index == -1) {
                                _touchedIndex = -1;
                              } else if (_touchedIndex == index) {
                                _touchedIndex = -1; // Toggle off
                              } else {
                                _touchedIndex = index; // Toggle on
                              }
                            });
                          }
                        },
                      ),
                      startDegreeOffset: 0,
                      sectionsSpace: 2.5,
                      centerSpaceRadius: 58,
                      sections: () {
                        final total = widget.data.fold<double>(0.0, (sum, item) => sum + item.value);
                        return widget.data.asMap().entries.map((entry) {
                          final i = entry.key;
                          final data = entry.value;
                          final isTouched = i == _touchedIndex;
                          final radius = isTouched ? 48.0 : 38.0; // Pop-out effect

                          final percentage = total > 0 ? (data.value / total) * 100 : 0.0;
                          final hasNoData = widget.data.length == 1 && widget.data.first.label == 'Tidak ada data';
                          final showPercentage = total > 0 && data.value > 0 && !hasNoData;
                          final percentageText = showPercentage ? '${percentage.toStringAsFixed(0)}%' : '';

                          return PieChartSectionData(
                            color: data.color,
                            value: data.value,
                            title: '',
                            showTitle: false,
                            radius: radius,
                            badgeWidget: Transform.rotate(
                              angle: -_rotationAngle, // counter-rotate badges to stay upright
                              child: _buildBadge(data.label, percentageText, isTouched),
                            ),
                            badgePositionPercentageOffset: 1.35, // Push outside
                          );
                        }).toList();
                      }(),
                    ),
                  ),
                ),
              ),
              // Center Text Plate
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black.withValues(alpha: 0.15), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.centerTitle,
                      style: textTheme.labelSmall?.copyWith(
                        fontFamily: 'Plus Jakarta Sans',
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        widget.centerAmount,
                        textAlign: TextAlign.center,
                        style: textTheme.titleSmall?.copyWith(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBadge(String label, String percentageText, bool isTouched) {
    final displayText = percentageText.isNotEmpty ? '$label $percentageText' : label;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: isTouched ? 2.0 : 1.2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(0, 1.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade400, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(displayText, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}
