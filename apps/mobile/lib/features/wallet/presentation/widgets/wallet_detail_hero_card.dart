import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/institutions/institution_logo_widget.dart';
import '../../../../core/models/wallet_model.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class WalletDetailHeroCard extends StatelessWidget {
  final WalletModel wallet;
  final VoidCallback onSyncPressed;

  const WalletDetailHeroCard({
    super.key,
    required this.wallet,
    required this.onSyncPressed,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: NeoBrutalism.cardDecoration(
        backgroundColor: Colors.white,
        borderRadius: NeoBrutalism.radiusXl,
        shadowOffset: 4.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InstitutionLogoWidget(
                institutionId: wallet.institutionId,
                walletName: wallet.name,
                walletType: wallet.type,
                size: 46,
                borderWidth: 2.0,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wallet.name,
                      style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900, color: NeoBrutalism.dark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildBadge(wallet.type, const Color(0xFFF3F4F6), NeoBrutalism.dark),
                        if (wallet.isAutoSync) ...[
                          const SizedBox(width: 6),
                          _buildAutoSyncBadge(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Saldo Saat Ini',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: NeoBrutalism.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            currencyFormat.format(wallet.balance),
            style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w900, color: NeoBrutalism.dark, letterSpacing: -0.5),
          ),
          if (wallet.returnPercentage != null || wallet.dividendDropDate != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (wallet.returnPercentage != null) _buildReturnBadge(),
                if (wallet.dividendDropDate != null) _buildDividendBadge(),
              ],
            ),
          ],
          if (wallet.isAutoSync) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onSyncPressed,
              child: Container(
                width: double.infinity,
                height: 52,
                alignment: Alignment.center,
                decoration: NeoBrutalism.cardDecoration(
                  backgroundColor: NeoBrutalism.lime,
                  borderRadius: NeoBrutalism.radiusSm,
                  shadowOffset: 3.0,
                  borderWidth: 2.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sync_rounded, size: 20, color: NeoBrutalism.dark),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'SINKRONISASI SEKARANG',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: NeoBrutalism.dark,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textHeightBehavior: const TextHeightBehavior(
                          applyHeightToFirstAscent: false,
                          applyHeightToLastDescent: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(NeoBrutalism.radiusPill), border: Border.all(color: NeoBrutalism.borderBlack)),
      child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: text)),
    );
  }

  Widget _buildAutoSyncBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: NeoBrutalism.lime, borderRadius: BorderRadius.circular(NeoBrutalism.radiusPill), border: Border.all(color: NeoBrutalism.borderBlack)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 12, color: NeoBrutalism.dark),
          const SizedBox(width: 2),
          Text('AUTO-SYNC', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w900, color: NeoBrutalism.dark)),
        ],
      ),
    );
  }

  Widget _buildReturnBadge() {
    final isPos = wallet.returnPercentage! >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: isPos ? const Color(0xFFE5F9E0) : const Color(0xFFFFDAD6), borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm), border: Border.all(color: NeoBrutalism.borderBlack, width: 1.5)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isPos ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 14, color: NeoBrutalism.dark),
          const SizedBox(width: 4),
          Text('Return: ${wallet.returnPercentage!.toStringAsFixed(2)}%', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: NeoBrutalism.dark)),
        ],
      ),
    );
  }

  Widget _buildDividendBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFFCF9F8), borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm), border: Border.all(color: NeoBrutalism.borderBlack, width: 1.5)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_rounded, size: 12, color: NeoBrutalism.dark),
          const SizedBox(width: 4),
          Text('Dividen: ${DateFormat('d MMM yyyy').format(wallet.dividendDropDate!)}', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: NeoBrutalism.dark)),
        ],
      ),
    );
  }
}
