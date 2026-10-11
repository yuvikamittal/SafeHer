/// Central app state — a thin Riverpod layer over the existing singleton
/// services. Nothing here re-implements business logic; each provider simply
/// exposes a service's stream/method so every screen reads from ONE source of
/// truth instead of opening its own subscription.
///
/// Why this exists:
///   • Contacts were watched separately by the contacts screen AND fetched
///     one-off by the SOS screen → two sources that could drift.
///   • Auth state was resolved once at routing time → sign-out elsewhere
///     didn't propagate.
///   • Live location lived only inside live_location_screen → unreadable
///     by other screens.
///
/// Usage in a screen (convert StatefulWidget → ConsumerStatefulWidget, or a
/// StatelessWidget → ConsumerWidget):
///
///   final contactsAsync = ref.watch(contactsProvider);
///   contactsAsync.when(
///     data: (contacts) => ...,
///     loading: () => const CircularProgressIndicator(),
///     error: (e, _) => Text('$e'),
///   );
///
/// Existing screens keep working untouched; migrate them one at a time.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/emergency_contact.dart';
import '../models/mock_location.dart';
import '../models/safety_alert.dart';
import '../services/auth_service.dart';
import '../services/contacts_service.dart';
import '../services/location_service.dart';
import '../services/sos_service.dart';

// ── Services ────────────────────────────────────────────────────────────────
// Exposed as providers so tests can override them with fakes.

final authServiceProvider = Provider<AuthService>((ref) => AuthService.instance);

final contactsServiceProvider =
    Provider<ContactsService>((ref) => ContactsService.instance);

final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService.instance);

// ── Auth ────────────────────────────────────────────────────────────────────

/// Reactive auth state. Emits a new value on every sign-in / sign-out so the
/// whole app (router, dashboard, settings) stays consistent.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Convenience: the current user's uid, or null. Rebuilds only when the uid
/// itself changes (not on unrelated User field updates).
final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid;
});

/// Convenience: true while a user is signed in.
final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUidProvider) != null;
});

/// Live profile document (name, phone, address, dob, bloodGroup) for the
/// signed-in user. Powers the Profile screen.
final profileProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return const Stream<Map<String, dynamic>>.empty();
  return ref.watch(authServiceProvider).watchProfile();
});

// ── Emergency contacts ──────────────────────────────────────────────────────

/// The single live contacts list for the signed-in user. Both the contacts
/// screen and the SOS screen should read THIS instead of subscribing/fetching
/// on their own — that's what keeps them in sync.
///
/// Keyed on uid so switching accounts (sign out → sign in) tears down the old
/// subscription and starts a fresh one automatically.
final contactsProvider = StreamProvider<List<EmergencyContact>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return const Stream<List<EmergencyContact>>.empty();
  return ref.watch(contactsServiceProvider).watchContacts();
});

// ── Live location ───────────────────────────────────────────────────────────

/// One-shot current location (permission-gated). `.future` gives a Future the
/// UI can await; auto-refetch by invalidating this provider.
final currentLocationProvider = FutureProvider<MockLocation>((ref) {
  return ref.watch(locationServiceProvider).current();
});

/// Continuous live-location stream. Shared so any screen can display the
/// current position without spinning up its own geolocator subscription.
/// autoDispose so the GPS stream stops when nothing is watching it.
final liveLocationProvider = StreamProvider.autoDispose<MockLocation>((ref) {
  return ref.watch(locationServiceProvider).watch();
});

// ── SOS alerts ──────────────────────────────────────────────────────────────

final sosServiceProvider = Provider<SosService>((ref) => SosService.instance);

/// The signed-in user's own SOS alerts, newest first. Powers the Alerts tab.
final sosAlertsProvider = StreamProvider<List<SafetyAlert>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return const Stream<List<SafetyAlert>>.empty();
  return ref.watch(sosServiceProvider).watchMyAlerts();
});
