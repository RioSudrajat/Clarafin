import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/finance_providers.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

/// Content view for the Goals tab adhering to the Neo-Brutalist design system.
class GoalsTabContent extends ConsumerWidget {
  const GoalsTabContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Saving Goals',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: -0.3,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/goal/add'),
                  child: Row(
                    children: const [
                      Icon(Icons.add, color: Colors.black, size: 18),
                      SizedBox(width: 4),
                      Text(
                        'New Goal',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Goals 2-Column Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.70,
              ),
              itemCount: goals.length + 1, // +1 for the Add New button
              itemBuilder: (context, index) {
                if (index == goals.length) {
                  return GestureDetector(
                    onTap: () => context.push('/goal/add'),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFFCC7),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.black, width: 2.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(0, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 52,
                            width: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFCCFF00),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 2.0),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(0, 2),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.black,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Create New Goal',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final goal = goals[index];
                final progress = goal.targetAmount > 0
                    ? (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0)
                    : 0.0;
                final isComplete = progress >= 1.0;

                final now = DateTime.now();
                final daysLeft = goal.targetDate.difference(now).inDays;
                final timeLeftStr = isComplete
                    ? 'Complete'
                    : (daysLeft > 30
                        ? '${daysLeft ~/ 30} months left'
                        : '$daysLeft days left');

                return GestureDetector(
                  onTap: () => context.push('/goal/${goal.id}'),
                  child: _buildGoalCard(
                    context,
                    name: goal.name,
                    timeLeft: timeLeftStr,
                    tagColor: isComplete ? const Color(0xFFE5F9E0) : goal.tagColor,
                    tagTextColor: isComplete
                        ? Colors.green.shade800
                        : goal.tagTextColor,
                    icon: goal.icon,
                    progress: progress,
                    target: 'Rp ${goal.targetAmount.toInt()}',
                    shortfall: isComplete
                        ? 'Done'
                        : 'Rp ${(goal.targetAmount - goal.savedAmount).toInt()}',
                    saved: 'Rp ${goal.savedAmount.toInt()}',
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // 3. Smart Tip Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFE5F9E0),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.black, width: 2.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(0, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCFF00),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black,
                          offset: Offset(0, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.tips_and_updates,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Smart Tip',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Berdasarkan riwayat pengeluaranmu, kamu bisa menyisihkan ekstra Rp 500.000 bulan ini untuk mempercepat target liburanmu!',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11.5,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(
    BuildContext context, {
    required String name,
    required String timeLeft,
    required Color tagColor,
    required Color tagTextColor,
    required IconData icon,
    required double progress,
    required String target,
    required String shortfall,
    required String saved,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black, width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const SizedBox(height: 18),
                SizedBox(
                  height: 76,
                  width: 76,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 6,
                        backgroundColor: Colors.grey.shade100,
                        color: NeoBrutalism.lime,
                        strokeCap: StrokeCap.round,
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 22, color: Colors.black87),
                            const SizedBox(height: 2),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Target: $target',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 9.5,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  shortfall == 'Done' ? 'Complete' : 'Kurang $shortfall',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: shortfall == 'Done' ? Colors.green : Colors.red,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Saved',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 9,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        saved,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: tagColor,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: Text(
                timeLeft,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: tagTextColor,
                ),
              ),
            ),
          ),
          const Positioned(
            top: 10,
            right: 10,
            child: Icon(Icons.more_horiz, size: 18, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
