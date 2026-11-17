import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/models/transaction_model.dart';
import '../../../../core/providers/mock_providers.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../core/utils/ai_category_normalizer.dart';
import 'gmail_draft_item_card.dart';

class GmailDraftsPromptSheet extends ConsumerWidget {
  const GmailDraftsPromptSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const GmailDraftsPromptSheet(),
    );
  }

  static const List<Map<String, dynamic>> mockGmailDrafts = [
    {
      'title': 'Tokopedia Official Store',
      'category': 'Shopping',
      'amount': 385000.0,
      'wallet': 'BCA Rekening Utama',
      'icon': Icons.shopping_bag_outlined,
      'date': 'Hari ini, 14:20 WIB',
    },
    {
      'title': 'GoFood - Kopi & Makan Malam',
      'category': 'Food & Beverage • Food delivery',
      'amount': 48000.0,
      'wallet': 'GoPay Utama',
      'icon': Icons.fastfood_outlined,
      'date': 'Hari ini, 11:15 WIB',
    },
  ];

  void _confirmAll(BuildContext context, WidgetRef ref) {
    final wallets = ref.read(walletsProvider);
    final baseTs = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < mockGmailDrafts.length; i++) {
      final d = mockGmailDrafts[i];
      final matched = GmailDraftItemCard.matchWallet(wallets, d['wallet'] as String);
      ref.read(transactionsProvider.notifier).addTransaction(
            TransactionModel(
              id: 'tx_gmail_${baseTs}_$i',
              title: d['title'] as String,
              category: AiCategoryNormalizer.normalize(d['category'] as String),
              amount: d['amount'] as double,
              date: DateTime.now(),
              type: 'expense',
              walletId: matched?.id ?? 'w1',
              notes: 'Disinkronkan otomatis dari struk Gmail',
            ),
          );
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '2 Transaksi Gmail berhasil dicatat ke dompet Anda!',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: NeoBrutalism.teal,
      ),
    );
  }

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
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: NeoBrutalism.circleDecoration(
                      backgroundColor: const Color(0xFFF1F5F9),
                      shadowOffset: 0,
                      borderWidth: 1.5,
                    ),
                    child: const Icon(Icons.close, size: 18, color: NeoBrutalism.dark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Clarafin mendeteksi struk transaksi digital dari inbox Gmail Anda. Konfirmasi untuk mencatatnya sekarang:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF374151),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            ...mockGmailDrafts.map((d) => GmailDraftItemCard(draft: d)),
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _confirmAll(context, ref),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
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
                    Flexible(
                      child: Text(
                        'Konfirmasi Semua (+2 Transaksi)',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: NeoBrutalism.dark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                final prefillItems = GmailDraftItemCard.buildPrefillItems(
                  mockGmailDrafts,
                  ref.read(walletsProvider),
                );
                Navigator.pop(context);
                context.push('/draft/review', extra: {'prefillItems': prefillItems});
              },
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                alignment: Alignment.center,
                child: Text(
                  'Tinjau Rinci di AI Draft Review',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: NeoBrutalism.dark,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
