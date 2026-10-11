import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../routes/app_routes.dart';
import '../state/providers.dart';
import '../widgets/app_background.dart';

class DashboardScreen extends ConsumerWidget {
  final String email;

  const DashboardScreen({super.key, required this.email});

  String _displayName(WidgetRef ref) {
    final profileName =
        (ref.watch(profileProvider).valueOrNull?['name'] as String?)?.trim();
    if (profileName != null && profileName.isNotEmpty) {
      return profileName.split(' ').first;
    }
    final name = email.split('@').first.trim();
    if (name.isEmpty) return 'User';
    return name[0].toUpperCase() + name.substring(1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, ref),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGreeting(ref),
                      const SizedBox(height: 20),
                      _buildStatusBanner(),
                      const SizedBox(height: 28),
                      _buildSectionLabel('Features'),
                      const SizedBox(height: 14),
                      _buildAICard(context),
                      const SizedBox(height: 14),
                      _buildFeatureGrid(context),
                      const SizedBox(height: 28),
                      _buildSectionLabel('Recent Activity'),
                      const SizedBox(height: 12),
                      _buildActivityList(context),
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

  // ── App Bar ────────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE91E8C).withValues(alpha: 0.15),
              border: Border.all(
                color: const Color(0xFFE91E8C).withValues(alpha: 0.40),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Color(0xFFFF6EBF),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'SafeHer',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          // Settings icon button
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: const Icon(
                Icons.settings_outlined,
                color: Colors.white60,
                size: 18,
              ),
            ),
          ),
          // Avatar / profile button
          GestureDetector(
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.profile,
              arguments: email,
            ),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFE91E8C), Color(0xFFC2185B)],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Center(
                child: Text(
                  _displayName(ref)[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Greeting ────────────────────────────────────────────────────────────

  Widget _buildGreeting(WidgetRef ref) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, ${_displayName(ref)} 💜',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Stay safe — your protection is active',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }

  // ── Status Banner ───────────────────────────────────────────────────────

  Widget _buildStatusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE91E8C).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE91E8C).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE91E8C).withValues(alpha: 0.18),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: Color(0xFFFF6EBF),
              size: 19,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Protection Active',
                  style: TextStyle(
                    color: Color(0xFFFF6EBF),
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Live monitoring on · All systems operational',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_outline,
            color: Color(0xFFFF6EBF),
            size: 20,
          ),
        ],
      ),
    );
  }

  // ── Section Label ───────────────────────────────────────────────────────

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

  // ── Assistant Card ─────────────────────────────────────────────────────────────

  Widget _buildAICard(BuildContext context) {
    return _AIFeatureCard(
      onTap: () => Navigator.pushNamed(context, AppRoutes.assistant),
    );
  }

  // ── Feature Grid ────────────────────────────────────────────────────────

  Widget _buildFeatureGrid(BuildContext context) {
    final features = [
      _FeatureCardData(
        icon: Icons.sos_rounded,
        label: 'Emergency SOS',
        subtitle: 'Instant alert & call',
        gradient: const [Color(0xFF2A0A0A), Color(0xFF1A0F0F)],
        accentColor: const Color(0xFFFF3B3B),
        onTap: () => Navigator.pushNamed(context, AppRoutes.sos),
      ),
      _FeatureCardData(
        icon: Icons.location_on_rounded,
        label: 'Live Location',
        subtitle: 'Share in real-time',
        gradient: const [Color(0xFF0A1A2A), Color(0xFF0F1A30)],
        accentColor: const Color(0xFF34D399),
        onTap: () => Navigator.pushNamed(context, AppRoutes.liveLocation),
      ),
      _FeatureCardData(
        icon: Icons.route_rounded,
        label: 'Safe Route',
        subtitle: 'Safest path for you',
        gradient: const [Color(0xFF0A1A10), Color(0xFF0F2015)],
        accentColor: const Color(0xFF4ADE80),
        onTap: () => Navigator.pushNamed(context, AppRoutes.safeRoute),
      ),
      _FeatureCardData(
        icon: Icons.contacts_rounded,
        label: 'Emergency Contacts',
        subtitle: 'Manage trusted contacts',
        gradient: const [Color(0xFF1A0A2A), Color(0xFF150F25)],
        accentColor: const Color(0xFFA78BFA),
        onTap: () => Navigator.pushNamed(context, AppRoutes.emergencyContacts),
      ),
      _FeatureCardData(
        icon: Icons.local_hospital_rounded,
        label: 'Nearby Help',
        subtitle: 'Find help around you',
        gradient: const [Color(0xFF1A1A0A), Color(0xFF20200F)],
        accentColor: const Color(0xFFFBBF24),
        onTap: () => Navigator.pushNamed(context, AppRoutes.nearbyHelp),
      ),
      _FeatureCardData(
        icon: Icons.notifications_active_rounded,
        label: 'Alerts & Notifications',
        subtitle: 'Safety alerts & updates',
        gradient: const [Color(0xFF1A100A), Color(0xFF201510)],
        accentColor: const Color(0xFFFF9E44),
        onTap: () => Navigator.pushNamed(context, AppRoutes.alerts),
      ),
      _FeatureCardData(
        icon: Icons.person_rounded,
        label: 'My Profile',
        subtitle: 'View & edit info',
        gradient: const [Color(0xFF1A1040), Color(0xFF2A0F2E)],
        accentColor: const Color(0xFFE91E8C),
        onTap: () =>
            Navigator.pushNamed(context, AppRoutes.profile, arguments: email),
      ),
      _FeatureCardData(
        icon: Icons.settings_rounded,
        label: 'Settings',
        subtitle: 'Preferences & privacy',
        gradient: const [Color(0xFF0F2335), Color(0xFF1A1040)],
        accentColor: const Color(0xFF9C27B0),
        onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
      ),
    ];

    final List<Widget> rows = [];
    for (int i = 0; i < features.length; i += 2) {
      final left = features[i];
      final right = i + 1 < features.length ? features[i + 1] : null;
      rows.add(
        Row(
          children: [
            Expanded(
              child: _SmallFeatureCard(
                icon: left.icon,
                label: left.label,
                subtitle: left.subtitle,
                gradient: left.gradient,
                accentColor: left.accentColor,
                onTap: left.onTap,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: right != null
                  ? _SmallFeatureCard(
                      icon: right.icon,
                      label: right.label,
                      subtitle: right.subtitle,
                      gradient: right.gradient,
                      accentColor: right.accentColor,
                      onTap: right.onTap,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
      if (i + 2 < features.length) {
        rows.add(const SizedBox(height: 14));
      }
    }

    return Column(children: rows);
  }

  // ── Activity List ───────────────────────────────────────────────────────

  Widget _buildActivityList(BuildContext context) {
    final items = [
      _ActivityData(
        icon: Icons.auto_awesome_rounded,
        label: 'Your evening route was reviewed',
        sub: 'Today at ${_timeString()}',
        color: const Color(0xFFE91E8C),
      ),
      _ActivityData(
        icon: Icons.auto_awesome_rounded,
        label: 'Safety score updated for your area',
        sub: 'Today at 09:05 AM',
        color: const Color(0xFF9C27B0),
      ),
      _ActivityData(
        icon: Icons.tips_and_updates_rounded,
        label: 'New personalised safety tip',
        sub: 'Yesterday at 8:00 PM',
        color: const Color(0xFFFBBF24),
      ),
    ];

    return Column(
      children: items
          .map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildActivityTile(context, a),
            ),
          )
          .toList(),
    );
  }

  String _timeString() {
    final now = DateTime.now();
    final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final m = now.minute.toString().padLeft(2, '0');
    final period = now.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  Widget _buildActivityTile(BuildContext context, _ActivityData item) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.alerts),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF162435).withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: item.color.withValues(alpha: 0.12),
            ),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.sub,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.40),
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
      ),
    );
  }
}

// ── Feature Card Data Model ───────────────────────────────────────────────

class _FeatureCardData {
  final IconData icon;
  final String label;
  final String subtitle;
  final List<Color> gradient;
  final Color accentColor;
  final VoidCallback onTap;

  const _FeatureCardData({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.accentColor,
    required this.onTap,
  });
}

// ── Small Feature Card ────────────────────────────────────────────────────

class _SmallFeatureCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final List<Color> gradient;
  final Color accentColor;
  final VoidCallback onTap;

  const _SmallFeatureCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_SmallFeatureCard> createState() => _SmallFeatureCardState();
}

class _SmallFeatureCardState extends State<_SmallFeatureCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.gradient,
            ),
            border: Border.all(
              color: widget.accentColor.withValues(alpha: 0.30),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withValues(alpha: 0.14),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      widget.accentColor,
                      widget.accentColor.withValues(alpha: 0.6),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.35),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.07),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white60,
                      size: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Assistant Feature Card ───────────────────────────────────────────────────────

class _AIFeatureCard extends StatefulWidget {
  final VoidCallback onTap;
  const _AIFeatureCard({required this.onTap});

  @override
  State<_AIFeatureCard> createState() => _AIFeatureCardState();
}

class _AIFeatureCardState extends State<_AIFeatureCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _shimmerAnim = Tween<double>(
      begin: -1.5,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2A0F2E), Color(0xFF1A1040), Color(0xFF0D1B2A)],
            ),
            border: Border.all(
              color: const Color(0xFFE91E8C).withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE91E8C).withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: const Color(0xFF9C27B0).withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _shimmerAnim,
                builder: (_, _) => Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        begin: Alignment(_shimmerAnim.value - 0.5, 0),
                        end: Alignment(_shimmerAnim.value + 0.5, 0),
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.04),
                          Colors.transparent,
                        ],
                      ).createShader(bounds),
                      child: Container(color: Colors.white),
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE91E8C), Color(0xFF9C27B0)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFE91E8C,
                              ).withValues(alpha: 0.40),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Safety Assistant',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF34D399,
                                    ).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF34D399,
                                      ).withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: const Text(
                                    '24/7',
                                    style: TextStyle(
                                      color: Color(0xFF34D399),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Your personal safety companion',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.50),
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.07),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white70,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPill(
                        Icons.route_rounded,
                        'Safe Routes',
                        const Color(0xFF34D399),
                      ),
                      _buildPill(
                        Icons.location_on_rounded,
                        'Area Safety',
                        const Color(0xFFFF6EBF),
                      ),
                      _buildPill(
                        Icons.sos_rounded,
                        'Emergency Help',
                        const Color(0xFFFF6B6B),
                      ),
                      _buildPill(
                        Icons.tips_and_updates_rounded,
                        'Safety Tips',
                        const Color(0xFFFBBF24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE91E8C).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE91E8C).withValues(alpha: 0.22),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Color(0xFFFF6EBF),
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Ask me anything about your safety…',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE91E8C), Color(0xFF9C27B0)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Open',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
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
  }
}

// ── Data model ────────────────────────────────────────────────────────────

class _ActivityData {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  const _ActivityData({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
  });
}
