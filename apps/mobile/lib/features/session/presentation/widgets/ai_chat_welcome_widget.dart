import 'package:flutter/material.dart';

import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../home/presentation/widgets/notion_doodle_icons.dart';
import 'ai_action_card_primitives.dart';

class _PromptSuggestion {
  final IconData icon;
  final String label;
  final String prompt;

  const _PromptSuggestion({
    required this.icon,
    required this.label,
    required this.prompt,
  });
}

/// Clean empty-state welcome view with contextual domain prompts (zero decorative emojis).
class AiChatWelcomeWidget extends StatelessWidget {
  final ValueChanged<String> onSelectPrompt;
  final bool isCompact;

  const AiChatWelcomeWidget({
    super.key,
    required this.onSelectPrompt,
    this.isCompact = false,
  });

  static const List<_PromptSuggestion> _prompts = [
    _PromptSuggestion(
      icon: Icons.account_balance_wallet_outlined,
      label: 'Cek saldo dompet saat ini',
      prompt: 'Berapa total saldo dompetku saat ini?',
    ),
    _PromptSuggestion(
      icon: Icons.swap_horiz_rounded,
      label: 'Arus kas bulan ini',
      prompt: 'Uangku lari ke mana aja bulan ini?',
    ),
    _PromptSuggestion(
      icon: Icons.receipt_long_outlined,
      label: 'Catat jajan multi-item',
      prompt: 'kopi kenangan 25k + parkir goceng pake gopay',
    ),
    _PromptSuggestion(
      icon: Icons.savings_outlined,
      label: 'Target dana darurat',
      prompt: 'Buatin target dana darurat 15jt',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(14.0) / 14.0;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 18,
        vertical: isCompact ? 14 : 22,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHero(context),
          SizedBox(height: isCompact ? 14 : 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final useSingleColumn =
                  constraints.maxWidth < 310 || textScale >= 1.2;
              if (useSingleColumn) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < _prompts.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      _PromptChipButton(
                        item: _prompts[i],
                        onTap: () => onSelectPrompt(_prompts[i].prompt),
                      ),
                    ],
                  ],
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < _prompts.length; i += 2) ...[
                    if (i > 0) const SizedBox(height: 10),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _PromptChipButton(
                              item: _prompts[i],
                              onTap: () => onSelectPrompt(_prompts[i].prompt),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: i + 1 < _prompts.length
                                ? _PromptChipButton(
                                    item: _prompts[i + 1],
                                    onTap: () =>
                                        onSelectPrompt(_prompts[i + 1].prompt),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final avatarSize = isCompact ? 54.0 : 72.0;
    final iconSize = isCompact ? 34.0 : 44.0;
    return Column(
      children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            color: NeoBrutalism.lime,
            borderRadius: BorderRadius.circular(isCompact ? 14 : 18),
            border: NeoBrutalism.border(width: 2.2),
            boxShadow: NeoBrutalism.shadow(yOffset: 3.0),
          ),
          child: Center(
            child: NotionDoodleWidget(
              svgString: NotionDoodleIcons.aiChat,
              size: iconSize,
            ),
          ),
        ),
        SizedBox(height: isCompact ? 10 : 14),
        Text(
          'Halo, aku Clarafin AI',
          textAlign: TextAlign.center,
          style: aiActionTextStyle(
            context,
            isCompact ? 16.5 : 19,
            FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Catat transaksi harian, cek arus kas, atau susun anggaran dan target tabungan.',
          textAlign: TextAlign.center,
          style: aiActionTextStyle(
            context,
            12.5,
            FontWeight.w500,
            const Color(0xFF4B5563),
          ).copyWith(height: 1.4),
        ),
      ],
    );
  }
}

class _PromptChipButton extends StatefulWidget {
  final _PromptSuggestion item;
  final VoidCallback onTap;

  const _PromptChipButton({required this.item, required this.onTap});

  @override
  State<_PromptChipButton> createState() => _PromptChipButtonState();
}

class _PromptChipButtonState extends State<_PromptChipButton> {
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: widget.item.label,
        child: Transform.translate(
          offset: Offset(0, _isPressed ? 2.0 : 0.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: NeoBrutalism.border(width: 1.8),
              boxShadow: _isPressed ? null : NeoBrutalism.shadow(yOffset: 2.0),
            ),
            foregroundDecoration: _isFocused
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: NeoBrutalism.darkTeal, width: 2.5),
                  )
                : null,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: widget.onTap,
                onFocusChange: (focused) {
                  if (_isFocused != focused) setState(() => _isFocused = focused);
                },
                onHighlightChanged: (pressed) {
                  if (_isPressed != pressed) setState(() => _isPressed = pressed);
                },
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(widget.item.icon, size: 18, color: NeoBrutalism.darkTeal),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.item.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: aiActionTextStyle(context, 12, FontWeight.w800)
                                .copyWith(height: 1.25),
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
      ),
    );
  }
}
