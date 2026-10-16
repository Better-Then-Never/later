# PROGRESS.md — running log (resume from here)

Branch: `feature/polish-motion-messages-settings` (from main 5b30770). Plan: POLISH_PLAN.md.

## How to run things (emulator only)
- Firebase emulators: `firebase emulators:start --project later-da778 --only auth,firestore,storage`
  (needs `JAVA_HOME=C:\Program Files\Android\Android Studio\jbr`). If a port is taken, an orphaned
  `cloud-firestore-emulator` java process is still alive: stop it first.
- Seed: `cd tools/emulator && npm run seed` (accounts alice/bob/carol/dave/erin/frank @later.test, password
  `TEST_ACCOUNT_PASSWORD` or the emulator-only default in seed.js).
- App: `flutter run -d emulator-5554 --dart-define=USE_FIREBASE_EMULATOR=true`.
- Rules tests: `cd tools/rules-tests && npm run emulate`. Functions tests: `cd functions && npm test` (emulators).

## Log
- **Phase 1 (orientation)**: baseline gates clean (format, analyze 0, 108 tests). Plan written.
- **Phase 1 (baseline)**: 35 screenshots + 3 recordings in `baseline/` (emulator, local Firebase, seeded data,
  signed in as alice). Found on the way: POL-001 (startup ANR, fixed 5afdcc1), POL-002 (account without
  profile document: "Unknown User"/"Loading..." forever, open), POL-003 (sign-out could hang forever, fixed
  d589934). Design deviations noted for Phase 2: chat screens use Material icons (close, chevron, search,
  camera), plain grey rows instead of the white-card user rows, raw greys; the permissions page has a
  hand-built header unlike every other page; the five settings stubs have no header, a Material button and
  placeholder copy; the capsule card shows a bare Material broken-image icon.
- **Phase 2 (design consistency)** 6328299, 4ae16a4: neutral colour tokens + codemod (217 raw colours, 37 font
  literals); `tool/check_design_tokens.dart` + allowlist, run in `pr-build.yml` with format/analyze/test;
  DESIGN_DECISIONS.md, ICONS.md (58 accessors, all used).
- **Phase 3 (motion)** cf63271: `AppMotion` tokens, every animation converted, one 150 ms page fade for all
  routes (camera/signup no longer use the platform zoom), `AppPressable` on shared buttons + navbar,
  `AppFadeSwitcher`, `AppEnter`, reduce-motion support; 4 widget tests.
- **Next: Phase 4 (messages)**. Data: `unreadCounts` and `lastReadAt` maps on the chat document (one write to
  read a chat instead of one per message), client-generated message ids for an optimistic outbox
  (sending/failed/retry), reverse list + growing `limitToLast` window for older messages. UI: white-card rows
  like My friends, unread badges (tab + rows), custom icons only, "Sent/Read/Not sent" text receipts.
- **Phase 4 (messages)** 68f6c71: unread counts + one-write receipts (rules + 2 rules tests, 43 total), optimistic
  outbox with retry (no duplicates), paging, full redesign with shared components/tokens/custom icons, tab badge,
  CountBadge, AppNetworkImage. Verified on the emulator: list → chat clears both badges (rules accept the read
  write), send → "Sent", friend reads → "Read", offline send → "Not sent · Tap to retry", retry online → delivered
  once. Note: running `tools/rules-tests` (`npm run emulate`) stops the dev emulators; restart them afterwards.
- **Next: Phase 5+6 together** (settings data first, then a settings-aware sender, then the settings UI).
- **Phase 5+6 (notifications + settings)** d58b01a … 3d4cc45:
  - Server: `functions/lib/prefs.js` reads `users/{uid}/settings/app` (defaults when missing or malformed);
    follow/capsule pushes honour it; new `sendMessageNotification` (mute, categories, quiet hours in local time,
    preview, silent channels, one notification per chat); new `cleanupDeletedAccount` (auth `onDelete`).
    Functions tests 23/23. On the Functions emulator (`demo-later` project, so nothing real is reachable) both
    triggers ran: deleting an Auth user removed its profile, settings, username, chats and friend links.
  - Rules: owner-only, validated settings document; rules tests 45/45.
  - Client: `SettingsStore` (optimistic, rollback, keeps the quiet-hours UTC offset in sync), muted chats feed the
    unread badge, Mute/Unmute in the chat menu; push channels per kind, message pushes open the chat, no
    foreground notification for the chat on screen, opening a chat clears its notification.
  - Settings, all real: email (confirmation link) and password with re-auth, notifications, blocked users,
    permissions (shared header now), map and camera, data and storage (cache size, clear), help, about
    (version, licenses), customize profile, delete account. Language/App appearance removed (D-07).
  - Verified on the emulator: notification switches write the document and the rules accept it; a wrong current
    password is refused ("Wrong password."), the right one changes it (checked against the Auth emulator) and back;
    account deletion signs out to the welcome page and the Auth user is gone.
  - Fixed on the way: long page titles ran under the back button (PageHeader), raw `Color.fromARGB` literals (new
    `raw-argb` rule, D-05), POL-002 (account without profile → "Almost there" page).
- **Next: Phase 7 (quality sweep)**, then the final gates, after-screenshots and REPORT.md.
- **Phase 7 (quality sweep)**:
  - Text at 1.3×: messages, chat, profile, settings, blocked users fit without clipping (`after/text130_*.png`).
  - Fixed: dialog "Cancel" rendered in Roboto (button text style without the app font); muted chats now say
    "Notifications muted" in the chat header; the notifications page could save the defaults over the user's
    real choices if touched before the settings loaded (switches now wait; test proves the old page saved 2×).
  - Checked, no change needed: double taps cannot open a page twice (the Navigator absorbs pointers as soon as
    a push or pop starts; a test showed one page with and without a guard, so the guard was not added); every
    async button already ignores taps while busy.
- **Phase 8 (gates + report)**: format clean, analyze 0, 132 tests (+1 skipped), token check 0 violations, rules
  45/45, functions 23/23, release APK builds. After screenshots (`after/`, 45 images) and recordings
  (`after/flow_tabs.mp4`, `after/flow_settings.mp4`); the before/after comparison is in REPORT.md. Done.
