import 'package:flutter/material.dart';

import '../../../../core/theme/neo_brutalism_decorations.dart';
import 'ai_action_card_primitives.dart';

/// Renders assistant narrative text with clean paragraph breaks, hanging
/// numbered/bullet list indentation, and bold lead-ins or `**bold**` spans.
class AiFormattedNarrativeText extends StatelessWidget {
  final String text;
  final Color textColor;
  final double fontSize;

  const AiFormattedNarrativeText({
    super.key,
    required this.text,
    this.textColor = const Color(0xFF111827),
    this.fontSize = 13.0,
  });

  static final RegExp _inlineNumberedSplitRegex = RegExp(
    r'[ \t]+(\d+\.)[ \t]+(?=[A-Z\u00C0-\u024F*])',
  );
  static final RegExp _numberedLineRegex = RegExp(r'^(\d+)\.\s+(.*)$');
  static final RegExp _bulletLineRegex = RegExp(r'^(?:-|•|\*)\s+(.*)$');
  static final RegExp _titleColonRegex = RegExp(r'^([^:\n]{2,45}):(\s+.*)$');
  static final RegExp _boldMarkdownRegex = RegExp(r'\*\*([^*]+)\*\*');

  @override
  Widget build(BuildContext context) {
    final blocks = _parseBlocks(text);
    if (blocks.isEmpty) return const SizedBox.shrink();

    final baseStyle = aiActionTextStyle(
      context,
      fontSize,
      FontWeight.w500,
      textColor,
    ).copyWith(height: 1.48);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          _buildBlock(context, blocks[i], baseStyle),
          if (i < blocks.length - 1) const SizedBox(height: 7),
        ],
      ],
    );
  }

  List<_NarrativeBlock> _parseBlocks(String raw) {
    final normalized = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    if (normalized.isEmpty) return const [];

    final splitInline = normalized.replaceAllMapped(
      _inlineNumberedSplitRegex,
      (m) => '\n${m.group(1)} ',
    );

    final blocks = <_NarrativeBlock>[];
    for (final rawLine in splitInline.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final numbered = _numberedLineRegex.firstMatch(line);
      if (numbered != null) {
        blocks.add(_NarrativeBlock(
          kind: _BlockKind.numbered,
          marker: numbered.group(1)!,
          content: numbered.group(2)!.trim(),
        ));
        continue;
      }

      final bullet = _bulletLineRegex.firstMatch(line);
      if (bullet != null) {
        blocks.add(_NarrativeBlock(
          kind: _BlockKind.bullet,
          marker: '•',
          content: bullet.group(1)!.trim(),
        ));
        continue;
      }

      blocks.add(_NarrativeBlock(kind: _BlockKind.paragraph, content: line));
    }
    return blocks;
  }

  Widget _buildBlock(
    BuildContext context,
    _NarrativeBlock block,
    TextStyle baseStyle,
  ) {
    final richText = Text.rich(
      TextSpan(
        style: baseStyle,
        children: _buildInlineSpans(
          block.content,
          baseStyle,
          boldLeadIn: block.kind != _BlockKind.paragraph,
        ),
      ),
    );
    if (block.kind == _BlockKind.paragraph) return richText;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (block.kind == _BlockKind.numbered)
          Container(
            margin: const EdgeInsets.only(top: 1),
            constraints: const BoxConstraints(minWidth: 22),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: NeoBrutalism.lime,
              borderRadius: BorderRadius.circular(6),
              border: NeoBrutalism.border(width: 1.2),
            ),
            alignment: Alignment.center,
            child: Text(
              block.marker,
              style: aiActionTextStyle(context, 11, FontWeight.w800, textColor),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 7, left: 4, right: 2),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: textColor, shape: BoxShape.circle),
            ),
          ),
        const SizedBox(width: 8),
        Expanded(child: richText),
      ],
    );
  }

  List<InlineSpan> _buildInlineSpans(
    String content,
    TextStyle baseStyle, {
    required bool boldLeadIn,
  }) {
    if (_boldMarkdownRegex.hasMatch(content)) {
      return _parseMarkdownBoldSpans(content, baseStyle);
    }
    if (boldLeadIn) {
      final colonMatch = _titleColonRegex.firstMatch(content);
      if (colonMatch != null) {
        final title = colonMatch.group(1)!;
        if (!title.contains('http') && !RegExp(r'^\d{1,2}$').hasMatch(title)) {
          return [
            TextSpan(
              text: '$title:',
              style: baseStyle.copyWith(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: colonMatch.group(2)!),
          ];
        }
      }
    }
    return [TextSpan(text: content)];
  }

  List<InlineSpan> _parseMarkdownBoldSpans(String content, TextStyle baseStyle) {
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in _boldMarkdownRegex.allMatches(content)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: content.substring(cursor, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: baseStyle.copyWith(fontWeight: FontWeight.w700),
      ));
      cursor = match.end;
    }
    if (cursor < content.length) {
      spans.add(TextSpan(text: content.substring(cursor)));
    }
    return spans;
  }
}

enum _BlockKind { paragraph, numbered, bullet }

class _NarrativeBlock {
  final _BlockKind kind;
  final String marker;
  final String content;

  const _NarrativeBlock({
    required this.kind,
    this.marker = '',
    required this.content,
  });
}
