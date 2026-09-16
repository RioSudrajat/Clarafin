import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/finance_providers.dart';
import '../widgets/budget_form_header.dart';
import '../widgets/budget_form_inputs.dart';
import '../widgets/budget_icon_color_picker.dart';
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
  late final TextEditingController _nameController;
  late final TextEditingController _totalAmountController;
  late final TextEditingController _spentAmountController;

  IconData _selectedIcon = Icons.restaurant_rounded;
  Color _selectedColor = const Color(0xFFFF9F1C);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _totalAmountController = TextEditingController();
    _spentAmountController = TextEditingController(text: '0');

    if (widget.budgetId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final budgets = ref.read(budgetsProvider);
        final budget = budgets.firstWhere(
          (b) => b.id == widget.budgetId,
          orElse: () => budgets.first,
        );

        setState(() {
          _nameController.text = budget.name;
          _totalAmountController.text = _formatAmount(budget.totalAmount);
          _spentAmountController.text = _formatAmount(budget.spentAmount);
          _selectedIcon = budget.icon;
          _selectedColor = budget.iconColor;
        });
      });
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
    _nameController.dispose();
    _totalAmountController.dispose();
    _spentAmountController.dispose();
    super.dispose();
  }

  void _saveBudget() {
    if (!_formKey.currentState!.validate()) return;

    final totalClean = _totalAmountController.text.replaceAll('.', '');
    final spentClean = _spentAmountController.text.replaceAll('.', '');

    final totalAmount = double.tryParse(totalClean) ?? 0;
    final spentAmount = double.tryParse(spentClean) ?? 0;

    final newBudget = BudgetCategoryModel(
      id: widget.budgetId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      totalAmount: totalAmount,
      spentAmount: spentAmount,
      icon: _selectedIcon,
      iconColor: _selectedColor,
      iconBgColor: _selectedColor.withValues(alpha: 0.15),
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BudgetIconColorPicker(
                        selectedIcon: _selectedIcon,
                        selectedColor: _selectedColor,
                        onIconSelected: (i) => setState(() => _selectedIcon = i),
                        onColorSelected: (c) => setState(() => _selectedColor = c),
                      ),
                      const SizedBox(height: 20),
                      BudgetFormInputs(
                        nameController: _nameController,
                        totalAmountController: _totalAmountController,
                        spentAmountController: _spentAmountController,
                      ),
                      const SizedBox(height: 32),
                      BudgetSubmitButton(
                        isEditing: isEditing,
                        onPressed: _saveBudget,
                      ),
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
