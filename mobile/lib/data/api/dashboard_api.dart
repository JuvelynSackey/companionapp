import '../../core/network/api_client.dart';
import '../models/dashboard_data.dart';

class DashboardApi {
  DashboardApi(this._client);
  final ApiClient _client;

  Future<DashboardData> fetch() => _client.guard(() async {
        final res = await _client.dio.get('/dashboard');
        return DashboardData.fromJson(res.data as Map<String, dynamic>);
      });
}
