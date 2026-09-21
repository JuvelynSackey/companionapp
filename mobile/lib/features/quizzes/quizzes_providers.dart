import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../data/models/quiz_models.dart';

final quizzesForCourseProvider =
    FutureProvider.autoDispose.family<List<QuizSummary>, int>((ref, courseId) {
  return ref.watch(quizApiProvider).fetchQuizzes(courseId: courseId);
});

final quizDetailProvider = FutureProvider.autoDispose.family<Quiz, int>((ref, quizId) {
  return ref.watch(quizApiProvider).fetchQuiz(quizId);
});

/// Thin wrapper over QuizApi for the write actions (create/submit/delete) —
/// kept as a stateless action bundle rather than holding data itself, since
/// the list/detail providers above already own that via FutureProvider.
class QuizActionsController extends Notifier<void> {
  @override
  void build() {}

  Future<int> createQuiz({
    required int courseId,
    required String title,
    required String source,
    required List<QuizQuestionDraft> questions,
  }) {
    return ref.read(quizApiProvider).createQuiz(courseId: courseId, title: title, source: source, questions: questions);
  }

  Future<QuizAttemptResult> submitAttempt(int quizId, List<QuizAnswerInput> answers) {
    return ref.read(quizApiProvider).submitAttempt(quizId, answers);
  }

  Future<void> deleteQuiz(int quizId) {
    return ref.read(quizApiProvider).deleteQuiz(quizId);
  }
}

final quizActionsControllerProvider = NotifierProvider<QuizActionsController, void>(QuizActionsController.new);
