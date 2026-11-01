# Capsule v3, phase 3: the plan (for the owner's go)

Phase 3 is B1–B5 (how a capsule opens), C2 (Adjust) and F1–F2 (the "is open" and "is ready" pushes).
B3 asks for the lock in the data: "a capsule locked by place or date stays hidden from the app until
it may open (database rules, not just the screen)". This page says how, what changes on the server,
and what needs your answer before any of it is built.

## Today

- A capsule is one document, `capsules/{id}`, with everything in it: title, place, dates, and the
  photo, thumbnail and loop frame URLs and the description.
- Anyone who may see a capsule (public, friends', sent to them) can read the whole document, so a
  locked capsule's photo URL and words can be read with a little effort before its date. Only the
  app's screens hide them.
- The photo files in Storage are readable only by their owner; everyone else opens them through the
  download URLs in the document. Whoever holds a URL holds the photo, so the URL is the secret.
- Capsules are never edited (rules); the map's sync and the pin store rely on that, but they keep
  no title, photo or text, so they are not affected by where the photo URL lives.

## The idea: a sealed part

A capsule that is locked (it has a date in the future, or "Only when I'm back here") is written in
two parts:

| Part | Holds | Who can read it |
|---|---|---|
| `capsules/{id}` (as today) | owner, title, place, colour, privacy, dates, the new rule (`openWhere`), the crop | whoever may see the capsule, as today |
| `capsules/{id}/sealed/content` (new) | photo URL, thumbnail URL, loop frames, description | its owner and co-authors always (their phone has the photo anyway); anyone else who may see it only once its date has passed **and**, for a place capsule, once they have unlocked it there |

A capsule that opens at once and anywhere ("Anytime, Anywhere") stays one document, exactly as now.

### Opening by date

- The rules compare the date with the server's clock (`request.time`), so a locked capsule's sealed
  part cannot be read a minute early, whatever the phone's clock says.
- A scheduled function (every 5 minutes) finds sealed "anywhere" capsules whose date has passed,
  copies the sealed part back into the capsule document (lists and chats then work as they do today,
  without one extra read per capsule) and sends F1, "<Title> is open". Between the date and that run
  the app reads the sealed part directly, so it opens on the minute.

### Opening by place (150 m)

- Rules cannot know where a phone is, so a callable function `unlockCapsule(capsuleId, lat, lng)`
  checks that the caller may see the capsule, that its date has passed, and that the reported
  position is within 150 m of the spot (plus the fix's accuracy, up to 50 m). Then it writes
  `capsules/{id}/unlocks/{uid}`, and the rules let that person read the sealed part from then on.
- The function trusts the position the phone reports. Someone who fakes their GPS can open a place
  capsule from home; that takes deliberate effort, and nothing better exists without hardware
  attestation. Each unlock is logged.
- A place capsule is never released to everyone: each person opens it there.
- F2, "<Title> is ready. It's waiting in <place>", goes out when a place capsule's date comes.

### Everything else that touches it

- **Creating:** the app writes both parts in one batch (also from the offline outbox). The rules check
  the sealed part belongs to a capsule being created by the same person (`getAfter`).
- **Chats:** a capsule sent in a chat carries its thumbnail URL today; a sealed one goes without it,
  and the other side's app shows the locked tile until it may open.
- **Lists** (history, profile strips, the map card): a sealed capsule shows its pin tile, as locked
  capsules do now; once open, the photo comes from the released document (date) or the sealed part
  (place, one read when it is shown).
- **Deleting:** a function removes the sealed part and the unlocks with the capsule. Today a deleted
  capsule's comments and reactions stay behind in the database (only deleting an account removes
  them); the same function removes those too.
- **Data export:** includes the sealed part of your own capsules.
- **Older app versions** (v0.0.36 and before) handle a capsule without a photo URL (it is optional in
  the model) but would show a locked friend's capsule without a photo even after its date, until the
  release run. Testers should update; no crash expected (to be checked against v0.0.36 before the
  release).

## The rest of phase 3 (app side)

- **B1, B2:** "How it opens" as the first Settings row on Create (starts at Anytime), the sheet with
  When (Anytime, In a month, In a year, Pick a date) and Where (Anywhere, Only when I'm back here),
  the rule in words and Done (Figma `7094:2637`). The row then shows the rule.
- **B3, B4:** a place capsule's map card: "Be there to open", the distance and Go there (directions);
  date not reached: countdown, distance, Locked; date reached: "Ready to open", Go there; there: Hold
  to open, which unlocks it and then shows the wrapping (phase 2).
- **B5:** one dates line everywhere: "opens anytime", "opens 20 Oct 2027", "opens 20 Oct 2027, here".
- **C2 (built 2026-10-21, rules waiting for deploy):** Adjust on the Create preview: the whole photo with a square window, drag and pinch up to 3×.
  The square is saved with the capsule as `crop` (x, y, size as shares of the photo) and used wherever
  the photo is square; the thumbnail is cut from it at upload. A tap still shows the whole photo.
- **F1, F2:** new notification types in the app (in-app list and push), texts in five languages.

## What changes on the server (your deploy)

- `firestore.rules`: the sealed part and unlocks; `validCapsule` accepts `openWhere` and `crop`, and
  the photo fields become optional for a sealed capsule.
- New functions: `releaseOpenedCapsules` (scheduled, every 5 minutes), `unlockCapsule` (callable),
  `cleanupCapsule` (on delete). New ones are created with gcloud first, as before.
- One composite index for the release query.
- Rules and functions tests in the emulators (`tools/rules-tests`, `npm run test:emulate`).
- Order: deploy the server first (the current app keeps working: it writes unsealed capsules, which
  stay valid), then release the app.

## Built (2026-11-01, local, not deployed)

What changed from the plan while building:

- The unlocks live in `users/{uid}/unlocked/{capsuleId}` (one list per person, which the app reads
  for its lists and the rules check with `exists`), not `capsules/{id}/unlocks/{uid}`. A deleted
  capsule's entries stay there; they name a capsule that is gone and open nothing.
- A capsule doc says `sealed: true` while its content is apart, and `openWhere: 'here'` for a place
  capsule (which stays sealed for good). Release removes `sealed` and copies the content back.
- Capsules are queued in `capsule_schedule/{id}` (server only) when created; the 5-minute run reads
  that queue by `openAt`, so no composite index is needed. An older app's unsealed capsule for later
  is queued too and gets "is open".
- Four functions, not three: `queueCapsuleOpening` (on create), `releaseOpenedCapsules` (every 5
  minutes), `unlockCapsule` (callable), `cleanupCapsule` (on delete).
- The app adds `cloud_functions` (for the callable). On a server without the new rules a capsule for
  later is written whole as before; a place capsule is refused with a message ("isn't available
  yet").
- Old capsules: `tools/admin/seal-waiting-capsules.js` (`--dry-run` first).

### Deploy, in this order (owner's go)

1. `firebase deploy --only firestore:rules` (the current app keeps working: it writes unsealed
   capsules, which stay valid).
2. Create the four functions once with gcloud (the CLI cannot create new ones here; see
   docs/feel/DEPLOY_LOG.md): `queueCapsuleOpening` and `cleanupCapsule` as Firestore triggers in
   `europe-west1` with `--trigger-location=eur3`; `releaseOpenedCapsules` and `unlockCapsule` in
   `us-central1` as `--trigger-http` with the labels `deployment-scheduled=true` and
   `deployment-callable=true`. Then `firebase deploy --only functions:queueCapsuleOpening,functions:releaseOpenedCapsules,functions:unlockCapsule,functions:cleanupCapsule`.
3. `node tools/admin/seal-waiting-capsules.js --project later-da778 --production --dry-run`, then
   without `--dry-run`.
4. Then the app release.

Tests: rules `tools/rules-tests` (90), functions `functions` `npm run test:emulate` (76), admin
`tools/admin` `npm run selftest`, app `flutter test` (567).

## The owner's answers (2026-11-01)

1. Own capsule: owner and co-authors can always read the sealed part; the app shows it locked
   until it opens (option A).
2. Capsules already waiting for a date: sealed by a one-off script, run after the deploy with the
   owner's go.
3. "Only when I'm back here" turns Approximate location off and says why.
4. "is open" / "is ready" go to the owner, co-authors and the friend it was sent to.
5. Faked GPS: as described (the reported position is trusted, each unlock logged); not asked
   further.
6. Deploy: built and tested in the emulators; nothing reaches production without the owner's go.

## Decisions for you (asked)

1. **Your own capsule:** you (and co-authors) can always read its sealed part, and the app hides it
   until it opens (recommended: your phone took the photo anyway). Or lock it for its owner too.
2. **Capsules already waiting for a date:** seal them now with a one-off script, so they get the real
   lock too (recommended), or leave them as they are (B1 says they keep their date and Anywhere either
   way).
3. **Place capsules and "Approximate location":** a place capsule needs its exact spot (you cannot be
   within 150 m of a point a kilometre off), so choosing "Only when I'm back here" turns Approximate
   location off and says why (recommended).
4. **Who gets "is open" and "is ready":** the owner, co-authors and the friend it was sent to
   (recommended), not everyone who can see it.
5. **Faked GPS:** fine as described above, or you want more (there is no strong option without
   hardware attestation).
6. **Deploy:** rules, three functions and one index, by you or with your go, before the app release.

With your answers, the server part comes first (rules, functions, tests in the emulators), then the
app part, both on `feature/capsule-v3`.
