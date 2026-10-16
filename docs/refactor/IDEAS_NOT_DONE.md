# IDEAS_NOT_DONE.md — noticed, deliberately not implemented (no new features)

- **Chat / Messages tab** — the navbar has a "Messages" tab showing a placeholder; "Open chat", "Chat settings" do nothing.
- **Send Capsule to a friend**, **Friend's capsules list** on a friend's profile (static placeholder today), **Capsules settings**.
- **Report / Block user** buttons (close the modal only).
- **Facebook login** button (TODO, does nothing).
- **Settings stubs**: Email, Password, Language, App appearance (dark mode), Customize profile ("feature will be added soon").
- **Notification tabs "Replies"/"Comments"**: no reply/comment feature exists; tabs kept as designed (always empty).
- **Invite from contacts** (`contacts_list.dart`, never referenced; removed as dead code — recoverable from git history at `9f17db0`). The permission gate still asks for contacts (kept, product decision).
- **Optional permissions**: the gate makes all five permissions mandatory; making contacts/microphone optional (and asking just-in-time) would improve onboarding and store compliance.
- **Geohash-based map queries** (needs a data migration); the refactor uses latitude-band queries + client longitude filtering instead.
- **App Check, Crashlytics, Analytics events, Remote Config.**
- **Opening date picker with time of day** (currently date only, time = now).
- **Pagination UI for history and notifications** (the refactor bounds the queries; no "load more" UI was added).
- **Edit capsule**, **delete account**, **change email/password**.
- **Localisation** (strings are English literals).
- **Region alignment for Cloud Functions** (`europe-central2` like Firestore) — a deployment decision.
