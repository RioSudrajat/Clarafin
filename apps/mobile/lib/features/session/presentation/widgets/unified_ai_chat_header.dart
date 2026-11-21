import 'package:flutter/material.dart';

import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../home/presentation/widgets/notion_doodle_icons.dart';
import 'unified_ai_chat_header_controls.dart';

/// Shared Neo-Brutalist top bar for Quick Sheet and `/ai-chat`.
class UnifiedAiChatHeader extends StatelessWidget {
  final bool isFullScreen;
  final String quotaBadgeText;
  final bool isQuotaExhausted;
  final VoidCallback? onTapQuota;
  final VoidCallback? onNewChat;
  final VoidCallback? onExpandToFullScreen;
  final VoidCallback? onClose;

  const UnifiedAiChatHeader({
    super.key,
    required this.isFullScreen,
    required this.quotaBadgeText,
    this.isQuotaExhausted = false,
    this.onTapQuota,
    this.onNewChat,
    this.onExpandToFullScreen,
    this.onClose,
  });

  TextStyle _style(
    BuildContext context,
    double size,
    FontWeight weight, {
    Color color = NeoBrutalism.dark,
  }) {
    final base = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    return base.copyWith(fontSize: size, fontWeight: weight, color: color, height: 1.2);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.black, width: 2.0)),
      ),
      child: Row(
        children: [
          if (isFullScreen && onClose != null) ...[
            HeaderCircleButton(
              buttonKey: const Key('ai_chat_back_btn'),
              icon: Icons.arrow_back_rounded,
              semanticLabel: 'Kembali',
              tooltip: 'Kembali',
              onTap: onClose,
            ),
            const SizedBox(width: 2),
          ],
          _buildAvatar(),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Clarafin AI',
                  maxLines: 1,
                  style: _style(context, 14.5, FontWeight.w900),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          _buildQuotaBadge(context),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: NeoBrutalism.lime,
        borderRadius: BorderRadius.circular(10),
        border: NeoBrutalism.border(width: 2.0),
      ),
      child: Center(
        child: NotionDoodleWidget(svgString: NotionDoodleIcons.aiChat, size: 22),
      ),
    );
  }

  Widget _buildQuotaBadge(BuildContext context) {
    return HeaderQuotaBadge(
      quotaText: quotaBadgeText,
      isExhausted: isQuotaExhausted,
      onTap: onTapQuota,
      style: _style(context, 11, FontWeight.w900, color: NeoBrutalism.dark),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HeaderCircleButton(
          buttonKey: const Key('ai_chat_new_chat_btn'),
          iconWidget: const GeminiNewChatIcon(),
          semanticLabel: 'Chat Baru',
          tooltip: 'Chat Baru',
          onTap: onNewChat,
        ),
        if (!isFullScreen && onExpandToFullScreen != null)
          HeaderCircleButton(
            buttonKey: const Key('ai_chat_expand_btn'),
            icon: Icons.open_in_full_rounded,
            semanticLabel: 'Lanjutkan di Layar Penuh',
            tooltip: 'Layar Penuh',
            onTap: onExpandToFullScreen,
          ),
        if (!isFullScreen && onClose != null)
          HeaderCircleButton(
            buttonKey: const Key('ai_chat_close_btn'),
            icon: Icons.close_rounded,
            semanticLabel: 'Tutup panel AI',
            tooltip: 'Tutup',
            onTap: onClose,
          ),
      ],
    );
  }
}
