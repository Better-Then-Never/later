# BACKEND_CHANGES.md: server changes in Session A (none deployed)

Rules for every change here: additive and backward compatible (old app versions keep working), covered by
rules or functions tests in the emulator, cost-aware, and **not deployed** by this session. Deploy steps are
written for the owner.

## Summary
| # | Change | Kind | Old apps | Tests | Deploy |
|---|---|---|---|---|---|
| 1 | Functions emulator logs pushes instead of sending them | functions (emulator only) | unaffected | functions 43/43 | with the next functions deploy; no effect in production |

## 1. Pushes are logged, not sent, in the Functions emulator
`functions/index.js`: when `FUNCTIONS_EMULATOR === 'true'` (set only by the Firebase emulator), `services()`
hands the triggers a `loggedMessaging` object with the same `send` / `sendEach` shape instead of
`admin.messaging()`. Production is unaffected: the variable is never set there.

Why: the phone rig (docs/feel/RIG.md) runs the real triggers against the emulators so counters, notifications and
achievements behave as in production. FCM has no emulator; without this, a trigger would send a real push
through FCM with the developer's credentials.

Deploy: nothing to do on its own; it ships with the next `firebase deploy --only functions`.
