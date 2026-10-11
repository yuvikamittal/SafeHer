import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _locationSharing = true;
  bool _sosVibration = true;
  bool _nightMode = false;
  bool _emergencyAlerts = true;
  bool _biometricLock = false;
  bool _routeTracking = true;

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
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      _buildSectionLabel('Safety'),
                      const SizedBox(height: 12),
                      _buildSafetySection(),
                      const SizedBox(height: 22),
                      _buildSectionLabel('Notifications'),
                      const SizedBox(height: 12),
                      _buildNotificationsSection(),
                      const SizedBox(height: 22),
                      _buildSectionLabel('Security'),
                      const SizedBox(height: 12),
                      _buildSecuritySection(),
                      const SizedBox(height: 22),
                      _buildSectionLabel('Support'),
                      const SizedBox(height: 12),
                      _buildSupportSection(context),
                      const SizedBox(height: 28),
                      _buildSignOutButton(context),
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
                Icons.arrow_back_ios_rounded,
                color: Colors.white70,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
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

  Widget _buildSafetySection() {
    return _card(
      child: Column(
        children: [
          _toggleTile(
            icon: Icons.location_on_rounded,
            color: const Color(0xFF34D399),
            title: 'Live Location Sharing',
            subtitle: 'Share location with trusted contacts',
            value: _locationSharing,
            onChanged: (v) => setState(() => _locationSharing = v),
          ),
          _divider(),
          _toggleTile(
            icon: Icons.route_rounded,
            color: const Color(0xFFFF6EBF),
            title: 'Route Tracking',
            subtitle: 'Track and record safe routes',
            value: _routeTracking,
            onChanged: (v) => setState(() => _routeTracking = v),
          ),
          _divider(),
          _toggleTile(
            icon: Icons.nightlight_round,
            color: const Color(0xFF9C27B0),
            title: 'Night Mode Alerts',
            subtitle: 'Enhanced monitoring after 9 PM',
            value: _nightMode,
            onChanged: (v) => setState(() => _nightMode = v),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return _card(
      child: Column(
        children: [
          _toggleTile(
            icon: Icons.notifications_active_rounded,
            color: const Color(0xFFFBBF24),
            title: 'Emergency Alerts',
            subtitle: 'Get notified about nearby incidents',
            value: _emergencyAlerts,
            onChanged: (v) => setState(() => _emergencyAlerts = v),
          ),
          _divider(),
          _toggleTile(
            icon: Icons.vibration_rounded,
            color: const Color(0xFFFF6B6B),
            title: 'SOS Vibration',
            subtitle: 'Vibrate device on SOS trigger',
            value: _sosVibration,
            onChanged: (v) => setState(() => _sosVibration = v),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return _card(
      child: Column(
        children: [
          _toggleTile(
            icon: Icons.fingerprint_rounded,
            color: const Color(0xFFE91E8C),
            title: 'Biometric Lock',
            subtitle: 'Require fingerprint to open app',
            value: _biometricLock,
            onChanged: (v) => setState(() => _biometricLock = v),
          ),
          _divider(),
          _navTile(
            icon: Icons.lock_reset_rounded,
            color: const Color(0xFF9C27B0),
            title: 'Change PIN',
            subtitle: 'Update your emergency access PIN',
            onTap: () => _showComingSoon(context, 'Change PIN'),
          ),
          _divider(),
          _navTile(
            icon: Icons.delete_outline_rounded,
            color: const Color(0xFFFF6B6B),
            title: 'Delete Account',
            subtitle: 'Permanently remove your data',
            onTap: () => _showDeleteConfirm(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return _card(
      child: Column(
        children: [
          _navTile(
            icon: Icons.help_outline_rounded,
            color: const Color(0xFF34D399),
            title: 'Help & FAQ',
            subtitle: 'Answers to common questions',
            onTap: () => _showComingSoon(context, 'Help & FAQ'),
          ),
          _divider(),
          _navTile(
            icon: Icons.privacy_tip_outlined,
            color: const Color(0xFFFF6EBF),
            title: 'Privacy Policy',
            subtitle: 'How we protect your data',
            onTap: () => _showComingSoon(context, 'Privacy Policy'),
          ),
          _divider(),
          _navTile(
            icon: Icons.info_outline_rounded,
            color: const Color(0xFFFBBF24),
            title: 'About SafeHer',
            subtitle: 'Version 1.0.0',
            onTap: () => _showAbout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSignOutConfirm(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B6B).withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFFF6B6B).withValues(alpha: 0.30),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFFF6B6B), size: 18),
            SizedBox(width: 8),
            Text(
              'Sign Out',
              style: TextStyle(
                color: Color(0xFFFF6B6B),
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.12),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.38),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        Transform.scale(
          scale: 0.80,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFFE91E8C),
            activeTrackColor: const Color(0xFFE91E8C).withValues(alpha: 0.30),
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.white12,
          ),
        ),
      ],
    );
  }

  Widget _navTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.38),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.white.withValues(alpha: 0.25),
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Divider(
        height: 1,
        color: Colors.white.withValues(alpha: 0.07),
        thickness: 1,
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF162435).withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: child,
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature — coming soon',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF162435),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF162435),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.shield_rounded, color: Color(0xFFFF6EBF), size: 22),
            SizedBox(width: 10),
            Text(
              'SafeHer',
              style: TextStyle(color: Colors.white, fontSize: 17),
            ),
          ],
        ),
        content: Text(
          'SafeHer v1.0.0\n\nYour personal safety companion. Built with care to keep women safe at every step.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 13,
            height: 1.6,
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E8C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF162435),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.white, fontSize: 17),
        ),
        content: Text(
          'This will permanently delete your account and all data. This action cannot be undone.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Account deleted. Signing you out…',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFFD85A30),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSignOutConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF162435),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign out',
          style: TextStyle(color: Colors.white, fontSize: 17),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E8C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx); // close dialog
              await FcmService.instance.clearToken();
              await AuthService.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (route) => false, // clears entire navigation stack
              );
            },
            child: const Text(
              'Sign out',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
