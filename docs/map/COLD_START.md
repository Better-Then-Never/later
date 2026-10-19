# COLD_START.md: the full map with every capsule, at once (M-06)

Mission of 19 Oct 2026, branch `feature/map-instant-start` (from `fix/map-flash-ghosts-selection` at `c7f3e37`).
Galaxy S20 FE (Android 13, 120 Hz), profile builds against the local emulators (`docs/feel/RIG.md`), the heavy
seed (alice: 102 own capsules, 60 friends, 1,205 visible on the map).

## The rig
`tool/dev/coldstart.sh [launches] [--no-build] [label]` (`VIDEO=1` films launch 1): force-stops the app, launches it
as the home screen does (`am start -W --splashscreen-show-icon`), waits for the frame summary and reads the device
log with `tool/dev/coldstart_report.js`. Every number is **milliseconds from Android's launch of the activity**
(the moment "Displayed" and "Fully drawn" count from; a finger's tap on the icon comes about 0.1 s before it).
- `ttid`: Android's first frame (`am start -W` TotalTime).
- The app's marks (`LATERSTART <name>`, `lib/app/shell/startup_report.dart`, debug and profile builds only):
  `dart` (first Dart line), `run` (runApp), `home` (first frame of the signed-in home), `shell` (first frame of the
  map page with its buttons), `map_created`, `style_native` (MapLibre loaded the style), `images_made` /
  `images_added` (the marker pictures), `style` (our layers added), `streets` (the map idle for the first time: all
  tiles drawn), `data_own` / `data_co` / `data_friends` / `data_public` / `data_all` (each capsule source answered
  once), `pins_first` (the first pins drawn), `full`.
- `full` = **TTFD**: Android's `reportFullyDrawn`, called by the app once the picture holding every source has been
  drawn by the map (the map's next idle after it was sent). FlutterActivity reported "fully drawn" at Flutter's
  first frame, which made Android's TTFD equal to TTID; `MainActivity.onFlutterUiDisplayed` no longer does.
- `jank`: frames whose build or raster took over 8.3 ms, from the first frame to two seconds after `full`, and
  the worst one (`FrameTiming`).

## Baseline (`c7f3e37` plus the marks; `build/perf/coldstart_base.txt`, `coldstart_base_b.txt`)
Medians of 5 launches (TTFD: of 3, once Android's number was fixed). The phone's Firestore cache as the owner had it:
3,727 cached capsules and 468 cached queries, mostly from earlier test seeds.

| ttid | shell | streets | own answered | first pins | all answered | **full (TTFD)** | janky frames |
|---|---|---|---|---|---|---|---|
| 1,113 | 1,198 | 2,856 | 3,675 | 3,883 | 4,327 | **4,262** (4,062–4,938) | 48 of ~200 (worst 38 ms) |

Where the time goes (launch 3 of `base_b`, typical):

| ms | What |
|---|---|
| 0–754 | Android starts the process and Flutter's engine (`dart` at 754) |
| 1,030 | `runApp` (Firebase, settings, fonts in parallel before it) |
| 1,150 | first frame (TTID); the map page's buttons at 1,226 (a saved camera: no wait for it) |
| 1,408 / 1,423 | the native map view created; MapLibre has parsed the style |
| 1,191 → 1,646 | the map controller: marker icons (Google's, unused on MapLibre) 350 ms, then the location |
| 1,423 → 3,172 | **the 107 marker pictures drawn one by one (1.75 s)**, then handed to the map one by one (260 ms) |
| 2,578 | the streets drawn (the map's first idle), our layers not yet added |
| 1,646 → 3,398 | **Firestore answers the first capsule query (1.75 s)**; friends at 3,828, public at 3,909 |
| 3,527 / 4,262 | the first pins drawn; every pin drawn (TTFD) |

What a launch looks like (`build/dev/video/coldstart_base.mp4`, first launch, frames 1/6 s apart): the launch
window in the page grey for about 0.9 s (no logo); the Later logo for one frame; the buttons with the navigation
bar's white pill **empty for one frame**, then its icons; **the empty map behind the buttons for 1.2 s**; the
streets all at once; 1.8 s later the heat and the person (that launch opened zoomed out, in the heat).

## Step 1: quick wins (each measured; medians of 5, ms from launch)
| Step | What changed | streets | own answered | all answered | **full (TTFD)** | janky |
|---|---|---|---|---|---|---|
| base | – | 2,856 | 3,675 | 4,327 | **4,262** | 48 |
| 1 | the capsule reads start first (before the marker icons and the location); no GPS wait with a saved camera; Google's marker icons not loaded on MapLibre; the 107 marker pictures drawn at once and handed to the map at once (1.75 s → 0.5 s) | 2,839 | 2,436 | 3,400 | **3,472** | 8 |
| 2 | Firestore's cache: emptied once (3,727 cached capsules of old seeds, 17 MB → 1.7 MB), bounded to 40 MB, indexes made by the SDK | 3,836 | 3,694 | 4,535 | **4,802** | 8 |
| 3 | launch screen, first Flutter frame and the map's cover in the map's ground colour; the cover thins out once the streets are drawn (or 1.8 s after the buttons, or at a touch) | 2,814 | 2,447 | 3,534 | **3,593** | 11 |
| 3b | the permission check shows the splash, not a loader on the page grey; the first screen's pictures decoded during the splash (home waits at most 150 ms) | 2,873 | 2,461 | 3,374 | **3,537** | 14 |
| 3c | the saved camera read at once: the map's buttons in the same frame as the tab bar | 2,724 | 2,399 | 3,396 | **3,459** | 8 |

Notes:
- Step 2 was slower only right after the cleanup: the SDK answers a listened query from its last result plus every
  cached document read since (Firestore's own log, `--dart-define=FIRESTORE_LOG=true`: "Re-using previous result
  from SnapshotVersion..."); after the cleanup every capsule had just been read again, so each query looked at all of
  them. Three launches later (step 3) the first answers were back at 2.4 s. The SDK made two indexes of its own
  (`privacy, ownerId` for the friends' query, `privacy, location` for the public band), used from then on. Firestore's
  first answer is still 1.2 s after the map asks: the reason for the pin store (step 2 of the mission).
- With FlutterFire's own `reportFullyDrawn` gone, `full` waits for the reveal too (the cover gone): it is what the
  user sees.
- The video of each launch (`build/dev/video/coldstart_step3c.mp4`, 30 frames a second): the launch window in the
  map's ground (sampled 243,244,241, the map's #F3F3F0 after the video's compression) from its first frame; the
  logo for 4 frames (this launch, from `am start`, gets Android 13's splash without its icon; from the home screen
  the splash has the logo); the tab bar, the map's buttons and their icons in one frame (the streak pill one frame
  later, when its data is read); the cover until the streets, which fade in over 0.3 s. No grey, no white, no empty
  tab bar, no half-drawn map.

## Step 2: the pin store (medians of 5, ms from launch)
`lib/features/map/map_pin_store.dart`. From here every measurement opens at the same street-level camera
(`CAMERA=52.2297,21.0122,14.5`, pins and bubbles on screen); earlier ones opened where the last test had left the map.

| Step | What changed | store read | style ready | streets | **full (TTFD)** | fresh (every source's answer drawn) | janky |
|---|---|---|---|---|---|---|---|
| 3c | (before the store, its own camera) | – | 2,398 | 2,724 | **3,459** | – | 8 |
| store | the pins the map last showed, read from the phone when the account signs in; each source's answer replaces its pins | 1,203 | 2,447 | 2,226 | **2,556** | 3,302 | 10 |
| store + pictures | the 107 marker pictures kept on the phone (drawn once per app version); the sources and layers sent in order and waited for together | 1,189 | 1,525 | 1,869 | **1,875** (1,669–2,539) | 3,038 | 9 |

- The store file for alice (1,205 pins) is 66 KB; it is read 20 to 50 ms after the map starts. 5,000 pins decode in
  well under 200 ms (test `map_pin_store_test.dart`, on the computer; on the phone the whole read is the `store` mark).
- `full` is now the first picture of every pin the map had (the store's, drawn and uncovered); `fresh` is the first
  picture of every source's own answer, about 1.2 s later: the window in which a pin can be stale (below).

## Step 3: one reveal, then only what changes (E)
- **Hidden until the reveal.** Every pin and bubble the map is sent before it is uncovered carries "not yet" ('a'
  far in the future), so nothing is seen arriving under a thinning cover or in steps. On the first map idle after
  our layers are in (the cover's moment), and once every pin of this start is grouped (the pin store's picture, or
  on a first start every source's answer, at most 1 s after the first one), they grow in: from the middle of the
  screen out in rings (150 ms between the middle and the edge), each over 200 ms with AppMotion.enter's curve. The
  heat comes with them. Reduced motion: at once.
- **How it is drawn.** Each piece carries when it began to grow ('a') or shrink ('g') on the stage's clock; the
  pins' and bubbles' `icon-size` multiply by a function of that clock, which the view sends to the two layers once a
  frame while anything grows or shrinks (`_lifeScale`). No picture is sent for the motion itself. When it is done
  the next picture leaves the marks out.
- **Afterwards only what changes moves.** A new capsule's pin (or a new bubble) grows in, a gone one shrinks away where
  it stood (150 ms, AppMotion.exit's curve); a bubble that a capsule joins or leaves keeps its place and changes its
  number (`CapsuleGroups.changes`: a bubble grown from the same capsule is the same bubble, even when its id's level
  moved). The live answers that replace the stored pins change nothing when nothing changed. A filter change shows
  the same way.

Measured (`build/perf/coldstart_reveal2.txt`, zoom 13.5 over the centre, 5 launches): full **2,741** ms median
(2,351–2,984: the streets take longer at this zoom than at 14.5); in the video the streets fade in, the pins grow from
nothing to their size in about 0.1 s with the nearer ones first, then hold still; the live answers (fresh at
3.4–3.9 s) moved nothing. No frame over 16.7 ms between the reveal and the end of its motion in any of the five
launches; the slow builds (11–22 ms) are 0.3–0.6 s before it, under the cover.

## Delta sync (C): only what changed since the pins the phone kept
**Built and tested on the local emulators, off in the app (`FeatureFlags.mapDeltaSync`, `--dart-define=MAP_DELTA=true`)
until the owner deploys its backend part (below).** Without it the app reads everything at every start, as before.

Why it is simple here: capsules are never edited (firestore.rules: only a co-author may take themselves off), so a
change to the map is a **new capsule** (its `createdAt`, set by the server) or a **deleted one**.
- The store keeps, besides the pins, `syncedTo` (the newest change it holds: a capsule's `createdAt` or a deletion's
  `deletedAt`, server times), the friend ids and the public band's latitude (format v2; a v1 file reads as nothing
  kept, so the first start after this change reads everything once).
- A start with such a store (`MapDeltaSync`): the **friends'** friends-only capsules created after `syncedTo` (one query
  per 30 friends), the **public** capsules created after it (anywhere, newest first), and the **deletions** after it
  (`capsule_deletions`: public ones, and friends-only ones of the user's friends). Merged: the kept pins (of today's
  friends) + the new ones − the deleted ones; a friend added since gets their capsules read in full. All live
  listeners: changes during the session arrive the same way. The own and co-authored lists stay full listeners (the
  history page listens to the own one anyway, so it costs nothing more).
- **Any doubt, everything is read** (the kept pins standing in until it answers): an error (no index or rule yet: the
  backend not deployed), a query that hit its limit (500), a friend added or removed during the session, the camera
  moving to another band.
- A kept pin (only its pin known) opens from the phone's copy of Firestore at once, while the server's read decides
  whether it stays open ("no longer available" otherwise).
- Cost: the friends' and public queries read only what is new (0 documents when nothing changed) instead of the 1,114
  they hold for the test account; Firestore counts every document of a listener that has been away for over 30
  minutes, which is most cold starts. The emulator does not count reads, so this is by construction, not measured.

Backend (additive, nothing existing changes; old app versions never read the new collection):
- `functions/lib/mapsync.js` + `exports.recordCapsuleDeletion` (`onDocumentDeleted('capsules/{id}')`): for a
  friends-only or public capsule, `capsule_deletions/{id}` = owner, privacy, `deletedAt` (server time), `expireAt`
  (+30 days). Private capsules leave nothing (only their owner and co-authors saw them; their lists are full).
- `firestore.rules`: `capsule_deletions` readable by whoever could see the capsule (public; friends-only by the
  owner's friends), written by nobody but the server.
- `firestore.indexes.json`: capsules (ownerId, privacy, createdAt↓) and (privacy, createdAt↓); capsule_deletions
  (ownerId, privacy, deletedAt↓) and (privacy, deletedAt↓); a TTL field override on `capsule_deletions.expireAt`.
- Tests: `functions/test/mapsync.test.js` (3), `tools/rules-tests/firestore.test.js` "the map's sync" (3; all 73
  Firestore rules tests pass), `test/features/map_delta_sync_test.dart` (6), `map_pin_store_test.dart` (format v2).

**Deploy steps for the owner (not done):**
1. `firebase deploy --only firestore:rules,firestore:indexes,functions:recordCapsuleDeletion --project later-da778`
2. If the TTL override did not come with the indexes: `gcloud firestore fields ttls update expireAt
   --collection-group=capsule_deletions --enable-ttl --project=later-da778`
3. Wait until the four new indexes show "Enabled" in the console (Firestore > Indexes).
4. Set `FeatureFlags.mapDeltaSync` to `true` (or build with `--dart-define=MAP_DELTA=true`) and release.
Deletions made before step 1 have no record: a phone that kept such a pin keeps it until its next full read (a sync
doubt, or the record's 30 days). To be safe, step 4 can wait a day after step 1, or `_cacheGeneration` /
the store's format version can be bumped in the same release to start everyone from a full read once.

Checked on the phone (local emulators, `MAP_DELTA=true`, `build/perf/coldstart_delta1.txt`): every start in delta
mode (`sync_delta` mark), full **2,427** ms median at zoom 13.5 (the first picture is the store's either way), every
source answered at about 3.1 s. A friend's friends-only capsule in the middle of the screen deleted on the emulator
with the app closed: the function wrote its record (13 s later on the emulator's first run of the function), the
running app's deletions listener removed the pin and the store saved 1,204 pins with `syncedTo` = the deletion's
time.
