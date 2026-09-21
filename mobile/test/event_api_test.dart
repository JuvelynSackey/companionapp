import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/data/api/event_api.dart';

class _FakeTokenStorage extends TokenStorage {
  @override
  Future<String?> readToken() async => 'token';
  @override
  Future<void> saveToken(String token) async {}
  @override
  Future<void> clearToken() async {}
}

/// Records the request instead of sending it.
class _CaptureAdapter implements HttpClientAdapter {
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    last = options;
    return ResponseBody.fromString(jsonEncode({'eventId': 9}), 201, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('EventApi.create', () {
    // Regression test: the app used to send a local DateTime's
    // toIso8601String() ("2030-05-01T17:00:00.000", no offset), which the
    // backend's z.string().datetime({ offset: true }) rejects with
    // "Invalid datetime" — so creating an event from the app never worked.
    test('sends the event date as UTC with a Z offset, for the same instant', () async {
      final adapter = _CaptureAdapter();
      final client = ApiClient(_FakeTokenStorage())..dio.httpClientAdapter = adapter;
      final local = DateTime(2030, 5, 1, 17, 0); // what the date/time pickers build

      final id = await EventApi(client).create(
        title: 'Hackathon',
        description: 'Overnight',
        eventDate: local,
        location: 'Great Hall',
      );

      expect(id, 9);
      final sent = (adapter.last!.data as Map)['eventDate'] as String;
      expect(sent, endsWith('Z'));
      expect(DateTime.parse(sent).isAtSameMomentAs(local), isTrue);
      expect(adapter.last!.method, 'POST');
      expect(adapter.last!.path, '/events');
    });

    test('omits an empty location', () async {
      final adapter = _CaptureAdapter();
      final client = ApiClient(_FakeTokenStorage())..dio.httpClientAdapter = adapter;

      await EventApi(client).create(title: 'Talk', description: '', eventDate: DateTime(2030, 1, 1), location: '');

      expect((adapter.last!.data as Map).containsKey('location'), isFalse);
    });
  });
}
