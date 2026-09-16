import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/goal_model.dart';
import '../../domain/models/budget_category_model.dart';
import '../../domain/models/bill_model.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

export '../../domain/models/goal_model.dart';
export '../../domain/models/budget_category_model.dart';
export '../../domain/models/bill_model.dart';

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

final billsProvider = NotifierProvider<BillsNotifier, List<BillModel>>(BillsNotifier.new);
