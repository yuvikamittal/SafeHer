/// Firestore-backed persistence for a user's emergency contacts.
///
/// Contacts live at `users/{uid}/emergency_contacts/{contactId}`, matching
/// the per-user document layout already used by AuthService (which creates
/// `users/{uid}` on signup) and SosService (which reads/writes under the
/// same `users` collection tree conceptually via `uid`).
///
/// ── Setup checklist ─────────────────────────────────────────────────────
/// 1. No new packages needed — this reuses `cloud_firestore` and
///    `firebase_auth`, already in pubspec.yaml.
/// 2. Firestore security rules should scope reads/writes to the owner:
///      match /users/{uid}/emergency_contacts/{contactId} {
///        allow read, write: if request.auth != null
///                           && request.auth.uid == uid;
///      }
/// ─────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/emergency_contact.dart';

class ContactsService {
  ContactsService._();
  static final ContactsService instance = ContactsService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// The `users/{uid}/emergency_contacts` collection for the signed-in user.
  /// Throws if nobody is signed in — every call site is already behind the
  /// auth gate (contacts screen / SOS screen are only reachable post-login).
  CollectionReference<Map<String, dynamic>> get _collection {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('No signed-in user — cannot access emergency contacts.');
    }
    return _db
        .collection('users')
        .doc(uid)
        .collection('emergency_contacts');
  }

  // ── Read ─────────────────────────────────────────────────────────────────

  /// Live stream of the signed-in user's contacts, ordered by creation time.
  /// Use this to keep a screen's list in sync as Firestore changes (e.g.
  /// from another device, or right after a local add/edit/delete).
  Stream<List<EmergencyContact>> watchContacts() {
    if (_auth.currentUser == null) {
      return const Stream<List<EmergencyContact>>.empty();
    }
    return _collection.orderBy('createdAt').snapshots().map(
          (snap) => snap.docs
              .map((d) => EmergencyContact.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  /// One-time fetch of the signed-in user's contacts — used on app/screen
  /// load (e.g. the SOS screen grabbing the list once before a dispatch)
  /// where a live subscription isn't needed.
  Future<List<EmergencyContact>> fetchContacts() async {
    final snap = await _collection.orderBy('createdAt').get();
    return snap.docs
        .map((d) => EmergencyContact.fromMap(d.id, d.data()))
        .toList();
  }

  // ── Write ────────────────────────────────────────────────────────────────

  /// Adds a new contact and returns the generated Firestore document id.
  Future<String> addContact(EmergencyContact contact) async {
    final docRef = await _collection.add({
      ...contact.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Overwrites the fields of an existing contact. [contact.id] must be set
  /// (i.e. this contact was previously loaded from or added to Firestore).
  Future<void> updateContact(EmergencyContact contact) async {
    final id = contact.id;
    if (id == null) {
      throw Exception('Cannot update a contact with no Firestore id.');
    }
    await _collection.doc(id).update(contact.toMap());
  }

  /// Deletes the contact document with the given id.
  Future<void> deleteContact(String id) async {
    await _collection.doc(id).delete();
  }
}
