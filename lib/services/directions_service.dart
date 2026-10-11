import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../config/api_keys.dart';
import '../models/route_option.dart';
import 'places_service.dart';

/// Real route computation via Google Directions API, with a safety score
/// derived from how many police stations sit near each alternative route.
/// Replaces SafetyService.routeOptions().
class DirectionsService {
  DirectionsService._();
  static final DirectionsService instance = DirectionsService._();

  static const _base = 'https://maps.googleapis.com/maps/api/directions/json';
  static const _proxyBase = String.fromEnvironment(
    'PROXY_BASE_URL',
    defaultValue: 'https://safeher-maps-proxy.aaditya-yuvika-safeher.workers.dev',
  );

  /// [destination] accepts either a "lat,lng" pair or a free-text address —
  /// the Directions API geocodes address strings itself.
  Future<List<RouteOption>> safeRoutes({
    required LatLng origin,
    required Object destination,
    String mode = 'walking',
  }) async {
    final destinationParam = destination is LatLng
        ? '${destination.latitude},${destination.longitude}'
        : destination.toString();

    final params = {
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': destinationParam,
      'mode': mode,
      'alternatives': 'true',
      if (!kIsWeb) 'key': ApiKeys.googleMaps,
    };

    final uri = kIsWeb
        ? Uri.parse('$_proxyBase/directionsProxy').replace(queryParameters: params)
        : Uri.parse(_base).replace(queryParameters: params);

    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw DirectionsException('Directions request failed (${res.statusCode}).');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final status = body['status'] as String?;
    if (status != 'OK') {
      throw DirectionsException(
        body['error_message'] as String? ?? 'No route found ($status).',
      );
    }

    final routes = (body['routes'] as List?) ?? [];
    if (routes.isEmpty) {
      throw DirectionsException('No route found between these points.');
    }

    // Decode + score every alternative.
    final scored = <_ScoredRoute>[];
    for (final r in routes) {
      final leg = (r['legs'] as List).first as Map<String, dynamic>;
      final points = _decodePolyline(r['overview_polyline']['points'] as String);
      final safety = await _safetyScore(points);
      scored.add(_ScoredRoute(
        distanceText: leg['distance']['text'] as String,
        durationText: leg['duration']['text'] as String,
        durationSeconds: (leg['duration']['value'] as num).toInt(),
        points: points,
        safetyScore: safety.score,
        policeNearby: safety.policeCount,
      ));
    }

    // Pick: highest safety score = Safest, shortest duration = Fastest.
    final bySafety = [...scored]..sort((a, b) => b.safetyScore.compareTo(a.safetyScore));
    final byDuration = [...scored]..sort((a, b) => a.durationSeconds.compareTo(b.durationSeconds));

    final safest = bySafety.first;
    final fastest = byDuration.firstWhere(
      (r) => r != safest,
      orElse: () => byDuration.first,
    );
    final rest = scored.where((r) => r != safest && r != fastest).toList();

    final result = <RouteOption>[
      RouteOption(
        label: 'Safest Route',
        duration: safest.durationText,
        distance: safest.distanceText,
        safetyScore: safest.safetyScore,
        highlights: _highlightsFor(safest.safetyScore, isSafest: true),
        color: const Color(0xFF34D399),
        icon: Icons.verified_user_rounded,
        points: safest.points,
        policeNearby: safest.policeNearby,
      ),
    ];
    if (fastest != safest) {
      result.add(RouteOption(
        label: 'Fastest Route',
        duration: fastest.durationText,
        distance: fastest.distanceText,
        safetyScore: fastest.safetyScore,
        highlights: _highlightsFor(fastest.safetyScore, isSafest: false),
        color: const Color(0xFFFBBF24),
        icon: Icons.bolt_rounded,
        points: fastest.points,
        policeNearby: fastest.policeNearby,
      ));
    }
    for (final r in rest) {
      result.add(RouteOption(
        label: 'Alternate Route',
        duration: r.durationText,
        distance: r.distanceText,
        safetyScore: r.safetyScore,
        highlights: _highlightsFor(r.safetyScore, isSafest: false),
        color: const Color(0xFF60A5FA),
        icon: Icons.alt_route_rounded,
        points: r.points,
        policeNearby: r.policeNearby,
      ));
    }
    return result;
  }

  // ── Safety scoring ─────────────────────────────────────────────────────
  //
  // Heuristic only — Google doesn't provide a "safety" metric. We sample a
  // few points along the route and count nearby police stations within
  // 400 m of each sample; more coverage -> higher score. This is a
  // reasonable proxy but should be presented to users as an estimate, not
  // a guarantee.

  Future<({int score, int policeCount})> _safetyScore(List<LatLng> points) async {
    if (points.isEmpty) return (score: 50, policeCount: 0);
    final samples = _sampleAlong(points, count: 4);

    final seenPlaceIds = <String?>{};
    var samplesWithPolice = 0;
    for (final p in samples) {
      final places = await PlacesService.instance.nearby(
        lat: p.latitude,
        lng: p.longitude,
        radiusMeters: 400,
      );
      final police = places.where((pl) => pl.category == 'Police');
      if (police.isNotEmpty) samplesWithPolice++;
      seenPlaceIds.addAll(police.map((p) => p.placeId));
    }

    final coverage = samplesWithPolice / samples.length; // 0..1
    // Base 55, up to +40 for full police coverage along the route.
    final score = (55 + coverage * 40).round().clamp(0, 99);
    return (score: score, policeCount: seenPlaceIds.length);
  }

  List<LatLng> _sampleAlong(List<LatLng> points, {required int count}) {
    if (points.length <= count) return points;
    final step = points.length / count;
    return List.generate(count, (i) => points[(i * step).floor()]);
  }

  List<String> _highlightsFor(int score, {required bool isSafest}) {
    if (isSafest) {
      return score >= 85
          ? ['Well-lit streets', 'Police coverage', 'Busy area']
          : ['Passes police station', 'Moderate coverage'];
    }
    return score < 65
        ? ['Shorter path', 'Limited police coverage']
        : ['Shorter path', 'Some police coverage'];
  }

  // ── Polyline decoding (Google's encoded polyline algorithm) ───────────

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }
}

class _ScoredRoute {
  final String distanceText;
  final String durationText;
  final int durationSeconds;
  final List<LatLng> points;
  final int safetyScore;
  final int policeNearby;
  _ScoredRoute({
    required this.distanceText,
    required this.durationText,
    required this.durationSeconds,
    required this.points,
    required this.safetyScore,
    required this.policeNearby,
  });
}

class DirectionsException implements Exception {
  final String message;
  DirectionsException(this.message);
  @override
  String toString() => message;
}

