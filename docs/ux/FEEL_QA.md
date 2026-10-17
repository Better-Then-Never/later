# FEEL_QA.md: how it feels, screen by screen

> **Superseded for the phone** by `docs/feel/FEEL_QA.md` (checked on a Galaxy S20 FE, PR #79). This page is the
> night session's emulator pass and stays as it was.

Checked by hand on the emulator (dark theme, English and Russian). ✓ = good, △ = acceptable with a note,
✗ = still rough (in IDEAS_NOT_DONE.md).

| Screen | Feel | Notes |
|---|---|---|
| Launch | ✓ | Splash = first frame, no white flash, logo does not jump. |
| Welcome / Login | ✓ | Dark looks native; fields readable; "Get Started" button text scales down in long languages. |
| Permission steps | ✓ | Three, each skippable; no longer a wall before the app. |
| Map | ✓ | Dark style calm and on-brand; markers memoized (no re-send on position updates); logo always visible; my-location button flies smoothly. Zoomed out, a calm brand-green density glow; zoomed in, markers only (D-19). |
| Capsule card | ✓ | Slides up, closes the way people expect (tap, swipe, back, tab, zoom-out). |
| Capsule dialog | ✓ | Reactions respond instantly (optimistic), green tint on the chosen one. The photo opens full screen (zoom, drag to close). △ the card keeps its original 45%-height layout (design reference). |
| Comments | ✓ | Sheet with grab handle, composer above the keyboard, "Just now" times, replies indented. |
| Creation | ✓ | Header pinned, new switches clear; asks for location when needed; offline save is instant (pending pill). Privacy, colour and date open the menu card with every option; date presets mean the calendar is rarely needed. △ "Pick a date…" still opens the stock (themed) calendar. |
| Camera | ✓ | Starts on first use; pinch zoom with a 1.8× hint, tap-to-focus ring, haptic + blink on the shutter. Flash cycles off/auto/on. |
| History | ✓ | Photos from disk after restart; labels fit in all languages. Reset has its own clear icon. Sort/Filter are the app's menu card and show the current choice; place pills never empty; empty and no-match states offer the next step. |
| Messages / Chat | ✓ | Re-entering a chat shows the last messages at once; read receipts respect the privacy switch. Hold a message: menu card with Reply/Copy/Delete, a light haptic, no keyboard popping back. Swipe right to reply: the bubble follows the finger, ticks at the threshold and springs back. Tapping a quote scrolls to the message and lights it briefly. Checked in light and dark. |
| Profile | ✓ | Scrolls now; counts and verified badge; achievements card with streak. |
| Achievements | ✓ | Clear levels and progress bars; goals written as actions. |
| Add friends | ✓ | Suggestions from friends of friends with mutual counts; no list of strangers; built lazily. |
| Friend's profile | ✓ | Their capsules (open ones open in place, locked ones on the map), achievements, readable header. |
| Friend requests | ✓ | Same tab look as Notifications. |
| Settings | ✓ | Appearance, Language, Privacy pages follow the existing settings look; theme switch crossfades. |
| Russian / German | △ | Texts fit (several shortened after checks); Cyrillic uses the system font (BLOCKERS.md). |

Reduced motion: the app's motion widgets honour the system setting (`AppMotion.of`, `AppPressable`).
