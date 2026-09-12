import 'package:flutter/material.dart';

class FormattedPostText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final Color? accentColor;

  const FormattedPostText({
    super.key,
    required this.text,
    this.baseStyle,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = accentColor ?? theme.colorScheme.primary;

    final defaultStyle = baseStyle ??
        TextStyle(
          fontSize: 14.5,
          height: 1.5,
          color: isDark ? const Color(0xFFF5F5FA) : const Color(0xFF0E0E14),
        );

    final spans = _parseMarkdownSpans(text, defaultStyle, primary);

    return SelectableText.rich(
      TextSpan(children: spans),
      style: defaultStyle,
    );
  }

  static List<InlineSpan> _parseMarkdownSpans(
    String rawText,
    TextStyle baseStyle,
    Color primaryColor,
  ) {
    final List<InlineSpan> spans = [];
    final lines = rawText.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Check for bullet list line: "• ", "- ", "* "
      if (line.startsWith('• ') || line.startsWith('- ') || line.startsWith('* ')) {
        final content = line.substring(2);
        spans.add(
          TextSpan(
            text: '  •  ',
            style: baseStyle.copyWith(
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        );
        spans.addAll(_parseInlineFormatting(content, baseStyle));
      }
      // Check for numbered list line: "1. ", "2. ", etc.
      else if (RegExp(r'^\d+\.\s').hasMatch(line)) {
        final match = RegExp(r'^(\d+\.)\s').firstMatch(line)!;
        final numPrefix = match.group(1)!;
        final content = line.substring(match.end);

        spans.add(
          TextSpan(
            text: '  $numPrefix ',
            style: baseStyle.copyWith(
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        );
        spans.addAll(_parseInlineFormatting(content, baseStyle));
      }
      // Regular line
      else {
        spans.addAll(_parseInlineFormatting(line, baseStyle));
      }

      // Add newline between lines
      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return spans;
  }

  static List<InlineSpan> _parseInlineFormatting(String text, TextStyle baseStyle) {
    final List<InlineSpan> spans = [];
    final pattern = RegExp(r'(\*\*\*(.*?)\*\*\*|\*\*(.*?)\*\*|\*(.*?)\*)');
    int lastMatchEnd = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: baseStyle,
          ),
        );
      }

      // ***Bold Italic***
      if (match.group(2) != null) {
        spans.add(
          TextSpan(
            text: match.group(2),
            style: baseStyle.copyWith(
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      }
      // **Bold**
      else if (match.group(3) != null) {
        spans.add(
          TextSpan(
            text: match.group(3),
            style: baseStyle.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }
      // *Italic*
      else if (match.group(4) != null) {
        spans.add(
          TextSpan(
            text: match.group(4),
            style: baseStyle.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastMatchEnd),
          style: baseStyle,
        ),
      );
    }

    return spans;
  }
}
