import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/data/api/auth_api.dart';
import 'package:mobile/data/models/app_user.dart';
import 'package:mobile/data/repositories/auth_repository.dart';

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

class _FakeAuthApi extends AuthApi {
  _FakeAuthApi(this._meImpl) : super(ApiClient(TokenStorage()));
  final Future<AppUser> Function() _meImpl;

  @override
  Future<AppUser> me() => _meImpl();
}

void main() {
  group('AuthRepository.restoreSession', () {
    // Regression test: a real bug found via code review — restoreSession()
    // used to catch every failure from /auth/me identically and clear the
    // stored token, which meant a transient network error on app launch
    // (no connection, backend down, a timeout) silently signed the student
    // out even though their token was still perfectly valid. Only a genuine
    // 401 from the backend (see backend/src/middleware/auth.js) means the
    // token itself is invalid/expired.
    test('clears the token and returns null on a 401 (genuinely invalid token)', () async {
      final tokenStorage = _FakeTokenStorage()..saveToken('stale-token');
      final api = _FakeAuthApi(() async => throw ApiException('Invalid or expired token', statusCode: 401));
      final repo = AuthRepository(api, tokenStorage);

      final result = await repo.restoreSession();

      expect(result.user, isNull);
      expect(result.expired, isTrue);
      expect(tokenStorage.cleared, isTrue);
    });

    test('keeps the token and rethrows on a network failure (no statusCode)', () async {
      final tokenStorage = _FakeTokenStorage()..saveToken('still-valid-token');
      final api = _FakeAuthApi(
        () async => throw ApiException('Could not reach the server. Check your connection and try again.'),
      );
      final repo = AuthRepository(api, tokenStorage);

      await expectLater(repo.restoreSession(), throwsA(isA<ApiException>()));
      expect(tokenStorage.cleared, isFalse);
      expect(await tokenStorage.readToken(), 'still-valid-token');
    });

    test('keeps the token and rethrows on an unrelated server error (500)', () async {
      final tokenStorage = _FakeTokenStorage()..saveToken('still-valid-token');
      final api = _FakeAuthApi(
        () async => throw ApiException('Something went wrong. Please try again.', statusCode: 500),
      );
      final repo = AuthRepository(api, tokenStorage);

      await expectLater(repo.restoreSession(), throwsA(isA<ApiException>()));
      expect(tokenStorage.cleared, isFalse);
    });

    test('returns null without calling the API when there is no stored token', () async {
      final tokenStorage = _FakeTokenStorage();
      var calls = 0;
      final api = _FakeAuthApi(() async {
        calls++;
        throw ApiException('should not be called');
      });
      final repo = AuthRepository(api, tokenStorage);

      final result = await repo.restoreSession();

      expect(result.user, isNull);
      expect(result.expired, isFalse);
      expect(calls, 0);
    });
  });
}
