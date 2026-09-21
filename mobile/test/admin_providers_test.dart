import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/features/admin/admin_providers.dart';
import 'package:mobile/features/auth/session_controller.dart';

import 'support/admin_fakes.dart';

ProviderContainer _container({FakeAdminApi? api, dynamic user}) {
  final container = ProviderContainer(overrides: [
    if (api != null) adminApiProvider.overrideWithValue(api),
    sessionControllerProvider.overrideWith(() => FakeSessionController(user)),
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('isAdminProvider', () {
    test('true only for an admin', () async {
      for (final entry in {adminUser: true, lecturerUser: false, studentUser: false, null: false}.entries) {
        final container = _container(user: entry.key);
        await container.read(sessionControllerProvider.future);
        expect(container.read(isAdminProvider), entry.value, reason: '${entry.key?.role}');
      }
    });

    test('false while the session is still loading', () {
      final container = _container(user: adminUser);
      expect(container.read(isAdminProvider), isFalse);
    });
  });

  group('ProvisionUserController', () {
    Future<bool> provision(ProviderContainer c, {String role = 'lecturer'}) =>
        c.read(provisionUserProvider.notifier).provision(
              fullName: 'Dr. Ama Mensah',
              email: 'ama@ug.edu.gh',
              password: 'longenough1',
              role: role,
            );

    test('starts idle', () async {
      final container = _container(api: FakeAdminApi());
      container.listen(provisionUserProvider, (_, _) {});
      await container.read(provisionUserProvider.future);

      expect(container.read(provisionUserProvider).valueOrNull, isNull);
    });

    test('a successful request returns true and exposes the created user', () async {
      final api = FakeAdminApi();
      final container = _container(api: api);
      container.listen(provisionUserProvider, (_, _) {});

      expect(await provision(container), isTrue);

      final created = container.read(provisionUserProvider).requireValue!;
      expect(created.fullName, 'Dr. Ama Mensah');
      expect(created.role, 'lecturer');
      expect(api.provisioned.single, {
        'fullName': 'Dr. Ama Mensah',
        'email': 'ama@ug.edu.gh',
        'password': 'longenough1',
        'role': 'lecturer',
      });
    });

    test('a failed request returns false and keeps the backend message', () async {
      final api = FakeAdminApi()
        ..provisionError = ApiException('An account with that email already exists', statusCode: 409);
      final container = _container(api: api);
      container.listen(provisionUserProvider, (_, _) {});

      expect(await provision(container), isFalse);

      final state = container.read(provisionUserProvider);
      expect(state.hasError, isTrue);
      expect(describeApiError(state.error!), 'An account with that email already exists');
    });

    test('a second request while one is in flight is ignored', () async {
      final api = FakeAdminApi();
      final gate = Completer<void>();
      api.onProvision = () => gate.future;
      final container = _container(api: api);
      container.listen(provisionUserProvider, (_, _) {});

      final first = provision(container);
      final second = await provision(container);
      gate.complete();
      final firstResult = await first;

      expect(second, isFalse);
      expect(firstResult, isTrue);
      expect(api.provisioned.length, 1);
    });

    test('a new request after a failure is allowed and can succeed', () async {
      final api = FakeAdminApi()..provisionError = ApiException('nope', statusCode: 500);
      final container = _container(api: api);
      container.listen(provisionUserProvider, (_, _) {});

      expect(await provision(container), isFalse);
      api.provisionError = null;
      expect(await provision(container), isTrue);
      expect(container.read(provisionUserProvider).hasError, isFalse);
    });
  });

  group('describeApiError', () {
    test('uses the message alone when there are no details', () {
      expect(describeApiError(ApiException('Incorrect email or password', statusCode: 401)), 'Incorrect email or password');
    });

    test('appends validation details', () {
      final error = ApiException('Validation failed', statusCode: 400, details: [
        'Password must be at least 8 characters',
        'Enter a valid email address',
      ]);
      expect(
        describeApiError(error),
        'Validation failed: Password must be at least 8 characters; Enter a valid email address',
      );
    });

    test('falls back to a generic message for unexpected errors', () {
      expect(describeApiError(StateError('boom')), 'Something went wrong. Please try again.');
    });
  });
}
