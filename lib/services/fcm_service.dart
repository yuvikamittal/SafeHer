/// Registers this device for push notifications and keeps its FCM token in
/// Firestore up to date, so the `onSosAlertCreated` Cloud Function
/// (functions/index.js) can look up a trusted contact's device by phone
/// number and push straight to it the moment an SOS alert is filed.
///
/// This is the client-side half of "Backend notification" in the SOS spec —
/// the Cloud Function is the half that actually sends the push.
///
/// ── Setup checklist ────────────────────────────────────────────────────────
/// 1. Add to pubspec.yaml (already added): firebase_messaging: ^15.1.3
/// 2. Call `FcmService.instance.init()` once after a user signs in (e.g. in
///    login_screen.dart / dashboard_screen.dart's initState) — it's a no-op
///    if already initialised, so it's safe to call again on app resume.
/// 3. Android — add to android/app/src/main/AndroidManifest.xml, inside
///    <manifest>:
///      <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
///    (Android 13+ also needs the runtime prompt, which
///    `FirebaseMessaging.requestPermission()` triggers automatically.)
/// 4. iOS — enable "Push Notifications" + "Background Modes → Remote
///    notifications" capabilities in Xcode, and upload your APNs auth key
///    in Firebase Console → Project Settings → Cloud Messaging.
/// 5. Web — two extra pieces beyond mobile:
///      a. `web/firebase-messaging-sw.js` must exist (already added) — the
///         web SDK auto-registers it, no manual `serviceWorker.register()`
///         call needed.
///      b. Generate a "Web Push certificate" in Firebase Console → Project
///         Settings → Cloud Messaging → Web configuration, and paste it into
///         `ApiKeys.fcmVapidKey` (lib/config/api_keys.dart). Without it,
///         `getToken()` throws on web and [init] fails silently (caught
///         below) rather than crashing the app.
///      Browsers also only grant the notification permission prompt in
///      response to a real user gesture (a button tap) — calling [init]
///      straight from a login button's `onPressed`, as this app does, is
///      the correct place for that reason.
/// 6. This writes the token to `users/{uid}.fcmToken` and
///    `users/{uid}.phone` (so the Cloud Function can match a contact's
///    phone number to a SafeHer account). Make sure users have a `phone`
///    field set — e.g. when they add/confirm their own number in
///    settings_screen.dart — otherwise the Cloud Function can't find them.
/// ───────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

import '../config/api_keys.dart';

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _initialised = false;

  /// Requests notification permission, grabs the current FCM token, saves it
  /// to Firestore against the signed-in user, and keeps it fresh if it
  /// rotates. Call once after sign-in.
  ///
  /// Never throws — a push-registration failure (e.g. a missing VAPID key
  /// on web, or a user who denies the permission prompt) should never block
  /// login or crash the app. SMS + the Firestore alert log still work
  /// without this.
  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Web needs the VAPID key from the Cloud Messaging web configuration;
      // mobile ignores this parameter entirely.
      final token = kIsWeb
          ? await _messaging.getToken(vapidKey: ApiKeys.fcmVapidKey)
          : await _messaging.getToken();

      if (token != null) await _saveToken(token);
      _messaging.onTokenRefresh.listen(_saveToken);
    } catch (e) {
      // Common causes: permission denied, no VAPID key configured yet on
      // web, or (rarely) no notification support on this browser/device.
      debugPrint('FcmService.init failed — push notifications disabled: $e');
      _initialised = false;
    }
  }

  Future<void> _saveToken(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }

  /// Clears this device's token on sign-out so it stops receiving pushes
  /// meant for the now-signed-out account.
  Future<void> clearToken() async {
    final uid = _auth.currentUser?.uid;
    _initialised = false;
    if (uid == null) return;
    await _db.collection('users').doc(uid).set(
      {'fcmToken': FieldValue.delete()},
      SetOptions(merge: true),
    );
  }
}
