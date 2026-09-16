import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

/// Top header for GoalDetailScreen with Neo-Brutalist circular back and edit actions.
class GoalDetailHeader extends StatelessWidget {
  final String title;
  final String goalId;

  const GoalDetailHeader({
    super.key,
    required this.title,
    required this.goalId,
  });

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
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                letterSpacing: -0.3,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/goal/edit/$goalId'),
            child: Container(
              width: 44,
              height: 44,
              decoration: NeoBrutalism.circleDecoration(
                backgroundColor: Colors.white,
                shadowOffset: 2.5,
              ),
              child: const Icon(
                Icons.edit_outlined,
                size: 22,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
