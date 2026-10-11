/// A trusted contact that is notified during an emergency.
///
/// [id] is the Firestore document id (under
/// `users/{uid}/emergency_contacts/{id}`). It is `null` for a contact that
/// hasn't been saved yet (e.g. while a "new contact" form is open).
class EmergencyContact {
  String? id;
  final String name;
  final String relation;
  final String phone;
  bool isNotifyOnSOS;
  bool isShareLocation;

  EmergencyContact({
    this.id,
    required this.name,
    required this.relation,
    required this.phone,
    required this.isNotifyOnSOS,
    required this.isShareLocation,
  });

  /// Returns a copy with the given fields overridden. Handy for edits, since
  /// `name`/`relation`/`phone` are otherwise immutable.
  EmergencyContact copyWith({
    String? id,
    String? name,
    String? relation,
    String? phone,
    bool? isNotifyOnSOS,
    bool? isShareLocation,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      relation: relation ?? this.relation,
      phone: phone ?? this.phone,
      isNotifyOnSOS: isNotifyOnSOS ?? this.isNotifyOnSOS,
      isShareLocation: isShareLocation ?? this.isShareLocation,
    );
  }

  /// Field map written to Firestore. Deliberately excludes [id] (that's the
  /// document id, not a field) and any server-managed timestamp.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'relation': relation,
      'phone': phone,
      'isNotifyOnSOS': isNotifyOnSOS,
      'isShareLocation': isShareLocation,
    };
  }

  /// Builds a contact from a Firestore document id + its data map.
  factory EmergencyContact.fromMap(String id, Map<String, dynamic> map) {
    return EmergencyContact(
      id: id,
      name: (map['name'] as String?)?.trim() ?? '',
      relation: (map['relation'] as String?)?.trim() ?? 'Other',
      phone: (map['phone'] as String?)?.trim() ?? '',
      isNotifyOnSOS: map['isNotifyOnSOS'] as bool? ?? true,
      isShareLocation: map['isShareLocation'] as bool? ?? false,
    );
  }
}
