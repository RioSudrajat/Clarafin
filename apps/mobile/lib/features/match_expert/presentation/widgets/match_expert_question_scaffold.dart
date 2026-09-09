import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top glowing orb & back button (strictly left aligned)
        MatchExpertOrbHeader(onBack: onBack),

        // Scrollable question area
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),

                // Question Title
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

                // Helper Subtitle
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

                const SizedBox(height: 20),

                // Options Content: Special chips for Step 12, Grid for Step 2/4, List for others
                if (question.id == 'specific_tags')
                  _buildTagsWrap(multiAnswer)
                else if (question.isGrid)
                  _buildGridView(isMulti, singleAnswer, multiAnswer)
                else
                  _buildListView(isMulti, singleAnswer, multiAnswer),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // Sticky Bottom Next Button + Footer
        Container(
          color: Colors.transparent,
          padding: EdgeInsets.fromLTRB(20, 6, 20, bottomPadding + 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: canProceed ? onNext : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: canProceed ? NeoBrutalism.lime : const Color(0xFF334155),
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
                          color: canProceed ? NeoBrutalism.dark : Colors.white60,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        color: canProceed ? NeoBrutalism.dark : Colors.white60,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Consistent Footer "Powered by clarafin" on every question page
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Powered by ',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  Text(
                    'clarafin',
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTagsWrap(Set<String> multiAnswer) {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: question.options.map((opt) {
        final isSelected = multiAnswer.contains(opt.id);
        return GestureDetector(
          onTap: () => onToggleMulti(opt.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? NeoBrutalism.lime : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: isSelected
                  ? NeoBrutalism.shadow(yOffset: 3, xOffset: 1)
                  : NeoBrutalism.shadow(yOffset: 2, xOffset: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (opt.icon != null) ...[
                  Icon(opt.icon, size: 16, color: NeoBrutalism.dark),
                  const SizedBox(width: 6),
                ],
                Text(
                  opt.title,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: NeoBrutalism.dark,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.check, size: 14, color: NeoBrutalism.dark),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGridView(bool isMulti, String? singleAnswer, Set<String> multiAnswer) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.22,
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
    );
  }

  Widget _buildListView(bool isMulti, String? singleAnswer, Set<String> multiAnswer) {
    return ListView.separated(
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
    );
  }
}
