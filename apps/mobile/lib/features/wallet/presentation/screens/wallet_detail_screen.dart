import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/models/wallet_model.dart';
import '../../../../core/providers/mock_providers.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../widgets/wallet_detail_chart_card.dart';
import '../widgets/wallet_detail_delete_dialog.dart';
import '../widgets/wallet_detail_hero_card.dart';
import '../widgets/wallet_detail_mutations_section.dart';

class WalletDetailScreen extends ConsumerWidget {
  final String walletId;

  const WalletDetailScreen({
    super.key,
    required this.walletId,
  });

  static const List<String> colorSwatches = [
    '#0F758A', // Teal
    '#003B73', // Navy
    '#D35400', // Tangerine
    '#4C2A86', // Violet
    '#1E5128', // Emerald
    '#2C2510', // Dark Bronze
    '#0081A7', // Cyan
    '#111827', // Midnight
  ];

  void _showColorPickerSheet(BuildContext context, WidgetRef ref, WalletModel wallet) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: Colors.black, width: 2.0),
            left: BorderSide(color: Colors.black, width: 2.0),
            right: BorderSide(color: Colors.black, width: 2.0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ganti Warna Kartu Dompet',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              'Pilih tema palet warna untuk membedakan kartu di tumpukan dompetmu.',
              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: NeoBrutalism.textMuted),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: colorSwatches.map((hex) {
                final color = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                final isCurrent = wallet.customColorHex == hex;

                return GestureDetector(
                  onTap: () {
                    final updated = wallet.copyWith(customColorHex: hex);
                    ref.read(walletsProvider.notifier).updateWallet(updated);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Warna kartu berhasil diperbarui!'),
                        backgroundColor: NeoBrutalism.dark,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCurrent ? Colors.black : Colors.black26,
                        width: isCurrent ? 3.0 : 1.5,
                      ),
                      boxShadow: isCurrent ? NeoBrutalism.shadow(yOffset: 2.0) : null,
                    ),
                    child: isCurrent
                        ? const Center(child: Icon(Icons.check_rounded, color: Colors.white, size: 22))
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletsProvider);
    final transactions = ref.watch(transactionsProvider);

    final wallet = wallets.firstWhere(
      (w) => w.id == walletId,
      orElse: () => wallets.isNotEmpty ? wallets.first : wallets.first,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Detail Akun',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: NeoBrutalism.dark,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
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
        actions: [
          // Color Swatch Button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: NeoBrutalism.circleDecoration(
                backgroundColor: NeoBrutalism.lime,
              ),
              child: IconButton(
                icon: const Icon(Icons.palette_outlined, color: Colors.black, size: 20),
                onPressed: () => _showColorPickerSheet(context, ref, wallet),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: NeoBrutalism.circleDecoration(
                backgroundColor: const Color(0xFFFFDAD6),
              ),
              child: IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
                onPressed: () {
                  WalletDetailDeleteDialog.show(
                    context: context,
                    wallet: wallet,
                    onConfirmDelete: () {
                      ref.read(walletsProvider.notifier).deleteWallet(wallet.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${wallet.name} berhasil dihapus'),
                          backgroundColor: NeoBrutalism.dark,
                        ),
                      );
                      context.pop();
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WalletDetailHeroCard(
              wallet: wallet,
              onSyncPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: NeoBrutalism.lime, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Saldo ${wallet.name} berhasil disinkronkan!',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    backgroundColor: NeoBrutalism.dark,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            WalletDetailChartCard(currentBalance: wallet.balance),
            const SizedBox(height: 24),
            WalletDetailMutationsSection(
              walletId: wallet.id,
              transactions: transactions,
            ),
          ],
        ),
      ),
    );
  }
}
