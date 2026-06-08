import 'package:flutter/material.dart';

class SimpleMarkdownDocumentView extends StatelessWidget {
  const SimpleMarkdownDocumentView({required this.content, super.key});

  final String content;

  @override
  Widget build(BuildContext context) {
    final blocks = _buildBlocks(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }

  List<Widget> _buildBlocks(BuildContext context) {
    final lines = content.split('\n');
    final blocks = <Widget>[];
    final tableLines = <String>[];

    void flushTable() {
      if (tableLines.isEmpty) {
        return;
      }

      blocks.add(_ReadableTableBlock(lines: List<String>.from(tableLines)));
      blocks.add(const SizedBox(height: 12));
      tableLines.clear();
    }

    for (final rawLine in lines) {
      final line = rawLine.trim();

      if (line.isEmpty) {
        flushTable();
        if (blocks.isNotEmpty && blocks.last is! SizedBox) {
          blocks.add(const SizedBox(height: 8));
        }
        continue;
      }

      if (_isMarkdownSeparator(line)) {
        continue;
      }

      if (_isTableLine(line)) {
        tableLines.add(line);
        continue;
      }

      flushTable();

      if (line.startsWith('# ')) {
        blocks.add(
          _TextBlock(
            text: _cleanInlineMarkdown(line.substring(2)),
            style: Theme.of(context).textTheme.headlineSmall,
            bottomSpacing: 16,
          ),
        );
      } else if (line.startsWith('## ')) {
        blocks.add(
          _TextBlock(
            text: _cleanInlineMarkdown(line.substring(3)),
            style: Theme.of(context).textTheme.titleLarge,
            bottomSpacing: 12,
          ),
        );
      } else if (line.startsWith('### ')) {
        blocks.add(
          _TextBlock(
            text: _cleanInlineMarkdown(line.substring(4)),
            style: Theme.of(context).textTheme.titleMedium,
            bottomSpacing: 8,
          ),
        );
      } else if (line.startsWith('- ')) {
        blocks.add(_BulletBlock(text: _cleanInlineMarkdown(line.substring(2))));
      } else {
        blocks.add(_RichTextBlock(text: line));
      }
    }

    flushTable();
    return blocks;
  }
}

class _TextBlock extends StatelessWidget {
  const _TextBlock({
    required this.text,
    required this.style,
    required this.bottomSpacing,
  });

  final String text;
  final TextStyle? style;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: SelectableText(text, style: style?.copyWith(height: 1.25)),
    );
  }
}

class _RichTextBlock extends StatelessWidget {
  const _RichTextBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SelectableText.rich(
        TextSpan(
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35),
          children: _inlineSpans(text),
        ),
      ),
    );
  }
}

class _BulletBlock extends StatelessWidget {
  const _BulletBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.only(top: 3), child: Text('•')),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText.rich(
              TextSpan(
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.35),
                children: _inlineSpans(text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadableTableBlock extends StatelessWidget {
  const _ReadableTableBlock({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final rows = lines
        .where((line) => !_isMarkdownSeparator(line))
        .map(_tableCells)
        .where((cells) => cells.any((cell) => cell.isNotEmpty))
        .toList();

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
            if (rowIndex > 0) const Divider(height: 18),
            _ReadableTableRow(cells: rows[rowIndex], isHeader: rowIndex == 0),
          ],
        ],
      ),
    );
  }
}

class _ReadableTableRow extends StatelessWidget {
  const _ReadableTableRow({required this.cells, required this.isHeader});

  final List<String> cells;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      height: 1.35,
      fontWeight: isHeader ? FontWeight.w700 : FontWeight.w400,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: cells
          .map(
            (cell) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: SelectableText(
                _cleanInlineMarkdown(cell),
                style: textStyle,
              ),
            ),
          )
          .toList(),
    );
  }
}

List<InlineSpan> _inlineSpans(String text) {
  final spans = <InlineSpan>[];
  final pattern = RegExp(r'\*\*(.*?)\*\*');
  var currentIndex = 0;

  for (final match in pattern.allMatches(text)) {
    if (match.start > currentIndex) {
      spans.add(
        TextSpan(
          text: _cleanInlineMarkdown(text.substring(currentIndex, match.start)),
        ),
      );
    }

    spans.add(
      TextSpan(
        text: _cleanInlineMarkdown(match.group(1) ?? ''),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
    currentIndex = match.end;
  }

  if (currentIndex < text.length) {
    spans.add(
      TextSpan(text: _cleanInlineMarkdown(text.substring(currentIndex))),
    );
  }

  return spans.isEmpty ? [TextSpan(text: _cleanInlineMarkdown(text))] : spans;
}

bool _isTableLine(String line) {
  return line.contains('|') && line.replaceAll('|', '').trim().isNotEmpty;
}

bool _isMarkdownSeparator(String line) {
  final cleaned = line.replaceAll('|', '').replaceAll(':', '').trim();
  return cleaned.isNotEmpty && RegExp(r'^-+$').hasMatch(cleaned);
}

List<String> _tableCells(String line) {
  return line
      .split('|')
      .map(_cleanInlineMarkdown)
      .where((cell) => cell.isNotEmpty)
      .toList();
}

String _cleanInlineMarkdown(String text) {
  return text
      .replaceAll('**', '')
      .replaceAll('###', '')
      .replaceAll('##', '')
      .replaceAll('|', ' ')
      .replaceAll('---', '')
      .trim();
}
