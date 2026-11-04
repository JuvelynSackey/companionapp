import 'package:flutter/material.dart';

/// Turns the light markdown that Gemini and the local engine both produce
/// into styled spans, so a bubble shows "Campus Shuttle" in bold instead of
/// "**Campus Shuttle**". Deliberately small: bold, italic, inline code,
/// bullet lines, headings and dividers. Anything unmatched is left as typed.
///
///   **bold**   *italic*   `code`   "* item" / "- item" -> "• item"   "## Title" -> bold
///   "---" / "***" / "___" -> a paragraph break
List<TextSpan> formatMessage(String text, TextStyle base) {
  final lines = text
      .split('\n')
      .map(_normaliseLine)
      .join('\n')
      // A removed divider leaves blank lines either side; keep one gap.
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .replaceAll(RegExp(r'^\n+|\n+$'), '');

  final spans = <TextSpan>[];
  var cursor = 0;
  for (final match in _inline.allMatches(lines)) {
    if (match.start > cursor) spans.add(TextSpan(text: lines.substring(cursor, match.start)));

    final bold = match.namedGroup('b');
    final code = match.namedGroup('c');
    final italic = match.namedGroup('i');
    if (bold != null) {
      spans.add(TextSpan(text: bold, style: base.copyWith(fontWeight: FontWeight.bold)));
    } else if (code != null) {
      spans.add(TextSpan(
        text: code,
        style: base.copyWith(fontFamily: 'monospace', backgroundColor: base.color?.withValues(alpha: 0.12)),
      ));
    } else if (italic != null) {
      spans.add(TextSpan(text: italic, style: base.copyWith(fontStyle: FontStyle.italic)));
    }
    cursor = match.end;
  }
  if (cursor < lines.length) spans.add(TextSpan(text: lines.substring(cursor)));
  return spans;
}

/// Bold first so "**x**" is never read as two italics. Italic must hug its
/// text ("*x*", not "5 * 3 * 2"). None of them cross a line break.
final _inline = RegExp(r'\*\*(?<b>[^*\n]+?)\*\*|`(?<c>[^`\n]+)`|\*(?<i>[^*\s][^*\n]*?)\*');

final _bullet = RegExp(r'^(\s*)[*-]\s+');
final _heading = RegExp(r'^#{1,6}\s+(.*)$');
final _divider = RegExp(r'^\s*([-*_])(\s*\1){2,}\s*$');

String _normaliseLine(String line) {
  // Before bullets, so "- - -" and "* * *" are not read as bullet items.
  if (_divider.hasMatch(line)) return '';
  final heading = _heading.firstMatch(line);
  if (heading != null) {
    // Gemini often bolds inside a heading ("### 4. **Title**"); wrapping that
    // again would pair the asterisks wrongly and leave "****" on screen.
    final title = heading.group(1)!.replaceAll('**', '').trim();
    return title.isEmpty ? '' : '**$title**';
  }
  return line.replaceFirstMapped(_bullet, (m) => '${m.group(1)}• ');
}
