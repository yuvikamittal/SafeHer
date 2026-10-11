import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/emergency_contact.dart';
import '../routes/app_routes.dart';
import '../state/providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String email;

  const ProfileScreen({super.key, required this.email});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String get email => widget.email;

  String _displayName(Map<String, dynamic> profile) {
    final n = (profile['name'] as String?)?.trim();
    if (n != null && n.isNotEmpty) return n;
    final name = email.split('@').first.trim();
    if (name.isEmpty) return 'User';
    return name[0].toUpperCase() + name.substring(1);
  }

  SnackBar _snack(String msg) => SnackBar(
    content: Text(msg),
    backgroundColor: const Color(0xFF162435),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).valueOrNull ?? const {};
    final contacts = ref.watch(contactsProvider).valueOrNull ?? const [];
    final alerts = ref.watch(sosAlertsProvider).valueOrNull ?? const [];

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
              _buildAppBar(context, profile),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      _buildAvatar(profile),
                      const SizedBox(height: 28),
                      _buildInfoCard(profile),
                      const SizedBox(height: 20),
                      _buildSafetyStatsCard(contacts.length, alerts.length),
                      const SizedBox(height: 20),
                      _buildTrustedContactsCard(context, contacts),
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

  Widget _buildAppBar(BuildContext context, Map<String, dynamic> profile) {
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
            'My Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _openEditSheet(context, profile),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE91E8C), Color(0xFF9C27B0)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Edit',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> profile) {
    final name = _displayName(profile);
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFE91E8C), Color(0xFF9C27B0)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE91E8C).withValues(alpha: 0.40),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF34D399),
                  border: Border.all(color: const Color(0xFF0D1B2A), width: 2),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF34D399).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF34D399).withValues(alpha: 0.30),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_user_rounded,
                color: Color(0xFF34D399),
                size: 13,
              ),
              SizedBox(width: 5),
              Text(
                'Verified & Protected',
                style: TextStyle(
                  color: Color(0xFF34D399),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> profile) {
    String v(String key) {
      final s = (profile[key] as String?)?.trim();
      return (s == null || s.isEmpty) ? 'Not set' : s;
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            Icons.person_outline_rounded,
            'Personal Info',
            const Color(0xFFE91E8C),
          ),
          const SizedBox(height: 16),
          _infoRow(Icons.phone_outlined, 'Phone', v('phone')),
          const SizedBox(height: 12),
          _infoRow(Icons.location_on_outlined, 'Home Address', v('address')),
          const SizedBox(height: 12),
          _infoRow(Icons.cake_outlined, 'Date of Birth', v('dob')),
          const SizedBox(height: 12),
          _infoRow(Icons.bloodtype_outlined, 'Blood Group', v('bloodGroup')),
        ],
      ),
    );
  }

  Widget _buildSafetyStatsCard(int contactsCount, int alertsCount) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            Icons.bar_chart_rounded,
            'Safety Activity',
            const Color(0xFF9C27B0),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statBox('$contactsCount', 'Trusted\nContacts',
                  const Color(0xFF34D399)),
              const SizedBox(width: 10),
              _statBox('$alertsCount', 'Emergency\nAlerts Sent',
                  const Color(0xFFFF6B6B)),
              const SizedBox(width: 10),
              _statBox(contactsCount > 0 ? 'On' : 'Off', 'Protection\nStatus',
                  const Color(0xFFFF6EBF)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustedContactsCard(
    BuildContext context,
    List<EmergencyContact> contacts,
  ) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            Icons.people_outline_rounded,
            'Trusted Contacts',
            const Color(0xFFFBBF24),
          ),
          const SizedBox(height: 16),
          if (contacts.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'No trusted contacts yet.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.40),
                  fontSize: 12.5,
                ),
              ),
            )
          else
            ...contacts.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFBBF24).withValues(alpha: 0.12),
                        border: Border.all(
                          color:
                              const Color(0xFFFBBF24).withValues(alpha: 0.30),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Color(0xFFFBBF24),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${c.relation} · ${c.phone}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.40),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ScaffoldMessenger.of(context)
                          .showSnackBar(_snack('Calling ${c.name}…')),
                      child: Icon(
                        Icons.call_outlined,
                        color: const Color(0xFF34D399).withValues(alpha: 0.7),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.emergencyContacts),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline_rounded,
                  color: const Color(0xFFE91E8C).withValues(alpha: 0.7),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Add trusted contact',
                  style: TextStyle(
                    color: const Color(0xFFFF6EBF).withValues(alpha: 0.8),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openEditSheet(BuildContext context, Map<String, dynamic> profile) {
    final nameC = TextEditingController(text: profile['name'] as String? ?? '');
    final phoneC =
        TextEditingController(text: profile['phone'] as String? ?? '');
    final addressC =
        TextEditingController(text: profile['address'] as String? ?? '');
    final dobC = TextEditingController(text: profile['dob'] as String? ?? '');
    final bloodC =
        TextEditingController(text: profile['bloodGroup'] as String? ?? '');
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F2335),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheet) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _field('Full Name', nameC),
                  _field('Phone', phoneC, keyboard: TextInputType.phone),
                  _field('Home Address', addressC),
                  _field('Date of Birth', dobC, hint: 'e.g. 15 March 1998'),
                  _field('Blood Group', bloodC, hint: 'e.g. B+'),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE91E8C),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: saving
                          ? null
                          : () async {
                              setSheet(() => saving = true);
                              try {
                                await ref
                                    .read(authServiceProvider)
                                    .updateProfile({
                                  'name': nameC.text.trim(),
                                  'phone': phoneC.text.trim(),
                                  'address': addressC.text.trim(),
                                  'dob': dobC.text.trim(),
                                  'bloodGroup': bloodC.text.trim(),
                                });
                                if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(_snack('Profile updated'));
                                }
                              } catch (e) {
                                setSheet(() => saving = false);
                                if (sheetCtx.mounted) {
                                  ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                    _snack('Could not save: $e'),
                                  );
                                }
                              }
                            },
                      child: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _field(
    String label,
    TextEditingController c, {
    String? hint,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: c,
            keyboardType: keyboard,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  TextStyle(color: Colors.white.withValues(alpha: 0.25)),
              filled: true,
              fillColor: const Color(0xFF162435),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE91E8C)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 10.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFFFF6EBF).withValues(alpha: 0.7),
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF162435).withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: child,
    );
  }

  Widget _cardHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
