import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
