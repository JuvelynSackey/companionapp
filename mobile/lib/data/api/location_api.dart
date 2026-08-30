import '../../core/network/api_client.dart';
import '../models/campus_location.dart';

class LocationApi {
  LocationApi(this._client);
  final ApiClient _client;

  Future<List<CampusLocation>> fetch({String? category, String? search}) => _client.guard(() async {
        final res = await _client.dio.get('/locations', queryParameters: {
          'category': ?category,
          if (search != null && search.isNotEmpty) 'search': search,
        });
        final list = res.data['locations'] as List;
        return list.map((e) => CampusLocation.fromJson(e as Map<String, dynamic>)).toList();
      });

  Future<List<String>> fetchCategories() => _client.guard(() async {
        final res = await _client.dio.get('/locations/categories');
        return (res.data['categories'] as List).cast<String>();
      });
}
