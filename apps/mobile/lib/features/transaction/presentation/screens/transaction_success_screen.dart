import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../core/providers/mock_providers.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../widgets/transaction_receipt_card.dart';
import '../widgets/transaction_success_action_buttons.dart';

class TransactionSuccessScreen extends ConsumerStatefulWidget {
  final String? returnTo;
  final TransactionModel? transaction;

  const TransactionSuccessScreen({
    super.key,
    this.returnTo,
    this.transaction,
  });

  @override
  ConsumerState<TransactionSuccessScreen> createState() => _TransactionSuccessScreenState();
}

class _TransactionSuccessScreenState extends ConsumerState<TransactionSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletsProvider);
    final walletName = widget.transaction != null
        ? wallets
            .firstWhere(
              (w) => w.id == widget.transaction!.walletId,
              orElse: () => wallets.first,
            )
            .name
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: NeoBrutalism.lime,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: NeoBrutalism.borderBlack,
                                width: 2.0,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: NeoBrutalism.borderBlack,
                                  offset: Offset(0, 4),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Transform.scale(
                                scale: _checkAnimation.value,
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: NeoBrutalism.dark,
                                  size: 46,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Transaksi Berhasil!',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: NeoBrutalism.dark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Transaksi Anda telah dicatat\ndan saldo otomatis diperbarui.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: NeoBrutalism.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TransactionReceiptCard(
                      transaction: widget.transaction,
                      walletName: walletName,
                    ),
                  ],
                ),
              ),
            ),
            TransactionSuccessActionButtons(returnTo: widget.returnTo),
          ],
        ),
      ),
    );
  }
}
