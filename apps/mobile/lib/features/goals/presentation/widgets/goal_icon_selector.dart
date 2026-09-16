import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

/// Tactile Neo-Brutalist Icon Selector for Goals.
class GoalIconSelector extends StatelessWidget {
  final IconData selectedIcon;
  final ValueChanged<IconData> onIconSelected;

  static const List<IconData> availableIcons = [
    Icons.star_rounded,
    Icons.laptop_mac_rounded,
    Icons.health_and_safety_rounded,
    Icons.flight_takeoff_rounded,
    Icons.directions_car_rounded,
    Icons.home_rounded,
    Icons.phone_iphone_rounded,
    Icons.school_rounded,
    Icons.shopping_bag_rounded,
    Icons.sports_esports_rounded,
    Icons.camera_alt_rounded,
    Icons.diamond_rounded,
  ];

  const GoalIconSelector({
    super.key,
    required this.selectedIcon,
    required this.onIconSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: NeoBrutalism.cardDecoration(
        backgroundColor: Colors.white,
        borderRadius: 20,
        shadowOffset: 3.0,
      ),
      child: Column(
        children: [
          // Live Preview
          Container(
            width: 72,
            height: 72,
            decoration: NeoBrutalism.circleDecoration(
              backgroundColor: NeoBrutalism.lime,
              shadowOffset: 3.0,
            ),
            child: Icon(
              selectedIcon,
              size: 36,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'PILIH IKON TARGET',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Color(0xFF6B7280),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),

          // Icons Grid / Wrap
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: availableIcons.map((icon) {
              final isSelected = selectedIcon == icon;
              return GestureDetector(
                onTap: () => onIconSelected(icon),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected ? NeoBrutalism.lime : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.black,
                      width: isSelected ? 2.0 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? const [
                            BoxShadow(
                              color: Colors.black,
                              offset: Offset(0, 2),
                              blurRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: Colors.black,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
