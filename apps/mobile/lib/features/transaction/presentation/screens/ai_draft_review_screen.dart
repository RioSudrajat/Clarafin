import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../core/providers/mock_providers.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../core/utils/thousand_separator_formatter.dart';

class AiDraftReviewScreen extends ConsumerStatefulWidget {
  const AiDraftReviewScreen({super.key});

  @override
  ConsumerState<AiDraftReviewScreen> createState() => _AiDraftReviewScreenState();
}

class _AiDraftReviewScreenState extends ConsumerState<AiDraftReviewScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  String _selectedCategory = 'Makanan';
  String? _selectedWalletId;

  final List<String> _categories = [
    'Makanan',
    'Transportasi',
    'Belanja',
    'Tagihan',
    'Hiburan',
    'Kesehatan',
  ];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: '55.000');
    _noteController = TextEditingController(text: 'Makan Malam HokBen');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _confirmAndSave() {
    final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(amountText) ?? 0.0;
    final note = _noteController.text.trim();

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nominal transaksi tidak valid.',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
          backgroundColor: NeoBrutalism.dark,
        ),
      );
      return;
    }

    final wallets = ref.read(walletsProvider);
    final walletId = _selectedWalletId ?? (wallets.isNotEmpty ? wallets.first.id : 'w_main');

    final tx = TransactionModel(
      id: 'tx_ai_${DateTime.now().millisecondsSinceEpoch}',
      title: note.isNotEmpty ? note : 'Transaksi Struk AI',
      category: _selectedCategory,
      amount: amount,
      date: DateTime.now(),
      type: 'expense',
      walletId: walletId,
      notes: 'Dipindai otomatis via AI Receipt Scanner',
    );

    ref.read(transactionsProvider.notifier).addTransaction(tx);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.black, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Transaksi Rp ${amount.toInt()} berhasil disimpan!',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: NeoBrutalism.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );

    context.go('/transaction/history');
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletsProvider);
    if (_selectedWalletId == null && wallets.isNotEmpty) {
      _selectedWalletId = wallets.first.id;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F758A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: NeoBrutalism.brandGradient,
        ),
        child: Column(
          children: [
            // Pinned Neo-Brutalist Header
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => context.pop(),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: NeoBrutalism.border(width: 2.0),
                          boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
                        ),
                        child: const Center(
                          child: Icon(Icons.arrow_back_rounded, size: 22, color: NeoBrutalism.dark),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Review Transaksi AI',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main White Container with Curvature
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(
                    top: BorderSide(color: Colors.black, width: 2.0),
                    left: BorderSide(color: Colors.black, width: 2.0),
                    right: BorderSide(color: Colors.black, width: 2.0),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // AI Receipt Detection Banner
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: NeoBrutalism.surfaceWarm,
                            borderRadius: BorderRadius.circular(16),
                            border: NeoBrutalism.border(width: 2.0),
                            boxShadow: NeoBrutalism.shadow(yOffset: 2.5),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: NeoBrutalism.primary,
                                  shape: BoxShape.circle,
                                  border: NeoBrutalism.border(width: 1.5),
                                ),
                                child: const Icon(Icons.auto_awesome_rounded, size: 20, color: Colors.black),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '1 Transaksi Terdeteksi',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'OCR mendeteksi struk belanja HokBen. Silakan sesuaikan dompet dan kategori sebelum menyimpan.',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: NeoBrutalism.textMuted,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Form Card (Neo-Brutalism with 2px border & 4px hard shadow)
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: NeoBrutalism.border(width: 2.0),
                            boxShadow: NeoBrutalism.shadow(yOffset: 4.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Amount Field
                              Text(
                                'Nominal Transaksi',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                decoration: BoxDecoration(
                                  color: NeoBrutalism.surfaceWarm,
                                  borderRadius: BorderRadius.circular(12),
                                  border: NeoBrutalism.border(width: 1.8),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'Rp ',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: _amountController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          ThousandSeparatorFormatter(),
                                        ],
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black,
                                        ),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          hintText: '0',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Merchant / Note Field
                              Text(
                                'Catatan / Merchant',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: NeoBrutalism.border(width: 1.8),
                                ),
                                child: TextField(
                                  controller: _noteController,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Nama pengeluaran...',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Category Selection
                              Text(
                                'Kategori Pengeluaran',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _categories.map((cat) {
                                  final isSelected = _selectedCategory == cat;
                                  return GestureDetector(
                                    onTap: () => setState(() => _selectedCategory = cat),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: isSelected ? NeoBrutalism.primary : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: NeoBrutalism.border(width: 1.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black,
                                            offset: isSelected ? const Offset(0, 2) : const Offset(0, 1),
                                            blurRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        cat,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 18),

                              // Wallet Selection
                              Text(
                                'Dompet Sumber Dana',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (wallets.isEmpty)
                                Text(
                                  'Belum ada dompet. Transaksi akan dicatat ke dompet default.',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: NeoBrutalism.textMuted),
                                )
                              else
                                Column(
                                  children: wallets.map((wallet) {
                                    final isSelected = _selectedWalletId == wallet.id;
                                    return GestureDetector(
                                      onTap: () => setState(() => _selectedWalletId = wallet.id),
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isSelected ? NeoBrutalism.primaryLight : Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: NeoBrutalism.border(width: 1.8),
                                          boxShadow: NeoBrutalism.shadow(yOffset: 1.5),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                              size: 18,
                                              color: Colors.black,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                wallet.name,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              'Rp ${wallet.balance.toInt()}',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: NeoBrutalism.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: GestureDetector(
                                onTap: () => context.pop(),
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: NeoBrutalism.coral,
                                    borderRadius: BorderRadius.circular(14),
                                    border: NeoBrutalism.border(width: 2.0),
                                    boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Batalkan',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFFBA1A1A),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: GestureDetector(
                                onTap: _confirmAndSave,
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: NeoBrutalism.primary,
                                    borderRadius: BorderRadius.circular(14),
                                    border: NeoBrutalism.border(width: 2.0),
                                    boxShadow: NeoBrutalism.shadow(yOffset: 2.5),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Konfirmasi & Simpan',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
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
