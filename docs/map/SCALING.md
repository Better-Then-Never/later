# SCALING.md: when the phone can no longer hold every pin

Written with the cold start mission (docs/map/COLD_START.md, 19 Oct 2026). **Nothing here is built.** It is the next
step for the map's data, and the point at which to take it.

## Today
- Each phone reads its own capsules, its friends' friends-only ones and the public ones in a latitude band of ±2°
  (at most 300), and keeps the pins it showed (`map_pins/<uid>.bin`, about 55 bytes a pin: 66 KB for the test
  account's 1,205). It groups them itself (`CapsuleGroups`, in an isolate) and draws them from one GeoJSON source.
- With delta sync on (`FeatureFlags.mapDeltaSync`, after the backend is deployed) a start reads only what changed.
- Measured limits on the Galaxy S20 FE: 2,205 capsules zoom and split smoothly (docs/map/PERFORMANCE.md "After 3");
  5,000 stored pins decode in a few milliseconds (`map_pin_store_test.dart`).

## What breaks first, and when
| Grows | First symptom | Rough point |
|---|---|---|
| Public capsules in one band | the band query's 300 limit leaves some out (already true: it returns the first 300 by place, not the newest) | a city with more than 300 public capsules |
| Public capsules created per day | delta sync's public query (new ones anywhere since the last start) hits its 500 limit, and the map reads everything | more than ~500 new public capsules between two starts of one user |
| Pins one phone sees | grouping and the first picture take longer than a frame's budget; the store grows past a megabyte | **over about 20,000 visible capsules** (10x today), or a public band over a few thousand |

**Trigger to build what follows:** public capsules over about 20,000 in total, or over 1,000 in any one city, or the
delta sync's public limit being hit in the field (log "Map sync off, reading everything: public at their limit").

## The design (Snap Map's principle: the server pre-shapes the data)
- **Public pins as tiles, made by the server.** A scheduled function (every 5 to 15 minutes) groups the public
  capsules per map tile at a few zoom levels (e.g. z6, z9, z12) into at most about 150 points per tile: single
  capsules where they are few, counted bubbles where they are many (the same grouping as `CapsuleGroups`, run in
  Node). Written as small JSON (or MVT) files to Storage under `pins/v<n>/<z>/<x>/<y>.json`, behind the CDN
  (Hosting rewrite or a public Storage bucket with `Cache-Control: max-age=300`), plus a `manifest.json` with the
  generation and time.
- **The phone asks for the tiles it shows**, not for a band: the public part of the map becomes a second
  GeoJSON source (or a vector tile source in the style), cached like the base map. Friends' and own capsules stay
  per user (few, private, already synced by the store).
- **Privacy:** only public capsules, only what a pin needs (id, place as shown, colour, opening state); the
  approximate-location rounding happens on the phone before upload, so the tiles never hold an exact point the
  owner chose to hide. A capsule made private or deleted leaves the next generation of tiles (minutes).
- **Cost:** one function run per schedule (reads only capsules changed since the last generation: the same
  `createdAt` / `capsule_deletions` cursor as the delta sync), Storage egress through the CDN; no Firestore read per
  user for public pins at all.
- **Rollout:** behind a flag; the band query stays as the fallback until the tiles have been checked on a large seed
  (`tool/seed_heavy.js` with more public capsules) with the gesture and cold start harnesses.

## Not to do before the trigger
Building it now would add a scheduled function, a storage layout and a second data path for a few thousand
capsules that the phone handles in milliseconds today.
