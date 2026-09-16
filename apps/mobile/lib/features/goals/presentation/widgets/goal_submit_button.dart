import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

/// Tactile Neo-Brutalist submit button for Goals forms.
class GoalSubmitButton extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onPressed;

  const GoalSubmitButton({
    super.key,
    required this.isEditing,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: NeoBrutalism.cardDecoration(
          backgroundColor: NeoBrutalism.lime,
          borderRadius: 16,
          shadowOffset: 3.5,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isEditing ? Icons.check_circle_rounded : Icons.rocket_launch_rounded,
              size: 20,
              color: Colors.black,
            ),
            const SizedBox(width: 8),
            Text(
              isEditing ? 'SIMPAN PERUBAHAN TARGET' : 'BUAT TARGET TABUNGAN',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
