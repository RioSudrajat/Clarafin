import 'package:flutter/material.dart';

/// Neo-Brutalist priority selector for Goals: Urgent, Needs, Wants.
class GoalPrioritySelector extends StatelessWidget {
  final String selectedPriority;
  final ValueChanged<String> onPrioritySelected;

  static const List<Map<String, dynamic>> options = [
    {
      'key': 'Urgent',
      'label': 'Urgent',
      'icon': Icons.priority_high_rounded,
      'color': Color(0xFFE71D36),
      'bgColor': Color(0xFFFFDAD6),
    },
    {
      'key': 'Needs',
      'label': 'Needs',
      'icon': Icons.check_circle_outline_rounded,
      'color': Color(0xFFFF9F1C),
      'bgColor': Color(0xFFFFF3E0),
    },
    {
      'key': 'Wants',
      'label': 'Wants',
      'icon': Icons.favorite_border_rounded,
      'color': Color(0xFF3A86FF),
      'bgColor': Color(0xFFE3F2FD),
    },
  ];

  const GoalPrioritySelector({
    super.key,
    required this.selectedPriority,
    required this.onPrioritySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PRIORITAS TARGET',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Color(0xFF374151),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: options.map((opt) {
            final key = opt['key'] as String;
            final label = opt['label'] as String;
            final icon = opt['icon'] as IconData;
            final color = opt['color'] as Color;
            final bgColor = opt['bgColor'] as Color;
            final isSelected = selectedPriority == key;

            return Expanded(
              child: GestureDetector(
                onTap: () => onPrioritySelected(key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? bgColor : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? Colors.black : const Color(0xFFD1D5DB),
                      width: isSelected ? 2.0 : 1.5,
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
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSelected ? color : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          size: 18,
                          color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                          color: isSelected ? Colors.black : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
