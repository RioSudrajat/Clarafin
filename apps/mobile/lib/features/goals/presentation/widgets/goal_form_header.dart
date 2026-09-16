import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

/// Top header for AddEditGoalScreen with Neo-Brutalist circular back button and delete action.
class GoalFormHeader extends StatelessWidget {
  final bool isEditing;
  final VoidCallback? onDelete;

  const GoalFormHeader({
    super.key,
    required this.isEditing,
    this.onDelete,
  });

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.black, width: 2.0),
        ),
        title: const Text(
          'Hapus Target Tabungan?',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        content: const Text(
          'Yakin ingin menghapus target ini? Riwayat setoran dan progres akan terhapus.',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4B5563),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pop(ctx);
              onDelete?.call();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: NeoBrutalism.cardDecoration(
                backgroundColor: const Color(0xFFFFDAD6),
                borderRadius: 12,
                shadowOffset: 2.0,
              ),
              child: const Text(
                'Hapus',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFBA1A1A),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: NeoBrutalism.circleDecoration(
                backgroundColor: Colors.white,
                shadowOffset: 2.5,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 22,
                color: Colors.black,
              ),
            ),
          ),
          Text(
            isEditing ? 'Edit Target Tabungan' : 'Buat Goal Baru',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: -0.3,
            ),
          ),
          if (isEditing)
            GestureDetector(
              onTap: () => _showDeleteDialog(context),
              child: Container(
                width: 44,
                height: 44,
                decoration: NeoBrutalism.circleDecoration(
                  backgroundColor: const Color(0xFFFFDAD6),
                  shadowOffset: 2.5,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  size: 22,
                  color: Color(0xFFBA1A1A),
                ),
              ),
            )
          else
            const SizedBox(width: 44),
        ],
      ),
    );
  }
}
