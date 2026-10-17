# REPORT.md: Polish and Complete the App

**Branch:** `feature/polish-motion-messages-settings` (from `main` at 5b30770), **23 commits**, not merged, not
pushed. Nothing was deployed and production was not touched: all checks ran on the local Firebase emulators
(rules and functions suites on their own `demo-` projects).

## In plain words

Later now looks and moves the same everywhere, chats work like a modern messenger, notifications respect what
the user wants, and every Settings option does something real.

- **Looks:** every colour and font goes through the design tokens, and a script in CI blocks new raw values.
  Shared pieces (section cards, switch rows, badges, image placeholders, page frame) replace one-off copies.
  Long page titles no longer run into the back button. Dialog buttons use the app font.
- **Motion:** one set of timings and curves. Pages fade in over 150 ms instead of cutting (or zooming on two of
  them). Buttons and the tab bar shrink slightly when pressed. "Remove animations" in the phone's settings turns
  all of it off.
- **Messages:** unread counts on each chat and on the tab, "Sent" / "Read" under your last message, and messages
  appear the moment you send them. Without a connection, a message says "Not sent · Tap to retry" and is
  delivered once. Long chats load older messages as you scroll. The screens were redrawn in the app's own
  style. A chat can be muted, and then says "Notifications muted".
- **Notifications:** new message pushes that open the chat, one notification per chat, and nothing for the
  chat you are reading. The server checks the user's choices first: everything on/off, messages, followers,
  capsules, message text, sound, quiet hours (in the user's own time zone) and muted chats. Android shows
  separate channels for messages and for activity.
- **Settings, all real:** change email (confirmation link) and password after confirming it is you; customize
  profile; notifications; blocked users with unblock; app permissions; map look and starting camera; cache
  size and clear cache; help (questions, copy app info); about (version, licenses); delete account (password or
  Google check; the server then removes everything the account owned). Language and App appearance were
  removed: the app has no translations or dark theme for them to switch.
- **Bugs fixed on the way:** startup freeze (POL-001), Log Out that could hang (POL-003), an account without a
  profile stuck on "Loading..." (POL-002, now asks for a name and username), and switches that could save the
  default notification settings over the user's real ones if touched too early.

## What to do next (the owner)

1. Read **BLOCKERS.md**: a support email address, a privacy policy and terms are missing (their rows appear
   as soon as the links are set in `lib/core/config/app_links.dart`).
2. Deploy in the order of **MIGRATIONS_NEEDED.md** §2: rules, then functions, then the app. "Delete account"
   must not ship before the functions are live. No data migration is needed.
3. Test pushes on two real devices (the emulators have no FCM; BLOCKERS.md B-04).

## Gates (final run)

| Gate | Result |
|---|---|
| `dart format --set-exit-if-changed lib test tool` | clean |
| `flutter analyze` | no issues |
| `flutter test` | 132 passed, 1 skipped (baseline 108) |
| `dart run tool/check_design_tokens.dart` | 0 violations, 211 files |
| Firestore rules tests (`tools/rules-tests`) | 45/45 (baseline 41) |
| Cloud Functions tests (`functions`, emulators) | 23/23 |
| `flutter build apk --release` | built (80.4 MB) |
| CI (`pr-build.yml`) | now also runs format, analyze, tests and the token check |

Checked by hand on the Android emulator against the local emulators: unread badges and read receipts, offline
send and retry, mute (saved, rules accept it, header shows it), notification switches (saved, rules accept
them), wrong vs right current password (verified against the Auth emulator, then restored), account without a
profile completing it, account deletion (Auth user gone, welcome page), and with the Functions emulator the
cleanup trigger removing profile, settings, username, chats and friend links. Text at 1.3× fits on messages,
chat, profile, settings and blocked users.

## Before and after

Screenshots are in `baseline/` (start of the branch) and `after/` (end), same emulator, same seeded data.

| Screen | Before (`baseline/`) | After (`after/`) |
|---|---|---|
| Messages list | grey rows, no unread counts | white cards like My friends, unread badges, muted chats grey (`messages_list*.png`) |
| Chat | Material icons, raw greys, no receipts, no retry | app icons, day separators, Sent/Read, Not sent/retry, muted line (`chat_*.png`) |
| Settings | 9 rows, 5 of them "coming soon" stubs without a header | grouped sections, every row works (`settings*.png`) |
| Email / Password | "You can't change your email right now… Skebob…" / "The feature will be added soon." | real forms with re-authentication (`settings_email.png`, `settings_password*.png`) |
| App permissions | hand-built header, raw green switch | shared header and switch (`settings_permissions.png`) |
| Account without profile | "Unknown User", "Loading..." forever | "Almost there" (`complete_profile.png`) |
| Map, history, profile, friends, notifications, login, signup | — | unchanged layout; colours now from tokens, dialogs in the app font (`map_populated.png` etc.) |
| Recordings | `flow_tabs.mp4`, `flow_chat.mp4`, `flow_profile_sheets.mp4` | `flow_tabs.mp4` (150 ms fades, press feedback), `flow_settings.mp4` |

## Where the details are

| File | What |
|---|---|
| POLISH_PLAN.md | the ordered plan |
| PROGRESS.md | running log per phase, with what was verified |
| DESIGN_DECISIONS.md | tokens, motion, decisions D-01 to D-07 |
| ICONS.md | every icon asset and where it is used |
| BUGS.md | POL-001 to POL-003 |
| MIGRATIONS_NEEDED.md | new data, deploy order, behaviour changes to announce |
| BLOCKERS.md | what needs the owner |
| IDEAS_NOT_DONE.md | ideas left out on purpose |
