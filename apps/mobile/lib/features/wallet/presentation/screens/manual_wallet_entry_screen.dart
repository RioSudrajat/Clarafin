import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/models/wallet_model.dart';
import '../../../../core/providers/mock_providers.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../widgets/manual_wallet_header_card.dart';
import '../widgets/manual_wallet_inputs.dart';
import '../widgets/manual_wallet_investment_fields.dart';
import '../widgets/manual_wallet_submit_button.dart';
import '../widgets/manual_wallet_type_selector.dart';

class ManualWalletEntryScreen extends ConsumerStatefulWidget {
  final String? institutionId;
  final String institutionName;
  final String institutionType;

  const ManualWalletEntryScreen({
    super.key,
    this.institutionId,
    required this.institutionName,
    required this.institutionType,
  });

  @override
  ConsumerState<ManualWalletEntryScreen> createState() => _ManualWalletEntryScreenState();
}

class _ManualWalletEntryScreenState extends ConsumerState<ManualWalletEntryScreen> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _returnController = TextEditingController();
  late String _selectedType;
  DateTime? _dividendDate;

  bool get isInvestment =>
      ['Mutual Fund', 'Stock', 'Crypto', 'Bond', 'Deposit'].contains(_selectedType);
  bool get isVolatile => _selectedType == 'Crypto' || _selectedType == 'Stock';

  @override
  void initState() {
    super.initState();
    _selectedType = widget.institutionType.isNotEmpty ? widget.institutionType : 'Bank';
    _nameController.text = widget.institutionName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _returnController.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dividendDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _dividendDate = picked);
  }

  void _saveWallet() {
    final name = _nameController.text.trim();
    final balanceRaw = _balanceController.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (name.isEmpty || balanceRaw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama dompet dan saldo wajib diisi'),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final balance = double.tryParse(balanceRaw) ?? 0.0;
    double? returnPct;
    if (isInvestment && _returnController.text.isNotEmpty) {
      returnPct = double.tryParse(_returnController.text.replaceAll(',', '.'));
    }

    final newWallet = WalletModel(
      id: 'w_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: _selectedType,
      balance: balance,
      isAutoSync: false,
      returnPercentage: returnPct,
      dividendDropDate: _dividendDate,
      isVolatile: isVolatile,
      institutionId: widget.institutionId,
    );

    ref.read(walletsProvider.notifier).addWallet(newWallet);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Dompet "$name" berhasil disimpan!',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: NeoBrutalism.dark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black, width: 1.5),
        ),
      ),
    );

    Navigator.pop(context);
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Input Dompet Manual',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: NeoBrutalism.dark,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: NeoBrutalism.circleDecoration(),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: NeoBrutalism.dark, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          ManualWalletHeaderCard(
            institutionId: widget.institutionId,
            institutionName: widget.institutionName,
            selectedType: _selectedType,
          ),
          const SizedBox(height: 16),
          const WalletFieldLabel('Kategori Aset / Dompet'),
          ManualWalletTypeSelector(
            selectedType: _selectedType,
            onTypeSelected: (type) => setState(() => _selectedType = type),
          ),
          const SizedBox(height: 16),
          ManualWalletInputs(
            nameController: _nameController,
            balanceController: _balanceController,
          ),
          if (isInvestment)
            ManualWalletInvestmentFields(
              returnController: _returnController,
              dividendDate: _dividendDate,
              isVolatile: isVolatile,
              onPickDate: _pickDate,
            ),
          const SizedBox(height: 32),
          ManualWalletSubmitButton(onTap: _saveWallet),
        ],
      ),
    );
  }
}
