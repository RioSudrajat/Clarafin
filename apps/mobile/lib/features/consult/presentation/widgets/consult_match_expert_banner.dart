import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class ConsultMatchExpertBanner extends StatelessWidget {
  const ConsultMatchExpertBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: NeoBrutalism.mint,
        borderRadius: BorderRadius.circular(NeoBrutalism.radiusXl),
        border: NeoBrutalism.border(width: 2.0),
        boxShadow: NeoBrutalism.shadow(yOffset: 4.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: NeoBrutalism.lime,
                  borderRadius: BorderRadius.circular(NeoBrutalism.radiusPill),
                  border: NeoBrutalism.border(width: 1.5),
                  boxShadow: NeoBrutalism.shadow(yOffset: 1.5),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 12, color: NeoBrutalism.dark),
                    SizedBox(width: 4),
                    Text(
                      'REKOMENDASI AI',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: NeoBrutalism.dark,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.handshake_outlined,
                size: 20,
                color: NeoBrutalism.dark,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Title
          const Text(
            'Bingung cari konsultan yang cocok?',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: NeoBrutalism.dark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          // Subtitle
          const Text(
            'Jawab beberapa pertanyaan singkat, kami akan mencocokkan konsultan berlisensi yang paling sesuai dengan preferensimu.',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          // CTA Button
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => context.push('/match-expert'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: NeoBrutalism.lime,
                  borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
                  border: NeoBrutalism.border(width: 2.0),
                  boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Coba Fitur Match Expert',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: NeoBrutalism.dark,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, size: 16, color: NeoBrutalism.dark),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
