class BudgetSummary {
  final double totalBudget;
  final double totalAllocated;
  final double remainingAllocation;
  final double totalSpent;
  final double remainingBudget;
  final double progress;

  const BudgetSummary({
    required this.totalBudget,
    required this.totalAllocated,
    required this.remainingAllocation,
    required this.totalSpent,
    required this.remainingBudget,
    required this.progress,
  });
}
