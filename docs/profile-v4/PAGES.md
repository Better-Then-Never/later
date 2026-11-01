# Profile v4: the pages it leads to

Figma page 14 · Profile v4 pages (`7188:682`), drawn 2 Nov 2026. One rule across all of them: a person
always appears as their own stamp (the shape and colour they chose), never as a plain round avatar.
Where a page exists in the app today, its file is named; the design replaces its look, not its job.

## From the header (section `7188:683`)

| Page | Frame | Reached from | What it shows | In the app today |
|---|---|---|---|---|
| Notifications | `7188:684` | the bell | Filters All / Friends / Capsules / Places. Friend requests wait in one card on top (their stamps, a count). Today and Earlier; unread rows tinted, a dot. People show their stamp; a capsule shows its photo as a stamp and as a thumbnail on the right; a place alert shows the pin; a new passport stamp shows the stamp. "Follow back" inline. | `notifications/notifications_page.dart` |
| Settings | `7188:917` | the gear | Starts with your postcard (cover, stamp, name, "Edit profile"). Then Account (username, email, password), Notifications and privacy (notifications, Places alerts, who sees my capsules, blocked), This phone, Support, Log out and Delete account in red. | `settings/settings_page.dart` and its pages |
| Edit profile | `7188:1035` | Settings, or a long press on your postcard | A live postcard: "Change cover" on the photo, a camera badge on the stamp (photo, shape, colour). Fields: name, username (available / taken), About me with a 150 counter, home town. Rows: cover photo, your photo, stamp. "Remove cover photo". Save in the title bar. | replaces `profile_customization_settings_page.dart`, `name_settings_page.dart` and the profile image editor entry |
| Your Later card, front | `7189:723` | the share button | The same postcard as the profile with the Later logo and your link. "Tap the card to turn it over" with two dots. Share, Save image, Copy link; Scan a friend's code. | `profile/share/share_profile_page.dart` |
| Your Later card, back | `7189:812` | tapping the card (3D flip, 400 ms) | A written postcard: your About me on ruled lines, signed; your stamp; a postmark with today and your town; the QR code; name, username, link on address lines. | new |
| Share sheet | `7189:917` | Share | Friends in Later first (their stamps, then All), then Save image, Copy link, More apps. The image has both sides. | new (today: the system sheet) |
| A friend's menu | `7189:1113` | ≡ on a friend's profile | Their stamp, "Friends since …". Pin to my profile, Share their card, Mute notifications from them, Remove friend, then Block and Report in red. | `friends/pages/your_friend_profile_page.dart` |

## From the widgets (section `7190:777`)

| Page | Frame | Reached from | What it shows | In the app today |
|---|---|---|---|---|
| My capsules | `7190:778` | the My capsules row | The three numbers (capsules, places, with friends), search, filters (All, Opening soon, Opened, Locked), List or Map, Opening soon then Opened (v2 capsule cards), a floating New capsule button. | `history/history_page.dart` |
| A capsule for a friend | `7190:913` | Send a capsule on a friend's profile | The v3 Create page with "To" filled: the friend's stamp in a chip, "+ Add someone". Photo with Retake, title, a few words, how it opens, who sees it ("Only Bob"), "Send to Bob". | the Create page (capsule v3) with a recipient |
| My friends | `7190:972` | the My friends row | Search with QR. "Pinned on your profile" (the five, Edit, an empty Pin slot). Everyone A to Z with stamps; ⋯ opens the friend's menu. A count at the end. | `friends/pages/my_friends_page.dart` |
| Pin a friend | `7190:1239` | the Pin slot or Edit | A sheet: "Pin to your profile, 4 of 5 pinned", search, a grid of stamps; pinned ones carry their order number. Done. | `friends/pinned_friends_controller.dart` (no picker page yet) |
| Add friends | `7191:906` | the Add friends row | Search by username. Two tiles: Share your Later card, Scan a friend's code. Requests (count) / Suggested. Requests: Accept, Not now. Suggestions: + Add or Requested, with a reason ("Bob's friend", "2 in common"). | `friends/pages/add_friends_page.dart`, `friend_requests_page.dart` |
| Achievements | `7191:1084` | the Achievements card | The streak card on top (to its page). "3 of 12". Three groups (Capsules, Places, Friends) of three marks each in this drawing; a ring shows progress, a filled mark is done. | `achievements/achievements_view.dart` |
| One achievement | `7191:1169` | a mark | A sheet: the mark large, what it asks, a bar ("16 of 20, 4 to go"), friends who have it (stamps), a link to the Passport where it fits. | new |
| Streak | `7191:1271` | the streak row | The flame and the count, hours left today. This week (done days filled, today dashed). The month. Best streak, a daily reminder switch. Make a capsule. | `achievements/streak_flame.dart`, `streak_pill.dart` (no page yet) |

## The Passport, further (section `7192:977`)

The owner likes the Passport (page 8) and asked for it to grow. Four new pages, same booklet and colours.

| Page | Frame | What it shows |
|---|---|---|
| Visas | `7192:980` | After the stamps: a visa per country (colour band, first entry, towns and capsules, a machine-readable line). Tap one for its towns. |
| Your year | `7192:1157` | The last page, from December and on the first open of a new year: the year in big type, countries / towns / capsules, the year's stamps on a month line, longest away, most capsules, new this year, your About me. Shareable. |
| You and a friend | `7192:1306` | From a friend's profile: both stamps, what you both have (stamps), only them, only you, and "Make a capsule for Bob in Iceland?". |
| Share a page | `7192:1508` | Any page goes out as an image: send to a friend in Later, save, more apps. |

## Open questions for the owner

1. The friend's Places: the friend profile has no Places card today; "You and a friend" needs an entry
   (a Places row on their profile, or in their menu).
2. Achievements: the drawing shows nine marks in three groups and "3 of 12" (as Profile v2 does); the
   catalogue (`achievement_catalog.dart`) has thirteen, from first_capsule to curious. The groups and
   the count follow the catalogue when built.
3. Streak reminder: a new local notification (this phone only) or part of the existing notification settings.
