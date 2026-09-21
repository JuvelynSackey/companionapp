import '../../core/network/api_client.dart';
import '../models/quiz_models.dart';

class QuizApi {
  QuizApi(this._client);
  final ApiClient _client;

  Future<List<QuizSummary>> fetchQuizzes({int? courseId}) => _client.guard(() async {
        final res = await _client.dio.get(
          '/quizzes',
          queryParameters: courseId != null ? {'courseId': courseId} : null,
        );
        final list = res.data['quizzes'] as List;
        return list.map((e) => QuizSummary.fromJson(e as Map<String, dynamic>)).toList();
      });

  Future<Quiz> fetchQuiz(int quizId) => _client.guard(() async {
        final res = await _client.dio.get('/quizzes/$quizId');
        return Quiz.fromJson(res.data as Map<String, dynamic>);
      });

  /// lecturer/admin only
  Future<int> createQuiz({
    required int courseId,
    required String title,
    required String source,
    required List<QuizQuestionDraft> questions,
  }) =>
      _client.guard(() async {
        final res = await _client.dio.post('/quizzes', data: {
          'courseId': courseId,
          'title': title,
          'source': source,
          'questions': questions.map((q) => q.toJson()).toList(),
        });
        return res.data['quizId'] as int;
      });

  Future<QuizAttemptResult> submitAttempt(int quizId, List<QuizAnswerInput> answers) =>
      _client.guard(() async {
        final res = await _client.dio.post('/quizzes/$quizId/attempts', data: {
          'answers': answers.map((a) => a.toJson()).toList(),
        });
        return QuizAttemptResult.fromJson(res.data as Map<String, dynamic>);
      });

  /// admin-only
  Future<void> deleteQuiz(int quizId) => _client.guard(() async {
        await _client.dio.delete('/quizzes/$quizId');
      });
}
