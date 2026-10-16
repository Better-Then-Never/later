# Before / after screenshots

Both sets come from the same emulator (Pixel-class AVD, 1080×2400) against the Firebase Emulator Suite with `tools/emulator/seed.js` data. The "after" run used the new security rules plus the data migration (`tools/migrations/migrate.js`). Files share names. Snowflakes are the app's animated overlay and differ in every capture. The clock, the avatars of pinned friends (a random fill) and the countdown seconds also differ by nature.

**Summary: no intended visual change.** Layouts, colours, typography, spacing, icons, copy and navigation match the before set screen for screen. The differences below are bug fixes or capture artefacts.

| Screen(s) | Difference | Why |
|---|---|---|
| `startup_notification_permission_prompt` | After: the welcome screen, with no system dialog. | BUG-002: the notification permission is no longer requested at cold start; the permission gate asks after login. |
| `login_loading`, `map_loading` | Captured mid-transition (navbar icons not yet decoded in `map_loading`). | Timing of the capture only; same layout once settled. |
| `map_blank_tiles_auth_failure` | Same blank tiles. | The Maps key is still not authorised for this machine (BLOCKERS.md B-01). |
| `history_*` | Newest capsule first; the new "Living room" capsule shows its photo. | BUG-063 (ordering); BUG-055 (upload with content type). |
| `add_friends` | Dave (who sent Alice a request) shows the add button instead of the pending clock; Erin (request sent) keeps the clock. | BUG-070. |
| `add_friends_search` | "da" finds @davem. | BUG-072: case-insensitive prefix search. |
| `permission_gate_notifications_already_granted` | After: the home map directly. | With every permission already granted the gate is skipped, which is the intended flow. The before shot showed the gate page. |
| `profile_second_user_after_switch`, `history_second_user` | Bob's own avatar and Alice's avatar load after the account switch. | BUG-012 and BUG-114: no data or cache survives from the previous account. |
| `settings` | Name, @username and e-mail come from the live session (Auth for the e-mail). | BUG-011: no "Loading..."/placeholder uid. |
| `capsule_creation_*` | Identical. Save shows the spinner once, and a double tap creates one capsule. | BUG-054 (behaviour, not visible in a still). |
