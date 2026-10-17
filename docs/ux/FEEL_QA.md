# FEEL_QA.md: how it feels, screen by screen

Checked by hand on the emulator (dark theme, English and Russian). ✓ = good, △ = acceptable with a note,
✗ = still rough (in IDEAS_NOT_DONE.md).

| Screen | Feel | Notes |
|---|---|---|
| Launch | ✓ | Splash = first frame, no white flash, logo does not jump. |
| Welcome / Login | ✓ | Dark looks native; fields readable; "Get Started" button text scales down in long languages. |
| Permission steps | ✓ | Three, each skippable; no longer a wall before the app. |
| Map | ✓ | Dark style calm and on-brand; markers memoized (no re-send on position updates); logo always visible; my-location button flies smoothly. △ heatmap glow still bright (F-16). |
| Capsule card | ✓ | Slides up, closes the way people expect (tap, swipe, back, tab, zoom-out). |
| Capsule dialog | ✓ | Reactions respond instantly (optimistic), green tint on the chosen one. △ the card itself is the old 45%-height layout. |
| Comments | ✓ | Sheet with grab handle, composer above the keyboard, "Just now" times, replies indented. |
| Creation | △ | Header pinned, new switches clear; asks for location when needed; offline save is instant (pending pill). Still the cycling pills and stock date picker (F-27/F-28). |
| Camera | ✓ | Starts on first use; pinch zoom with a 1.8× hint, tap-to-focus ring, haptic + blink on the shutter. △ flash has on/off only. |
| History | ✓ | Photos from disk after restart; labels fit in all languages. Reset has its own clear icon. Sort/Filter are the app's menu card and show the current choice; place pills never empty. |
| Messages / Chat | ✓ | Re-entering a chat shows the last messages at once; read receipts respect the privacy switch. Hold a message: menu card with Reply/Copy/Delete, a light haptic, no keyboard popping back. Swipe right to reply: the bubble follows the finger, ticks at the threshold and springs back. |
| Profile | ✓ | Scrolls now; counts and verified badge; achievements card with streak. |
| Achievements | ✓ | Clear levels and progress bars; goals written as actions. |
| Add friends | ✓ | Suggestions from friends of friends with mutual counts; no list of strangers; built lazily. |
| Friend's profile | ✓ | Their capsules (open ones open in place, locked ones on the map), achievements, readable header. |
| Friend requests | ✓ | Same tab look as Notifications. |
| Settings | ✓ | Appearance, Language, Privacy pages follow the existing settings look; theme switch crossfades. |
| Russian / German | △ | Texts fit (several shortened after checks); Cyrillic uses the system font (BLOCKERS.md). |

Reduced motion: the app's motion widgets honour the system setting (`AppMotion.of`, `AppPressable`).
