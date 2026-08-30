import '../../core/network/api_client.dart';
import '../models/schedule_entry.dart';

class ScheduleApi {
  ScheduleApi(this._client);
  final ApiClient _client;

  Future<List<ScheduleEntry>> fetch({int? day}) => _client.guard(() async {
        final res = await _client.dio.get(
          '/schedule',
          queryParameters: day != null ? {'day': day} : null,
        );
        final list = res.data['schedule'] as List;
        return list.map((e) => ScheduleEntry.fromJson(e as Map<String, dynamic>)).toList();
      });

  /// admin-only
  Future<int> create({
    required int courseId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? room,
  }) =>
      _client.guard(() async {
        final res = await _client.dio.post('/schedule', data: {
          'courseId': courseId,
          'dayOfWeek': dayOfWeek,
          'startTime': startTime,
          'endTime': endTime,
          if (room != null && room.isNotEmpty) 'room': room,
        });
        return res.data['scheduleId'] as int;
      });

  /// admin-only
  Future<void> delete(int scheduleId) => _client.guard(() async {
        await _client.dio.delete('/schedule/$scheduleId');
      });
}
