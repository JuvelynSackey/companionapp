import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/data/api/auth_api.dart';
import 'package:mobile/data/models/app_user.dart';
import 'package:mobile/data/repositories/auth_repository.dart';
import 'package:mobile/features/auth/session_controller.dart';

import 'support/google_auth_fakes.dart';
import 'support/local_prefs_fakes.dart';

/// In-memory fake — never touches the real FlutterSecureStorage platform channel.
class _FakeTokenStorage extends TokenStorage {
  String? _token;
  @override
  Future<String?> readToken() async => _token;
  @override
  Future<void> saveToken(String token) async => _token = token;
  @override
  Future<void> clearToken() async => _token = null;
}

Future<ProviderContainer> _container({required FakeGoogleAuthService google, required FakeGoogleAuthApi api}) async {
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(AuthRepository(api, _FakeTokenStorage(), googleAuth: google)),
    localPrefsProvider.overrideWithValue(await testLocalPrefs()),
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('SessionController.loginWithGoogle', () {
    test('a cancelled picker leaves state as data(null) — signed out, not an error', () async {
      final container = await _container(google: FakeGoogleAuthService(idToken: null), api: FakeGoogleAuthApi());
      container.listen(sessionControllerProvider, (_, _) {});
      await container.read(sessionControllerProvider.future); // build()

      await container.read(sessionControllerProvider.notifier).loginWithGoogle();

      final state = container.read(sessionControllerProvider);
      expect(state.hasError, isFalse);
      expect(state.value, isNull);
    });

    test('a successful sign-in ends with the signed-in user in state', () async {
      final api = FakeGoogleAuthApi(
        result: AuthResult('jwt', AppUser(userId: 3, fullName: 'Kojo', email: 'kojo@ug.edu.gh', role: 'student', permissions: const {})),
      );
      final container = await _container(google: FakeGoogleAuthService(idToken: 'tok'), api: api);
      container.listen(sessionControllerProvider, (_, _) {});
      await container.read(sessionControllerProvider.future);

      await container.read(sessionControllerProvider.notifier).loginWithGoogle();

      expect(container.read(sessionControllerProvider).value?.email, 'kojo@ug.edu.gh');
    });

    test('a backend failure surfaces as a state error, not an unhandled exception', () async {
      final api = FakeGoogleAuthApi()..error = ApiException('Invalid or expired Google sign-in token', statusCode: 401);
      final container = await _container(google: FakeGoogleAuthService(idToken: 'tok'), api: api);
      container.listen(sessionControllerProvider, (_, _) {});
      await container.read(sessionControllerProvider.future);

      await container.read(sessionControllerProvider.notifier).loginWithGoogle();

      expect(container.read(sessionControllerProvider).hasError, isTrue);
    });

    test('clears sessionExpiredProvider on a real sign-in, but not on a cancel', () async {
      final api = FakeGoogleAuthApi(
        result: AuthResult('jwt', AppUser(userId: 1, fullName: 'X', email: 'x@ug.edu.gh', role: 'student', permissions: const {})),
      );
      final container = await _container(google: FakeGoogleAuthService(idToken: 'tok'), api: api);
      container.listen(sessionControllerProvider, (_, _) {});
      await container.read(sessionControllerProvider.future);
      container.read(sessionExpiredProvider.notifier).state = true;

      await container.read(sessionControllerProvider.notifier).loginWithGoogle();

      expect(container.read(sessionExpiredProvider), isFalse);
    });

    test('a cancel leaves a prior "session expired" flag untouched', () async {
      final container = await _container(google: FakeGoogleAuthService(idToken: null), api: FakeGoogleAuthApi());
      container.listen(sessionControllerProvider, (_, _) {});
      await container.read(sessionControllerProvider.future);
      container.read(sessionExpiredProvider.notifier).state = true;

      await container.read(sessionControllerProvider.notifier).loginWithGoogle();

      expect(container.read(sessionExpiredProvider), isTrue, reason: 'a cancelled picker did not resolve anything');
    });
  });

  test('a successful sign-in clears a saved guest mode, so the next launch does not reopen as a guest', () async {
    final api = FakeGoogleAuthApi(
      result: AuthResult('jwt', AppUser(userId: 3, fullName: 'Kojo', email: 'kojo@ug.edu.gh', role: 'student', permissions: const {})),
    );
    final container = await _container(google: FakeGoogleAuthService(idToken: 'tok'), api: api);
    container.listen(sessionControllerProvider, (_, _) {});
    await container.read(sessionControllerProvider.future);
    await container.read(guestModeProvider.notifier).enter();
    expect(container.read(localPrefsProvider).isGuestMode, isTrue);

    await container.read(sessionControllerProvider.notifier).loginWithGoogle();

    expect(container.read(guestModeProvider), isFalse);
    expect(container.read(localPrefsProvider).isGuestMode, isFalse);
  });
}
