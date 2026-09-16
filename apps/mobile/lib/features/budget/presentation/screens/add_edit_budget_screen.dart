import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/transaction_category_model.dart';
import '../../../transaction/presentation/widgets/category_picker_bottom_sheet.dart';
import '../providers/finance_providers.dart';
import '../widgets/budget_form_header.dart';
import '../widgets/budget_form_inputs.dart';
import '../widgets/budget_related_transactions_section.dart';
import '../widgets/budget_submit_button.dart';

/// Screen for creating or editing a budget category.
/// Fully adheres to Clarafin Neo-Brutalism design system.
class AddEditBudgetScreen extends ConsumerStatefulWidget {
  final String? budgetId;

  const AddEditBudgetScreen({super.key, this.budgetId});

  @override
  ConsumerState<AddEditBudgetScreen> createState() => _AddEditBudgetScreenState();
}

class _AddEditBudgetScreenState extends ConsumerState<AddEditBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _totalAmountController;

  String _categoryName = '';
  String? _categoryEmoji;
  String? _categoryGroup;
  Color _categoryColor = const Color(0xFFEA580C);
  Color _categoryBgColor = const Color(0xFFFFEDD5);
  IconData _categoryIcon = Icons.restaurant;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _totalAmountController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized && widget.budgetId != null) {
      _initialized = true;
      final budgets = ref.read(budgetsProvider);
      final budget = budgets.where((b) => b.id == widget.budgetId).firstOrNull;
      if (budget != null) {
        final mainCat = TransactionCategories.findCategory(budget.name);
        _categoryName = budget.name;
        _totalAmountController.text = _formatAmount(budget.totalAmount);
        _categoryIcon = mainCat?.icon ?? budget.icon;
        _categoryColor = mainCat?.color ?? budget.iconColor;
        _categoryBgColor = mainCat?.bgColor ?? budget.iconBgColor;
        _categoryEmoji = mainCat?.emoji ?? '🍜';
        _categoryGroup = mainCat?.group;
      }
    }
  }

  String _formatAmount(double val) {
    final str = val.toInt().toString();
    final buffer = StringBuffer();
    final len = str.length;
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  @override
  void dispose() {
    _totalAmountController.dispose();
    super.dispose();
  }

  void _pickCategory() async {
    final result = await CategoryPickerBottomSheet.show(
      context,
      isIncome: false,
      mainOnly: true,
      selectedCategoryName: _categoryName.isNotEmpty ? _categoryName : null,
    );

    if (result != null) {
      final mainCat = TransactionCategories.findCategory(result.category);
      setState(() {
        _categoryName = result.category;
        _categoryIcon = mainCat?.icon ?? result.icon;
        _categoryColor = mainCat?.color ?? result.color;
        _categoryBgColor =
            mainCat?.bgColor ?? result.bgColor ?? result.color.withValues(alpha: 0.15);
        _categoryEmoji = mainCat?.emoji ?? result.emoji;
        _categoryGroup = mainCat?.group;
      });
    }
  }

  void _saveBudget(double existingSpent) {
    if (!_formKey.currentState!.validate()) return;

    final totalClean = _totalAmountController.text.replaceAll('.', '').trim();
    final totalAmount = double.tryParse(totalClean) ?? 0;

    final newBudget = BudgetCategoryModel(
      id: widget.budgetId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _categoryName.trim(),
      totalAmount: totalAmount,
      spentAmount: existingSpent,
      icon: _categoryIcon,
      iconColor: _categoryColor,
      iconBgColor: _categoryBgColor,
    );

    if (widget.budgetId == null) {
      ref.read(budgetsProvider.notifier).addBudget(newBudget);
    } else {
      ref.read(budgetsProvider.notifier).updateBudget(newBudget);
    }

    context.pop();
  }

  void _deleteBudget() {
    if (widget.budgetId != null) {
      ref.read(budgetsProvider.notifier).removeBudget(widget.budgetId!);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.budgetId != null;
    final topPadding = MediaQuery.of(context).padding.top;

    final summary = ref.watch(monthlyBudgetSummaryProvider);
    final budgets = ref.watch(syncedBudgetsProvider);
    final existingBudget = isEditing
        ? budgets.where((b) => b.id == widget.budgetId).firstOrNull
        : null;

    final maxAllocatable = (summary.remainingAllocation + (existingBudget?.totalAmount ?? 0))
        .clamp(0.0, summary.totalBudget);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(height: topPadding),
            BudgetFormHeader(
              isEditing: isEditing,
              onDelete: _deleteBudget,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BudgetFormInputs(
                        categoryName: _categoryName,
                        categoryEmoji: _categoryEmoji,
                        categoryGroup: _categoryGroup,
                        categoryColor: _categoryColor,
                        categoryBgColor: _categoryBgColor,
                        categoryIcon: _categoryIcon,
                        onSelectCategory: _pickCategory,
                        totalAmountController: _totalAmountController,
                        maxAllocatable: maxAllocatable,
                        totalBudget: summary.totalBudget,
                        spentAmount: existingBudget?.spentAmount ?? 0,
                      ),
                      const SizedBox(height: 32),
                      BudgetSubmitButton(
                        isEditing: isEditing,
                        onPressed: () => _saveBudget(existingBudget?.spentAmount ?? 0),
                      ),
                      if (isEditing && _categoryName.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        BudgetRelatedTransactionsSection(
                          categoryName: _categoryName,
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
