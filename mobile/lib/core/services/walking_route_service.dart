import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/campus_location.dart';
import '../engine/context_engine.dart';
import '../providers/core_providers.dart';
import '../storage/local_prefs.dart';

/// Walking times along real footpaths, from the FOSSGIS foot-routing server
/// (OSRM on OpenStreetMap data, the same data as the campus map). No API key
/// or account is needed, and it allows calls from the web build. Its fair-use
/// terms ask for light use, so each walk is fetched once and kept on the
/// device: campus buildings do not move, and a walk fetched once keeps
/// working offline.
class WalkingRouteService {
  /// [dio] is only overridden in tests.
  WalkingRouteService(this._prefs, {Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(connectTimeout: const Duration(seconds: 6), receiveTimeout: const Duration(seconds: 6)));

  final LocalPrefs _prefs;
  final Dio _dio;

  static const _endpoint = 'https://routing.openstreetmap.de/routed-foot/route/v1/foot';

  /// Minutes on foot from [from] to [to], rounded up, or null when no route
  /// could be fetched (offline, server busy, no path); the caller then falls
  /// back to its straight-line estimate.
  Future<int?> walkMinutes(CampusLocation from, CampusLocation to) async {
    final key = ContextEngine.walkKey(from, to);
    final saved = _prefs.walkRouteMinutes[key];
    if (saved != null) return saved;

    try {
      final response = await _dio.get(
        '$_endpoint/${from.longitude},${from.latitude};${to.longitude},${to.latitude}',
        queryParameters: {'overview': 'false'},
      );
      final data = response.data;
      if (data is! Map || data['code'] != 'Ok') return null;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;
      final seconds = (routes.first['duration'] as num?)?.toDouble();
      if (seconds == null || seconds <= 0) return null;

      final minutes = (seconds / 60).ceil();
      await _prefs.saveWalkRouteMinutes(key, minutes);
      return minutes;
    } catch (_) {
      return null;
    }
  }

  /// Routed minutes for each walk that could be fetched, keyed by
  /// ContextEngine.walkKey, ready for ContextEngine.evaluate.
  Future<Map<String, int>> walkMinutesFor(List<(CampusLocation, CampusLocation)> walks) async {
    final results = await Future.wait([for (final (from, to) in walks) walkMinutes(from, to)]);
    return {
      for (var i = 0; i < walks.length; i++)
        if (results[i] != null) ContextEngine.walkKey(walks[i].$1, walks[i].$2): results[i]!,
    };
  }
}

final walkingRouteServiceProvider = Provider<WalkingRouteService>((ref) => WalkingRouteService(ref.watch(localPrefsProvider)));
