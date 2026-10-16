# MIGRATIONS_NEEDED.md (polish branch)

Nothing here has been run against production (`later-da778`). No deploy was made from this branch. Every
step was exercised on the local emulators only (rules tests, functions tests, the app against the emulators).

## 1. No data migration is needed

All new data is optional and read tolerantly:

| New data | Where | Missing / old documents |
|---|---|---|
| `unreadCounts {uid: n}`, `lastReadAt {uid: timestamp}` | `chats/{chatId}` | Read as 0 unread / never read. Old chats keep working (rules test "legacy chat"). Counts start from the first message sent by the new app. |
| Client-generated message ids | `chats/{chatId}/messages/{id}` | Old random ids are still read. |
| Settings document | `users/{uid}/settings/app` | Missing = defaults: every push on, preview on, sound on, no quiet hours, nothing muted. Same defaults on the client (`UserSettings`) and the server (`functions/lib/prefs.js`). |

Optional, cosmetic: existing chats have no `unreadCounts`, so their badges start at 0 rather than showing old
unread messages. A backfill could count messages newer than each member's last visit, but the app never
stored when someone last read a chat, so there is nothing reliable to count from. Not recommended.

## 2. Deployment order

| # | What | Command (run by the owner) | Why this order |
|---|---|---|---|
| 1 | Firestore rules | `firebase deploy --only firestore:rules` | The new app writes `unreadCounts` / `lastReadAt` on chats and `users/{uid}/settings/app`. The rules in production refuse both, so the new app's sends, read receipts and settings would fail. The new rules still accept every write of the current app (rules tests `legacy` cases, 45/45). Safe to deploy before the app. |
| 2 | Cloud Functions | `cd functions && npm ci && firebase deploy --only functions` | Adds `sendMessageNotification` (message pushes) and `cleanupDeletedAccount` (auth `onDelete`, v1). Updates follow/capsule pushes to honour the settings and the new Android channels. **Must be live before an app with "Delete account" ships**, otherwise a deleted account's data stays behind. `cleanupDeletedAccount` runs as `later-functions@later-da778.iam.gserviceaccount.com` like the other functions; it needs Firestore and Storage delete access (the account already has them for the existing functions). |
| 3 | App release | store / GitHub release of this branch | |

Old app versions after steps 1–2: the new functions name the channels `messages` / `activity` (and their
silent variants), which old versions never created. Android then uses the manifest's default channel
(`high_importance_channel`), so pushes still appear. Old versions also receive message pushes; tapping one
opens the app without going to the chat (they do not know the `message` type). Acceptable.

## 3. Behaviour changes worth announcing

- Message pushes are new: users will start receiving them after step 2. They can be turned off in
  Settings > Notifications, per chat with Mute, or with quiet hours.
- Deleting an account removes the user's chats for the other participant too (the partner no longer exists).
  See `functions/lib/account.js`.
