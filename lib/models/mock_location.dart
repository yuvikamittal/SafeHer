/// A simulated device location (used in place of a real GPS plugin).
class MockLocation {
  final String label;
  final String coordinates;
  final String accuracy;
  final double lat;
  final double lng;

  const MockLocation({
    required this.label,
    required this.coordinates,
    required this.accuracy,
    this.lat = 0,
    this.lng = 0,
  });
}
