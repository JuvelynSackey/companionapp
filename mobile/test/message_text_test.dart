import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/assistant/widgets/message_text.dart';

const _base = TextStyle(color: Color(0xFF112233), fontSize: 14);

/// The plain text the user would read, markers removed.
String _plain(List<TextSpan> spans) => spans.map((s) => s.text ?? '').join();

/// Text -> its style, for each styled run.
Map<String, TextStyle?> _styled(List<TextSpan> spans) => {
      for (final s in spans)
        if (s.style != null) s.text!: s.style,
    };

void main() {
  group('formatMessage', () {
    test('plain text is left exactly as it is, with no styling', () {
      final spans = formatMessage('Your next class is at 10:00.', _base);
      expect(_plain(spans), 'Your next class is at 10:00.');
      expect(_styled(spans), isEmpty);
    });

    test('**bold** loses its asterisks and becomes bold', () {
      final spans = formatMessage('🚌 **Campus Shuttle**: every 10 minutes', _base);
      expect(_plain(spans), '🚌 Campus Shuttle: every 10 minutes');
      expect(_styled(spans)['Campus Shuttle']!.fontWeight, FontWeight.bold);
    });

    test('*italic* loses its asterisks and becomes italic', () {
      final spans = formatMessage('Try *"Where are vacant study desks?"*', _base);
      expect(_plain(spans), 'Try "Where are vacant study desks?"');
      expect(_styled(spans)['"Where are vacant study desks?"']!.fontStyle, FontStyle.italic);
    });

    test('`code` becomes monospace', () {
      final spans = formatMessage('Set the method to `PEAP` now', _base);
      expect(_plain(spans), 'Set the method to PEAP now');
      expect(_styled(spans)['PEAP']!.fontFamily, 'monospace');
    });

    test('several styles in one line', () {
      final spans = formatMessage('**Course:** DCIT 201 — *Mathematics* (`Room 204`)', _base);
      expect(_plain(spans), 'Course: DCIT 201 — Mathematics (Room 204)');
      expect(_styled(spans).keys, ['Course:', 'Mathematics', 'Room 204']);
    });

    test('a bold run is not mistaken for two italics', () {
      final spans = formatMessage('**x**', _base);
      expect(_styled(spans).keys, ['x']);
      expect(_styled(spans)['x']!.fontWeight, FontWeight.bold);
    });

    test('markdown bullets ("* " and "- ") become "•"', () {
      final spans = formatMessage('Options:\n* one\n- two\n  * nested', _base);
      expect(_plain(spans), 'Options:\n• one\n• two\n  • nested');
    });

    test('a bullet line keeps its inline styling', () {
      final spans = formatMessage('* **Venue:** Great Hall', _base);
      expect(_plain(spans), '• Venue: Great Hall');
      expect(_styled(spans).keys, ['Venue:']);
    });

    test('headings become a bold line', () {
      final spans = formatMessage('## Your week\nbody', _base);
      expect(_plain(spans), 'Your week\nbody');
      expect(_styled(spans)['Your week']!.fontWeight, FontWeight.bold);
    });

    test('a heading that already contains bold leaves no stray asterisks', () {
      // Shapes Gemini produced on 4 Nov 2026, which showed as "...Session****".
      for (final heading in [
        '### 4. **Prepare for the Q&A Session**',
        '### **Week 2: Practice & Exam Simulation (Days 7 – 1)**',
        '### 💡 **Pro-Tip for University of Ghana Students:**',
      ]) {
        final plain = _plain(formatMessage(heading, _base));
        expect(plain.contains('*'), isFalse, reason: heading);
      }
      final spans = formatMessage('### 4. **Prepare for the Q&A Session**', _base);
      expect(_plain(spans), '4. Prepare for the Q&A Session');
      expect(_styled(spans)['4. Prepare for the Q&A Session']!.fontWeight, FontWeight.bold);
    });

    test('a divider line ("---", "***", "___") becomes a paragraph break', () {
      for (final rule in ['---', '***', '___', '- - -', ' ----- ']) {
        expect(_plain(formatMessage('above\n\n$rule\n\nbelow', _base)), 'above\n\nbelow', reason: rule);
      }
      expect(_plain(formatMessage('above\n---\nbelow', _base)), 'above\n\nbelow');
    });

    test('a divider at the start or end leaves no blank lines behind', () {
      expect(_plain(formatMessage('---\n\ntext\n\n---', _base)), 'text');
    });

    test('bold inside italics leaves no stray asterisks', () {
      // The shape Gemini produced on a phone on 4 Nov 2026, which showed "Resources* tab ... times.*".
      final spans = formatMessage('*Note: please check the **Resources** tab for the latest times.*', _base);
      expect(_plain(spans), 'Note: please check the Resources tab for the latest times.');
      final styled = _styled(spans);
      expect(styled['Resources']!.fontWeight, FontWeight.bold);
      expect(styled['Resources']!.fontStyle, FontStyle.italic, reason: 'still inside the italics');
      expect(styled['Note: please check the ']!.fontStyle, FontStyle.italic);
      expect(styled[' tab for the latest times.']!.fontStyle, FontStyle.italic);
    });

    test('math with spaced asterisks is not treated as italic', () {
      expect(_plain(formatMessage('5 * 3 * 2 = 30', _base)), '5 * 3 * 2 = 30');
    });

    test('unmatched markers are left as typed rather than eating text', () {
      expect(_plain(formatMessage('a lone ** marker and a lone * one', _base)), 'a lone ** marker and a lone * one');
      expect(_plain(formatMessage('half **open', _base)), 'half **open');
    });

    test('emphasis never spans a line break', () {
      expect(_plain(formatMessage('**one\ntwo**', _base)), '**one\ntwo**');
    });

    test('the local engine\'s real responses lose every marker', () {
      const shuttle = '🚌 **Campus Shuttle & Transit Assistance**:\n'
          '• Dedicated campus shuttles run every 8-12 minutes.\n'
          '• Standard fare: ~GH₵ 3.50 - GH₵ 5.00 per trip.';
      final plain = _plain(formatMessage(shuttle, _base));
      expect(plain.contains('**'), isFalse);
      expect(plain, startsWith('🚌 Campus Shuttle & Transit Assistance:'));
      expect(plain, contains('GH₵ 3.50 - GH₵ 5.00'));
    });

    test('empty input gives no spans', () {
      expect(formatMessage('', _base), isEmpty);
    });
  });
}
