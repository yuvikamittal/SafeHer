import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/mock_location.dart';
import '../models/share_contact.dart';
import '../services/location_service.dart';
import '../state/providers.dart';

class LiveLocationScreen extends ConsumerStatefulWidget {
  const LiveLocationScreen({super.key});

  @override
  ConsumerState<LiveLocationScreen> createState() => _LiveLocationScreenState();
}

class _LiveLocationScreenState extends ConsumerState<LiveLocationScreen>
    with TickerProviderStateMixin {
  bool _isSharingActive = false;
  String _selectedDuration = '1 hour';

  MockLocation? _location;
  bool _loadingLocation = true;
  LocationException? _locationError;
  StreamSubscription<MockLocation>? _liveSub;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  final List<String> _durations = [
    '30 minutes',
    '1 hour',
    '2 hours',
    'Until I stop',
  ];

  // Live-location sharing selection. Contacts come from the shared
  // contactsProvider (same source as the Contacts screen). We only track
  // which ids the user has toggled OFF locally — everyone defaults to ON.
  final Set<String> _deselectedIds = {};

  List<ShareContact> _shareContacts() {
    final contacts = ref.watch(contactsProvider).valueOrNull ?? const [];
    return contacts
        .map((c) => ShareContact(
              id: c.id ?? c.phone,
              name: c.name,
              relation: c.relation,
              isSelected: !_deselectedIds.contains(c.id ?? c.phone),
            ))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _liveSub?.cancel();
    super.dispose();
  }

  // ── Location loading ─────────────────────────────────────────────────────

  Future<void> _loadLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });
    try {
      final loc = await LocationService.instance.current();
      if (!mounted) return;
      setState(() {
        _location = loc;
        _loadingLocation = false;
      });
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = e;
        _loadingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = LocationException('Could not get your location.');
        _loadingLocation = false;
      });
    }
  }

  // ── Sharing toggle ───────────────────────────────────────────────────────

  void _toggleSharing() {
    if (_location == null) {
      _showSnack('Location unavailable. Try again.', isSuccess: false);
      return;
    }

    setState(() => _isSharingActive = !_isSharingActive);

    if (_isSharingActive) {
      // Start watching live position updates while sharing is on.
      _liveSub = LocationService.instance.watch().listen(
        (loc) {
          if (!mounted) return;
          setState(() => _location = loc);
        },
        onError: (_) {
          // Stream errors (e.g. permission revoked mid-session) shouldn't
          // crash sharing — just stop silently and notify.
          if (!mounted) return;
          setState(() => _isSharingActive = false);
          _showSnack('Lost location access. Sharing stopped.', isSuccess: false);
        },
      );
      _showSnack('Location sharing started', isSuccess: true);
    } else {
      _liveSub?.cancel();
      _liveSub = null;
      _showSnack('Location sharing stopped', isSuccess: false);
    }
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

  // ── Build ─────────────────────────────────────────────────────────────────

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
          'Live Location',
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
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, _) => Opacity(
                opacity: _isSharingActive ? _pulseAnim.value : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _isSharingActive
                        ? const Color(0xFF34D399).withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isSharingActive
                          ? const Color(0xFF34D399).withValues(alpha: 0.35)
                          : Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(
                    _isSharingActive ? 'LIVE' : 'OFF',
                    style: TextStyle(
                      color: _isSharingActive
                          ? const Color(0xFF34D399)
                          : Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Live map ──────────────────────────────────────
                _LiveMap(isActive: _isSharingActive, location: _location),
                const SizedBox(height: 20),

                // ── Current location card ────────────────────────
                _infoCard(
                  icon: Icons.my_location_rounded,
                  iconColor: const Color(0xFF34D399),
                  title: 'Current location',
                  child: _buildLocationContent(),
                ),
                const SizedBox(height: 14),

                // ── Share duration ───────────────────────────────
                _infoCard(
                  icon: Icons.timer_outlined,
                  iconColor: const Color(0xFF4DA3FF),
                  title: 'Share duration',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _durations.map((d) {
                      final selected = d == _selectedDuration;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDuration = d),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(
                                    0xFF4DA3FF,
                                  ).withValues(alpha: 0.18)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? const Color(
                                      0xFF4DA3FF,
                                    ).withValues(alpha: 0.55)
                                  : Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                          child: Text(
                            d,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: selected
                                  ? const Color(0xFF4DA3FF)
                                  : Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Share with ───────────────────────────────────
                _infoCard(
                  icon: Icons.people_alt_outlined,
                  iconColor: const Color(0xFFFBBF24),
                  title: 'Share with',
                  child: Builder(builder: (context) {
                    final shareContacts = _shareContacts();
                    if (shareContacts.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No trusted contacts yet. Add them in Emergency Contacts.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 12.5,
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: shareContacts.map((c) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(
                                0xFF34D399,
                              ).withValues(alpha: 0.12),
                              child: Text(
                                c.name.isNotEmpty ? c.name[0] : '?',
                                style: const TextStyle(
                                  color: Color(0xFF34D399),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    c.relation,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.40,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: c.isSelected,
                              onChanged: (v) => setState(() {
                                if (v) {
                                  _deselectedIds.remove(c.id);
                                } else {
                                  _deselectedIds.add(c.id);
                                }
                              }),
                              activeThumbColor: const Color(0xFF34D399),
                              activeTrackColor: const Color(
                                0xFF34D399,
                              ).withValues(alpha: 0.25),
                              inactiveThumbColor: Colors.white38,
                              inactiveTrackColor: Colors.white.withValues(
                                alpha: 0.10,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    );
                  }),
                ),
                const SizedBox(height: 28),

                // ── Toggle button ────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _loadingLocation ? null : _toggleSharing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSharingActive
                          ? const Color(0xFFD85A30).withValues(alpha: 0.85)
                          : const Color(0xFF34D399),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          const Color(0xFF34D399).withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    icon: Icon(
                      _isSharingActive
                          ? Icons.location_off_rounded
                          : Icons.location_on_rounded,
                      size: 20,
                    ),
                    label: Text(
                      _isSharingActive
                          ? 'Stop sharing location'
                          : 'Start sharing location',
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                if (_isSharingActive) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Sharing for $_selectedDuration · Live updates',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Current location card content (loading / error / loaded states) ──────

  Widget _buildLocationContent() {
    if (_loadingLocation) {
      return Row(
        children: const [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF34D399),
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Getting your location...',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      );
    }

    if (_locationError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFFF6B6B), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _locationError!.message,
                  style: const TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton(
                onPressed: _loadLocation,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Color(0xFF4DA3FF), fontSize: 12.5),
                ),
              ),
              if (_locationError!.canOpenSettings) ...[
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () => LocationService.instance.openAppSettings(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                  ),
                  child: const Text(
                    'Open settings',
                    style: TextStyle(color: Color(0xFF4DA3FF), fontSize: 12.5),
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    }

    final loc = _location!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.coordinates,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${loc.label} · Accuracy ${loc.accuracy}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 12.5,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _statusChip(
              icon: Icons.gps_fixed_rounded,
              label: 'GPS Active',
              color: const Color(0xFF34D399),
            ),
            const SizedBox(width: 8),
            _statusChip(
              icon: Icons.refresh_rounded,
              label: 'Refresh',
              color: const Color(0xFF4DA3FF),
              onTap: _loadLocation,
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF162435).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 17),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _statusChip({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
    return onTap != null ? GestureDetector(onTap: onTap, child: chip) : chip;
  }
}

// ── Live Map (real Google Map) ────────────────────────────────────────────

class _LiveMap extends StatefulWidget {
  final bool isActive;
  final MockLocation? location;
  const _LiveMap({required this.isActive, required this.location});

  @override
  State<_LiveMap> createState() => _LiveMapState();
}

class _LiveMapState extends State<_LiveMap> {
  GoogleMapController? _controller;

  @override
  void didUpdateWidget(covariant _LiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final loc = widget.location;
    if (loc != null && loc.lat != 0 && loc.lng != 0) {
      _controller?.animateCamera(
        CameraUpdate.newLatLng(LatLng(loc.lat, loc.lng)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.location;
    final hasFix = loc != null && loc.lat != 0 && loc.lng != 0;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF162435),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isActive
              ? const Color(0xFF34D399).withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: hasFix
            ? GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(loc.lat, loc.lng),
                  zoom: 16,
                ),
                onMapCreated: (c) => _controller = c,
                style: _darkMapStyle,
                markers: {
                  Marker(
                    markerId: const MarkerId('me'),
                    position: LatLng(loc.lat, loc.lng),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      widget.isActive
                          ? BitmapDescriptor.hueGreen
                          : BitmapDescriptor.hueAzure,
                    ),
                  ),
                },
                circles: widget.isActive
                    ? {
                        Circle(
                          circleId: const CircleId('accuracy'),
                          center: LatLng(loc.lat, loc.lng),
                          radius: 60,
                          fillColor:
                              const Color(0xFF34D399).withValues(alpha: 0.10),
                          strokeColor:
                              const Color(0xFF34D399).withValues(alpha: 0.35),
                          strokeWidth: 1,
                        ),
                      }
                    : {},
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                compassEnabled: false,
                mapToolbarEnabled: false,
              )
            : const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF34D399),
                  ),
                ),
              ),
      ),
    );
  }
}

// Dark, low-clutter map style so the widget matches the app's theme.
const String _darkMapStyle = '''
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
