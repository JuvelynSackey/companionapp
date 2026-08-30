import '../../core/network/api_client.dart';
import '../models/announcement.dart';

class AnnouncementApi {
  AnnouncementApi(this._client);
  final ApiClient _client;

  Future<List<Announcement>> fetch({int limit = 50}) => _client.guard(() async {
        final res = await _client.dio.get('/announcements', queryParameters: {'limit': limit});
        final list = res.data['announcements'] as List;
        return list.map((e) => Announcement.fromJson(e as Map<String, dynamic>)).toList();
      });

  /// admin-only
  Future<int> create({
    required String title,
    required String message,
    String category = 'general',
  }) =>
      _client.guard(() async {
        final res = await _client.dio.post('/announcements', data: {
          'title': title,
          'message': message,
          'category': category,
        });
        return res.data['announcementId'] as int;
      });

  /// admin-only
  Future<void> delete(int announcementId) => _client.guard(() async {
        await _client.dio.delete('/announcements/$announcementId');
      });
}
