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
  ApiClient(this._tokenStorage, {this.onSessionExpired}) : dio = Dio(BaseOptions(baseUrl: _defaultBaseUrl)) {
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

  /// Fired when a request comes back 401 mid-session (the token was valid
  /// at app launch but got rejected later — expiry, revocation, etc.).
  /// Wired in core_providers.dart to invalidate the session and flip
  /// sessionExpiredProvider, since without this the student would keep
  /// sitting on whatever screen they were on making requests that all fail
  /// silently until the next app restart.
  final void Function()? onSessionExpired;

  /// Runs [request] and rethrows any Dio error as a typed [ApiException]
  /// carrying the backend's { error, details? } shape.
  ///
  /// A 401 here always means the token itself is dead (see
  /// backend/src/middleware/auth.js — it never means "wrong permissions",
  /// that's 403), so it's cleared centrally right here rather than leaving
  /// every call site to notice and do it themselves. onSessionExpired then
  /// propagates this to the app state immediately, rather than leaving the
  /// student on a broken screen until the next app launch.
  ///
  /// Only a 401 on a request that carried a token counts: a guest (no token)
  /// hitting an account-only route has no session to expire, and must not be
  /// thrown onto the "your session expired" screen.
  Future<T> guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && e.requestOptions.headers['Authorization'] != null) {
        await _tokenStorage.clearToken();
        onSessionExpired?.call();
      }
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
