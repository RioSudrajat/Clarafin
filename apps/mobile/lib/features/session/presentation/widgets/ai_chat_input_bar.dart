import 'package:flutter/material.dart';

import '../../../../core/theme/neo_brutalism_decorations.dart';
import 'ai_action_card_primitives.dart';
import 'ai_chat_input_buttons.dart';

/// Single-pill Neo-Brutalist input dock shared across Quick Sheet and `/ai-chat`.
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
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final animDuration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 150);

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 3, 4, 3),
      decoration: NeoBrutalism.cardDecoration(
        backgroundColor: Colors.white,
        borderRadius: 28,
        shadowOffset: 3.0,
      ),
      foregroundDecoration: _isInputFocused
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: NeoBrutalism.darkTeal, width: 2.5),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              key: const Key('ai_input_text_field'),
              controller: widget.controller,
              focusNode: widget.focusNode,
              readOnly: widget.isAiTyping,
              cursorColor: Colors.black,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              maxLines: 3,
              minLines: 1,
              style: aiActionTextStyle(
                context,
                13.5,
                FontWeight.w600,
                Colors.black,
              ),
              decoration: InputDecoration(
                hintText: widget.isAiTyping
                    ? 'Sedang memproses...'
                    : 'Tanya Clarafin AI...',
                hintStyle: aiActionTextStyle(
                  context,
                  13.5,
                  FontWeight.w500,
                  const Color(0xFF9CA3AF),
                ),
                filled: false,
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
              ),
              onSubmitted: (text) {
                if (!widget.isAiTyping && text.trim().isNotEmpty) {
                  widget.onSendMessage(text);
                }
              },
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.controller,
            builder: (context, val, _) {
              final hasTypedText = val.text.isNotEmpty;
              final canSend =
                  val.text.trim().isNotEmpty && !widget.isAiTyping;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSize(
                    duration: animDuration,
                    curve: Curves.easeOutCubic,
                    child: hasTypedText
                        ? const SizedBox.shrink()
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.onOpenScan != null)
                                AiInputInlineIconButton(
                                  buttonKey: const Key('ai_input_scan_btn'),
                                  icon: Icons.qr_code_scanner_rounded,
                                  semanticLabel: 'Scan struk belanja',
                                  tooltip: 'Scan',
                                  onTap: widget.isAiTyping
                                      ? null
                                      : widget.onOpenScan,
                                ),
                              if (widget.onOpenVoice != null)
                                AiInputInlineIconButton(
                                  buttonKey: const Key('ai_input_voice_btn'),
                                  icon: Icons.mic_none_rounded,
                                  semanticLabel: 'Input suara AI',
                                  tooltip: 'Bicara',
                                  onTap: widget.isAiTyping
                                      ? null
                                      : widget.onOpenVoice,
                                ),
                            ],
                          ),
                  ),
                  AiInputCircleSendButton(
                    buttonKey: const Key('ai_input_send_btn'),
                    onTap: canSend
                        ? () => widget.onSendMessage(widget.controller.text)
                        : null,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
