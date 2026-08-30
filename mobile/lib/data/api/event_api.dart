import '../../core/network/api_client.dart';
import '../models/campus_event.dart';

class EventApi {
  EventApi(this._client);
  final ApiClient _client;

  Future<List<CampusEvent>> fetch({bool upcoming = true}) => _client.guard(() async {
        final res = await _client.dio.get('/events', queryParameters: {'upcoming': upcoming});
        final list = res.data['events'] as List;
        return list.map((e) => CampusEvent.fromJson(e as Map<String, dynamic>)).toList();
      });

  /// admin-only
  Future<int> create({
    required String title,
    required String description,
    required DateTime eventDate,
    String? location,
  }) =>
      _client.guard(() async {
        final res = await _client.dio.post('/events', data: {
          'title': title,
          'description': description,
          'eventDate': eventDate.toIso8601String(),
          if (location != null && location.isNotEmpty) 'location': location,
        });
        return res.data['eventId'] as int;
      });

  /// Real RSVP against the backend, not a local-only bookmark flag.
  Future<void> register(int eventId) => _client.guard(() async {
        await _client.dio.post('/events/$eventId/register');
      });

  Future<void> cancelRegistration(int eventId) => _client.guard(() async {
        await _client.dio.delete('/events/$eventId/register');
      });
}
