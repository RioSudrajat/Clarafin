import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

/// Tactile Neo-Brutalist Icon & Color Picker for BudgetCategory.
class BudgetIconColorPicker extends StatelessWidget {
  final IconData selectedIcon;
  final Color selectedColor;
  final ValueChanged<IconData> onIconSelected;
  final ValueChanged<Color> onColorSelected;

  static const List<IconData> availableIcons = [
    Icons.restaurant_rounded,
    Icons.directions_car_rounded,
    Icons.movie_filter_rounded,
    Icons.shopping_bag_rounded,
    Icons.medical_services_rounded,
    Icons.bolt_rounded,
    Icons.pets_rounded,
    Icons.card_giftcard_rounded,
    Icons.flight_takeoff_rounded,
    Icons.school_rounded,
  ];

  static const List<Color> availableColors = [
    Color(0xFFFF9F1C), // Orange
    Color(0xFF2EC4B6), // Teal
    Color(0xFFE71D36), // Red
    Color(0xFF8338EC), // Purple
    Color(0xFF3A86FF), // Blue
    Color(0xFF52B788), // Green
    Color(0xFFFF006E), // Pink
    Color(0xFF704214), // Brown
  ];

  const BudgetIconColorPicker({
    super.key,
    required this.selectedIcon,
    required this.selectedColor,
    required this.onIconSelected,
    required this.onColorSelected,
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
          // 1. Live Preview
          Container(
            width: 72,
            height: 72,
            decoration: NeoBrutalism.circleDecoration(
              backgroundColor: selectedColor.withValues(alpha: 0.2),
              shadowOffset: 3.0,
            ),
            child: Icon(
              selectedIcon,
              size: 36,
              color: selectedColor,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'PILIH IKON & WARNA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Color(0xFF6B7280),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),

          // 2. Icon Selection (horizontal scroll)
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: availableIcons.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final icon = availableIcons[index];
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
              },
            ),
          ),
          const SizedBox(height: 12),

          // 3. Color Selection
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: availableColors.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final color = availableColors[index];
                final isSelected = selectedColor.toARGB32() == color.toARGB32();
                return GestureDetector(
                  onTap: () => onColorSelected(color),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black,
                        width: isSelected ? 2.5 : 1.5,
                      ),
                      boxShadow: isSelected
                          ? const [
                              BoxShadow(
                                color: Colors.black,
                                offset: Offset(0, 2.5),
                                blurRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 20,
                            color: Colors.white,
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
