import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/services/walking_route_service.dart';
import 'package:mobile/data/models/campus_location.dart';

import 'support/local_prefs_fakes.dart';

/// Answers each request with [body] (or fails) and records what was asked.
class _Adapter implements HttpClientAdapter {
  _Adapter({this.body, this.fail = false});
  final Map<String, dynamic>? body;
  final bool fail;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    if (fail) throw DioException(requestOptions: options, type: DioExceptionType.connectionError);
    return ResponseBody.fromString(jsonEncode(body ?? {}), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

/// The shape the foot-routing server returned for Balme Library to the Great Hall.
Map<String, dynamic> _route(double seconds) => {
      'code': 'Ok',
      'routes': [
        {'duration': seconds, 'distance': 319.2},
      ],
    };

final _balme = CampusLocation(locationId: 1, name: 'Balme Library', category: 'library', description: '', latitude: 5.6508, longitude: -0.1866);
final _greatHall = CampusLocation(locationId: 2, name: 'Great Hall', category: 'other', description: '', latitude: 5.6522, longitude: -0.1869);

void main() {
  test('asks the foot-routing server for the walk, longitude first, and rounds the time up', () async {
    final adapter = _Adapter(body: _route(255.5));
    final service = WalkingRouteService(await testLocalPrefs(), dio: Dio()..httpClientAdapter = adapter);

    expect(await service.walkMinutes(_balme, _greatHall), 5, reason: '255.5 s is 4.26 min, rounded up');
    expect(
      adapter.requests.single.uri.toString(),
      'https://routing.openstreetmap.de/routed-foot/route/v1/foot/-0.1866,5.6508;-0.1869,5.6522?overview=false',
    );
  });

  test('a walk is fetched once and then read from the device, so it also works offline', () async {
    final prefs = await testLocalPrefs();
    final online = _Adapter(body: _route(255.5));
    await WalkingRouteService(prefs, dio: Dio()..httpClientAdapter = online).walkMinutes(_balme, _greatHall);

    final offline = _Adapter(fail: true);
    final again = WalkingRouteService(prefs, dio: Dio()..httpClientAdapter = offline);
    expect(await again.walkMinutes(_balme, _greatHall), 5);
    expect(offline.requests, isEmpty);
  });

  test('no route (offline, or the server finds none) gives null, and nothing is saved', () async {
    final prefs = await testLocalPrefs();
    expect(await WalkingRouteService(prefs, dio: Dio()..httpClientAdapter = _Adapter(fail: true)).walkMinutes(_balme, _greatHall), isNull);
    expect(
      await WalkingRouteService(prefs, dio: Dio()..httpClientAdapter = _Adapter(body: {'code': 'NoRoute', 'routes': []}))
          .walkMinutes(_balme, _greatHall),
      isNull,
    );
    expect(prefs.walkRouteMinutes, isEmpty);
  });

  test('walkMinutesFor keeps only the walks that could be routed', () async {
    final service = WalkingRouteService(await testLocalPrefs(), dio: Dio()..httpClientAdapter = _Adapter(fail: true));
    expect(await service.walkMinutesFor([(_balme, _greatHall)]), isEmpty);

    final routed = WalkingRouteService(await testLocalPrefs(), dio: Dio()..httpClientAdapter = _Adapter(body: _route(400)));
    expect(await routed.walkMinutesFor([(_balme, _greatHall), (_greatHall, _balme)]), {'1-2': 7, '2-1': 7});
  });
}
