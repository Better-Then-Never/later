// Chat housekeeping: a photo's file goes with its message.
'use strict';

/**
 * chats/{chatId}/messages/{id} was deleted (by its sender, "Clear history"
 * or account deletion): the photo it carried is deleted from Storage too, so
 * a deleted photo does not stay behind. Only files in that chat's folder are
 * touched (storage.rules: chats/{chatId}/{sender}/{id}.jpg).
 */
async function onMessageDeleted({ bucket }, chatId, message) {
  const path = message && message.type === 'image' ? message.imagePath : null;
  if (
    typeof path !== 'string' ||
    !path.startsWith(`chats/${chatId}/`) ||
    path.includes('..')
  ) {
    return null;
  }
  await bucket.file(path).delete({ ignoreNotFound: true });
  return { deleted: path };
}

module.exports = { onMessageDeleted };
