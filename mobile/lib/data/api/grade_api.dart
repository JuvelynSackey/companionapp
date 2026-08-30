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
}
