import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/quiz_models.dart';
import 'package:mobile/features/quizzes/past_paper_extraction.dart';

void main() {
  group('PastPaperExtraction.parseQuestions', () {
    test('parses a well-formed JSON array with both question types', () {
      const reply = '''
      [
        {"questionType": "multiple_choice", "questionText": "What is 2+2?", "options": ["3", "4", "5"], "correctOption": 1, "modelAnswer": "Basic addition."},
        {"questionType": "open_ended", "questionText": "Explain Newton's third law.", "modelAnswer": "For every action there is an equal and opposite reaction."}
      ]
      ''';

      final questions = PastPaperExtraction.parseQuestions(reply);

      expect(questions, hasLength(2));
      expect(questions[0].questionType, QuestionType.multipleChoice);
      expect(questions[0].options, ['3', '4', '5']);
      expect(questions[0].correctOption, 1);
      expect(questions[1].questionType, QuestionType.openEnded);
      expect(questions[1].options, isNull);
      expect(questions[1].modelAnswer, contains('equal and opposite'));
    });

    test('strips markdown code fences Gemini sometimes adds despite instructions', () {
      const reply = '''
```json
[{"questionType": "open_ended", "questionText": "Define entropy.", "modelAnswer": "A measure of disorder."}]
```
''';

      final questions = PastPaperExtraction.parseQuestions(reply);

      expect(questions, hasLength(1));
      expect(questions.first.questionText, 'Define entropy.');
    });

    test('defaults a missing correctOption to 0 rather than throwing', () {
      const reply = '[{"questionType": "multiple_choice", "questionText": "Pick one", "options": ["a", "b"]}]';

      final questions = PastPaperExtraction.parseQuestions(reply);

      expect(questions.first.correctOption, 0);
    });

    test('returns an empty list for malformed JSON instead of throwing', () {
      expect(PastPaperExtraction.parseQuestions('not json at all'), isEmpty);
    });

    test('returns an empty list for an empty array response (no extractable questions)', () {
      expect(PastPaperExtraction.parseQuestions('[]'), isEmpty);
    });

    test('truncate leaves short text untouched', () {
      const text = 'short exam text';
      expect(PastPaperExtraction.truncate(text), text);
    });

    test('truncate caps text at maxExtractedChars', () {
      final longText = 'a' * (PastPaperExtraction.maxExtractedChars + 500);
      final truncated = PastPaperExtraction.truncate(longText);
      expect(truncated.length, PastPaperExtraction.maxExtractedChars);
    });
  });
}
