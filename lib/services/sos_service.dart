/// Real emergency-dispatch service backed by SMS, a phone dialer intent,
/// and Firestore (which fans out push notifications via a Cloud Function).
///
/// Replaces the previous mock that just did `Future.delayed`. A single call
/// to [dispatchAlert] now does four things:
///
///   1. Grabs the device's current GPS fix (best-effort — a location
///      failure must never block the alert from going out).
///   2. Writes a server-side SOS log to Firestore FIRST, so there's a
///      durable record even if the device loses connectivity or the app
///      is killed mid-alert. This write is also what triggers the
///      `onSosAlertCreated` Cloud Function (see functions/index.js), which
///      pushes an FCM notification to every trusted contact who has the
///      SafeHer app installed — all of them, simultaneously, independent
///      of whether the SMS below succeeds.
///   3. Texts every contact with `isNotifyOnSOS == true` with a message +
///      Google Maps link, using the `telephony` package for a silent,
///      no-tap send on Android.
///   4. Leaves a one-tap "Call 112" action available via [callEmergencyServices].
///
/// ── Setup checklist ────────────────────────────────────────────────────────
/// 1. Add to pubspec.yaml (already added):
///      telephony: ^0.2.0
///      url_launcher: ^6.3.1
///      firebase_messaging: ^15.1.3
/// 2. Android — add to android/app/src/main/AndroidManifest.xml, inside
///    <manifest> (above <application>):
///      <uses-permission android:name="android.permission.SEND_SMS"/>
///      <uses-permission android:name="android.permission.READ_PHONE_STATE"/>
///    and inside <queries>:
///      <intent><action android:name="android.intent.action.DIAL"/></intent>
///      <intent><action android:name="android.intent.action.SENDTO"/>
///        <data android:scheme="sms"/></intent>
///    NOTE (Play Store policy): SEND_SMS is a "restricted permission." Google
///    approves it for apps whose *core* function is sending messages on the
///    user's behalf without additional interaction — a personal-safety SOS
///    feature like this one is an accepted core use case, but you must
///    declare it in the Play Console's Permissions Declaration Form before
///    release. If you'd rather avoid that review step, set
///    `SosService.instance.silentSmsEnabled = false` to always fall back to
///    the `sms:` composer intent below (one extra tap, no special permission).
/// 3. iOS does not allow programmatic SMS sending at all (Apple sandbox
///    restriction) — on iOS, [dispatchAlert] automatically uses the native
///    Messages composer (pre-filled, user taps send) via `url_launcher`.
///    Add to ios/Runner/Info.plist:
///      <key>LSApplicationQueriesSchemes</key>
///      <array><string>tel</string><string>sms</string></array>
/// 4. Deploy the Cloud Function in functions/index.js:
///      cd functions && npm install && firebase deploy --only functions
/// 5. Firestore security rules should allow an authenticated user to create
///    (but not overwrite others') documents in `sos_alerts`:
///      match /sos_alerts/{id} {
///        allow create: if request.auth != null
///                       && request.resource.data.uid == request.auth.uid;
///        allow read, update: if request.auth != null
///                       && resource.data.uid == request.auth.uid;
///      }
/// ───────────────────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:telephony/telephony.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/emergency_contact.dart';
import '../models/mock_location.dart';
import '../models/safety_alert.dart';
import 'location_service.dart';

/// Per-contact outcome of the SMS fan-out, surfaced to the UI so it can show
/// which contacts were actually reached.
enum SmsDispatchStatus {
  sent,
  composerOpened,
  failed,

  /// Browsers can't send or reliably compose SMS at all — this is reported
  /// instead of silently attempting (and failing) a launchUrl call, so the
  /// UI can tell the person "install the app" rather than implying a retry
  /// might work.
  unsupportedOnWeb,
}

class SmsDispatchOutcome {
  final EmergencyContact contact;
  final SmsDispatchStatus status;
  const SmsDispatchOutcome(this.contact, this.status);
}

/// Everything the UI needs to render the "alert sent" state.
class SosDispatchResult {
  final String alertId;
  final MockLocation? location;
  final List<SmsDispatchOutcome> smsOutcomes;
  const SosDispatchResult({
    required this.alertId,
    required this.location,
    required this.smsOutcomes,
  });

  int get contactsReached => smsOutcomes
      .where((o) =>
          o.status == SmsDispatchStatus.sent ||
          o.status == SmsDispatchStatus.composerOpened)
      .length;
}

class SosService {
  SosService._();
  static final SosService instance = SosService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Telephony _telephony = Telephony.instance;

  /// Live stream of the signed-in user's own SOS alerts, newest first.
  /// Powers the Alerts tab. Requires the Firestore rule allowing an owner to
  /// read their own `sos_alerts` documents.
  Stream<List<SafetyAlert>> watchMyAlerts() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream<List<SafetyAlert>>.empty();
    return _db
        .collection('sos_alerts')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => SafetyAlert.fromSos(d.data())).toList());
  }

  /// Number of trusted contacts that would be notified on dispatch — kept
  /// for backwards compatibility with any UI still reading a static count.
  static const int notifiedContacts = 3;

  /// Set to `false` to always use the tap-to-send SMS composer instead of
  /// silent background sending (see setup note #2 above).
  bool silentSmsEnabled = true;

  // ── Public API ─────────────────────────────────────────────────────────

  /// Dispatches a full SOS alert to [contacts] (only those with
  /// `isNotifyOnSOS == true` are texted). Returns once the Firestore log is
  /// written and the SMS fan-out has been attempted; the FCM push to
  /// contacts' devices happens asynchronously server-side and is not
  /// awaited here.
  Future<SosDispatchResult> dispatchAlert({
    required List<EmergencyContact> contacts,
  }) async {
    // 1. Best-effort location — never let a GPS failure block the alert.
    MockLocation? location;
    try {
      location = await LocationService.instance.current();
    } catch (_) {
      location = null;
    }

    final mapsLink = location != null
        ? 'https://maps.google.com/?q=${location.lat},${location.lng}'
        : null;
    final message = _buildMessage(mapsLink);

    final notifyList = contacts.where((c) => c.isNotifyOnSOS).toList();

    // 2. Server-side log FIRST — durable record even if the device goes
    // offline mid-alert, and the trigger for the FCM fan-out Cloud Function.
    final docRef = await _logToFirestore(
      contacts: notifyList,
      location: location,
      message: message,
    );

    // 3. SMS fan-out to trusted contacts.
    final outcomes = await _sendSms(contacts: notifyList, message: message);

    // Best-effort status patch so the Firestore record reflects what
    // actually happened with the SMS leg (the Cloud Function doesn't need
    // this, but a support/admin dashboard reading sos_alerts will).
    unawaited(_updateSmsStatus(docRef, outcomes));

    return SosDispatchResult(
      alertId: docRef.id,
      location: location,
      smsOutcomes: outcomes,
    );
  }

  /// Opens the phone dialer pre-filled with [number] (defaults to India's
  /// emergency number, 112). Uses `tel:` so the user still taps "Call" —
  /// placing a call with zero interaction would need the CALL_PHONE
  /// permission, which Google reserves for default dialer/assistant apps.
  Future<void> callEmergencyServices({String number = '112'}) async {
    if (kIsWeb) {
      // Desktop browsers have no dialer to hand off to, and mobile-browser
      // support for `tel:` is inconsistent — rather than pretend this
      // worked, tell the caller plainly so the UI can show real guidance.
      throw Exception(
        "Calling isn't available from a browser. Please dial $number "
        'directly from your phone.',
      );
    }
    final uri = Uri(scheme: 'tel', path: number);
    final launched = await launchUrl(uri);
    if (!launched) {
      throw Exception('Could not open the phone dialer.');
    }
  }

  /// Texts [contacts] with the SOS message + maps link without writing a
  /// new Firestore alert log — used by the SOS screen's standalone "Send
  /// SMS" quick action, as opposed to the full [dispatchAlert] flow.
  Future<List<SmsDispatchOutcome>> sendSmsToContacts(
    List<EmergencyContact> contacts,
  ) async {
    MockLocation? location;
    try {
      location = await LocationService.instance.current();
    } catch (_) {
      location = null;
    }
    final mapsLink = location != null
        ? 'https://maps.google.com/?q=${location.lat},${location.lng}'
        : null;
    return _sendSms(
      contacts: contacts.where((c) => c.isNotifyOnSOS).toList(),
      message: _buildMessage(mapsLink),
    );
  }

  /// Marks an active alert as resolved/cancelled (e.g. from the "Cancel
  /// Alert" button) so the Firestore record — and anyone watching it on a
  /// dashboard — reflects that the emergency ended.
  Future<void> markAlertResolved(String alertId, {required String status}) {
    return _db.collection('sos_alerts').doc(alertId).update({
      'status': status,
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── SMS fan-out ────────────────────────────────────────────────────────

  Future<List<SmsDispatchOutcome>> _sendSms({
    required List<EmergencyContact> contacts,
    required String message,
  }) async {
    final outcomes = <SmsDispatchOutcome>[];
    if (contacts.isEmpty) return outcomes;

    if (kIsWeb) {
      // No silent path (no telephony radio) and no reliable composer
      // handoff (most desktop browsers have nothing registered for
      // `sms:`) — be honest about it rather than reporting a false
      // "sent"/"failed" for something that was never really attempted.
      return contacts
          .map((c) => SmsDispatchOutcome(c, SmsDispatchStatus.unsupportedOnWeb))
          .toList();
    }

    final canSendSilently = Platform.isAndroid && silentSmsEnabled;

    bool permissionGranted = false;
    if (canSendSilently) {
      permissionGranted =
          await _telephony.requestPhoneAndSmsPermissions ?? false;
    }

    for (final contact in contacts) {
      final phone = contact.phone.trim();
      if (phone.isEmpty) {
        outcomes.add(SmsDispatchOutcome(contact, SmsDispatchStatus.failed));
        continue;
      }

      if (canSendSilently && permissionGranted) {
        try {
          await _telephony.sendSms(to: phone, message: message);
          outcomes.add(SmsDispatchOutcome(contact, SmsDispatchStatus.sent));
          continue;
        } catch (_) {
          // Fall through to the composer below rather than dropping the
          // contact entirely.
        }
      }

      // iOS, silent sending disabled, or permission denied: open the native
      // SMS composer pre-filled with the message. The user only has to tap
      // "Send" once — no extra typing.
      try {
        final uri = Uri(
          scheme: 'sms',
          path: phone,
          queryParameters: {'body': message},
        );
        final opened = await launchUrl(uri);
        outcomes.add(
          SmsDispatchOutcome(
            contact,
            opened
                ? SmsDispatchStatus.composerOpened
                : SmsDispatchStatus.failed,
          ),
        );
      } catch (_) {
        outcomes.add(SmsDispatchOutcome(contact, SmsDispatchStatus.failed));
      }
    }

    return outcomes;
  }

  // ── Firestore log ─────────────────────────────────────────────────────

  Future<DocumentReference<Map<String, dynamic>>> _logToFirestore({
    required List<EmergencyContact> contacts,
    required MockLocation? location,
    required String message,
  }) {
    final user = _auth.currentUser;
    return _db.collection('sos_alerts').add({
      'uid': user?.uid,
      'userEmail': user?.email,
      'status': 'active', // 'active' | 'resolved' | 'cancelled'
      'createdAt': FieldValue.serverTimestamp(),
      'message': message,
      'location': location == null
          ? null
          : {
              'geopoint': GeoPoint(location.lat, location.lng),
              'label': location.label,
              'accuracy': location.accuracy,
            },
      'contacts': contacts
          .map((c) => {
                'name': c.name,
                'phone': c.phone,
                'relation': c.relation,
              })
          .toList(),
      // Populated once the SMS leg finishes — see _updateSmsStatus.
      'smsStatus': null,
    });
  }

  Future<void> _updateSmsStatus(
    DocumentReference<Map<String, dynamic>> docRef,
    List<SmsDispatchOutcome> outcomes,
  ) async {
    try {
      await docRef.update({
        'smsStatus': {
          for (final o in outcomes) o.contact.phone: o.status.name,
        },
      });
    } catch (_) {
      // Non-fatal — the alert log already exists without this detail.
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  String _buildMessage(String? mapsLink) {
    final buffer = StringBuffer(
      '🚨 SOS ALERT — I need help right now. This is an automated message '
      'from SafeHer.',
    );
    if (mapsLink != null) {
      buffer.write(' My live location: $mapsLink');
    } else {
      buffer.write(' My location could not be determined.');
    }
    return buffer.toString();
  }
}

/// Fires-and-forgets a future while making the "don't await this" intent
/// explicit at the call site.
void unawaited(Future<void> future) {
  future.catchError((_) {});
}
