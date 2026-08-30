import '../../core/network/api_client.dart';
import '../models/course.dart';

class CourseApi {
  CourseApi(this._client);
  final ApiClient _client;

  Future<List<Course>> fetch() => _client.guard(() async {
        final res = await _client.dio.get('/courses');
        final list = res.data['courses'] as List;
        return list.map((e) => Course.fromJson(e as Map<String, dynamic>)).toList();
      });
}
