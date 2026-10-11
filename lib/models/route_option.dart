import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// A candidate walking route with a computed safety score.
class RouteOption {
  final String label;
  final String duration;
  final String distance;
  final int safetyScore;
  final List<String> highlights;
  final Color color;
  final IconData icon;

  /// Decoded polyline points for this route (empty for mock/fallback data).
  final List<LatLng> points;

  /// Approx. count of distinct police stations found near sampled points
  /// along the route (used for the "N police on route" map chip).
  final int policeNearby;

  const RouteOption({
    required this.label,
    required this.duration,
    required this.distance,
    required this.safetyScore,
    required this.highlights,
    required this.color,
    required this.icon,
    this.points = const [],
    this.policeNearby = 0,
  });
}
