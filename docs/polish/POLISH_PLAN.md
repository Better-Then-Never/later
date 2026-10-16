# POLISH_PLAN.md — ordered work items

Branch `feature/polish-motion-messages-settings`, from `main` 5b30770 (refactor + chat/blocking + releases v0.0.30/31).
Conventions are those of the refactor (docs/refactor/REPORT.md): Provider + ChangeNotifier, repositories behind
interfaces in `data/`, `SessionScoped` stores attached by the session, navigation through `AppRoutes`, tokens in
`core/theme`, typed assets in `core/assets/app_assets.dart`, shared widgets in `shared/`.

## Orientation findings that drive the plan
- **Design system**: tokens exist (AppColors, AppRadii, AppSpacing, AppShadows, AppDurations, AppTextStyles). The
  chat code ported from `main` (features/messages) bypasses them: `Colors.grey[…]`, raw `TextStyle`, `Color(0x…)`,
  Material `Icons.*`.
- **Motion**: page fade 10 ms (instant), slide-up 100 ms, navbar 200 ms easeInOut, header 250 ms fastOutSlowIn /
  150 ms switcher, popup 300 ms. No reduce-motion handling, no shared press feedback, list updates pop.
- **Messages**: no unread counts, read receipts = one write per message, 500-message window without paging,
  no optimistic/failed state, no push for messages at all, no mute.
- **Notifications**: one channel for everything, sender ignores user preferences (none exist), no message
  notifications, no suppression while viewing a chat, static iOS badge 1.
- **Settings**: Name, Username, Permissions and Log out work; Email, Password, Language, App appearance and
  Customize profile are "coming soon" stubs. No delete account, notification, privacy, help or about sections.

## Work items (in order; each ends with format/analyze/tests/build and a PROGRESS.md entry)
1. **Baseline**: gates (clean), screenshots of every screen incl. chat into `baseline/`, recordings of the
   main flows.
2. **Design inventory + check script**: DESIGN_DECISIONS.md (tokens), ICONS.md, `tool/check_design_tokens.dart`
   (fails on raw colours / TextStyle / Icons outside allow-listed theme files; existing debt baselined so only
   new violations fail, debt then burned down).
3. **Motion tokens** (`AppMotion`): durations/curves derived from the existing ones, reduce-motion aware
   helpers; shared press feedback; skeleton→content crossfade; list item enter; map marker fade.
4. **Shared components completed**: switch row, selection row (bottom-sheet picker), section header,
   destructive row, skeletons, empty/error states with retry, count badge — all from tokens.
5. **Messages**: data model (unread counts per participant, lastReadAt receipts — one write), optimistic
   outbox with pending/failed/retry, paging of older messages, conversation list redesign within tokens,
   unread badge on the Messages tab, per-chat mute, motion; rules + rules tests; emulator two-user check.
6. **Notifications**: per-category channels (messages, activity) + quiet variants, settings-aware sender
   (master, categories, quiet hours, mute, preview), message push function, foreground suppression for the
   open chat, tap routing to the exact chat, badge counts, invalid-token cleanup kept; functions tests.
7. **Settings**: account (email/password change with re-auth, providers, delete account with re-auth +
   server cleanup), notifications, privacy (blocked users, permission status), map type, camera defaults,
   data & storage (cache size/clear), help & support, legal & about (links in one config file, licenses,
   version). Stubs removed or made real. Repository + rules + tests.
8. **Quality sweep** over all screens (states, double-taps, forms, a11y labels, text scaling 1.3×).
9. **Gates + after screenshots + REPORT.md**.
