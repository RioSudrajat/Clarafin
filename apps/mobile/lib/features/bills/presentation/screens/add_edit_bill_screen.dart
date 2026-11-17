import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../budget/presentation/providers/finance_providers.dart';
import '../widgets/bill_form_header.dart';
import '../widgets/bill_form_inputs.dart';
import '../widgets/bill_icon_selector.dart';
import '../widgets/bill_submit_button.dart';
import '../widgets/bill_switches_card.dart';

/// Screen for creating or editing recurring bills.
/// Fully adheres to Clarafin Neo-Brutalism design system.
class AddEditBillScreen extends ConsumerStatefulWidget {
  final String? billId;
  final String? initialTitle;
  final double? initialAmount;
  final int? initialDueDay;
  final String? initialFrequency;
  final String? initialCategory;

  const AddEditBillScreen({
    super.key,
    this.billId,
    this.initialTitle,
    this.initialAmount,
    this.initialDueDay,
    this.initialFrequency,
    this.initialCategory,
  });

  @override
  ConsumerState<AddEditBillScreen> createState() => _AddEditBillScreenState();
}

class _AddEditBillScreenState extends ConsumerState<AddEditBillScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;

  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isAutoPay = false;
  bool _isPaid = false;
  IconData _selectedIcon = Icons.receipt_long_rounded;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _amountController = TextEditingController();

    if (widget.billId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final bills = ref.read(billsProvider);
        final bill = bills.firstWhere(
          (b) => b.id == widget.billId,
          orElse: () => bills.first,
        );

        setState(() {
          _nameController.text = bill.name;
          _amountController.text = _formatAmount(bill.amount);
          if (bill.dueDate != null) _dueDate = bill.dueDate!;
          _isAutoPay = bill.isAutoPay;
          _isPaid = bill.isPaid;
          _selectedIcon = bill.icon;
        });
      });
    } else {
      if (widget.initialTitle != null && widget.initialTitle!.trim().isNotEmpty) {
        _nameController.text = widget.initialTitle!.trim();
      }
      if (widget.initialAmount != null && widget.initialAmount! > 0) {
        _amountController.text = _formatAmount(widget.initialAmount!);
      }
      if (widget.initialDueDay != null && widget.initialDueDay! >= 1) {
        _dueDate = _computeNextDueDate(widget.initialDueDay!);
      }
      _selectedIcon = _resolveBillIcon(
        widget.initialCategory,
        widget.initialTitle,
      );
    }
  }

  DateTime _computeNextDueDate(int day) {
    final now = DateTime.now();
    final clampedDay = day.clamp(1, 31);
    final maxDaysThisMonth = DateTime(now.year, now.month + 1, 0).day;
    var candidate = DateTime(
      now.year,
      now.month,
      clampedDay.clamp(1, maxDaysThisMonth),
    );
    final today = DateTime(now.year, now.month, now.day);
    if (candidate.isBefore(today)) {
      final nextMonth = now.month == 12 ? 1 : now.month + 1;
      final nextYear = now.month == 12 ? now.year + 1 : now.year;
      final maxDaysNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
      candidate = DateTime(
        nextYear,
        nextMonth,
        clampedDay.clamp(1, maxDaysNextMonth),
      );
    }
    return candidate;
  }

  IconData _resolveBillIcon(String? category, String? title) {
    final hint = '${category ?? ''} ${title ?? ''}'.toLowerCase();
    if (hint.contains('wifi') || hint.contains('internet') || hint.contains('indihome')) {
      return Icons.wifi_rounded;
    }
    if (hint.contains('listrik') || hint.contains('pln') || hint.contains('electric')) {
      return Icons.bolt_rounded;
    }
    if (hint.contains('air') || hint.contains('pdam') || hint.contains('water')) {
      return Icons.water_drop_rounded;
    }
    if (hint.contains('sewa') || hint.contains('kos') || hint.contains('kpr') || hint.contains('rent')) {
      return Icons.home_work_rounded;
    }
    if (hint.contains('kredit') || hint.contains('cicil') || hint.contains('card')) {
      return Icons.credit_card_rounded;
    }
    if (hint.contains('pulsa') || hint.contains('hp') || hint.contains('phone')) {
      return Icons.phone_iphone_rounded;
    }
    if (hint.contains('stream') || hint.contains('netflix') || hint.contains('hiburan')) {
      return Icons.movie_filter_rounded;
    }
    return Icons.receipt_long_rounded;
  }

  String _formatAmount(double val) =>
      CurrencyFormatter.formatWithoutSymbol(val.roundToDouble(), isIdrBase: false);

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _saveBill() {
    if (!_formKey.currentState!.validate()) return;

    final cleanAmount = _amountController.text.replaceAll('.', '');
    final amount = double.tryParse(cleanAmount) ?? 0;

    final newBill = BillModel(
      id: widget.billId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      amount: amount,
      dueDate: _dueDate,
      isAutoPay: _isAutoPay,
      isPaid: _isPaid,
      icon: _selectedIcon,
      iconColor: Colors.white,
      iconBgColor: Colors.black,
    );

    if (widget.billId == null) {
      ref.read(billsProvider.notifier).addBill(newBill);
    } else {
      ref.read(billsProvider.notifier).updateBill(newBill);
    }

    context.pop();
  }

  void _deleteBill() {
    if (widget.billId != null) {
      ref.read(billsProvider.notifier).removeBill(widget.billId!);
      context.pop();
    }
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null && picked != _dueDate) {
      setState(() => _dueDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.billId != null;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(height: topPadding),
            BillFormHeader(
              isEditing: isEditing,
              onDelete: _deleteBill,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BillIconSelector(
                        selectedIcon: _selectedIcon,
                        onIconSelected: (i) => setState(() => _selectedIcon = i),
                      ),
                      const SizedBox(height: 20),
                      BillFormInputs(
                        nameController: _nameController,
                        amountController: _amountController,
                        dueDate: _dueDate,
                        onSelectDueDate: _selectDueDate,
                      ),
                      const SizedBox(height: 20),
                      BillSwitchesCard(
                        isAutoPay: _isAutoPay,
                        isPaid: _isPaid,
                        onAutoPayChanged: (v) => setState(() => _isAutoPay = v),
                        onPaidChanged: (v) => setState(() => _isPaid = v),
                      ),
                      const SizedBox(height: 32),
                      BillSubmitButton(
                        isEditing: isEditing,
                        onPressed: _saveBill,
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
