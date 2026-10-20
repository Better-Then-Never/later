# PRIVACY.md: what changed for users' data

For the owner, to update `public/privacy.html` (not changed in this branch: it is live on Hosting and a legal
text; the points below are what it should add).

## New data the app stores
| Data | Where | Who can read it |
|---|---|---|
| Reactions (type, time) | `capsules/{id}/reactions/{uid}` | everyone who can see the capsule |
| Comments (text, time, reply link) | `capsules/{id}/comments/{id}` | everyone who can see the capsule; author or capsule owner can delete |
| Reports (reason, optional details, what was reported) | `reports/{id}` | nobody through the app (write-only); the owner in the console |
| App language | settings doc | the user (and the server, to write pushes) |
| Privacy choices | settings doc | the user |
| Counters and stats (followers, following, capsules, public capsules, streak, number of places, distance in km, reactions received, comments written) | `users/{uid}` | **any signed-in user** (profiles are public to signed-in users) |
| Place cells (about 5 km geohash cells) and the last capsule position | `users/{uid}/private/gamification` | the user only (server-written) |
| Achievements | `users/{uid}/achievements` | the user; friends unless "Show my achievements" is off |
| Capture time and time-zone offset of new capsules | capsule doc | whoever can see the capsule |

## New controls
- **Approximate location** (Settings > Privacy, and per capsule): the position is rounded to two decimals
  (about 1 km) **on the phone, before upload**; the exact point never leaves the device.
- **Read receipts** off: the app stops writing the user's read time to the chat, and stops showing the friend's.
- **Default visibility** for new capsules; **comments / reactions** off per capsule.
- **Show my achievements** to friends.
- **Report** capsules and comments.
- **Permissions**: microphone and contacts are no longer requested (and no longer declared on Android); camera,
  location and notifications are each optional and asked again only where needed.

## Things to say in the policy
- Stats on profiles are visible to signed-in users (counts only, no places).
- Reports are reviewed by the Later team and kept as long as needed for moderation.
- Account deletion also removes the user's reactions and comments on other people's capsules.
- Announcements: the device subscribes to a topic of its language when "News from Later" is on.

## On the phone: the map's start (M-06, docs/map/COLD_START.md)
| Data | Where | Who can read it |
|---|---|---|
| The map's pins as last shown: per pin its id, owner id, place (as shown, so rounded for approximate capsules), colour, privacy, opening time and which query it came from; never a title, photo or text | `map_pins/<uid>.bin` in the app's private storage | the app only. Only pins the server returned to this account. Deleted when the account signs out or its session ends (revoked, deleted), and when another account signs in on the phone |
| The map's marker pictures (pins, bubbles, the user's figure) | `map_images/` in the app's private storage | nothing personal: the same pictures for everyone |
| The last camera of the map (place and zoom) | the app's preferences, per account | the app only (already kept before this change) |

- **Stale for a moment, never shown in detail:** a cold start draws the stored pins at once; each of the map's four
  queries (own, co-authored, friends', public) replaces its stored pins with its first answer, about 1 to 2 s later.
  A capsule deleted, made private, a friend removed or a user blocked since the last start can therefore show as a
  pin for that moment; a removed friend's friends-only pins never show (the visibility rule runs on stored pins with
  today's friends). Tapping a stored pin before its query has answered reads the capsule from the server, which checks
  that the user may still see it, or says it is no longer available. Nothing of a capsule but its pin is ever kept.
- **Firestore's own cache on the phone** (which already held every capsule the user saw, with titles and photos
  links) is now bounded to 40 MB and was emptied once to drop old test data; its content is unchanged otherwise.

## Not changed
No analytics, no ads, no location history: places are stored only as coarse cells for the Explorer achievement and
only by the server.
