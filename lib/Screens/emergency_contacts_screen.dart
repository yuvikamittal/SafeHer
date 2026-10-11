import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/emergency_contact.dart';
import '../services/contacts_service.dart';
import '../state/providers.dart';

class EmergencyContactsScreen extends ConsumerStatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  ConsumerState<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState
    extends ConsumerState<EmergencyContactsScreen> {
  // Local mirror of the shared `contactsProvider` stream. Kept as local state
  // (rather than reading the provider directly in build) so the optimistic
  // toggle logic in _updateToggle can mutate a single entry instantly; the
  // provider listener below reconciles it with the server value on the next
  // snapshot. This is the SINGLE source of truth — the SOS screen reads the
  // same provider, so the two can no longer drift.
  List<EmergencyContact> _contacts = [];
  bool _isLoading = true;
  String? _loadError;

  /// Retry button just re-triggers the shared stream by invalidating it.
  void _retryLoadContacts() {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    ref.invalidate(contactsProvider);
  }

  /// Pushes the latest AsyncValue from `contactsProvider` into local state.
  void _syncFromAsync(AsyncValue<List<EmergencyContact>> value) {
    value.when(
      data: (contacts) {
        if (!mounted) return;
        setState(() {
          _contacts = contacts;
          _isLoading = false;
          _loadError = null;
        });
      },
      loading: () {
        if (!mounted) return;
        setState(() => _isLoading = true);
      },
      error: (e, _) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _loadError = 'Could not load contacts: $e';
        });
      },
    );
  }

  final List<Color> _avatarColors = [
    const Color(0xFF4DA3FF),
    const Color(0xFF34D399),
    const Color(0xFFFBBF24),
    const Color(0xFFB47AFF),
    const Color(0xFFFF6B6B),
  ];

  Color _colorFor(int index) => _avatarColors[index % _avatarColors.length];

  /// Flips the SOS-alert or share-location toggle for the contact at
  /// [index]. Updates the UI immediately (optimistic) and writes the change
  /// to Firestore; the stream listener will reconcile with the server value
  /// shortly after.
  Future<void> _updateToggle({
    required int index,
    bool? isNotifyOnSOS,
    bool? isShareLocation,
  }) async {
    final current = _contacts[index];
    final updated = current.copyWith(
      isNotifyOnSOS: isNotifyOnSOS,
      isShareLocation: isShareLocation,
    );
    setState(() => _contacts[index] = updated);
    try {
      await ContactsService.instance.updateContact(updated);
    } catch (e) {
      if (!mounted) return;
      // Revert on failure and let the person know.
      setState(() => _contacts[index] = current);
      _showSnack('Could not update contact: $e', isError: true);
    }
  }

  void _showAddContactSheet() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String relation = 'Family';
    final relations = ['Family', 'Friend', 'Colleague', 'Neighbour', 'Other'];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF162435),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: StatefulBuilder(
          builder: (_, setS) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
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
              const Text(
                'Add emergency contact',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),

              _sheetLabel('Full name'),
              const SizedBox(height: 7),
              _sheetField(
                controller: nameCtrl,
                hint: 'e.g. Priya Sharma',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 16),

              _sheetLabel('Phone number'),
              const SizedBox(height: 7),
              _sheetField(
                controller: phoneCtrl,
                hint: '+91 00000 00000',
                icon: Icons.phone_outlined,
                inputType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              _sheetLabel('Relation'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: relations.map((r) {
                  final sel = r == relation;
                  return GestureDetector(
                    onTap: () => setS(() => relation = r),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF4DA3FF).withValues(alpha: 0.18)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel
                              ? const Color(0xFF4DA3FF).withValues(alpha: 0.55)
                              : Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Text(
                        r,
                        style: TextStyle(
                          color: sel
                              ? const Color(0xFF4DA3FF)
                              : Colors.white.withValues(alpha: 0.55),
                          fontSize: 12.5,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final phone = phoneCtrl.text.trim();
                    if (name.isEmpty || phone.isEmpty) {
                      _showSnack('Please fill all fields', isError: true);
                      return;
                    }
                    try {
                      await ContactsService.instance.addContact(
                        EmergencyContact(
                          name: name,
                          relation: relation,
                          phone: phone,
                          isNotifyOnSOS: true,
                          isShareLocation: false,
                        ),
                      );
                    } catch (e) {
                      _showSnack('Could not save contact: $e', isError: true);
                      return;
                    }
                    // No local list mutation needed — the shared contactsProvider
                    // stream reconciles _contacts (via ref.listen in build) as
                    // soon as this write round-trips.
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    _showSnack(
                      '$name added as emergency contact',
                      isSuccess: true,
                    );
                  },
                  child: const Text(
                    'Add contact',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      nameCtrl.dispose();
      phoneCtrl.dispose();
    });
  }

  void _showEditContactSheet(int index) {
    final c = _contacts[index];
    final nameCtrl = TextEditingController(text: c.name);
    final phoneCtrl = TextEditingController(text: c.phone);
    final relations = <String>[
      'Family',
      'Friend',
      'Colleague',
      'Neighbour',
      'Other',
    ];
    if (!relations.contains(c.relation)) relations.insert(0, c.relation);
    String relation = c.relation;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF162435),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: StatefulBuilder(
          builder: (_, setS) => Column(
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
              const Text(
                'Edit contact',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),

              _sheetLabel('Full name'),
              const SizedBox(height: 7),
              _sheetField(
                controller: nameCtrl,
                hint: 'e.g. Priya Sharma',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 16),

              _sheetLabel('Phone number'),
              const SizedBox(height: 7),
              _sheetField(
                controller: phoneCtrl,
                hint: '+91 00000 00000',
                icon: Icons.phone_outlined,
                inputType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              _sheetLabel('Relation'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: relations.map((r) {
                  final sel = r == relation;
                  return GestureDetector(
                    onTap: () => setS(() => relation = r),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF4DA3FF).withValues(alpha: 0.18)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel
                              ? const Color(0xFF4DA3FF).withValues(alpha: 0.55)
                              : Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Text(
                        r,
                        style: TextStyle(
                          color: sel
                              ? const Color(0xFF4DA3FF)
                              : Colors.white.withValues(alpha: 0.55),
                          fontSize: 12.5,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final phone = phoneCtrl.text.trim();
                    if (name.isEmpty || phone.isEmpty) {
                      _showSnack('Please fill all fields', isError: true);
                      return;
                    }
                    try {
                      await ContactsService.instance.updateContact(
                        c.copyWith(
                          name: name,
                          relation: relation,
                          phone: phone,
                        ),
                      );
                    } catch (e) {
                      _showSnack(
                        'Could not update contact: $e',
                        isError: true,
                      );
                      return;
                    }
                    // The Firestore stream listener refreshes _contacts.
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    _showSnack('Contact updated', isSuccess: true);
                  },
                  child: const Text(
                    'Save changes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      nameCtrl.dispose();
      phoneCtrl.dispose();
    });
  }

  void _showContactOptions(int index) {
    final c = _contacts[index];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF162435),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _colorFor(index).withValues(alpha: 0.15),
                  child: Text(
                    c.name.isNotEmpty ? c.name[0] : '?',
                    style: TextStyle(
                      color: _colorFor(index),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        c.phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.white.withValues(alpha: 0.08)),
            const SizedBox(height: 8),
            _optionTile(
              Icons.phone_outlined,
              'Call ${c.name.split(' ').first}',
              const Color(0xFF34D399),
              () {
                Navigator.pop(ctx);
                _showSnack('Calling ${c.name.split(' ').first}...');
              },
            ),
            _optionTile(
              Icons.message_outlined,
              'Send message',
              const Color(0xFF4DA3FF),
              () {
                Navigator.pop(ctx);
                _showSnack('Opening messages...');
              },
            ),
            _optionTile(
              Icons.edit_outlined,
              'Edit contact',
              const Color(0xFFFBBF24),
              () {
                Navigator.pop(ctx);
                _showEditContactSheet(index);
              },
            ),
            _optionTile(
              Icons.delete_outline_rounded,
              'Remove contact',
              const Color(0xFFFF6B6B),
              () {
                Navigator.pop(ctx);
                _confirmDelete(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF162435),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Remove contact',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Text(
          'Remove ${_contacts[index].name} from your emergency contacts?',
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
              style: TextStyle(color: Colors.white.withValues(alpha: 0.50)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B).withValues(alpha: 0.85),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              final contact = _contacts[index];
              final name = contact.name;
              final id = contact.id;
              try {
                if (id != null) {
                  await ContactsService.instance.deleteContact(id);
                }
              } catch (e) {
                _showSnack('Could not remove contact: $e', isError: true);
                return;
              }
              // The Firestore stream listener removes it from _contacts.
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _showSnack('$name removed', isError: true);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isSuccess = false, bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess
            ? const Color(0xFF1D9E75)
            : isError
            ? const Color(0xFFD85A30)
            : const Color(0xFF1A73E8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Reconcile local state whenever the shared stream emits (adds/edits/
    // deletes, including this screen's own writes round-tripping back).
    ref.listen<AsyncValue<List<EmergencyContact>>>(
      contactsProvider,
      (_, next) => _syncFromAsync(next),
    );
    // Seed synchronously on build (listen only fires on subsequent changes).
    // Assign fields directly here — calling setState during build is illegal.
    final current = ref.watch(contactsProvider);
    current.when(
      data: (contacts) {
        _contacts = contacts;
        _isLoading = false;
        _loadError = null;
      },
      loading: () => _isLoading = _contacts.isEmpty,
      error: (e, _) {
        _isLoading = false;
        _loadError = 'Could not load contacts: $e';
      },
    );

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
          'Emergency Contacts',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(
                Icons.person_add_alt_1_rounded,
                color: Color(0xFF4DA3FF),
                size: 22,
              ),
              onPressed: _showAddContactSheet,
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
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF4DA3FF),
                  ),
                )
              : _loadError != null
              ? _ErrorState(message: _loadError!, onRetry: _retryLoadContacts)
              : _contacts.isEmpty
              ? _EmptyState(onAdd: _showAddContactSheet)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  children: [
                    // Summary banner
                    _SummaryBanner(count: _contacts.length),
                    const SizedBox(height: 24),

                    // Section label
                    _sectionLabel('Your contacts'),
                    const SizedBox(height: 12),

                    // Contact cards
                    ..._contacts.asMap().entries.map((entry) {
                      final i = entry.key;
                      final c = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ContactCard(
                          contact: c,
                          avatarColor: _colorFor(i),
                          onTap: () => _showContactOptions(i),
                          onSOSToggle: (v) => _updateToggle(
                            index: i,
                            isNotifyOnSOS: v,
                          ),
                          onLocationToggle: (v) => _updateToggle(
                            index: i,
                            isShareLocation: v,
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 8),

                    // Add contact button
                    GestureDetector(
                      onTap: _showAddContactSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF4DA3FF,
                          ).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(
                              0xFF4DA3FF,
                            ).withValues(alpha: 0.20),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_circle_outline_rounded,
                              color: Color(0xFF4DA3FF),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Add another contact',
                              style: TextStyle(
                                color: Color(0xFF4DA3FF),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Tips card
                    _TipsCard(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: Colors.white.withValues(alpha: 0.38),
      letterSpacing: 1.2,
    ),
  );

  Widget _optionTile(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(label, style: TextStyle(color: color, fontSize: 14)),
      onTap: onTap,
    );
  }

  Widget _sheetLabel(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w500,
      color: Colors.white.withValues(alpha: 0.55),
    ),
  );

  Widget _sheetField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.25),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: Colors.white30, size: 18),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 13,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 1.5),
        ),
      ),
    );
  }
}

// ── Contact Card ──────────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final Color avatarColor;
  final VoidCallback onTap;
  final ValueChanged<bool> onSOSToggle;
  final ValueChanged<bool> onLocationToggle;

  const _ContactCard({
    required this.contact,
    required this.avatarColor,
    required this.onTap,
    required this.onSOSToggle,
    required this.onLocationToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF162435).withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: avatarColor.withValues(alpha: 0.15),
                  child: Text(
                    contact.name.isNotEmpty ? contact.name[0] : '?',
                    style: TextStyle(
                      color: avatarColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: avatarColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              contact.relation,
                              style: TextStyle(
                                color: avatarColor,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              contact.phone,
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
                    ],
                  ),
                ),
                Icon(
                  Icons.more_vert_rounded,
                  color: Colors.white.withValues(alpha: 0.30),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
            const SizedBox(height: 12),

            // Toggle row
            Row(
              children: [
                Expanded(
                  child: _toggleRow(
                    icon: Icons.sos_rounded,
                    iconColor: const Color(0xFFFF6B6B),
                    label: 'SOS alerts',
                    value: contact.isNotifyOnSOS,
                    onChanged: onSOSToggle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _toggleRow(
                    icon: Icons.location_on_rounded,
                    iconColor: const Color(0xFF34D399),
                    label: 'Location',
                    value: contact.isShareLocation,
                    onChanged: onLocationToggle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: value
            ? iconColor.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: value
              ? iconColor.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: value ? iconColor : Colors.white30, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                color: value
                    ? Colors.white.withValues(alpha: 0.70)
                    : Colors.white.withValues(alpha: 0.30),
              ),
            ),
          ),
          Transform.scale(
            scale: 0.75,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: iconColor,
              activeTrackColor: iconColor.withValues(alpha: 0.22),
              inactiveThumbColor: Colors.white24,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary Banner ────────────────────────────────────────────────────────

class _SummaryBanner extends StatelessWidget {
  final int count;
  const _SummaryBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A73E8).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF1A73E8).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A73E8).withValues(alpha: 0.18),
            ),
            child: const Icon(
              Icons.people_alt_rounded,
              color: Color(0xFF4DA3FF),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count contact${count == 1 ? '' : 's'} added',
                  style: const TextStyle(
                    color: Color(0xFF4DA3FF),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'They will be alerted in an emergency',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.40),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tips Card ─────────────────────────────────────────────────────────────

class _TipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tips = [
      'Add at least 3 trusted contacts for best coverage.',
      'Enable SOS alerts for all primary contacts.',
      'Keep phone numbers up to date.',
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF162435).withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: const Color(0xFFFBBF24).withValues(alpha: 0.80),
                size: 16,
              ),
              const SizedBox(width: 7),
              Text(
                'Tips',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.60),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...tips.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '·  ',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.30),
                      fontSize: 13,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      t,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.40),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error State ───────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              color: Colors.white.withValues(alpha: 0.30),
              size: 40,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4DA3FF),
                side: const BorderSide(color: Color(0xFF4DA3FF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4DA3FF).withValues(alpha: 0.10),
                border: Border.all(
                  color: const Color(0xFF4DA3FF).withValues(alpha: 0.30),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.person_add_alt_1_rounded,
                color: Color(0xFF4DA3FF),
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No contacts yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add trusted people who will be notified in an emergency.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.40),
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 13,
                ),
              ),
              icon: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: const Text(
                'Add first contact',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────
