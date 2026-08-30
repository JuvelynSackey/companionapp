import 'package:dio/dio.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Default matches the Android emulator's alias for the host machine.
/// Override per-run with: flutter run --dart-define=API_BASE_URL=http://192.168.x.x:4000/api
const String _defaultBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:4000/api',
);

class ApiClient {
  ApiClient(this._tokenStorage) : dio = Dio(BaseOptions(baseUrl: _defaultBaseUrl)) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.readToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio dio;
  final TokenStorage _tokenStorage;

  /// Runs [request] and rethrows any Dio error as a typed [ApiException]
  /// carrying the backend's { error, details? } shape.
  Future<T> guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Something went wrong. Please try again.';
      List<String>? details;
      if (data is Map<String, dynamic>) {
        if (data['error'] is String) message = data['error'] as String;
        final rawDetails = data['details'];
        if (rawDetails is List) {
          details = rawDetails
              .map((d) => d is Map && d['message'] != null ? d['message'].toString() : d.toString())
              .toList();
        }
      } else if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        message = 'Could not reach the server. Check your connection and try again.';
      }
      throw ApiException(message, statusCode: e.response?.statusCode, details: details);
    }
  }
}
