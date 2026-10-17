# FEATURES_B.md: Part B, feature by feature

Every feature here was built on the Part A foundation (MOTION_CATALOG.md rules, tokens, five languages). Status:
**ON** (shipped in the build), **FLAGGED** (built, off in `lib/core/config/feature_flags.dart`), **NOT BUILT**.
"Phone" means checked on the reference phone (DEVICE.md) against the emulators; everything else is tests only.
Server changes are in BACKEND_CHANGES.md; none is deployed.

## B1. Chat

### Photo messages: ON
- **What**: a camera button in the message field offers the gallery or the camera; a card shows the photo with a
  caption field and Send (it stays between the status bar and the keyboard). The photo appears at once in its
  bubble, in its own proportions, with a turning ring while it uploads; then the time and "Sent". Tapping it opens
  the full-screen viewer (hero). The chat list says "📷 Photo"; a reply quotes "📷 Photo" or "📷 caption"; the
  menu has no "Copy" for a photo without a caption; deleting removes the file too.
- **How**: resized on the phone to ≤ 1600 px JPEG off the UI isolate (`ImageProcessor.chatJpegFromFile`),
  uploaded to `chats/{chat}/{sender}/{messageId}.jpg`, then the message (type `image`, URL, path, width, height)
  in the same transaction as text messages. The uploaded bytes go into the image cache under their URL, and the
  bubble keeps showing the phone's file after the server confirms, so the sender never downloads or reloads it.
  A failed upload is retried with the message; a failed send after a good upload sends without uploading again;
  an upload whose answer was lost is reused (the rules refuse replacing a sent photo).
- **Older app versions** show the caption, or "📷".
- **Tests**: `messages_test.dart` ("Photo messages", "ChatController photos": shown at once, upload once, retry,
  quote, delete with file), `photo_message_test.dart` (shape, caption, ring, tap, the card above a keyboard),
  rules (photo messages, the Storage folder), functions (`chats.test.js`, photo pushes).
- **Phone** (Russian, light): photo button, menu, system camera, the card (with and without the keyboard), a photo
  with a caption and one without sent through the emulators' rules and Storage, the viewer, the chat list preview,
  delete (the cleanup function ran in the emulator).
- **Not done**: no gallery multi-select or albums; no upload progress percentage (a ring only); a photo that
  uploaded but whose message was then deleted while "not sent" leaves its file (rare; no message exists for the
  server cleanup to follow); pushes could not be delivered (no dev project).
