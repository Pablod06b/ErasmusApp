const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onRequest } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");
const { getMessaging } = require("firebase-admin/messaging");
const logger = require("firebase-functions/logger");

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

// ─── Moderation: alert on new report ───────────────────────────────────────────
// Trigger: reports/{reportId} created
// Acción actual: log estructurado + email/Slack (configurable).
// Para usar email/Slack: configura functions:secrets con MODERATION_WEBHOOK_URL.
exports.onReportCreated = onDocumentCreated(
  "reports/{reportId}",
  async (event) => {
    const report = event.data.data();
    if (!report) return;

    logger.info("Nuevo reporte recibido", {
      reportId: event.params.reportId,
      type: report.type ?? "unknown",
      targetId: report.targetId ?? null,
      reportedBy: report.reportedBy ?? null,
      reason: report.reason ?? null,
    });

    // (Opcional) enviar webhook a Slack/Discord si está configurado el secret.
    const webhookURL = process.env.MODERATION_WEBHOOK_URL;
    if (webhookURL) {
      try {
        const body = JSON.stringify({
          text: `:warning: Nuevo reporte (${report.type ?? "?"}). Target: ${report.targetId ?? "?"} · Por: ${report.reportedBy ?? "?"}`,
        });
        await fetch(webhookURL, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body,
        });
      } catch (err) {
        logger.error("Error enviando webhook de moderación:", err);
      }
    }

    // Mantener contador agregado en moderationStats/global para vista admin futura
    await db.doc("moderationStats/global").set(
      {
        totalReports: require("firebase-admin/firestore").FieldValue.increment(1),
        lastReportAt: new Date(),
      },
      { merge: true }
    );
  }
);

// ─── Delete user data: borra todos los datos del usuario antes de borrar la cuenta ─
// HTTP endpoint que requiere Authorization: Bearer <idToken>
// Llamado por DeleteAccountView. Borra perfil, posts, eventos, conversaciones,
// notificaciones, friend requests, favoritos, y fotos en Storage.
exports.deleteUserData = onRequest({ cors: true }, async (req, res) => {
  if (req.method !== "POST") {
    return res.status(405).send({ error: "Method not allowed" });
  }

  // 1. Validar token de Auth
  const authHeader = req.headers.authorization || "";
  const match = authHeader.match(/^Bearer (.+)$/);
  if (!match) {
    return res.status(401).send({ error: "Missing Authorization header" });
  }
  const idToken = match[1];
  let uid;
  try {
    const decoded = await getAuth().verifyIdToken(idToken);
    uid = decoded.uid;
  } catch (err) {
    return res.status(401).send({ error: "Invalid token" });
  }

  try {
    // 2. Borrar subcolecciones del usuario (notifications, friendRequests, sentRequests, favorites)
    const userRef = db.collection("users").doc(uid);
    for (const sub of ["notifications", "friendRequests", "sentRequests", "favorites"]) {
      const snap = await userRef.collection(sub).get();
      const batch = db.batch();
      snap.docs.forEach((doc) => batch.delete(doc.ref));
      if (!snap.empty) await batch.commit();
    }

    // 3. Borrar posts del usuario
    const postsSnap = await db.collection("posts").where("userId", "==", uid).get();
    const batchP = db.batch();
    postsSnap.docs.forEach((doc) => batchP.delete(doc.ref));
    if (!postsSnap.empty) await batchP.commit();

    // 4. Borrar eventos del usuario
    const eventsSnap = await db.collection("events").where("userId", "==", uid).get();
    const batchE = db.batch();
    eventsSnap.docs.forEach((doc) => batchE.delete(doc.ref));
    if (!eventsSnap.empty) await batchE.commit();

    // 5. Borrar conversaciones donde participa
    const convsSnap = await db
      .collection("conversations")
      .where("participants", "array-contains", uid)
      .get();
    for (const convDoc of convsSnap.docs) {
      // Borra mensajes
      const msgsSnap = await convDoc.ref.collection("messages").get();
      const batchM = db.batch();
      msgsSnap.docs.forEach((d) => batchM.delete(d.ref));
      if (!msgsSnap.empty) await batchM.commit();
      await convDoc.ref.delete();
    }

    // 6. Borrar perfil
    await userRef.delete();

    // 7. Borrar fotos en Storage (profile_images/{uid}.jpg y events/{uid}/* y chat/.../...uid...)
    const bucket = getStorage().bucket();
    try {
      await bucket.deleteFiles({ prefix: `profile_images/${uid}` });
      await bucket.deleteFiles({ prefix: `events/${uid}/` });
      // Para chat/{convId}/{uid}/ recorremos por conversación si quedaran ficheros huérfanos
    } catch (storageErr) {
      logger.warn("Storage cleanup parcial:", storageErr);
    }

    logger.info("Cuenta eliminada", { uid });
    return res.status(200).send({ ok: true });
  } catch (err) {
    logger.error("Error eliminando datos del usuario:", err);
    return res.status(500).send({ error: "Server error" });
  }
});
