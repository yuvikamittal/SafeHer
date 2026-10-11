import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/route_option.dart';
import '../services/directions_service.dart';
import '../services/location_service.dart';

class SafeRouteScreen extends StatefulWidget {
  const SafeRouteScreen({super.key});

  @override
  State<SafeRouteScreen> createState() => _SafeRouteScreenState();
}

class _SafeRouteScreenState extends State<SafeRouteScreen> {
  int _selectedRoute = 0;
  String _destination = 'Home';

  // Known destination addresses — Directions API geocodes these itself.
  static const _destinationAddresses = {
    'Home': 'Sector 21, New Delhi',
    'Work': 'Cyber Hub, Gurugram',
    'Hostel / PG': 'Laxmi Nagar, New Delhi',
    'Metro station': 'Rajiv Chowk',
  };

  List<RouteOption>? _routes;
  bool _loadingRoutes = true;
  String? _routeError;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    setState(() {
      _loadingRoutes = true;
      _routeError = null;
    });
    try {
      final loc = await LocationService.instance.current();
      final routes = await DirectionsService.instance.safeRoutes(
        origin: LatLng(loc.lat, loc.lng),
        destination: _destinationAddresses[_destination]!,
      );
      if (!mounted) return;
      setState(() {
        _routes = routes;
        _selectedRoute = 0;
        _loadingRoutes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _routeError = e.toString();
        _loadingRoutes = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1B2A), Color(0xFF1A2E44), Color(0xFF0F2335)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 20),
                      _buildRouteMap(),
                      const SizedBox(height: 24),
                      if (_routeError != null) _buildRouteErrorCard(),
                      if (_routes != null && _routes!.isNotEmpty) ...[
                        _buildSectionLabel('Choose Your Route'),
                        const SizedBox(height: 12),
                        ..._routes!.asMap().entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildRouteCard(e.key, e.value),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      _buildSafetyTips(),
                    ],
                  ),
                ),
              ),
              _buildStartButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF34D399).withValues(alpha: 0.15),
              border: Border.all(
                color: const Color(0xFF34D399).withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.alt_route_rounded,
              color: Color(0xFF34D399),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Safe Route',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF34D399).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF34D399).withValues(alpha: 0.30),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF34D399),
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Live',
                  style: TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: _showDestinationSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFF162435).withValues(alpha: 0.80),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.my_location_rounded,
              color: const Color(0xFF34D399).withValues(alpha: 0.80),
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Current Location → $_destination',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 13.5,
                ),
              ),
            ),
            GestureDetector(
              onTap: _showRouteFiltersSheet,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF34D399).withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Color(0xFF34D399),
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Route Map ─────────────────────────────────────────────────────────────

  Widget _buildRouteMap() {
    final container = Container(
      height: 210,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF0E1F30),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: _buildRouteMapContent(),
    );
    return container;
  }

  Widget _buildRouteMapContent() {
    if (_loadingRoutes) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF34D399),
          ),
        ),
      );
    }
    if (_routes == null || _routes!.isEmpty) {
      return Center(
        child: Text(
          _routeError ?? 'No route available',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12.5),
        ),
      );
    }

    final selected = _routes![_selectedRoute];
    final start = selected.points.isNotEmpty ? selected.points.first : null;
    final end = selected.points.isNotEmpty ? selected.points.last : null;

    return Stack(
      children: [
        Positioned.fill(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: start ?? const LatLng(28.6315, 77.2167),
              zoom: 14,
            ),
            style: _darkRouteMapStyle,
            polylines: {
              Polyline(
                polylineId: const PolylineId('selected_route'),
                points: selected.points,
                color: selected.color,
                width: 4,
              ),
            },
            markers: {
              if (start != null)
                Marker(
                  markerId: const MarkerId('start'),
                  position: start,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  ),
                ),
              if (end != null)
                Marker(
                  markerId: const MarkerId('end'),
                  position: end,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ),
                ),
            },
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            liteModeEnabled: false,
          ),
        ),

        // Route summary (top-left)
        Positioned(
          left: 12,
          top: 12,
          child: _mapChip(
            icon: Icons.alt_route_rounded,
            text: '${selected.duration} · ${selected.distance}',
            color: selected.color,
          ),
        ),
        // Police on route (bottom-right)
        Positioned(
          right: 12,
          bottom: 12,
          child: _mapChip(
            icon: Icons.local_police_rounded,
            text: '${selected.policeNearby} police on route',
            color: const Color(0xFF60A5FA),
          ),
        ),
      ],
    );
  }

  Widget _buildRouteErrorCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B6B).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFFF6B6B), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _routeError!,
              style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12.5),
            ),
          ),
          TextButton(
            onPressed: _loadRoutes,
            child: const Text('Retry', style: TextStyle(color: Color(0xFF4DA3FF))),
          ),
        ],
      ),
    );
  }

  Widget _mapChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Label ─────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.white.withValues(alpha: 0.35),
        letterSpacing: 1.2,
      ),
    );
  }

  // ── Route Card ────────────────────────────────────────────────────────────

  Widget _buildRouteCard(int index, RouteOption route) {
    final isSelected = _selectedRoute == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedRoute = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? route.color.withValues(alpha: 0.10)
              : const Color(0xFF162435).withValues(alpha: 0.70),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? route.color.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.07),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: route.color.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: route.color.withValues(alpha: 0.14),
                border: Border.all(color: route.color.withValues(alpha: 0.30)),
              ),
              child: Icon(route.icon, color: route.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          route.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.80),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        route.duration,
                        style: TextStyle(
                          color: route.color,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        route.distance,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.40),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildSafetyBadge(route.safetyScore, route.color),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: route.highlights
                        .map((h) => _buildTag(h, route.color))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyBadge(int score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Safety $score%',
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.50),
          fontSize: 10.5,
        ),
      ),
    );
  }

  // ── Safety Tips ───────────────────────────────────────────────────────────

  Widget _buildSafetyTips() {
    final tips = [
      _TipData(
        Icons.lightbulb_outline_rounded,
        'Stay on lit roads after dark',
        const Color(0xFFFBBF24),
      ),
      _TipData(
        Icons.share_location_rounded,
        'Share live location with a trusted contact',
        const Color(0xFFFF6EBF),
      ),
      _TipData(
        Icons.groups_2_rounded,
        'Choose routes with more foot traffic',
        const Color(0xFF60A5FA),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Safety Tips'),
        const SizedBox(height: 12),
        ...tips.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF162435).withValues(alpha: 0.70),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Icon(t.icon, color: t.color, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.text,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Start Button ──────────────────────────────────────────────────────────

  Widget _buildStartButton() {
    final routes = _routes;
    if (routes == null || routes.isEmpty) return const SizedBox.shrink();
    final selected = routes[_selectedRoute];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF1A2E44),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              content: Row(
                children: [
                  Icon(selected.icon, color: selected.color, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Navigating to $_destination via ${selected.label}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [selected.color, selected.color.withValues(alpha: 0.75)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: selected.color.withValues(alpha: 0.30),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.navigation_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Start ${selected.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Destination picker & route filter sheets ──────────────────────────────

  void _showDestinationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF162435),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _sheetHandle()),
            const SizedBox(height: 18),
            const Text(
              'Choose destination',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _destTile(
              ctx,
              'Home',
              'Sector 21, New Delhi',
              Icons.home_rounded,
            ),
            _destTile(
              ctx,
              'Work',
              'Cyber Hub, Gurugram',
              Icons.work_outline_rounded,
            ),
            _destTile(
              ctx,
              'Hostel / PG',
              'Laxmi Nagar, New Delhi',
              Icons.bed_rounded,
            ),
            _destTile(
              ctx,
              'Metro station',
              'Rajiv Chowk',
              Icons.train_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _destTile(
    BuildContext ctx,
    String name,
    String sub,
    IconData icon,
  ) {
    final selected = name == _destination;
    return GestureDetector(
      onTap: () {
        setState(() {
          _destination = name;
          _selectedRoute = 0;
        });
        Navigator.pop(ctx);
        _snack('Finding the safest route to $name…');
        _loadRoutes();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF34D399).withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFF34D399).withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF34D399).withValues(alpha: 0.14),
              ),
              child: Icon(icon, color: const Color(0xFF34D399), size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF34D399),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _showRouteFiltersSheet() {
    final prefs = <String, bool>{
      'Prefer well-lit roads': true,
      'Avoid isolated areas': true,
      'Prefer CCTV-covered streets': true,
      'Pass near police stations': true,
      'Auto-share trip with a contact': false,
    };
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF162435),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (_, setS) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _sheetHandle()),
              const SizedBox(height: 18),
              const Text(
                'Route preferences',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...prefs.keys.map(
                (k) => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeThumbColor: const Color(0xFF34D399),
                  title: Text(
                    k,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  ),
                  value: prefs[k]!,
                  onChanged: (v) => setS(() => prefs[k] = v),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF34D399),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _snack('Route preferences updated');
                  },
                  child: const Text(
                    'Apply preferences',
                    style: TextStyle(
                      color: Color(0xFF0F2335),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
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

  Widget _sheetHandle() {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1A2E44),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(msg, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────

class _TipData {
  final IconData icon;
  final String text;
  final Color color;
  const _TipData(this.icon, this.text, this.color);
}

// Dark, low-clutter map style so the widget matches the app's theme.
const String _darkRouteMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#0e1f30"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#8ba3b8"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#0d1b2a"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#1a2e44"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0d1b2a"}]},
  {"featureType": "poi", "stylers": [{"visibility": "off"}]},
  {"featureType": "transit", "stylers": [{"visibility": "off"}]}
]
''';
