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

  /// Server-side (not per-device) high-water mark — see
  /// users.last_synced_announcement_id in schema.sql for why.
  Future<int> fetchSyncCursor() => _client.guard(() async {
        final res = await _client.dio.get('/announcements/sync-cursor');
        return res.data['lastSyncedAnnouncementId'] as int;
      });

  /// Only ever moves the cursor forward server-side (see updateSyncCursor in
  /// announcementController.js) — safe to call with a value that turns out
  /// to be stale.
  Future<int> updateSyncCursor(int lastSyncedAnnouncementId) => _client.guard(() async {
        final res = await _client.dio.put('/announcements/sync-cursor', data: {
          'lastSyncedAnnouncementId': lastSyncedAnnouncementId,
        });
        return res.data['lastSyncedAnnouncementId'] as int;
      });
}
