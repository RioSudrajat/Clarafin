import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/institutions/institution_logo_widget.dart';
import '../../../../core/institutions/institution_registry.dart';
import '../../../../core/models/wallet_model.dart';

/// Neo-Brutalist card for adding a new wallet or financial asset.
class WalletAddCard extends StatelessWidget {
  const WalletAddCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/wallet/add'),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEFFCC7),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black, width: 2.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFCCFF00),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(0, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.black, size: 26),
            ),
            const SizedBox(height: 10),
            const Text(
              'Add New',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Wallet or Asset',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Neo-Brutalist card displaying an individual wallet/account balance and status.
class WalletAccountCard extends StatelessWidget {
  final WalletModel wallet;
  final double totalBalance;
  final NumberFormat formatCurrency;

  const WalletAccountCard({
    super.key,
    required this.wallet,
    required this.totalBalance,
    required this.formatCurrency,
  });

  Color _resolveAccentColor() {
    final inst = InstitutionRegistry.findByWallet(
      institutionId: wallet.institutionId,
      name: wallet.name,
      type: wallet.type,
    );
    if (inst.brandColor != Colors.transparent && inst.brandColor != Colors.white) {
      return inst.brandColor;
    }
    switch (wallet.type) {
      case 'Bank':
        return const Color(0xFF005EAA);
      case 'E-Wallet':
        return const Color(0xFF00AED6);
      case 'Mutual Fund':
        return Colors.teal;
      case 'Stock':
        return Colors.indigo;
      case 'Crypto':
        return Colors.orange;
      case 'Cash':
        return Colors.green;
      default:
        return const Color(0xFF198696);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _resolveAccentColor();
    final progressValue = totalBalance == 0 ? 0.0 : (wallet.balance / totalBalance);

    return GestureDetector(
      onTap: () => context.push('/wallet/${wallet.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black, width: 2.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header Row: Logo & Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InstitutionLogoWidget(
                  institutionId: wallet.institutionId,
                  walletName: wallet.name,
                  walletType: wallet.type,
                  size: 38,
                  borderWidth: 2.0,
                ),
                const Icon(Icons.more_horiz, color: Colors.black87, size: 20),
              ],
            ),

            // Account Info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wallet.name,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  wallet.isAutoSync ? 'Akun Otomatis' : 'Akun Manual',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatCurrency.format(wallet.balance),
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Accent Progress Bar
                Container(
                  height: 5,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progressValue.clamp(0.06, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
