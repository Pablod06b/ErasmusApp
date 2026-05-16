const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();

// ─── Send push notification when a new notification document is created ───────
// Triggers on: users/{userId}/notifications/{notificationId}
exports.sendPushOnNotification = onDocumentCreated(
  "users/{userId}/notifications/{notificationId}",
  async (event) => {
    const notif = event.data.data();
    const userId = event.params.userId;

    if (!notif) return;

    // Get the recipient's FCM token
    const userSnap = await db.collection("users").doc(userId).get();
    const fcmToken = userSnap.data()?.fcmToken;
    if (!fcmToken) return;

    // Map notification type to a friendly body (icon is used as rawValue)
    const title = notif.title ?? "Nueva notificación";
    const body = notif.message ?? "";

    const message = {
      token: fcmToken,
      notification: { title, body },
      apns: {
        payload: {
          aps: {
            badge: 1,
            sound: "default",
            "mutable-content": 1,
          },
        },
      },
      data: {
        type: notif.type ?? "",
        relatedItemId: notif.relatedItemId ?? "",
        fromUserId: notif.fromUserId ?? "",
        notificationId: event.params.notificationId,
      },
    };

    try {
      await getMessaging().send(message);
    } catch (err) {
      // Token expired or invalid – clean it up so we don't retry
      if (
        err.code === "messaging/registration-token-not-registered" ||
        err.code === "messaging/invalid-registration-token"
      ) {
        await db.collection("users").doc(userId).update({ fcmToken: null });
      }
      console.error("FCM send error:", err);
    }
  }
);

// ─── Badge reset: clear badge when all notifications are marked read ──────────
exports.clearBadgeOnAllRead = onDocumentCreated(
  "users/{userId}/notifications/{notificationId}",
  async (event) => {
    // Handled client-side; this is a no-op placeholder for future badge management
  }
);
