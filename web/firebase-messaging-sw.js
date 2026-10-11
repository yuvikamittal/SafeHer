// FCM background service worker for the web build.
//
// firebase_messaging's web implementation looks for this exact file at
// web/firebase-messaging-sw.js and registers it automatically — no manual
// registration call needed from Dart. It's what lets an SOS push notification
// show up even when the SafeHer web tab isn't focused (or is closed).
//
// The config below is intentionally the same public Firebase Web SDK values
// already committed in lib/firebase_options.dart (DefaultFirebaseOptions.web)
// — these are safe to ship client-side; they identify the project, they
// aren't secrets.

importScripts('https://www.gstatic.com/firebasejs/10.13.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'YOUR_GOOGLE_MAPS_API_KEY',
  appId: '1:694207000959:web:206d0a7fbba10e9d086a4a',
  messagingSenderId: '694207000959',
  projectId: 'safeher-app-49e64',
  authDomain: 'safeher-app-49e64.firebaseapp.com',
  storageBucket: 'safeher-app-49e64.firebasestorage.app',
});

const messaging = firebase.messaging();

// Optional: customize how a background SOS push looks as a browser
// notification. The onSosAlertCreated Cloud Function already sends a
// `notification` payload (title/body), so Firebase will auto-display it;
// this hook is only needed if you want to override that default rendering.
messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title || '🚨 SOS Alert';
  const options = {
    body: payload.notification?.body || 'A trusted contact needs help.',
    icon: '/icons/Icon-192.png',
    data: payload.data,
  };
  self.registration.showNotification(title, options);
});
