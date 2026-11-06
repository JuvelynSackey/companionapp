import 'package:flutter/material.dart';

/// Turns the light markdown that Gemini and the local engine both produce
/// into styled spans, so a bubble shows "Campus Shuttle" in bold instead of
/// "**Campus Shuttle**". Deliberately small: bold, italic, inline code,
/// bullet lines, headings and dividers. Anything unmatched is left as typed.
///
///   **bold**   *italic*   `code`   "* item" / "- item" -> "• item"   "## Title" -> bold
///   "---" / "***" / "___" -> a paragraph break
List<TextSpan> formatMessage(String text, TextStyle base) {
  final lines = plainMath(text)
      .split('\n')
      .map(_normaliseLine)
      .join('\n')
      // A removed divider leaves blank lines either side; keep one gap.
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .replaceAll(RegExp(r'^\n+|\n+$'), '');

  return _inlineSpans(lines, base);
}

/// Gemini sometimes writes maths in LaTeX ("$(1\times8) + (0\times4)$"),
/// which a chat bubble would show raw. This turns the common commands into
/// plain symbols and drops the $...$ delimiters around them. A dollar amount
/// ("$10 and $20") is left alone: only a $...$ span that contains a LaTeX
/// command, ^ or { is treated as maths.
String plainMath(String text) {
  var out = text.replaceAllMapped(
    RegExp(r'\$\$([^$]+?)\$\$|\$(?!\s)([^$\n]*?[\\^{][^$\n]*?)(?<!\s)\$'),
    (m) => m.group(1) ?? m.group(2)!,
  );
  out = out
      .replaceAllMapped(RegExp(r'\\frac\{([^{}]*)\}\{([^{}]*)\}'), (m) => '${m[1]}/${m[2]}')
      .replaceAllMapped(RegExp(r'\\sqrt\{([^{}]*)\}'), (m) => '√(${m[1]})')
      .replaceAllMapped(RegExp(r'\\(?:text|mathrm|mathbf)\{([^{}]*)\}'), (m) => m[1]!)
      .replaceAllMapped(RegExp(r'\^\{([^{}]*)\}'), (m) => '^${m[1]}');
  const symbols = {
    r'\times': '×', r'\div': '÷', r'\cdot': '·', r'\pm': '±', r'\leq': '≤', r'\geq': '≥',
    r'\neq': '≠', r'\approx': '≈', r'\rightarrow': '→', r'\to': '→', r'\infty': '∞',
    r'\le': '≤', r'\ge': '≥', r'\ne': '≠', r'\%': '%', r'\left': '', r'\right': '',
  };
  for (final entry in symbols.entries) {
    // Spaces around the command go too, so "1\times8" and "1 \times 8"
    // both become "1 × 8"; nothing else on the line is touched.
    out = out.replaceAllMapped(RegExp('[ \\t]*${RegExp.escape(entry.key)}(?![A-Za-z])[ \\t]*'), (m) {
      final symbol = entry.value;
      return symbol.isEmpty || symbol == '%' ? symbol : ' $symbol ';
    });
  }
  return out;
}

List<TextSpan> _inlineSpans(String text, TextStyle style) {
  final spans = <TextSpan>[];
  var cursor = 0;
  for (final match in _inline.allMatches(text)) {
    if (match.start > cursor) spans.add(TextSpan(text: text.substring(cursor, match.start), style: _orNull(style)));

    final bold = match.namedGroup('b');
    final code = match.namedGroup('c');
    final italic = match.namedGroup('i');
    if (bold != null) {
      spans.add(TextSpan(text: bold, style: style.copyWith(fontWeight: FontWeight.bold)));
    } else if (code != null) {
      spans.add(TextSpan(
        text: code,
        style: style.copyWith(fontFamily: 'monospace', backgroundColor: style.color?.withValues(alpha: 0.12)),
      ));
    } else if (italic != null) {
      // An italic run may hold bold (Gemini writes "*Note: check **Resources**.*").
      spans.addAll(_inlineSpans(italic, style.copyWith(fontStyle: FontStyle.italic)));
    }
    cursor = match.end;
  }
  if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor), style: _orNull(style)));
  return spans;
}

/// Plain runs at the top level carry no style of their own (they inherit
/// the bubble's), as before; inside an italic run they keep the italics.
TextStyle? _orNull(TextStyle style) => style.fontStyle == FontStyle.italic ? style : null;

/// Bold first so "**x**" is never read as two italics. Italic must hug its
/// text ("*x*", not "5 * 3 * 2"), may contain bold runs, and only closes on a
/// lone "*". None of them cross a line break.
final _inline = RegExp(r'\*\*(?<b>[^*\n]+?)\*\*|`(?<c>[^`\n]+)`|\*(?<i>[^*\s](?:\*\*[^*\n]+?\*\*|[^*\n])*?)\*(?!\*)');

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
