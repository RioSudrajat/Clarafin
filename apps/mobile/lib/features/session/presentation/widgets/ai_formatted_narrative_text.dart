import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
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
    this.textColor = Colors.black,
    this.fontSize = 13.5,
  });

  static final RegExp _inlineNumberedSplitRegex = RegExp(
    r'[ \t]+(\d+\.)[ \t]+(?=[A-Z\u00C0-\u024F*])',
  );
  static final RegExp _numberedLineRegex = RegExp(r'^(\d+)\.\s+(.*)$');
  static final RegExp _bulletLineRegex = RegExp(r'^(?:-|•|\*)\s+(.*)$');
  static final RegExp _titleColonRegex = RegExp(r'^([^:\n]{2,45}):(\s+.*)$');
  static final RegExp _boldMarkdownRegex = RegExp(r'\*\*([^*]+)\*\*');
  static final RegExp _sentenceBoundaryRegex = RegExp(
    r'(?<=[.!?])\s+(?=[A-Z\u00C0-\u024F])',
  );
  static const Set<String> _nonSplittingAbbreviations = {
    'no.',
    'dr.',
    'rp.',
    'dll.',
    'dsb.',
    'dkk.',
    'tgl.',
    'hal.',
  };

  @override
  Widget build(BuildContext context) {
    final blocks = _parseBlocks(text);
    if (blocks.isEmpty) return const SizedBox.shrink();

    final baseStyle = AppTypography.chatBody(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: textColor,
      height: 1.52,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          _buildBlock(context, blocks[i], baseStyle),
          if (i < blocks.length - 1) const SizedBox(height: 10),
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

      blocks.addAll(_splitDenseParagraph(line));
    }
    return blocks;
  }

  /// Breaks a long, dense single-line paragraph (>220 chars, >=3 sentences)
  /// into 2-sentence paragraphs so walls of text stay readable.
  List<_NarrativeBlock> _splitDenseParagraph(String paragraph) {
    if (paragraph.length <= 220) {
      return [_NarrativeBlock(kind: _BlockKind.paragraph, content: paragraph)];
    }

    final rawParts = paragraph.split(_sentenceBoundaryRegex);
    final sentences = <String>[];
    for (final part in rawParts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      if (sentences.isNotEmpty) {
        final prevWords = sentences.last.split(RegExp(r'\s+'));
        final lastWord = prevWords.isNotEmpty ? prevWords.last.toLowerCase() : '';
        if (_nonSplittingAbbreviations.contains(lastWord)) {
          sentences[sentences.length - 1] = '${sentences.last} $trimmed';
          continue;
        }
      }
      sentences.add(trimmed);
    }

    if (sentences.length < 3) {
      return [_NarrativeBlock(kind: _BlockKind.paragraph, content: paragraph)];
    }

    final result = <_NarrativeBlock>[];
    for (var i = 0; i < sentences.length; i += 2) {
      final end = (i + 2 < sentences.length) ? i + 2 : sentences.length;
      result.add(_NarrativeBlock(
        kind: _BlockKind.paragraph,
        content: sentences.sublist(i, end).join(' '),
      ));
    }
    return result;
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
      textAlign: TextAlign.justify,
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
              style: baseStyle.copyWith(fontWeight: FontWeight.w800),
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
        style: baseStyle.copyWith(fontWeight: FontWeight.w800),
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
