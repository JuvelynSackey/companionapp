import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/core/storage/token_storage.dart';

/// In-memory fake — never touches the real FlutterSecureStorage platform
/// channel, so it's safe to use in a plain `flutter test` unit test.
class _FakeTokenStorage extends TokenStorage {
  String? _token;
  bool cleared = false;

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> saveToken(String token) async => _token = token;

  @override
  Future<void> clearToken() async {
    cleared = true;
    _token = null;
  }
}

/// [sentToken]: whether the failed request carried an Authorization header
/// (the interceptor adds one whenever a token is stored; a guest has none).
DioException _dioErrorWithStatus(int? statusCode, {bool sentToken = true}) {
  final options = RequestOptions(
    path: '/whatever',
    headers: sentToken ? {'Authorization': 'Bearer dead-token'} : null,
  );
  return DioException(
    requestOptions: options,
    response: statusCode == null
        ? null
        : Response(requestOptions: options, statusCode: statusCode, data: {'error': 'boom'}),
  );
}

void main() {
  group('ApiClient.guard', () {
    // Regression test: a real bug found via code review — a 401 from any
    // endpoint (not just /auth/me) always means the JWT itself is dead
    // (see backend/src/middleware/auth.js: 401 is only ever "missing,
    // invalid, or expired token"; insufficient permissions is 403). Before
    // this fix, only AuthRepository.restoreSession ever cleared the token,
    // so a token that expired mid-session while calling some other
    // endpoint left a dead token sitting in storage indefinitely.
    test('clears the stored token when a request fails with 401', () async {
      final tokenStorage = _FakeTokenStorage()..saveToken('dead-token');
      final client = ApiClient(tokenStorage);

      await expectLater(
        client.guard(() async => throw _dioErrorWithStatus(401)),
        throwsA(isA<ApiException>()),
      );

      expect(tokenStorage.cleared, isTrue);
    });

    test('a 401 on a request that carried a token reports the session expired', () async {
      var expired = 0;
      final client = ApiClient(_FakeTokenStorage()..saveToken('dead-token'), onSessionExpired: () => expired++);

      await expectLater(client.guard(() async => throw _dioErrorWithStatus(401)), throwsA(isA<ApiException>()));

      expect(expired, 1);
    });

    // Guest mode: a guest has no token, so a 401 from an account-only route
    // must not throw them onto the "your session expired" screen.
    test('a 401 on a request sent without a token does not report an expired session', () async {
      var expired = 0;
      final tokenStorage = _FakeTokenStorage();
      final client = ApiClient(tokenStorage, onSessionExpired: () => expired++);

      await expectLater(
        client.guard(() async => throw _dioErrorWithStatus(401, sentToken: false)),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );

      expect(expired, 0);
      expect(tokenStorage.cleared, isFalse);
    });

    test('does not clear the token for an unrelated server error (500)', () async {
      final tokenStorage = _FakeTokenStorage()..saveToken('still-valid');
      final client = ApiClient(tokenStorage);

      await expectLater(
        client.guard(() async => throw _dioErrorWithStatus(500)),
        throwsA(isA<ApiException>()),
      );

      expect(tokenStorage.cleared, isFalse);
    });

    test('does not clear the token for a network-level failure (no response)', () async {
      final tokenStorage = _FakeTokenStorage()..saveToken('still-valid');
      final client = ApiClient(tokenStorage);

      await expectLater(
        client.guard(() async => throw _dioErrorWithStatus(null)),
        throwsA(isA<ApiException>()),
      );

      expect(tokenStorage.cleared, isFalse);
    });
  });
}
