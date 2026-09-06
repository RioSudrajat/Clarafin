import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../domain/models/match_expert_models.dart';
import 'match_expert_option_card.dart';
import 'match_expert_orb_header.dart';

class MatchExpertQuestionScaffold extends StatelessWidget {
  final MatchExpertQuestion question;
  final MatchExpertAnswerState answers;
  final void Function(String optionId) onSelectSingle;
  final void Function(String optionId) onToggleMulti;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final bool canProceed;

  const MatchExpertQuestionScaffold({
    super.key,
    required this.question,
    required this.answers,
    required this.onSelectSingle,
    required this.onToggleMulti,
    required this.onNext,
    required this.onBack,
    required this.canProceed,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isMulti = question.selectionType == SelectionType.multi;
    final singleAnswer = answers.getSingle(question.id);
    final multiAnswer = answers.getMulti(question.id);

    return Column(
      children: [
        // Top glowing orb & back button
        MatchExpertOrbHeader(onBack: onBack),

        // Scrollable question area
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Step pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Langkah ${question.stepIndex} dari 12',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Title
                Text(
                  question.title,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 6),

                // Subtitle
                Text(
                  question.subtitle,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFE2E8F0),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 24),

                // Options list / grid
                if (question.isGrid)
                  GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.18,
                    ),
                    itemCount: question.options.length,
                    itemBuilder: (context, index) {
                      final option = question.options[index];
                      final isSelected = isMulti
                          ? multiAnswer.contains(option.id)
                          : singleAnswer == option.id;

                      return MatchExpertOptionCard(
                        option: option,
                        isSelected: isSelected,
                        selectionType: question.selectionType,
                        isGrid: true,
                        onTap: () {
                          if (isMulti) {
                            onToggleMulti(option.id);
                          } else {
                            onSelectSingle(option.id);
                          }
                        },
                      );
                    },
                  )
                else
                  ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: question.options.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final option = question.options[index];
                      final isSelected = isMulti
                          ? multiAnswer.contains(option.id)
                          : singleAnswer == option.id;

                      return MatchExpertOptionCard(
                        option: option,
                        isSelected: isSelected,
                        selectionType: question.selectionType,
                        isGrid: false,
                        onTap: () {
                          if (isMulti) {
                            onToggleMulti(option.id);
                          } else {
                            onSelectSingle(option.id);
                          }
                        },
                      );
                    },
                  ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),

        // Sticky Bottom Next Button
        Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + 14),
          decoration: BoxDecoration(
            color: const Color(0xFF073B4C),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: GestureDetector(
            onTap: canProceed ? onNext : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: canProceed ? NeoBrutalism.lime : const Color(0xFF64748B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: canProceed ? Colors.black : Colors.transparent,
                  width: 2,
                ),
                boxShadow: canProceed
                    ? NeoBrutalism.shadow(yOffset: 3)
                    : [],
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Selanjutnya',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: canProceed ? NeoBrutalism.dark : Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    color: canProceed ? NeoBrutalism.dark : Colors.white70,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
