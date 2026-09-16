import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  const AddEditBillScreen({super.key, this.billId});

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
