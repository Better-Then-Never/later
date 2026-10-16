'use strict';

const { onRequest } = require('firebase-functions/v2/https');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');
const notify = require('./lib/notify');

admin.initializeApp();

const services = () => ({
  db: admin.firestore(),
  messaging: admin.messaging(),
  bucket: admin.storage().bucket(),
});

// Name and avatar for the profile landing page (public/index.html).
exports.getUserData = onRequest({ cors: true }, async (req, res) => {
  if (req.method !== 'GET') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }
  try {
    const summary = await notify.profileSummary(services(), req.query.userId);
    if (!summary) {
      res.status(404).json({ displayName: 'Your friend', photoURL: null });
      return;
    }
    res.set('Cache-Control', 'public, max-age=300');
    res.json(summary);
  } catch (error) {
    logger.error('getUserData failed', error);
    res.status(500).json({ displayName: 'Your friend', photoURL: null });
  }
});

// Push for "started following you" notifications.
exports.sendFollowerNotification = onDocumentCreated(
  'users/{userId}/notifications/{notificationId}',
  async (event) => {
    try {
      const result = await notify.onNotificationCreated(
        services(),
        event.params.userId,
        event.data && event.data.data(),
      );
      if (result) logger.info('Follower notification', result);
    } catch (error) {
      logger.error('Follower notification failed', error);
    }
  },
);

// In-app notification + push to followers when a capsule is created.
exports.sendCapsuleNotification = onDocumentCreated(
  'capsules/{capsuleId}',
  async (event) => {
    try {
      const result = await notify.onCapsuleCreated(
        services(),
        event.params.capsuleId,
        event.data && event.data.data(),
      );
      logger.info('Capsule notification', result);
    } catch (error) {
      logger.error('Capsule notification failed', error);
    }
  },
);
