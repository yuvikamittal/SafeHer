import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/places_service.dart';
import '../services/location_service.dart';
import '../models/help_place.dart';

class NearbyHelpScreen extends StatefulWidget {
  const NearbyHelpScreen({super.key});

  @override
  State<NearbyHelpScreen> createState() => _NearbyHelpScreenState();
}

class _NearbyHelpScreenState extends State<NearbyHelpScreen>
    with TickerProviderStateMixin {
  String _selectedFilter = 'All';
  bool _isLoading = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  final List<String> _filters = [
    'All',
    'Police',
    'Hospital',
    'Safe Zone',
    'Shelter',
  ];

  List<HelpPlace> _places = [];
  String? _loadError;
  String _locationLabel = 'Locating…';
  double? _userLat;
  double? _userLng;

  List<HelpPlace> get _filtered => _selectedFilter == 'All'
      ? _places
      : _places.where((p) => p.category == _selectedFilter).toList();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final loc = await LocationService.instance.current();
      final places = await PlacesService.instance.nearby(
        lat: loc.lat,
        lng: loc.lng,
      );
      if (!mounted) return;
      setState(() {
        _places = places;
        _locationLabel = loc.label;
        _userLat = loc.lat;
        _userLng = loc.lng;
        _isLoading = false;
      });
      _fadeController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _callPlace(HelpPlace place) async {
    var phone = place.phone;
    if (phone == null && place.placeId != null) {
      phone = await PlacesService.instance.phoneNumberFor(place.placeId!);
    }
    if (phone == null) {
      _showSnack('No phone number available for ${place.name}', isSuccess: false);
      return;
    }
    _showSnack('Calling ${place.name}…', isSuccess: true);
  }

  void _getDirections(HelpPlace place) {
    _showSnack('Opening directions to ${place.name}…');
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess
            ? const Color(0xFF1D9E75)
            : const Color(0xFF1A73E8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showPlaceDetail(HelpPlace place) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF162435),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _PlaceDetailSheet(
        place: place,
        onCall: () {
          Navigator.pop(context);
          _callPlace(place);
        },
        onDirections: () {
          Navigator.pop(context);
          _getDirections(place);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nearby Help',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF34D399).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF34D399).withValues(alpha: 0.30),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF34D399),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'GPS',
                    style: TextStyle(
                      color: Color(0xFF34D399),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1B2A), Color(0xFF1A2E44), Color(0xFF0F2335)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // ── Map placeholder ──────────────────────────────
              _MapPlaceholder(
                isLoading: _isLoading,
                userLat: _userLat,
                userLng: _userLng,
                places: _filtered,
              ),

              // ── Location info ────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Icon(
                      Icons.my_location_rounded,
                      color: const Color(0xFF34D399).withValues(alpha: 0.80),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$_locationLabel · Showing ${_filtered.length} places',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.40),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // ── Filter chips ─────────────────────────────────
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final f = _filters[i];
                    final selected = f == _selectedFilter;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilter = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF1A73E8).withValues(alpha: 0.20)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? const Color(
                                    0xFF1A73E8,
                                  ).withValues(alpha: 0.55)
                                : Colors.white.withValues(alpha: 0.10),
                          ),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            color: selected
                                ? const Color(0xFF4DA3FF)
                                : Colors.white.withValues(alpha: 0.45),
                            fontSize: 12.5,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // ── List ─────────────────────────────────────────
              Expanded(
                child: _isLoading
                    ? _LoadingList()
                    : _loadError != null
                    ? _LoadErrorView(message: _loadError!, onRetry: _loadPlaces)
                    : FadeTransition(
                        opacity: _fadeAnim,
                        child: _filtered.isEmpty
                            ? _EmptyFilter(filter: _selectedFilter)
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  24,
                                ),
                                itemCount: _filtered.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (_, i) => _PlaceCard(
                                  place: _filtered[i],
                                  onTap: () => _showPlaceDetail(_filtered[i]),
                                  onCall: () => _callPlace(_filtered[i]),
                                  onDirections: () =>
                                      _getDirections(_filtered[i]),
                                ),
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Map Placeholder ───────────────────────────────────────────────────────

class _MapPlaceholder extends StatelessWidget {
  final bool isLoading;
  final double? userLat;
  final double? userLng;
  final List<HelpPlace> places;
  const _MapPlaceholder({
    required this.isLoading,
    required this.userLat,
    required this.userLng,
    required this.places,
  });

  double _hueFor(String category) {
    switch (category) {
      case 'Police':
        return BitmapDescriptor.hueAzure;
      case 'Hospital':
        return BitmapDescriptor.hueRed;
      case 'Shelter':
        return BitmapDescriptor.hueViolet;
      default: // Safe Zone
        return BitmapDescriptor.hueGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFix = userLat != null && userLng != null &&
        !(userLat == 0 && userLng == 0);

    return Container(
      height: 170,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF162435),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: hasFix
            ? GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(userLat!, userLng!),
                  zoom: 14,
                ),
                style: _nearbyMapStyle,
                markers: {
                  Marker(
                    markerId: const MarkerId('me'),
                    position: LatLng(userLat!, userLng!),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure,
                    ),
                    infoWindow: const InfoWindow(title: 'You are here'),
                  ),
                  ...places
                      .where((p) => !(p.lat == 0 && p.lng == 0))
                      .map(
                        (p) => Marker(
                          markerId: MarkerId(p.placeId ?? '${p.name}${p.lat}'),
                          position: LatLng(p.lat, p.lng),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            _hueFor(p.category),
                          ),
                          infoWindow: InfoWindow(
                            title: p.name,
                            snippet: '${p.category} · ${p.distance}',
                          ),
                        ),
                      ),
                },
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                compassEnabled: false,
                mapToolbarEnabled: false,
                liteModeEnabled: false,
              )
            : Stack(
                children: [
                  CustomPaint(
                    size: const Size(double.infinity, 170),
                    painter: _GridPainter(),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF4DA3FF),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isLoading ? 'Scanning nearby…' : 'Locating…',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.40),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

const String _nearbyMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#162435"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#8ba3b8"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#0d1b2a"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#1a2e44"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0d1b2a"}]},
  {"featureType": "poi", "stylers": [{"visibility": "off"}]},
  {"featureType": "transit", "stylers": [{"visibility": "off"}]}
]
''';

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    const step = 26.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}

// ── Place Card ────────────────────────────────────────────────────────────

class _PlaceCard extends StatelessWidget {
  final HelpPlace place;
  final VoidCallback onTap;
  final VoidCallback onCall;
  final VoidCallback onDirections;

  const _PlaceCard({
    required this.place,
    required this.onTap,
    required this.onCall,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF162435).withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: place.color.withValues(alpha: 0.15)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: place.color.withValues(alpha: 0.12),
                border: Border.all(color: place.color.withValues(alpha: 0.28)),
              ),
              child: Icon(place.icon, color: place.color, size: 22),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          place.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: place.isOpen
                              ? const Color(0xFF34D399).withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          place.isOpen ? 'Open' : 'Closed',
                          style: TextStyle(
                            color: place.isOpen
                                ? const Color(0xFF34D399)
                                : Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    place.address,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.40),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _metaChip(
                        Icons.near_me_rounded,
                        place.distance,
                        place.color,
                      ),
                      const SizedBox(width: 6),
                      _metaChip(
                        Icons.directions_walk_rounded,
                        place.eta,
                        const Color(0xFFFBBF24),
                      ),
                      if (place.rating != null) ...[
                        const SizedBox(width: 6),
                        _metaChip(
                          Icons.star_rounded,
                          place.rating!.toString(),
                          const Color(0xFFFBBF24),
                        ),
                      ],
                      const Spacer(),
                      // Quick action buttons
                      if (place.phone != null)
                        _iconBtn(
                          Icons.phone_rounded,
                          const Color(0xFF34D399),
                          onCall,
                        ),
                      const SizedBox(width: 6),
                      _iconBtn(
                        Icons.directions_rounded,
                        const Color(0xFF4DA3FF),
                        onDirections,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color.withValues(alpha: 0.70), size: 12),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, color: color, size: 15),
      ),
    );
  }
}

// ── Place Detail Sheet ────────────────────────────────────────────────────

class _PlaceDetailSheet extends StatelessWidget {
  final HelpPlace place;
  final VoidCallback onCall;
  final VoidCallback onDirections;

  const _PlaceDetailSheet({
    required this.place,
    required this.onCall,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: place.color.withValues(alpha: 0.14),
                  border: Border.all(
                    color: place.color.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: Icon(place.icon, color: place.color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: place.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        place.category,
                        style: TextStyle(
                          color: place.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _detailRow(
            Icons.location_on_outlined,
            place.address,
            Colors.white.withValues(alpha: 0.55),
          ),
          if (place.phone != null) ...[
            const SizedBox(height: 10),
            _detailRow(
              Icons.phone_outlined,
              place.phone!,
              const Color(0xFF34D399),
            ),
          ],
          const SizedBox(height: 10),
          _detailRow(
            Icons.near_me_rounded,
            '${place.distance} away · ${place.eta} walk',
            const Color(0xFF4DA3FF),
          ),
          const SizedBox(height: 10),
          _detailRow(
            Icons.circle,
            place.isOpen ? 'Open now' : 'Currently closed',
            place.isOpen ? const Color(0xFF34D399) : Colors.white38,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (place.phone != null) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onCall,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF34D399),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                    ),
                    icon: const Icon(
                      Icons.phone_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Call',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onDirections,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                  ),
                  icon: const Icon(
                    Icons.directions_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'Directions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 13.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Loading List ──────────────────────────────────────────────────────────

class _LoadErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _LoadErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFFF6B6B), size: 28),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry', style: TextStyle(color: Color(0xFF4DA3FF))),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => Container(
        height: 90,
        decoration: BoxDecoration(
          color: const Color(0xFF162435).withValues(alpha: 0.60),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmer(width: 160, height: 13),
                  const SizedBox(height: 8),
                  _shimmer(width: 110, height: 10),
                  const SizedBox(height: 8),
                  _shimmer(width: 80, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmer({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ── Empty Filter ──────────────────────────────────────────────────────────

class _EmptyFilter extends StatelessWidget {
  final String filter;
  const _EmptyFilter({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            color: Colors.white.withValues(alpha: 0.18),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'No $filter places found nearby',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.40),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────
