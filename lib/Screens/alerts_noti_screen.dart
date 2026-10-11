import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/safety_service.dart';
import '../models/safety_alert.dart';
import '../routes/app_routes.dart';
import '../state/providers.dart';

class AlertsNotiScreen extends ConsumerStatefulWidget {
  const AlertsNotiScreen({super.key});

  @override
  ConsumerState<AlertsNotiScreen> createState() => _AlertsNotiScreenState();
}

class _AlertsNotiScreenState extends ConsumerState<AlertsNotiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Alert data ────────────────────────────────────────────────────────────
  // Real SOS alerts from Firestore (sos_alerts, owner-scoped) via sosAlertsProvider.
  List<SafetyAlert> get _allAlerts =>
      ref.watch(sosAlertsProvider).valueOrNull ?? const [];

  // ── Notification settings ─────────────────────────────────────────────────

  final Map<String, bool> _settings = {
    'Area safety alerts': true,
    'Trusted contact updates': true,
    'Route & location changes': true,
    'Night mode reminders': false,
    'Community reports': true,
    'App announcements': false,
  };

  String _sensitivity = 'High';

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
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAlertsTab(),
                    _buildNotificationsTab(),
                    _buildSettingsTab(),
                  ],
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
    final unreadCount = _allAlerts.where((a) => a.isUnread).length;

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
              color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
              border: Border.all(
                color: const Color(0xFFFBBF24).withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Color(0xFFFBBF24),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Alerts & Notifications',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                '$unreadCount new',
                style: const TextStyle(
                  color: Color(0xFFFF6B6B),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF162435).withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFFFBBF24).withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: const Color(0xFFFBBF24).withValues(alpha: 0.35),
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: const Color(0xFFFBBF24),
        unselectedLabelColor: Colors.white.withValues(alpha: 0.40),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Alerts'),
          Tab(text: 'Notifications'),
          Tab(text: 'Settings'),
        ],
      ),
    );
  }

  // ── Alerts Tab ────────────────────────────────────────────────────────────

  Widget _buildAlertsTab() {
    final alertsAsync = ref.watch(sosAlertsProvider);
    if (alertsAsync.isLoading && _allAlerts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4DA3FF)),
      );
    }
    if (_allAlerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined,
                size: 48, color: Colors.white.withValues(alpha: 0.25)),
            const SizedBox(height: 12),
            Text(
              'No alerts yet',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your SOS alerts will appear here.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      );
    }

    final critical = _allAlerts
        .where((a) => a.type == AlertType.critical)
        .toList();
    final others = _allAlerts
        .where((a) => a.type != AlertType.critical)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (critical.isNotEmpty) ...[
            _buildSectionLabel('Critical Alerts'),
            const SizedBox(height: 10),
            ...critical.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildAlertTile(a),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _buildSectionLabel('Recent Activity'),
          const SizedBox(height: 10),
          ...others.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildAlertTile(a),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertTile(SafetyAlert alert) {
    final color = alert.type == AlertType.critical
        ? const Color(0xFFFF6B6B)
        : alert.type == AlertType.safety
        ? const Color(0xFF34D399)
        : const Color(0xFF60A5FA);

    return GestureDetector(
      onTap: () => _showDetail(
        icon: alert.icon,
        color: color,
        title: alert.title,
        body: alert.body,
        time: alert.time,
      ),
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: alert.isUnread
            ? color.withValues(alpha: 0.07)
            : const Color(0xFF162435).withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: alert.isUnread
              ? color.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.14),
            ),
            child: Icon(alert.icon, color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        alert.title,
                        style: TextStyle(
                          color: alert.isUnread
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.70),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (alert.isUnread)
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  alert.body,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  alert.time,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.65),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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

  // ── Notifications Tab ─────────────────────────────────────────────────────

  Widget _buildNotificationsTab() {
    final notifs = SafetyService.instance.notifications();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('Today'),
          const SizedBox(height: 10),
          ...notifs
              .take(2)
              .map(
                (n) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildNotifTile(n),
                ),
              ),
          const SizedBox(height: 16),
          _buildSectionLabel('Earlier'),
          const SizedBox(height: 10),
          ...notifs
              .skip(2)
              .map(
                (n) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildNotifTile(n),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildNotifTile(AppNotification notif) {
    return GestureDetector(
      onTap: () => _showDetail(
        icon: notif.icon,
        color: notif.color,
        title: notif.title,
        body: notif.body,
        time: notif.time,
      ),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF162435).withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: notif.color.withValues(alpha: 0.12),
            ),
            child: Icon(notif.icon, color: notif.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notif.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  notif.body,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.40),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  notif.time,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.30),
                    fontSize: 11,
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

  // ── Settings Tab ──────────────────────────────────────────────────────────

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNotifBanner(),
          const SizedBox(height: 20),
          _buildSectionLabel('Notification Preferences'),
          const SizedBox(height: 12),
          ..._settings.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildToggleTile(entry.key, entry.value),
            ),
          ),
          const SizedBox(height: 18),
          _buildSectionLabel('Alert Sensitivity'),
          const SizedBox(height: 12),
          _buildSensitivityCard(),
          const SizedBox(height: 18),
          _buildClearButton(),
        ],
      ),
    );
  }

  Widget _buildNotifBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBBF24).withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFBBF24).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_active_rounded,
            color: const Color(0xFFFBBF24).withValues(alpha: 0.80),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Notifications are enabled. You\'ll receive real-time safety alerts.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.60),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile(String label, bool value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF162435).withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13.5,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: (v) => setState(() => _settings[label] = v),
            activeThumbColor: const Color(0xFFFBBF24),
            activeTrackColor: const Color(0xFFFBBF24).withValues(alpha: 0.25),
            inactiveThumbColor: Colors.white.withValues(alpha: 0.30),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
          ),
        ],
      ),
    );
  }

  Widget _buildSensitivityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF162435).withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Low', 'Medium', 'High'].map((level) {
              final isActive = level == _sensitivity;
              return GestureDetector(
                onTap: () => setState(() => _sensitivity = level),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFFF6EBF).withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFFFF6EBF).withValues(alpha: 0.40)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Text(
                    level,
                    style: TextStyle(
                      color: isActive
                          ? const Color(0xFFFF6EBF)
                          : Colors.white.withValues(alpha: 0.45),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            _sensitivity == 'Low'
                ? 'Low sensitivity: Only critical alerts within 500 m.'
                : _sensitivity == 'Medium'
                ? 'Medium sensitivity: Important alerts within 1 km.'
                : 'High sensitivity: Alerts for all flagged areas within 2 km.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.40),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClearButton() {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1A2E44),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: const Text(
              'All notifications cleared',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B6B).withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: const Color(0xFFFF6B6B).withValues(alpha: 0.28),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFFF6B6B),
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'Clear All Notifications',
              style: TextStyle(
                color: Color(0xFFFF6B6B),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
    required String time,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF162435),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.14),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              body,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.70),
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  color: color.withValues(alpha: 0.8),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(time, style: TextStyle(color: color, fontSize: 12)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Dismiss',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, AppRoutes.liveLocation);
            },
            child: const Text(
              'View on map',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

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
}

// ── Data models ───────────────────────────────────────────────────────────
