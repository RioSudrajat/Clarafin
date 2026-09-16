import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/mock_providers.dart';
import '../../../budget/presentation/providers/finance_providers.dart';
import '../widgets/goal_detail_header.dart';
import '../widgets/goal_detail_hero_card.dart';
import '../widgets/goal_source_action_sheet.dart';
import '../widgets/goal_source_funds_section.dart';

/// Screen displaying the full detail, progress, and funding sources of a savings goal.
/// Fully adheres to Clarafin Neo-Brutalism design system.
class GoalDetailScreen extends ConsumerWidget {
  final String goalId;

  const GoalDetailScreen({super.key, required this.goalId});

  void _addNewSource(BuildContext context, String goalId) {
    context.push('/transaction/entry', extra: {
      'type': 'Transfer',
      'targetGoalId': goalId,
    });
  }

  void _showSourceSheet(
    BuildContext context,
    String goalId,
    String walletId,
    String walletName,
    double amount,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => GoalSourceActionSheet(
        walletName: walletName,
        currentAmount: amount,
        onAddFunds: () {
          context.push('/transaction/entry', extra: {
            'type': 'Transfer',
            'targetGoalId': goalId,
            'sourceWalletId': walletId,
          });
        },
        onWithdrawFunds: () {
          context.push('/transaction/entry', extra: {
            'type': 'Transfer',
            'sourceWalletId': 'goal:$goalId:$walletId',
            'targetWalletId': walletId,
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    final wallets = ref.watch(walletsProvider);
    final goal = goals.firstWhere(
      (g) => g.id == goalId,
      orElse: () => goals.first,
    );

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(height: topPadding),
            GoalDetailHeader(
              title: goal.name,
              goalId: goalId,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  children: [
                    GoalDetailHeroCard(goal: goal),
                    const SizedBox(height: 24),
                    GoalSourceFundsSection(
                      goal: goal,
                      wallets: wallets,
                      onAddSource: () => _addNewSource(context, goalId),
                      onTapSource: (wId, wName, amt) => _showSourceSheet(
                        context,
                        goalId,
                        wId,
                        wName,
                        amt,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
