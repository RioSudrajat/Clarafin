import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/daily_pnl_provider.dart';
import '../../../../core/providers/mock_providers.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import 'sub_wallet_pills_row.dart';

class TotalBalanceHeroCard extends ConsumerWidget {
  final double progress;
  final bool obscureBalance;
  final VoidCallback onToggleObscure;

  const TotalBalanceHeroCard({
    super.key,
    required this.progress,
    required this.obscureBalance,
    required this.onToggleObscure,
  });

  double _evaluateProgressInterval(
    double progress,
    double begin,
    double end, {
    Curve curve = Curves.easeInOut,
  }) {
    if (progress <= begin) return 0.0;
    if (progress >= end) return 1.0;
    final t = (progress - begin) / (end - begin);
    return curve.transform(t);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletsProvider);
    final dailyPnl = ref.watch(dailyPnlProvider);
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final totalBalance = wallets.fold<double>(0, (sum, w) => sum + w.balance);

    // ── 1. Curtain Animation (Delay 0.10, moves upward -32px and fades out by 0.52) ──
    final curtainProgress = _evaluateProgressInterval(progress, 0.10, 0.52, curve: Curves.easeIn);
    final curtainOpacity = (1.0 - curtainProgress).clamp(0.0, 1.0);
    final curtainTranslationY = -32.0 * curtainProgress;

    // ── 2. Collapsed Action Button Animation (Slides from right +16px and fades in 0.35 to 0.75) ──
    final actionProgress = _evaluateProgressInterval(progress, 0.35, 0.75, curve: Curves.easeOut);
    final actionOpacity = actionProgress.clamp(0.0, 1.0);
    final actionTranslationX = 16.0 * (1.0 - actionProgress);

    // ── 3. Anchored Persistent Balance Amount ──
    final nominalTop = lerpDouble(40.0, 19.0, progress)!;
    const nominalLeft = 18.0;
    final nominalFontSize = lerpDouble(30.0, 16.5, progress)!;
    final rpFontSize = lerpDouble(15.0, 13.0, progress)!;
    final eyeIconSize = lerpDouble(17.0, 15.0, progress)!;
    final nominalRightBound = lerpDouble(75.0, 125.0, progress)!;

    final formattedAmount = obscureBalance
        ? '••••••••'
        : currencyFormat.format(totalBalance).replaceAll('Rp ', '');

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Lime Balance Card Body
        Container(
          width: double.infinity,
          height: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: NeoBrutalism.lime,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: NeoBrutalism.shadow(yOffset: lerpDouble(4.0, 2.0, progress)!),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Curtain Layer: TOTAL BALANCE label, PnL pill, Sub-wallets ──
              if (curtainOpacity > 0.001)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 198,
                  child: IgnorePointer(
                    ignoring: curtainOpacity < 0.5,
                    child: Opacity(
                      opacity: curtainOpacity,
                      child: Transform.translate(
                        offset: Offset(0, curtainTranslationY),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 18, bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Row 1: TOTAL BALANCE
                                    const Text(
                                      'TOTAL BALANCE',
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                        color: NeoBrutalism.dark,
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    // Space occupied by Row 2 (Rp + 30px nominal text height)
                                    const SizedBox(height: 38),

                                    const SizedBox(height: 10),

                                    // Row 3: Dynamic Daily PnL Indicator Pill
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.92),
                                        borderRadius: BorderRadius.circular(9999),
                                        border: Border.all(color: Colors.black, width: 2),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'Hari ini ',
                                            style: TextStyle(
                                              fontFamily: 'Plus Jakarta Sans',
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: NeoBrutalism.dark,
                                            ),
                                          ),
                                          Icon(
                                            dailyPnl.isPositive ? Icons.trending_up : Icons.trending_down,
                                            size: 13,
                                            color: dailyPnl.isPositive ? const Color(0xFF10B981) : const Color(0xFFDC2626),
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${dailyPnl.formattedPnl} (${dailyPnl.formattedPercentage})',
                                            style: TextStyle(
                                              fontFamily: 'Plus Jakarta Sans',
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: dailyPnl.isPositive ? const Color(0xFF10B981) : const Color(0xFFDC2626),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Row 4: Sub-wallets Horizontal List
                              const SubWalletPillsRow(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // ── Anchored Persistent Nominal: Rp [Nominal] [Eye Icon on Right] ──
              Positioned(
                top: nominalTop,
                left: nominalLeft,
                right: nominalRightBound,
                child: GestureDetector(
                  onTap: onToggleObscure,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Rp ',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: rpFontSize,
                          fontWeight: FontWeight.w700,
                          color: NeoBrutalism.dark,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          formattedAmount,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: nominalFontSize,
                            fontWeight: FontWeight.w900,
                            letterSpacing: lerpDouble(-1.4, -0.8, progress)!,
                            color: NeoBrutalism.dark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        obscureBalance ? Icons.visibility_off : Icons.visibility,
                        size: eyeIconSize,
                        color: NeoBrutalism.dark,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Collapsed Action Button: Portfolio > (Slides in from right) ──
              if (actionOpacity > 0.001)
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 16,
                  child: IgnorePointer(
                    ignoring: actionOpacity < 0.5,
                    child: Opacity(
                      opacity: actionOpacity,
                      child: Transform.translate(
                        offset: Offset(actionTranslationX, 0),
                        child: Center(
                          child: GestureDetector(
                            onTap: () => context.push('/reporting'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(9999),
                                border: Border.all(color: Colors.black, width: 2),
                                boxShadow: NeoBrutalism.shadow(yOffset: 1.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'Portfolio',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  Icon(Icons.chevron_right, size: 14, color: Colors.black),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ── Portfolio Pill Button (Protruding TOP-RIGHT in Expanded State) ──
        if (curtainOpacity > 0.001)
          Positioned(
            top: 15,
            right: -10,
            child: IgnorePointer(
              ignoring: curtainOpacity < 0.5,
              child: Opacity(
                opacity: curtainOpacity,
                child: Transform.translate(
                  offset: Offset(0, curtainTranslationY),
                  child: GestureDetector(
                    onTap: () => context.push('/reporting'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(color: Colors.black, width: 2),
                        boxShadow: NeoBrutalism.shadow(yOffset: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.pie_chart_outline, size: 14, color: Colors.black),
                          SizedBox(width: 4),
                          Text(
                            'Portfolio',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
