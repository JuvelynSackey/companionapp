import '../../core/network/api_client.dart';
import '../models/club.dart';

class ClubApi {
  ClubApi(this._client);
  final ApiClient _client;

  Future<List<Club>> fetch() => _client.guard(() async {
        final res = await _client.dio.get('/clubs');
        final list = res.data['clubs'] as List;
        return list.map((c) => Club.fromJson(c as Map<String, dynamic>)).toList();
      });

  /// Idempotent on the server: joining twice is a 201 with alreadyMember.
  Future<void> join(int clubId) => _client.guard(() async {
        await _client.dio.post('/clubs/$clubId/join');
      });

  /// 404 means the caller was not a member.
  Future<void> leave(int clubId) => _client.guard(() async {
        await _client.dio.delete('/clubs/$clubId/join');
      });
}
