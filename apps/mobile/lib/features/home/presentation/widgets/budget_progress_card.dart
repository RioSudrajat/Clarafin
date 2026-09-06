import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class BudgetProgressCard extends StatelessWidget {
  const BudgetProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Keuangan Bulan Ini',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: NeoBrutalism.dark,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: NeoBrutalism.surfaceWarm,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: NeoBrutalism.shadow(yOffset: 4),
            ),
            padding: const EdgeInsets.only(top: 20, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Budget Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Budget',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: NeoBrutalism.dark,
                        ),
                      ),
                      Text(
                        '75%',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: NeoBrutalism.dark,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0.75,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: NeoBrutalism.lime,
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(9999),
                            right: Radius.circular(9999),
                          ),
                          border: Border(
                            right: BorderSide(color: Colors.black, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        color: Color(0xFF4B5563),
                      ),
                      children: [
                        TextSpan(text: 'terpakai '),
                        TextSpan(
                          text: 'Rp 7.500.000',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: NeoBrutalism.dark,
                          ),
                        ),
                        TextSpan(text: ' / Rp 10.000.000'),
                      ],
                    ),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 14, 20, 14),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.black,
                  ),
                ),

                // Bot Button + Prompt Pills (Stack: pills on layer 0, bot button on layer 1)
                SizedBox(
                  height: 48,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Layer 0: Prompt Pills
                      Positioned(
                        left: 35,
                        right: 4,
                        top: 0,
                        bottom: 0,
                        child: ClipRect(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const ClampingScrollPhysics(),
                            clipBehavior: Clip.none,
                            padding: const EdgeInsets.only(
                              left: 35,
                              right: 16,
                              top: 4,
                              bottom: 6,
                            ),
                            child: Row(
                              children: [
                                _buildAssistantPromptPill(
                                  context,
                                  'Target nabung realistis?',
                                  onTap: () => context.push('/session'),
                                ),
                                const SizedBox(width: 8),
                                _buildAssistantPromptPill(
                                  context,
                                  'Cara naikkan tabungan?',
                                  onTap: () => context.push('/session'),
                                ),
                                const SizedBox(width: 8),
                                _buildAssistantPromptPill(
                                  context,
                                  'Tips hemat akhir bulan',
                                  onTap: () => context.push('/session'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Layer 1: Bot Button
                      Positioned(
                        left: 20,
                        top: 2,
                        child: GestureDetector(
                          onTap: () => context.push('/session'),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 2),
                              boxShadow: NeoBrutalism.shadow(yOffset: 2),
                            ),
                            child: const Icon(
                              Icons.smart_toy_outlined,
                              size: 20,
                              color: NeoBrutalism.dark,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantPromptPill(BuildContext context, String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: NeoBrutalism.shadow(yOffset: 2),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: NeoBrutalism.dark,
          ),
        ),
      ),
    );
  }
}
