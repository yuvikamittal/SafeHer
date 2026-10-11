import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_keys.dart';
import '../models/help_place.dart';

/// Real nearby-help data via Google Places API (Nearby Search, legacy).
/// Replaces the hardcoded list in SafetyService.nearbyPlaces().
class PlacesService {
  PlacesService._();
  static final PlacesService instance = PlacesService._();

  static const _base = 'https://maps.googleapis.com/maps/api/place';
  static const _proxyBase = String.fromEnvironment(
    'PROXY_BASE_URL',
    defaultValue: 'https://safeher-maps-proxy.aaditya-yuvika-safeher.workers.dev',
  );

  // Categories shown in the UI, mapped to a Google Places `type` (or a
  // keyword search when there's no exact matching type).
  static const _categoryQueries = {
    'Police': _CategoryQuery(type: 'police'),
    'Hospital': _CategoryQuery(type: 'hospital'),
    'Shelter': _CategoryQuery(type: null, keyword: "women's shelter"),
    'Safe Zone': _CategoryQuery(type: null, keyword: 'community center'),
  };

  Future<List<HelpPlace>> nearby({
    required double lat,
    required double lng,
    int radiusMeters = 3000,
  }) async {
    final results = await Future.wait(
      _categoryQueries.entries.map(
        (e) => _fetchCategory(
          category: e.key,
          query: e.value,
          lat: lat,
          lng: lng,
          radiusMeters: radiusMeters,
        ),
      ),
    );

    final places = results.expand((r) => r).toList()
      ..sort((a, b) => _distanceMeters(lat, lng, a.lat, a.lng)
          .compareTo(_distanceMeters(lat, lng, b.lat, b.lng)));

    return places;
  }

  Future<List<HelpPlace>> _fetchCategory({
    required String category,
    required _CategoryQuery query,
    required double lat,
    required double lng,
    required int radiusMeters,
  }) async {
    final params = {
      'location': '$lat,$lng',
      'radius': '$radiusMeters',
      if (!kIsWeb) 'key': ApiKeys.googleMaps,
      if (query.type != null) 'type': query.type!,
      if (query.keyword != null) 'keyword': query.keyword!,
    };
    final uri = kIsWeb
        ? Uri.parse('$_proxyBase/placesProxy').replace(
            queryParameters: {'path': 'nearbysearch/json', ...params},
          )
        : Uri.parse('$_base/nearbysearch/json').replace(queryParameters: params);

    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return [];
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final status = body['status'] as String?;
      if (status != 'OK' && status != 'ZERO_RESULTS') {
        debugPrint('Places API (${category}) error: $status '
            '${body['error_message'] ?? ''}');
      }
      final results = (body['results'] as List?) ?? [];

      return results.map((r) {
        final loc = r['geometry']['location'];
        final placeLat = (loc['lat'] as num).toDouble();
        final placeLng = (loc['lng'] as num).toDouble();
        final meters = _distanceMeters(lat, lng, placeLat, placeLng);

        return HelpPlace(
          name: r['name'] as String? ?? 'Unknown',
          category: category,
          distance: _formatDistance(meters),
          eta: _formatWalkEta(meters),
          address: r['vicinity'] as String? ?? '',
          phone: null, // requires a separate Place Details call
          isOpen: r['opening_hours']?['open_now'] as bool? ?? true,
          icon: _iconFor(category),
          color: _colorFor(category),
          rating: (r['rating'] as num?)?.toDouble(),
          lat: placeLat,
          lng: placeLng,
          placeId: r['place_id'] as String?,
        );
      }).toList();
    } catch (e) {
      debugPrint('Places API ($category) request failed: $e');
      return [];
    }
  }

  /// Fetches the phone number for a place on demand (e.g. when the user
  /// opens the detail sheet and taps "Call").
  Future<String?> phoneNumberFor(String placeId) async {
    final params = {
      'place_id': placeId,
      'fields': 'formatted_phone_number',
      if (!kIsWeb) 'key': ApiKeys.googleMaps,
    };
    final uri = kIsWeb
        ? Uri.parse('$_proxyBase/placesProxy').replace(
            queryParameters: {'path': 'details/json', ...params},
          )
        : Uri.parse('$_base/details/json').replace(queryParameters: params);
    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['result']?['formatted_phone_number'] as String?;
    } catch (_) {
      return null;
    }
  }

  IconData _iconFor(String category) => switch (category) {
        'Police' => Icons.local_police_rounded,
        'Hospital' => Icons.local_hospital_rounded,
        'Shelter' => Icons.home_rounded,
        _ => Icons.shield_rounded,
      };

  Color _colorFor(String category) => switch (category) {
        'Police' => const Color(0xFF4DA3FF),
        'Hospital' => const Color(0xFFFF6B6B),
        'Shelter' => const Color(0xFFB47AFF),
        _ => const Color(0xFF34D399),
      };

  double _distanceMeters(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _deg2rad(double deg) => deg * (math.pi / 180);

  String _formatDistance(double meters) => meters < 1000
      ? '${meters.round()} m'
      : '${(meters / 1000).toStringAsFixed(1)} km';

  // ~80 m/min average walking speed.
  String _formatWalkEta(double meters) {
    final min = (meters / 80).round().clamp(1, 999);
    return '$min min';
  }
}

class _CategoryQuery {
  final String? type;
  final String? keyword;
  const _CategoryQuery({this.type, this.keyword});
}
