import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

/// Top header section for the Budget & Finance screen.
/// Features the brand teal-to-lime gradient background, month selector,
/// and unified Neo-Brutalist segmented tab capsule (Goals, Budget, Bills).
class BudgetGradientHeader extends StatelessWidget {
  final double topSafeArea;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  const BudgetGradientHeader({
    super.key,
    required this.topSafeArea,
    required this.selectedTab,
    required this.onTabChanged,
  });

  static const double _curveRadius = 28.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: NeoBrutalism.brandGradient,
      ),
      child: Column(
        children: [
          SizedBox(height: topSafeArea + 10),

          // Month Selector Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'January 2026',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.expand_more, size: 22, color: Colors.white),
            ],
          ),
          const SizedBox(height: 14),

          // Unified Segmented Capsule (Goals | Budget | Bills)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildSegmentedTabs(),
          ),
          const SizedBox(height: 18),

          // Curved White Sheet Boundary at Bottom
          SizedBox(
            height: _curveRadius,
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(_curveRadius),
                    ),
                  ),
                ),
                const Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _BudgetCurveBorderPainter(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTabs() {
    const tabs = ['Goals', 'Budget', 'Bills'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(0, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / tabs.length;
          return Stack(
            children: [
              // Sliding active indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                left: selectedTab * tabWidth,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCFF00), // Lime neon
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 2.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(0, 1.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
              // Tab labels
              Row(
                children: List.generate(tabs.length, (index) {
                  final isSelected = selectedTab == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTabChanged(index),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Center(
                          child: Text(
                            tabs[index],
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                              color: isSelected
                                  ? Colors.black
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BudgetCurveBorderPainter extends CustomPainter {
  static const double cornerRadius = 28.0;

  const _BudgetCurveBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    path.moveTo(0, cornerRadius);
    path.arcToPoint(
      const Offset(cornerRadius, 0),
      radius: const Radius.circular(cornerRadius),
      clockwise: true,
    );
    path.lineTo(size.width - cornerRadius, 0);
    path.arcToPoint(
      Offset(size.width, cornerRadius),
      radius: const Radius.circular(cornerRadius),
      clockwise: true,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
