import 'package:flutter/material.dart';
import '../../domain/models/match_expert_models.dart';
import 'match_expert_grid_card.dart';

class MatchExpertGridOptions extends StatelessWidget {
  final List<MatchExpertOption> options;
  final bool isMulti;
  final String? singleAnswer;
  final Set<String> multiAnswer;
  final void Function(String optionId) onSelectSingle;
  final void Function(String optionId) onToggleMulti;

  const MatchExpertGridOptions({
    super.key,
    required this.options,
    required this.isMulti,
    required this.singleAnswer,
    required this.multiAnswer,
    required this.onSelectSingle,
    required this.onToggleMulti,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.98,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = isMulti
            ? multiAnswer.contains(option.id)
            : singleAnswer == option.id;

        return MatchExpertGridCard(
          option: option,
          isSelected: isSelected,
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
