# ADMIN.md: owner-only tools

Everything here runs against the **local emulators by default**. A real project is only touched when the command
gets `--project <id> --production` and the machine has Google credentials
(`gcloud auth application-default login` with an account that can administer the project).

Setup once: `cd tools/admin && npm install`. Self-test (throwaway emulators): `npm run selftest`.

## Make someone an admin (needed to send announcements)
```
node set-admin.js owner@example.com --project later-da778 --production
node set-admin.js owner@example.com --revoke --project later-da778 --production
```
Sets the `admin` custom claim. The person must sign out and in again (or wait up to an hour) before the claim is in
their token. Normal users cannot get it: only the Admin SDK sets claims.

## Verified badges
```
node set-verified.js --dry-run --project later-da778 --production     # shows which usernames exist
node set-verified.js --project later-da778 --production                # usernames from verified_users.json
node set-verified.js temka_ink --revoke --project later-da778 --production
```
`verified_users.json` lists `temka_ink`, `m9` and `amob3`. The last was dictated as "amo b3"; check the dry run's
"not found" list and fix the spelling (BLOCKERS.md). The badge is `users/{uid}.verified`; the security rules refuse
any client write to it (rules test "counters, stats and the verified badge are server-only").

## Announcements ("News and updates")
Two ways, same code (`functions/lib/broadcast.js`):

1. From a script:
   ```
   node announce.js message.json --project later-da778 --production
   ```
   with `message.json`:
   ```json
   {
     "title": { "en": "New in Later", "ru": "Новое в Later", "de": "Neu in Later" },
     "body":  { "en": "Loop capsules are here!" },
     "languages": ["en", "ru", "de"],
     "platform": "android"
   }
   ```
   `title.en` and `body.en` are required; missing languages fall back to English; `languages` and `platform` are
   optional filters.
2. From an admin client: the callable function `sendAnnouncement` with the same data. It refuses every caller
   without the `admin` claim (functions test "a normal user (or nobody) cannot send one").

Each announcement is stored in `announcements/{id}` (shown in the app's notifications tab) and sent as **one push
per language topic** (`news_<lang>`, optionally combined with `platform_android` / `platform_ios`). The app
subscribes to its language's topic while "News and updates" is on. Cost does not grow with the number of users.

## Reports
User reports land in `reports/{id}` (reporter, target path, reason, details, time). The app cannot read them;
review them in the Firebase console (Firestore > reports) and act with the console or a script.
