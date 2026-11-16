import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../core/providers/mock_providers.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class GmailDraftsPromptSheet extends ConsumerWidget {
  const GmailDraftsPromptSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const GmailDraftsPromptSheet(),
    );
  }

  static const List<Map<String, dynamic>> mockGmailDrafts = [
    {
      'title': 'Tokopedia Official Store',
      'category': 'Belanja',
      'amount': 385000.0,
      'wallet': 'BCA Rekening Utama',
      'icon': Icons.shopping_bag_outlined,
      'date': 'Hari ini, 14:20 WIB',
    },
    {
      'title': 'GoFood - Kopi & Makan Malam',
      'category': 'Makanan',
      'amount': 48000.0,
      'wallet': 'GoPay Utama',
      'icon': Icons.fastfood_outlined,
      'date': 'Hari ini, 11:15 WIB',
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Colors.black, width: 2.5),
          left: BorderSide(color: Colors.black, width: 2.0),
          right: BorderSide(color: Colors.black, width: 2.0),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(10),
                    border: NeoBrutalism.border(width: 1.5),
                  ),
                  child: const Icon(Icons.mail_rounded, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SINKRONISASI RESI GMAIL',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: NeoBrutalism.teal,
                        ),
                      ),
                      Text(
                        '2 Draf Transaksi Baru',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: NeoBrutalism.dark,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      border: NeoBrutalism.border(width: 1.5),
                    ),
                    child: const Icon(Icons.close, size: 16, color: NeoBrutalism.dark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'AI Clarafin mendeteksi struk transaksi digital dari inbox Gmail Anda. Konfirmasi untuk mencatatnya sekarang:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: NeoBrutalism.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Drafts List
            ...mockGmailDrafts.map((d) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: NeoBrutalism.border(width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: NeoBrutalism.mint,
                        borderRadius: BorderRadius.circular(8),
                        border: NeoBrutalism.border(width: 1.5),
                      ),
                      child: Icon(d['icon'] as IconData, size: 18, color: NeoBrutalism.dark),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d['title'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: NeoBrutalism.dark,
                            ),
                          ),
                          Text(
                            '${d['wallet']} • ${d['date']}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: NeoBrutalism.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Rp ${(d['amount'] as double).toInt()}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: NeoBrutalism.dark,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 14),

            // Actions
            GestureDetector(
              onTap: () {
                final wallets = ref.read(walletsProvider);
                final defaultWalletId = wallets.isNotEmpty ? wallets.first.id : 'w1';

                for (final d in mockGmailDrafts) {
                  final tx = TransactionModel(
                    id: 'tx_gmail_${DateTime.now().millisecondsSinceEpoch}_${d['title'].hashCode}',
                    title: d['title'] as String,
                    category: d['category'] as String,
                    amount: d['amount'] as double,
                    date: DateTime.now(),
                    type: 'expense',
                    walletId: defaultWalletId,
                    notes: 'Disinkronkan otomatis dari struk Gmail',
                  );
                  ref.read(transactionsProvider.notifier).addTransaction(tx);
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '2 Transaksi Gmail berhasil dicatat ke dompet Anda!',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                    ),
                    backgroundColor: NeoBrutalism.teal,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: NeoBrutalism.lime,
                  borderRadius: BorderRadius.circular(12),
                  border: NeoBrutalism.border(width: 2.0),
                  boxShadow: NeoBrutalism.shadow(yOffset: 3.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 18, color: NeoBrutalism.dark),
                    const SizedBox(width: 8),
                    Text(
                      'Konfirmasi Semua (+2 Transaksi)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: NeoBrutalism.dark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                context.push('/transaction/ai-draft-review');
              },
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    'Tinjau Rinci di AI Draft Review',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: NeoBrutalism.dark,
                      decoration: TextDecoration.underline,
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
