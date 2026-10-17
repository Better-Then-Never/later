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

## Not changed
No analytics, no ads, no location history: places are stored only as coarse cells for the Explorer achievement and
only by the server.
