import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/goal_model.dart';
import '../../domain/models/budget_category_model.dart';
import '../../domain/models/bill_model.dart';
import '../../../../core/models/transaction_category_model.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

export '../../domain/models/goal_model.dart';
export '../../domain/models/budget_category_model.dart';
export '../../domain/models/bill_model.dart';
export '../../domain/models/budget_summary_model.dart';
import '../../../../core/providers/mock_providers.dart';
import '../../domain/models/budget_summary_model.dart';

// --- NOTIFIERS ---

class GoalsNotifier extends Notifier<List<GoalModel>> {
  @override
  List<GoalModel> build() {
    final userId = ref.watch(authProvider.select((s) => s.currentUser?.id));
    if (userId == null || userId.isEmpty) return [];
    return ref.read(localStorageServiceProvider).getGoals(userId);
  }

  void _persist() {
    final userId = ref.read(authProvider).currentUser?.id;
    if (userId != null && userId.isNotEmpty) {
      ref.read(localStorageServiceProvider).saveGoals(userId, state);
    }
  }

  void addGoal(GoalModel goal) {
    state = [...state, goal];
    _persist();
  }

  void updateGoal(GoalModel updatedGoal) {
    state = [
      for (final goal in state)
        if (goal.id == updatedGoal.id) updatedGoal else goal,
    ];
    _persist();
  }

  void removeGoal(String id) {
    state = state.where((goal) => goal.id != id).toList();
    _persist();
  }

  /// Add savings to a goal from a specific wallet source
  void addSavings(String goalId, String walletId, double amount) {
    state = state.map((goal) {
      if (goal.id == goalId) {
        final newContributions = Map<String, double>.from(goal.contributions);
        newContributions[walletId] = (newContributions[walletId] ?? 0) + amount;
        return goal.copyWith(
          savedAmount: goal.savedAmount + amount,
          contributions: newContributions,
        );
      }
      return goal;
    }).toList();
    _persist();
  }

  /// Remove savings from a goal, returning funds to a specific wallet
  void removeSavings(String goalId, String walletId, double amount) {
    state = state.map((goal) {
      if (goal.id == goalId) {
        final newContributions = Map<String, double>.from(goal.contributions);
        final current = newContributions[walletId] ?? 0;
        final actualRemove = amount.clamp(0, current);
        newContributions[walletId] = current - actualRemove;
        if (newContributions[walletId]! <= 0) newContributions.remove(walletId);
        return goal.copyWith(
          savedAmount: (goal.savedAmount - actualRemove).clamp(0, double.infinity),
          contributions: newContributions,
        );
      }
      return goal;
    }).toList();
    _persist();
  }
}

class BudgetsNotifier extends Notifier<List<BudgetCategoryModel>> {
  @override
  List<BudgetCategoryModel> build() {
    final userId = ref.watch(authProvider.select((s) => s.currentUser?.id));
    if (userId == null || userId.isEmpty) return [];
    return ref.read(localStorageServiceProvider).getBudgets(userId);
  }

  void _persist() {
    final userId = ref.read(authProvider).currentUser?.id;
    if (userId != null && userId.isNotEmpty) {
      ref.read(localStorageServiceProvider).saveBudgets(userId, state);
    }
  }

  void addBudget(BudgetCategoryModel budget) {
    state = [...state, budget];
    _persist();
  }

  void updateBudget(BudgetCategoryModel updatedBudget) {
    state = [
      for (final budget in state)
        if (budget.id == updatedBudget.id) updatedBudget else budget,
    ];
    _persist();
  }

  void removeBudget(String id) {
    state = state.where((budget) => budget.id != id).toList();
    _persist();
  }
}

class MonthlyTotalBudgetNotifier extends Notifier<double> {
  @override
  double build() {
    final userId = ref.watch(authProvider.select((s) => s.currentUser?.id));
    if (userId == null || userId.isEmpty) return 5000000.0;
    return ref.read(localStorageServiceProvider).getTotalBudget(userId);
  }

  void setTotalBudget(double amount) {
    state = amount;
    final userId = ref.read(authProvider).currentUser?.id;
    if (userId != null && userId.isNotEmpty) {
      ref.read(localStorageServiceProvider).saveTotalBudget(userId, amount);
    }
  }
}

class BillsNotifier extends Notifier<List<BillModel>> {
  @override
  List<BillModel> build() {
    final userId = ref.watch(authProvider.select((s) => s.currentUser?.id));
    if (userId == null || userId.isEmpty) return [];
    return ref.read(localStorageServiceProvider).getBills(userId);
  }

  void _persist() {
    final userId = ref.read(authProvider).currentUser?.id;
    if (userId != null && userId.isNotEmpty) {
      ref.read(localStorageServiceProvider).saveBills(userId, state);
    }
  }

  void addBill(BillModel bill) {
    state = [...state, bill];
    _persist();
  }

  void updateBill(BillModel updatedBill) {
    state = [
      for (final bill in state)
        if (bill.id == updatedBill.id) updatedBill else bill,
    ];
    _persist();
  }

  void removeBill(String id) {
    state = state.where((bill) => bill.id != id).toList();
    _persist();
  }
}

// --- PROVIDERS ---

final goalsProvider = NotifierProvider<GoalsNotifier, List<GoalModel>>(GoalsNotifier.new);

final budgetsProvider = NotifierProvider<BudgetsNotifier, List<BudgetCategoryModel>>(BudgetsNotifier.new);

final monthlyTotalBudgetProvider = NotifierProvider<MonthlyTotalBudgetNotifier, double>(
  MonthlyTotalBudgetNotifier.new,
);

final billsProvider = NotifierProvider<BillsNotifier, List<BillModel>>(BillsNotifier.new);

/// Budgets synchronized dynamically with transactions of the current month
final syncedBudgetsProvider = Provider<List<BudgetCategoryModel>>((ref) {
  final rawBudgets = ref.watch(budgetsProvider);
  final transactions = ref.watch(transactionsProvider);
  final now = DateTime.now();

  return rawBudgets.map((budget) {
    final target = budget.name.toLowerCase().trim();
    final spent = transactions.where((t) {
      if (t.type != 'expense') return false;
      if (t.date.year != now.year || t.date.month != now.month) return false;
      final cat = t.category.toLowerCase().trim();
      if (cat == target) return true;
      if (cat.startsWith('$target •') ||
          cat.startsWith('$target -') ||
          cat.startsWith('$target:')) {
        return true;
      }
      final mainPart = cat.split('•').first.trim();
      return mainPart == target;
    }).fold<double>(0.0, (sum, t) => sum + t.amount);

    final mainCat = TransactionCategories.findCategory(budget.name);
    return budget.copyWith(
      spentAmount: spent,
      icon: mainCat?.icon ?? budget.icon,
      iconColor: mainCat?.color ?? budget.iconColor,
      iconBgColor: mainCat?.bgColor ?? budget.iconBgColor,
    );
  }).toList();
});

/// Comprehensive monthly budget summary
final monthlyBudgetSummaryProvider = Provider<BudgetSummary>((ref) {
  final totalBudget = ref.watch(monthlyTotalBudgetProvider);
  final budgets = ref.watch(syncedBudgetsProvider);
  final transactions = ref.watch(transactionsProvider);
  final now = DateTime.now();

  final totalSpent = transactions.where((t) {
    return t.type == 'expense' && t.date.year == now.year && t.date.month == now.month;
  }).fold<double>(0.0, (sum, t) => sum + t.amount);

  final totalAllocated = budgets.fold<double>(0.0, (sum, b) => sum + b.totalAmount);
  final remainingAllocation = (totalBudget - totalAllocated).clamp(0.0, double.infinity);
  final remainingBudget = totalBudget - totalSpent;
  final progress = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;

  return BudgetSummary(
    totalBudget: totalBudget,
    totalAllocated: totalAllocated,
    remainingAllocation: remainingAllocation,
    totalSpent: totalSpent,
    remainingBudget: remainingBudget,
    progress: progress,
  );
});
