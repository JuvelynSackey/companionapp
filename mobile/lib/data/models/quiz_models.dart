enum QuestionType { multipleChoice, openEnded }

QuestionType _questionTypeFromJson(String value) => switch (value) {
      'multiple_choice' => QuestionType.multipleChoice,
      'open_ended' => QuestionType.openEnded,
      _ => throw ArgumentError('Unknown question type: $value'),
    };

String questionTypeToJson(QuestionType type) => switch (type) {
      QuestionType.multipleChoice => 'multiple_choice',
      QuestionType.openEnded => 'open_ended',
    };

/// A quiz as listed (no questions) — GET /api/quizzes.
class QuizSummary {
  const QuizSummary({
    required this.quizId,
    required this.title,
    required this.source,
    required this.courseId,
    required this.courseCode,
    required this.questionCount,
    required this.createdAt,
  });

  factory QuizSummary.fromJson(Map<String, dynamic> json) => QuizSummary(
        quizId: json['quizId'] as int,
        title: json['title'] as String,
        source: json['source'] as String,
        courseId: json['courseId'] as int,
        courseCode: json['courseCode'] as String,
        questionCount: json['questionCount'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  final int quizId;
  final String title;
  final String source; // 'manual' | 'past_paper'
  final int courseId;
  final String courseCode;
  final int questionCount;
  final DateTime createdAt;
}

/// A question as served for *taking* a quiz — the answer key
/// (correctOption/modelAnswer) is deliberately absent; the backend strips
/// it from GET /api/quizzes/:id and only reveals it in the attempt
/// submission response (see QuizAttemptResult).
class QuizQuestion {
  const QuizQuestion({
    required this.questionId,
    required this.questionType,
    required this.questionText,
    required this.options,
    required this.orderIndex,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        questionId: json['questionId'] as int,
        questionType: _questionTypeFromJson(json['questionType'] as String),
        questionText: json['questionText'] as String,
        options: (json['options'] as List?)?.map((e) => e as String).toList(),
        orderIndex: json['orderIndex'] as int,
      );

  final int questionId;
  final QuestionType questionType;
  final String questionText;
  final List<String>? options; // multiple_choice only
  final int orderIndex;
}

/// Full quiz detail for the take-quiz screen — GET /api/quizzes/:id.
class Quiz {
  const Quiz({
    required this.quizId,
    required this.title,
    required this.source,
    required this.courseId,
    required this.courseCode,
    required this.courseTitle,
    required this.questions,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) => Quiz(
        quizId: json['quizId'] as int,
        title: json['title'] as String,
        source: json['source'] as String,
        courseId: json['courseId'] as int,
        courseCode: json['courseCode'] as String,
        courseTitle: json['courseTitle'] as String,
        questions: (json['questions'] as List)
            .map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final int quizId;
  final String title;
  final String source;
  final int courseId;
  final String courseCode;
  final String courseTitle;
  final List<QuizQuestion> questions;
}

/// A single answer being submitted for grading.
class QuizAnswerInput {
  const QuizAnswerInput({required this.questionId, this.selectedOption, this.freeTextAnswer});

  final int questionId;
  final int? selectedOption;
  final String? freeTextAnswer;

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        if (selectedOption != null) 'selectedOption': selectedOption,
        if (freeTextAnswer != null) 'freeTextAnswer': freeTextAnswer,
      };
}

/// Per-question result revealed only after submitting an attempt —
/// isCorrect is null for open_ended (never auto-graded; the student
/// self-marks against modelAnswer).
class QuizQuestionResult {
  const QuizQuestionResult({
    required this.questionId,
    required this.isCorrect,
    required this.correctOption,
    required this.modelAnswer,
  });

  factory QuizQuestionResult.fromJson(Map<String, dynamic> json) => QuizQuestionResult(
        questionId: json['questionId'] as int,
        isCorrect: json['isCorrect'] as bool?,
        correctOption: json['correctOption'] as int?,
        modelAnswer: json['modelAnswer'] as String?,
      );

  final int questionId;
  final bool? isCorrect;
  final int? correctOption;
  final String? modelAnswer;
}

class QuizAttemptResult {
  const QuizAttemptResult({
    required this.attemptId,
    required this.score,
    required this.totalGraded,
    required this.results,
  });

  factory QuizAttemptResult.fromJson(Map<String, dynamic> json) => QuizAttemptResult(
        attemptId: json['attemptId'] as int,
        score: (json['score'] as num?)?.toDouble(),
        totalGraded: json['totalGraded'] as int,
        results: (json['results'] as List)
            .map((e) => QuizQuestionResult.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final int attemptId;
  final double? score; // null when the quiz has no multiple_choice questions
  final int totalGraded;
  final List<QuizQuestionResult> results;
}

/// A question being authored (manually or from a reviewed PDF-extraction
/// draft) — the shape POSTed to /api/quizzes, carrying the answer key the
/// student-facing QuizQuestion deliberately omits.
class QuizQuestionDraft {
  QuizQuestionDraft({
    required this.questionType,
    required this.questionText,
    this.options,
    this.correctOption,
    this.modelAnswer,
    String? id,
  }) : id = id ?? _generateId();

  static int _idCounter = 0;
  static String _generateId() => 'draft_${_idCounter++}';

  /// Client-only identity for stable widget keying in the question editor
  /// (see QuestionEditorList) — never sent to the backend.
  final String id;
  final QuestionType questionType;
  final String questionText;
  final List<String>? options;
  final int? correctOption;
  final String? modelAnswer;

  /// Note: cannot null-out options/correctOption/modelAnswer via this method
  /// (a `??` can't distinguish "not provided" from "clear it") — switching
  /// question type constructs a fresh QuizQuestionDraft directly instead
  /// (see QuestionEditorList's _setType) rather than using copyWith for that.
  QuizQuestionDraft copyWith({
    QuestionType? questionType,
    String? questionText,
    List<String>? options,
    int? correctOption,
    String? modelAnswer,
  }) =>
      QuizQuestionDraft(
        id: id,
        questionType: questionType ?? this.questionType,
        questionText: questionText ?? this.questionText,
        options: options ?? this.options,
        correctOption: correctOption ?? this.correctOption,
        modelAnswer: modelAnswer ?? this.modelAnswer,
      );

  Map<String, dynamic> toJson() => {
        'questionType': questionTypeToJson(questionType),
        'questionText': questionText,
        if (options != null) 'options': options,
        if (correctOption != null) 'correctOption': correctOption,
        if (modelAnswer != null) 'modelAnswer': modelAnswer,
      };
}
