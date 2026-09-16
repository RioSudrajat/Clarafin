import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../budget/presentation/providers/finance_providers.dart';
import '../widgets/goal_form_header.dart';
import '../widgets/goal_form_inputs.dart';
import '../widgets/goal_icon_selector.dart';
import '../widgets/goal_priority_selector.dart';
import '../widgets/goal_submit_button.dart';

/// Screen for creating or editing savings goals.
/// Fully adheres to Clarafin Neo-Brutalism design system.
class AddEditGoalScreen extends ConsumerStatefulWidget {
  final String? goalId;

  const AddEditGoalScreen({super.key, this.goalId});

  @override
  ConsumerState<AddEditGoalScreen> createState() => _AddEditGoalScreenState();
}

class _AddEditGoalScreenState extends ConsumerState<AddEditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _targetAmountController;

  DateTime _targetDate = DateTime.now().add(const Duration(days: 90));
  String _priority = 'Needs';
  IconData _selectedIcon = Icons.star_rounded;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _targetAmountController = TextEditingController();

    if (widget.goalId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final goals = ref.read(goalsProvider);
        final goal = goals.firstWhere(
          (g) => g.id == widget.goalId,
          orElse: () => goals.first,
        );
        setState(() {
          _nameController.text = goal.name;
          _targetAmountController.text = _formatAmount(goal.targetAmount);
          _targetDate = goal.targetDate;
          _priority = goal.priority;
          _selectedIcon = goal.icon;
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
    _targetAmountController.dispose();
    super.dispose();
  }

  void _saveGoal() {
    if (!_formKey.currentState!.validate()) return;

    final cleanAmount = _targetAmountController.text.replaceAll('.', '');
    final targetAmount = double.tryParse(cleanAmount) ?? 0;

    Color tagColor = const Color(0xFFF3F4F6);
    Color tagTextColor = const Color(0xFF374151);
    if (_priority == 'Urgent') {
      tagColor = const Color(0xFFFFDAD6);
      tagTextColor = const Color(0xFFBA1A1A);
    } else if (_priority == 'Wants') {
      tagColor = const Color(0xFFE3F2FD);
      tagTextColor = const Color(0xFF1976D2);
    }

    if (widget.goalId == null) {
      final newGoal = GoalModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        targetAmount: targetAmount,
        savedAmount: 0,
        targetDate: _targetDate,
        icon: _selectedIcon,
        tagColor: tagColor,
        tagTextColor: tagTextColor,
        priority: _priority,
        sourceAsset: '',
      );
      ref.read(goalsProvider.notifier).addGoal(newGoal);
    } else {
      final existing = ref
          .read(goalsProvider)
          .firstWhere((g) => g.id == widget.goalId);
      final updated = existing.copyWith(
        name: _nameController.text.trim(),
        targetAmount: targetAmount,
        targetDate: _targetDate,
        icon: _selectedIcon,
        tagColor: tagColor,
        tagTextColor: tagTextColor,
        priority: _priority,
      );
      ref.read(goalsProvider.notifier).updateGoal(updated);
    }

    context.pop();
  }

  void _deleteGoal() {
    if (widget.goalId != null) {
      ref.read(goalsProvider.notifier).removeGoal(widget.goalId!);
      context.pop();
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
    );
    if (picked != null && picked != _targetDate) {
      setState(() => _targetDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.goalId != null;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(height: topPadding),
            GoalFormHeader(
              isEditing: isEditing,
              onDelete: _deleteGoal,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GoalIconSelector(
                        selectedIcon: _selectedIcon,
                        onIconSelected: (i) => setState(() => _selectedIcon = i),
                      ),
                      const SizedBox(height: 20),
                      GoalFormInputs(
                        nameController: _nameController,
                        targetAmountController: _targetAmountController,
                        targetDate: _targetDate,
                        onSelectDate: _selectDate,
                      ),
                      const SizedBox(height: 20),
                      GoalPrioritySelector(
                        selectedPriority: _priority,
                        onPrioritySelected: (p) => setState(() => _priority = p),
                      ),
                      const SizedBox(height: 32),
                      GoalSubmitButton(
                        isEditing: isEditing,
                        onPressed: _saveGoal,
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
