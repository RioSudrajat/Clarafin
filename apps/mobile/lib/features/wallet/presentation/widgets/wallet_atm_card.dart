import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/institutions/institution_logo_widget.dart';
import '../../../../core/institutions/institution_registry.dart';
import '../../../../core/models/wallet_model.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class WalletAtmCard extends StatelessWidget {
  final WalletModel wallet;
  final bool isFront;
  final NumberFormat? formatCurrency;
  final String Function(double)? formatAmount;
  final VoidCallback? onTap;

  const WalletAtmCard({
    super.key,
    required this.wallet,
    this.isFront = false,
    this.formatCurrency,
    this.formatAmount,
    this.onTap,
  });

  Color _resolveCardColor() {
    if (wallet.customColorHex != null && wallet.customColorHex!.isNotEmpty) {
      try {
        final hex = wallet.customColorHex!.replaceAll('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }

    final lower = (wallet.institutionId ?? wallet.name).toLowerCase();
    if (lower.contains('bca')) return const Color(0xFF003B73);
    if (lower.contains('mandiri')) return const Color(0xFF002B5B);
    if (lower.contains('bni')) return const Color(0xFFD35400);
    if (lower.contains('bri')) return const Color(0xFF004080);
    if (lower.contains('bsi')) return const Color(0xFF006A68);
    if (lower.contains('gopay')) return const Color(0xFF0081A7);
    if (lower.contains('dana')) return const Color(0xFF108EE9);
    if (lower.contains('ovo')) return const Color(0xFF4C2A86);
    if (lower.contains('binance')) return const Color(0xFF2C2510);
    if (lower.contains('phantom')) return const Color(0xFF382B5F);
    if (lower.contains('metamask')) return const Color(0xFF5A2A08);
    if (lower.contains('bibit')) return const Color(0xFF1E5128);
    if (lower.contains('stockbit')) return const Color(0xFF0E4947);
    if (lower.contains('tunai') || lower.contains('cash')) return const Color(0xFF2D6A4F);

    return const Color(0xFF1F2937);
  }

  bool get _isBankWallet => wallet.type == 'Bank';

  @override
  Widget build(BuildContext context) {
    final cardColor = _resolveCardColor();
    final inst = InstitutionRegistry.findByWallet(
      institutionId: wallet.institutionId,
      name: wallet.name,
      type: wallet.type,
    );

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: () => context.push('/wallet/${wallet.id}'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black, width: 2.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              offset: isFront ? const Offset(0, 6) : const Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Subtle background geometric accents
              Positioned(
                right: -30,
                bottom: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),

              // Card Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Row: Logo/Name + Chip/Sync Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            InstitutionLogoWidget(
                              institution: inst,
                              size: 32,
                              showBorder: true,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  wallet.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                Text(
                                  _isBankWallet ? 'DEBIT / ATM' : wallet.type.toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white70,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Auto-Sync or Manual Pill Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: wallet.isAutoSync ? NeoBrutalism.lime : Colors.black38,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.black, width: 1.0),
                          ),
                          child: Text(
                            wallet.isAutoSync ? 'AUTO-SYNC' : 'MANUAL',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: wallet.isAutoSync ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Middle Row: EMV Chip Graphic + Contactless Icon + Front Action Button
                    Row(
                      children: [
                        // Metallic EMV Chip
                        Container(
                          width: 38,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFF39C12), Color(0xFFFFE066)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.black, width: 1.2),
                          ),
                          child: Center(
                            child: Container(
                              width: 22,
                              height: 14,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black38, width: 0.8),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.contactless_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                        const Spacer(),
                        if (isFront)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => context.push('/wallet/${wallet.id}'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: NeoBrutalism.lime,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.black, width: 1.5),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black, offset: Offset(0, 2), blurRadius: 0),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Lihat Detail',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.black),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Bottom Row: Saldo + Network Logo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SALDO AKTIF',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white60,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatAmount != null
                                  ? formatAmount!(wallet.balance)
                                  : (formatCurrency?.format(wallet.balance) ?? 'Rp ${wallet.balance.toInt()}'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        // Network Logo: GPN / Mastercard / Web3
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.black, width: 1.0),
                          ),
                          child: Text(
                            _isBankWallet
                                ? 'GPN'
                                : (wallet.type == 'Investasi' ? 'KSEI' : 'QRIS'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
