import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/emergency_contact.dart';
import '../services/sos_service.dart';
import '../state/providers.dart';

class SOSScreen extends ConsumerStatefulWidget {
  const SOSScreen({super.key});

  @override
  ConsumerState<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends ConsumerState<SOSScreen>
    with SingleTickerProviderStateMixin {
  bool _alertSent = false;
  bool _isSending = false;
  int _countdown = 3;
  bool _countingDown = false;

  SosDispatchResult? _dispatchResult;

  // Trusted-contact list, sourced from the shared `contactsProvider` (single
  // source of truth). See the getter below — SosService just needs whatever
  // List<EmergencyContact> this resolves to in order to fan an alert out.
  List<EmergencyContact> get _contacts =>
      ref.read(contactsProvider).valueOrNull ?? const [];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.0).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── SOS trigger ──────────────────────────────────────────────────────────

  void _startCountdown() {
    if (_countingDown || _alertSent) return;
    setState(() {
      _countingDown = true;
      _countdown = 3;
    });
    _tick();
  }

  void _tick() async {
    for (int i = 3; i > 0; i--) {
      if (!mounted) return;
      setState(() => _countdown = i);
      await Future.delayed(const Duration(seconds: 1));
    }
    if (!mounted) return;
    _sendSOS();
  }

  void _cancelCountdown() {
    if (_alertSent) return;
    setState(() {
      _countingDown = false;
      _countdown = 3;
    });
  }

  Future<void> _sendSOS() async {
    setState(() {
      _countingDown = false;
      _isSending = true;
    });
    SosDispatchResult? result;
    try {
      result = await SosService.instance.dispatchAlert(contacts: _contacts);
    } catch (_) {
      // Even if something above throws, don't leave the user staring at a
      // spinner forever — fall through and show the sent state; the
      // Firestore log + SMS attempts inside dispatchAlert already did their
      // own best-effort error handling per-contact.
    }
    if (!mounted) return;
    setState(() {
      _isSending = false;
      _alertSent = true;
      _dispatchResult = result;
    });
  }

  void _resetSOS() {
    final alertId = _dispatchResult?.alertId;
    if (alertId != null) {
      // Best-effort — don't block the UI reset on this network call.
      SosService.instance
          .markAlertResolved(alertId, status: 'cancelled')
          .catchError((_) {});
    }
    setState(() {
      _alertSent = false;
      _countdown = 3;
      _dispatchResult = null;
    });
  }

  Future<void> _callEmergencyServices() async {
    try {
      await SosService.instance.callEmergencyServices();
    } catch (e) {
      if (!mounted) return;
      _showSnack(context, 'Could not open dialer: $e');
    }
  }

  Future<void> _sendSmsQuickAction() async {
    _showSnack(context, 'Sending SMS to trusted contacts...');
    try {
      final outcomes = await SosService.instance.sendSmsToContacts(_contacts);
      if (!mounted) return;
      if (outcomes.isNotEmpty &&
          outcomes.every((o) => o.status == SmsDispatchStatus.unsupportedOnWeb)) {
        _showSnack(
          context,
          "SMS isn't available in the browser — install the SafeHer app "
          'to text your contacts.',
        );
        return;
      }
      final reached = outcomes
          .where((o) =>
              o.status == SmsDispatchStatus.sent ||
              o.status == SmsDispatchStatus.composerOpened)
          .length;
      _showSnack(context, 'SMS sent to $reached of ${outcomes.length} contacts');
    } catch (e) {
      if (!mounted) return;
      _showSnack(context, 'Could not send SMS: $e');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Keep this screen subscribed to the shared contacts stream so `_contacts`
    // (a ref.read getter) always reflects the latest Firestore state.
    ref.watch(contactsProvider);
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      _buildSOSButton(),
                      const SizedBox(height: 36),
                      if (_alertSent) _buildAlertSentBanner(),
                      if (!_alertSent) _buildInstructions(),
                      const SizedBox(height: 28),
                      _buildContactsCard(),
                      const SizedBox(height: 20),
                      _buildLocationCard(),
                      const SizedBox(height: 20),
                      _buildActionsRow(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white70,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          const Text(
            'Emergency SOS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFD85A30).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFD85A30).withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFF6B6B),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SOS Button ────────────────────────────────────────────────────────────

  Widget _buildSOSButton() {
    if (_isSending) {
      return _sosRing(
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
        ),
        outerColor: const Color(0xFFD85A30).withValues(alpha: 0.20),
        innerColor: const Color(0xFFD85A30).withValues(alpha: 0.55),
      );
    }

    if (_alertSent) {
      return _sosRing(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_rounded, color: Colors.white, size: 44),
            const SizedBox(height: 6),
            const Text(
              'SENT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        outerColor: const Color(0xFF1D9E75).withValues(alpha: 0.20),
        innerColor: const Color(0xFF1D9E75),
      );
    }

    if (_countingDown) {
      return _sosRing(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$_countdown',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 52,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Hold to cancel',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.70),
                fontSize: 11,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        outerColor: const Color(0xFFD85A30).withValues(alpha: 0.25),
        innerColor: const Color(0xFFD85A30),
        onTap: _cancelCountdown,
      );
    }

    // Idle — pulsing button
    return _sosRing(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sos_rounded, color: Colors.white, size: 44),
          const SizedBox(height: 6),
          const Text(
            'SOS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Hold to activate',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.70),
              fontSize: 11,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
      outerColor: const Color(0xFFD85A30).withValues(alpha: 0.18),
      innerColor: const Color(0xFFD85A30),
      onTap: _startCountdown,
    );
  }

  Widget _sosRing({
    required Widget child,
    required Color outerColor,
    required Color innerColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: outerColor,
          border: Border.all(
            color: outerColor.withValues(alpha: 0.5),
            width: 14,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: innerColor,
            boxShadow: [
              BoxShadow(
                color: innerColor.withValues(alpha: 0.45),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // ── Instructions ──────────────────────────────────────────────────────────

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFD85A30).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFD85A30).withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        children: [
          _instructionRow(
            Icons.touch_app_rounded,
            'Tap the SOS button to start a 3-second countdown',
          ),
          const SizedBox(height: 10),
          _instructionRow(
            Icons.cancel_outlined,
            'Tap again to cancel if triggered accidentally',
          ),
          const SizedBox(height: 10),
          _instructionRow(
            Icons.people_outline_rounded,
            'Your trusted contacts will be notified instantly',
          ),
        ],
      ),
    );
  }

  Widget _instructionRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFFF8C64), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // ── Alert Sent Banner ─────────────────────────────────────────────────────

  Widget _buildAlertSentBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1D9E75).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF1D9E75).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF34D399),
                size: 22,
              ),
              SizedBox(width: 10),
              Text(
                'Alert sent successfully',
                style: TextStyle(
                  color: Color(0xFF34D399),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _bannerSubtitle(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: const Color(0xFF34D399).withValues(alpha: 0.40),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _resetSOS,
              child: const Text(
                'Cancel Alert',
                style: TextStyle(color: Color(0xFF34D399), fontSize: 13.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _bannerSubtitle() {
    final result = _dispatchResult;
    if (result == null) return 'Alert logged · Location shared';

    final locationPart =
        result.location != null ? 'Location shared' : 'Location unavailable';

    final allWebUnsupported = result.smsOutcomes.isNotEmpty &&
        result.smsOutcomes
            .every((o) => o.status == SmsDispatchStatus.unsupportedOnWeb);
    if (allWebUnsupported) {
      return 'Alert logged · $locationPart · SMS unavailable in browser';
    }

    return '${result.contactsReached} of ${result.smsOutcomes.length} '
        'contacts notified · $locationPart';
  }

  // ── Contacts Card ─────────────────────────────────────────────────────────

  Widget _buildContactsCard() {
    final rows = [
      ..._contacts.map(
        (c) => _Contact(c.name, c.relation, c.isNotifyOnSOS ? '🟢' : '⚪'),
      ),
      const _Contact('Emergency Services', '112', '🔴'),
    ];

    return _infoCard(
      title: 'Emergency Contacts',
      icon: Icons.people_outline_rounded,
      iconColor: const Color(0xFF4DA3FF),
      child: Column(
        children: rows
            .map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Text(c.dot, style: const TextStyle(fontSize: 10)),
                    const SizedBox(width: 10),
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
                            c.sub,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.40),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.phone_outlined,
                      color: const Color(0xFF4DA3FF).withValues(alpha: 0.70),
                      size: 18,
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ── Location Card ─────────────────────────────────────────────────────────

  Widget _buildLocationCard() {
    final locAsync = ref.watch(currentLocationProvider);
    final loc = locAsync.valueOrNull;
    final hasFix = loc != null && !(loc.lat == 0 && loc.lng == 0);

    return _infoCard(
      title: 'Your Location',
      icon: Icons.location_on_outlined,
      iconColor: const Color(0xFF34D399),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 80,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: hasFix
                ? GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(loc.lat, loc.lng),
                      zoom: 15,
                    ),
                    style: _sosMapStyle,
                    markers: {
                      Marker(
                        markerId: const MarkerId('me'),
                        position: LatLng(loc.lat, loc.lng),
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
                  )
                : Center(
                    child: locAsync.hasError
                        ? Text(
                            'Location unavailable',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.30),
                              fontSize: 12,
                            ),
                          )
                        : const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF34D399),
                            ),
                          ),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            hasFix ? loc.coordinates : 'Locating…',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            hasFix
                ? '${loc.label} · ${loc.accuracy}'
                : 'Fetching your location',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.40),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick Action Row ──────────────────────────────────────────────────────

  Widget _buildActionsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            icon: Icons.call_rounded,
            label: 'Call 112',
            color: const Color(0xFF34D399),
            onTap: _callEmergencyServices,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionButton(
            icon: Icons.message_outlined,
            label: 'Send SMS',
            color: const Color(0xFF4DA3FF),
            onTap: _sendSmsQuickAction,
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _infoCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF162435).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
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

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF1A73E8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class _Contact {
  final String name;
  final String sub;
  final String dot;
  const _Contact(this.name, this.sub, this.dot);
}

const String _sosMapStyle = '''
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
