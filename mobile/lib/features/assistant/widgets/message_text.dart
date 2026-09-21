import 'package:flutter/material.dart';

/// Turns the light markdown that Gemini and the local engine both produce
/// into styled spans, so a bubble shows "Campus Shuttle" in bold instead of
/// "**Campus Shuttle**". Deliberately small: bold, italic, inline code,
/// bullet lines and headings. Anything unmatched is left as typed.
///
///   **bold**   *italic*   `code`   "* item" / "- item" -> "• item"   "## Title" -> bold
List<TextSpan> formatMessage(String text, TextStyle base) {
  final lines = text.split('\n').map(_normaliseLine).join('\n');

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

String _normaliseLine(String line) {
  final heading = _heading.firstMatch(line);
  if (heading != null) return '**${heading.group(1)}**';
  return line.replaceFirstMapped(_bullet, (m) => '${m.group(1)}• ');
}
