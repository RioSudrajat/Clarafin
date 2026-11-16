import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/wallet_model.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import 'wallet_atm_card.dart';

class WalletStackedDeck extends StatefulWidget {
  final List<WalletModel> wallets;
  final NumberFormat? formatCurrency;
  final String Function(double)? formatAmount;

  const WalletStackedDeck({
    super.key,
    required this.wallets,
    this.formatCurrency,
    this.formatAmount,
  });

  @override
  State<WalletStackedDeck> createState() => _WalletStackedDeckState();
}

class _WalletStackedDeckState extends State<WalletStackedDeck> {
  int? _focusedIndex;

  void _onCardTap(int index) {
    setState(() {
      if (_focusedIndex == index) {
        // Tap on already selected card unselects it
        _focusedIndex = null;
      } else {
        // Tap on card brings it to the front
        _focusedIndex = index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final wallets = widget.wallets;
    if (wallets.isEmpty) {
      return _buildEmptySlot(context);
    }

    // Reset focused index if it exceeds list bounds
    if (_focusedIndex != null && _focusedIndex! >= wallets.length) {
      _focusedIndex = null;
    }

    // Each card is 200px tall. Header exposure is ~62px.
    const cardHeight = 200.0;
    const headerExposure = 62.0;
    final totalStackHeight = cardHeight + ((wallets.length - 1) * headerExposure) + 50.0;

    // Render non-focused cards first, and focused card LAST (highest z-index on top!)
    final stackIndices = List.generate(wallets.length, (i) => i);
    if (_focusedIndex != null) {
      stackIndices.remove(_focusedIndex);
      stackIndices.add(_focusedIndex!);
    }

    return Column(
      children: [
        SizedBox(
          height: totalStackHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: stackIndices.map((index) {
              final wallet = wallets[index];
              final isFront = _focusedIndex == index;

              // Calculate vertical offset with clean peek exposure
              double topOffset = index * headerExposure;
              if (_focusedIndex != null) {
                if (index > _focusedIndex!) {
                  topOffset += 36.0; // Push lower cards down to reveal full focused card
                } else if (index == _focusedIndex! && index == wallets.length - 1 && wallets.length > 1) {
                  topOffset -= 12.0; // Float bottom card up slightly for clear visibility
                }
              }

              return AnimatedPositioned(
                key: ValueKey(wallet.id),
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                top: topOffset,
                left: 0,
                right: 0,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  scale: isFront ? 1.03 : 1.0,
                  child: WalletAtmCard(
                    wallet: wallet,
                    isFront: isFront,
                    formatCurrency: widget.formatCurrency,
                    formatAmount: widget.formatAmount,
                    onTap: () => _onCardTap(index),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // "+ Tambah Kartu Baru" Slot at the bottom of the deck
        GestureDetector(
          onTap: () => context.push('/wallet/add'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFFCC7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black, width: 2.0),
              boxShadow: NeoBrutalism.shadow(yOffset: 2.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: NeoBrutalism.lime,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded, size: 20, color: Colors.black),
                ),
                const SizedBox(width: 8),
                Text(
                  'Tambah Dompet / Kartu Baru',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySlot(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/wallet/add'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black, width: 2.0),
          boxShadow: NeoBrutalism.shadow(yOffset: 3.0),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: NeoBrutalism.lime,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_wallet_outlined, size: 24, color: Colors.black),
            ),
            const SizedBox(height: 12),
            Text(
              'Belum Ada Akun / Kartu',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tekan untuk menambahkan rekening bank atau dompet digital pertamamu.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
