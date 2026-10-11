const { onRequest } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const nodemailer = require("nodemailer");

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

// Server-side key — NOT exposed to client. Restrict this key in Cloud
// Console to "IP addresses" = none (server key), APIs = Directions + Places.
const SERVER_KEY = process.env.MAPS_SERVER_KEY || "PASTE_SERVER_KEY_HERE";

function setCors(res) {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");
}

exports.directionsProxy = onRequest(async (req, res) => {
  setCors(res);
  if (req.method === "OPTIONS") return res.status(204).send("");

  const { origin, destination, mode = "walking", alternatives = "true" } = req.query;
  if (!origin || !destination) {
    return res.status(400).json({ status: "INVALID_REQUEST", error_message: "origin/destination required" });
  }

  const url = new URL("https://maps.googleapis.com/maps/api/directions/json");
  url.searchParams.set("origin", origin);
  url.searchParams.set("destination", destination);
  url.searchParams.set("mode", mode);
  url.searchParams.set("alternatives", alternatives);
  url.searchParams.set("key", SERVER_KEY);

  try {
    const r = await fetch(url.toString());
    const data = await r.json();
    res.status(200).json(data);
  } catch (e) {
    res.status(502).json({ status: "PROXY_ERROR", error_message: String(e) });
  }
});

/**
 * Fires the moment a client writes a new document to `sos_alerts`
 * (SosService.dispatchAlert in the Flutter app). Looks up each listed
 * contact's SafeHer account by phone number, collects their FCM tokens, and
 * pushes a high-priority notification to all of them simultaneously — this
 * is the "backend notification" leg of the SOS flow and runs independent of
 * whether the on-device SMS send in the app succeeded.
 */
exports.onSosAlertCreated = onDocumentCreated(
  "sos_alerts/{alertId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const alert = snap.data();
    const contacts = Array.isArray(alert.contacts) ? alert.contacts : [];
    if (contacts.length === 0) return;

    // Match each contact's phone number to a SafeHer user account so we
    // know where to push. Contacts who aren't SafeHer users simply won't
    // have a token — they were already reached via SMS on-device.
    const phones = contacts.map((c) => c.phone).filter(Boolean);
    const tokens = [];
    for (const phone of phones) {
      const usersSnap = await db
        .collection("users")
        .where("phone", "==", phone)
        .limit(1)
        .get();
      usersSnap.forEach((doc) => {
        const token = doc.data().fcmToken;
        if (token) tokens.push(token);
      });
    }

    if (tokens.length === 0) {
      await snap.ref.update({ pushStatus: "no_recipients" });
      return;
    }

    const locationLabel = alert.location?.label || "an unknown location";
    const senderName = alert.userEmail || "A trusted contact";

    const response = await messaging.sendEachForMulticast({
      tokens,
      notification: {
        title: "🚨 SOS Alert",
        body: `${senderName} needs help now — last known location: ${locationLabel}.`,
      },
      data: {
        type: "sos_alert",
        alertId: event.params.alertId,
        lat: String(alert.location?.geopoint?.latitude ?? ""),
        lng: String(alert.location?.geopoint?.longitude ?? ""),
      },
      android: { priority: "high" },
      apns: { headers: { "apns-priority": "10" } },
    });

    await snap.ref.update({
      pushStatus: "sent",
      pushSuccessCount: response.successCount,
      pushFailureCount: response.failureCount,
    });
  }
);

exports.placesProxy = onRequest(async (req, res) => {
  setCors(res);
  if (req.method === "OPTIONS") return res.status(204).send("");

  const { path, ...params } = req.query;
  // path: "nearbysearch/json" or "details/json"
  if (!path) {
    return res.status(400).json({ status: "INVALID_REQUEST", error_message: "path required" });
  }

  const url = new URL(`https://maps.googleapis.com/maps/api/place/${path}`);
  for (const [k, v] of Object.entries(params)) url.searchParams.set(k, v);
  url.searchParams.set("key", SERVER_KEY);

  try {
    const r = await fetch(url.toString());
    const data = await r.json();
    res.status(200).json(data);
  } catch (e) {
    res.status(502).json({ status: "PROXY_ERROR", error_message: String(e) });
  }
});

// ── Access-request email notifier ───────────────────────────────────────────
// Deploy secrets first:
//   firebase functions:secrets:set GMAIL_USER
//   firebase functions:secrets:set GMAIL_APP_PASSWORD
//   firebase functions:secrets:set ADMIN_EMAIL
// GMAIL_APP_PASSWORD = a Google App Password (myaccount.google.com/apppasswords),
// NOT your normal Gmail password.
exports.onAccessRequestCreated = onDocumentCreated(
  {
    document: "access_requests/{docId}",
    secrets: ["GMAIL_USER", "GMAIL_APP_PASSWORD", "ADMIN_EMAIL"],
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const r = snap.data();

    const gmailUser = process.env.GMAIL_USER || "";
    const gmailPass = process.env.GMAIL_APP_PASSWORD || "";
    const adminEmail = process.env.ADMIN_EMAIL || gmailUser;

    if (!gmailUser || !gmailPass) {
      await snap.ref.update({ notifyStatus: "skipped_no_smtp" });
      return;
    }

    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: { user: gmailUser, pass: gmailPass },
    });

    try {
      await transporter.sendMail({
        from: `"SafeHer" <${gmailUser}>`,
        to: adminEmail,
        subject: `New SafeHer access request — ${r.name || "Unknown"}`,
        text:
          `A new access request was submitted.\n\n` +
          `Name: ${r.name || "-"}\n` +
          `Email: ${r.email || "-"}\n` +
          `Phone: ${r.phone || "-"}\n` +
          `Emergency contact: ${r.emergencyContact || "-"}\n` +
          `Status: ${r.status || "pending"}\n` +
          `Request ID: ${event.params.docId}\n`,
      });
      await snap.ref.update({ notifyStatus: "emailed" });
    } catch (e) {
      await snap.ref.update({
        notifyStatus: "email_failed",
        notifyError: String(e),
      });
    }
  }
);
