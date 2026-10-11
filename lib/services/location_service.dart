/// Real GPS location service backed by the `geolocator` and `geocoding` packages.
///
/// Replaces the previous mock that always returned a fixed Connaught Place
/// coordinate. Handles permission requests, service-disabled checks, and
/// reverse geocoding (coordinates → human-readable address).
///
/// ── Setup checklist ────────────────────────────────────────────────────────
/// 1. Add to pubspec.yaml:
///      geolocator: ^13.0.2
///      geocoding: ^3.0.0
/// 2. Android — add to android/app/src/main/AndroidManifest.xml, inside
///    <manifest> (above <application>):
///      <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
///      <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
///      <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
///      <uses-permission android:name="android.permission.INTERNET"/>
/// 3. iOS — add to ios/Runner/Info.plist:
///      <key>NSLocationWhenInUseUsageDescription</key>
///      <string>SafeHer needs your location to show it on the map and share it
///      with your emergency contacts.</string>
///      <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
///      <string>SafeHer needs background location to keep sharing your live
///      location and run night-mode check-ins even when the app is closed.</string>
/// ───────────────────────────────────────────────────────────────────────────

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../models/mock_location.dart';

/// Thrown when location can't be retrieved — UI should catch this and show
/// a clear message + a button to open device settings.
class LocationException implements Exception {
  final String message;
  final bool canOpenSettings;
  LocationException(this.message, {this.canOpenSettings = false});

  @override
  String toString() => message;
}

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  /// Fetches the device's current GPS position and reverse-geocodes it into
  /// a human-readable label. Throws [LocationException] on failure.
  Future<MockLocation> current() async {
    await _ensurePermission();

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    final label = await _reverseGeocode(position.latitude, position.longitude);
    final coords = _formatCoordinates(position.latitude, position.longitude);
    final accuracy = '±${position.accuracy.round()} m';

    return MockLocation(
      label: label,
      coordinates: coords,
      accuracy: accuracy,
      lat: position.latitude,
      lng: position.longitude,
    );
  }

  /// Stream of live position updates — used for "live tracking" sharing mode.
  /// Emits a new [MockLocation] roughly every [distanceFilterMeters] of
  /// movement, or every few seconds, whichever comes first.
  Stream<MockLocation> watch({int distanceFilterMeters = 10}) async* {
    await _ensurePermission();

    final stream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
      ),
    );

    await for (final position in stream) {
      final label = await _reverseGeocode(position.latitude, position.longitude);
      yield MockLocation(
        label: label,
        coordinates: _formatCoordinates(position.latitude, position.longitude),
        accuracy: '±${position.accuracy.round()} m',
        lat: position.latitude,
        lng: position.longitude,
      );
    }
  }

  // ── Permission handling ──────────────────────────────────────────────────

  Future<void> _ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException(
        'Location services are turned off. Please enable GPS.',
        canOpenSettings: true,
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException(
          'Location permission denied. SafeHer needs this to show your location.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Location permission permanently denied. Please enable it in app settings.',
        canOpenSettings: true,
      );
    }
  }

  /// Opens the device's app settings screen so the user can grant permission
  /// manually after a permanent denial.
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Opens the device's location services settings (for when GPS is off).
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return 'Unknown location';
      final p = placemarks.first;
      final parts = [
        p.street,
        p.subLocality,
        p.locality,
      ].where((s) => s != null && s.isNotEmpty).toList();
      return parts.isNotEmpty ? parts.join(', ') : (p.locality ?? 'Unknown location');
    } catch (_) {
      // Reverse geocoding can fail (no network, no provider on some
      // emulators) — fall back to raw coordinates rather than throwing.
      return 'Near ${_formatCoordinates(lat, lng)}';
    }
  }

  String _formatCoordinates(double lat, double lng) {
    final latDir = lat >= 0 ? 'N' : 'S';
    final lngDir = lng >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(4)}° $latDir, ${lng.abs().toStringAsFixed(4)}° $lngDir';
  }
}
