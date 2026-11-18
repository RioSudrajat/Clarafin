import 'package:flutter/material.dart';

import '../../../../core/theme/neo_brutalism_decorations.dart';
import 'ai_action_card_primitives.dart';
import 'ai_chat_input_buttons.dart';

/// Card 2 Neo-Brutalist input dock shared across Quick Sheet and `/ai-chat`.
class AiChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isAiTyping;
  final ValueChanged<String> onSendMessage;
  final VoidCallback? onOpenScan;
  final VoidCallback? onOpenVoice;

  const AiChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isAiTyping,
    required this.onSendMessage,
    this.onOpenScan,
    this.onOpenVoice,
  });

  @override
  State<AiChatInputBar> createState() => _AiChatInputBarState();
}

class _AiChatInputBarState extends State<AiChatInputBar> {
  bool _isInputFocused = false;

  @override
  void initState() {
    super.initState();
    _isInputFocused = widget.focusNode.hasFocus;
    widget.focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant AiChatInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChange);
      widget.focusNode.addListener(_handleFocusChange);
      _isInputFocused = widget.focusNode.hasFocus;
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    super.dispose();
  }

  void _handleFocusChange() {
    if (!mounted || _isInputFocused == widget.focusNode.hasFocus) return;
    setState(() => _isInputFocused = widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: NeoBrutalism.cardDecoration(
        backgroundColor: Colors.white,
        borderRadius: 20,
        shadowOffset: 4.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: NeoBrutalism.border(width: 1.8),
            ),
            foregroundDecoration: _isInputFocused
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: NeoBrutalism.darkTeal, width: 2.5),
                  )
                : null,
            child: Semantics(
              textField: true,
              label: 'Tanya Clarafin AI',
              child: TextField(
                key: const Key('ai_input_text_field'),
                controller: widget.controller,
                focusNode: widget.focusNode,
                enabled: !widget.isAiTyping,
                cursorColor: Colors.black,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                maxLines: 3,
                minLines: 1,
                style: aiActionTextStyle(context, 13.5, FontWeight.w700),
                decoration: InputDecoration(
                  hintText: widget.isAiTyping
                      ? 'Sedang memproses permintaan...'
                      : 'Tanya Clarafin AI...',
                  hintStyle: aiActionTextStyle(
                    context,
                    13,
                    FontWeight.w600,
                    const Color(0xFF6B7280),
                  ),
                  filled: false,
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (text) {
                  if (!widget.isAiTyping && text.trim().isNotEmpty) {
                    widget.onSendMessage(text);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (widget.onOpenScan != null)
                      AiInputTactileControl(
                        buttonKey: const Key('ai_input_scan_btn'),
                        icon: Icons.document_scanner_outlined,
                        label: 'Scan',
                        semanticLabel: 'Scan struk belanja',
                        activeColor: Colors.white,
                        borderWidth: 1.5,
                        radius: 10,
                        onTap: widget.isAiTyping ? null : widget.onOpenScan,
                      ),
                    if (widget.onOpenVoice != null)
                      AiInputTactileControl(
                        buttonKey: const Key('ai_input_voice_btn'),
                        icon: Icons.mic_none_rounded,
                        label: 'Bicara',
                        semanticLabel: 'Input suara AI',
                        activeColor: Colors.white,
                        borderWidth: 1.5,
                        radius: 10,
                        onTap: widget.isAiTyping ? null : widget.onOpenVoice,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.controller,
                builder: (context, val, _) {
                  final canSend = val.text.trim().isNotEmpty && !widget.isAiTyping;
                  return AiInputTactileControl(
                    buttonKey: const Key('ai_input_send_btn'),
                    icon: Icons.arrow_upward_rounded,
                    semanticLabel: 'Kirim pesan',
                    activeColor: NeoBrutalism.lime,
                    borderWidth: 2.0,
                    radius: 12,
                    onTap: canSend
                        ? () => widget.onSendMessage(widget.controller.text)
                        : null,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
