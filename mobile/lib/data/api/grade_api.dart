import '../../core/network/api_client.dart';
import '../models/course_grade.dart';

class GradeApi {
  GradeApi(this._client);
  final ApiClient _client;

  Future<List<CourseGrade>> fetch() => _client.guard(() async {
        final res = await _client.dio.get('/grades');
        final list = res.data['grades'] as List;
        return list.map((e) => CourseGrade.fromJson(e as Map<String, dynamic>)).toList();
      });

  /// Records one of the student's own results (POST /api/grades/mine). The
  /// server refuses (409) to overwrite an official grade.
  Future<void> addMine({
    required String courseCode,
    required String courseTitle,
    required int creditHours,
    required double score,
    required String semester,
  }) =>
      _client.guard(() async {
        await _client.dio.post('/grades/mine', data: {
          'courseCode': courseCode,
          'courseTitle': courseTitle,
          'creditHours': creditHours,
          'score': score,
          'semester': semester,
        });
      });

  /// Removes one of the student's own, self-entered results.
  Future<void> deleteMine(int gradeId) => _client.guard(() async {
        await _client.dio.delete('/grades/mine/$gradeId');
      });
}
