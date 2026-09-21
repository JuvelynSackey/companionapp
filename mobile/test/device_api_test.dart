import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/data/api/device_api.dart';
import 'package:mobile/data/models/notification_preferences.dart';

class _FakeTokenStorage extends TokenStorage {
  @override
  Future<String?> readToken() async => 'jwt';
  @override
  Future<void> saveToken(String token) async {}
  @override
  Future<void> clearToken() async {}
}

/// Records the request and answers with [body] / [status] instead of sending it.
class _Adapter implements HttpClientAdapter {
  _Adapter({this.body = const {}, this.status = 200});
  final Object body;
  final int status;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    last = options;
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

DeviceApi _api(_Adapter adapter) => DeviceApi(ApiClient(_FakeTokenStorage())..dio.httpClientAdapter = adapter);

void main() {
  test('registerToken POSTs the token and platform to /users/me/device-token', () async {
    final adapter = _Adapter(body: {'registered': true, 'registeredDevices': 1});

    await _api(adapter).registerToken('fcm-token-abc', platform: 'android');

    expect(adapter.last!.method, 'POST');
    expect(adapter.last!.path, '/users/me/device-token');
    expect(adapter.last!.data, {'token': 'fcm-token-abc', 'platform': 'android'});
  });

  test('unregisterToken DELETEs /users/me/device-token with the token in the body', () async {
    final adapter = _Adapter(status: 204);

    await _api(adapter).unregisterToken('fcm-token-abc');

    expect(adapter.last!.method, 'DELETE');
    expect(adapter.last!.path, '/users/me/device-token');
    expect(adapter.last!.data, {'token': 'fcm-token-abc'});
  });

  test('fetchPreferences reads the server\'s answer', () async {
    final adapter = _Adapter(body: {'pushEnabled': false, 'registeredDevices': 2});

    final prefs = await _api(adapter).fetchPreferences();

    expect(adapter.last!.method, 'GET');
    expect(adapter.last!.path, '/users/me/notification-preferences');
    expect(prefs.pushEnabled, isFalse);
    expect(prefs.registeredDevices, 2);
  });

  test('setPushEnabled PUTs the flag and returns the saved preference', () async {
    final adapter = _Adapter(body: {'pushEnabled': true, 'registeredDevices': 1});

    final prefs = await _api(adapter).setPushEnabled(true);

    expect(adapter.last!.method, 'PUT');
    expect(adapter.last!.path, '/users/me/notification-preferences');
    expect(adapter.last!.data, {'pushEnabled': true});
    expect(prefs.pushEnabled, isTrue);
  });

  test('a server error becomes an ApiException carrying its message', () async {
    final adapter = _Adapter(status: 400, body: {'error': 'Validation failed'});

    await expectLater(
      _api(adapter).registerToken('x', platform: 'android'),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Validation failed')),
    );
  });

  test('NotificationPreferences.copyWith changes only the flag', () {
    const prefs = NotificationPreferences(pushEnabled: true, registeredDevices: 4);
    final off = prefs.copyWith(pushEnabled: false);
    expect(off.pushEnabled, isFalse);
    expect(off.registeredDevices, 4);
  });
}
