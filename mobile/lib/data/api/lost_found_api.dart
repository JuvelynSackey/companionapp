import '../../core/network/api_client.dart';
import '../models/lost_found_item.dart';

class LostFoundApi {
  LostFoundApi(this._client);
  final ApiClient _client;

  /// Guest-readable; open items first, newest first.
  Future<List<LostFoundItem>> fetch() => _client.guard(() async {
        final res = await _client.dio.get('/lost-found');
        final list = res.data['items'] as List;
        return list.map((i) => LostFoundItem.fromJson(i as Map<String, dynamic>)).toList();
      });

  /// Returns how many open posts of the other kind may be the same item;
  /// their posters are notified by the server.
  Future<int> post({
    required LostFoundKind kind,
    required String title,
    String? description,
    String? location,
    String? contact,
  }) =>
      _client.guard(() async {
        final res = await _client.dio.post('/lost-found', data: {
          'kind': kind.apiValue,
          'title': title,
          if (description != null && description.isNotEmpty) 'description': description,
          if (location != null && location.isNotEmpty) 'location': location,
          if (contact != null && contact.isNotEmpty) 'contact': contact,
        });
        final data = res.data;
        return data is Map && data['possibleMatches'] is List ? (data['possibleMatches'] as List).length : 0;
      });

  /// Only the poster or an admin; the server answers 403 otherwise.
  Future<void> markReturned(int itemId) => _client.guard(() async {
        await _client.dio.patch('/lost-found/$itemId/returned');
      });

  /// Only the poster or an admin; the server answers 403 otherwise.
  Future<void> remove(int itemId) => _client.guard(() async {
        await _client.dio.delete('/lost-found/$itemId');
      });
}
