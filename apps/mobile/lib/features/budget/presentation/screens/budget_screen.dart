import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/bills_tab_content.dart';
import '../widgets/budget_gradient_header.dart';
import '../widgets/budget_tab_content.dart';
import '../widgets/goals_tab_content.dart';

/// Orchestrator screen for Budget, Goals, and Bills.
/// Features a Halofin brand gradient header with month selector and Neo-Brutalist tab pills,
/// followed by a white canvas holding the active tab content.
class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  int _selectedTab = 1; // 0 = Goals, 1 = Budget, 2 = Bills

  @override
  Widget build(BuildContext context) {
    final topSafeArea = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. Top Gradient Header with Month Selector & Tab Pills
          BudgetGradientHeader(
            topSafeArea: topSafeArea,
            selectedTab: _selectedTab,
            onTabChanged: (index) => setState(() => _selectedTab = index),
          ),

          // 2. White Canvas holding the active tab's content
          Expanded(
            child: _buildActiveTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_selectedTab) {
      case 0:
        return const GoalsTabContent(key: ValueKey('goals'));
      case 2:
        return const BillsTabContent(key: ValueKey('bills'));
      default:
        return const BudgetTabContent(key: ValueKey('budget'));
    }
  }
}
