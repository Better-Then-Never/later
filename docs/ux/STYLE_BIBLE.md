# STYLE_BIBLE.md: how Later looks, moves and talks

Written before any feature work, from the code (`lib/core/theme`, `lib/shared`), the extracted spec
(`docs/refactor/DESIGN_SPEC.md`), the polish decisions (`docs/polish/DESIGN_DECISIONS.md`) and the screenshots of
the running app (`docs/polish/after/*.png`, which are this mission's baseline, see `baseline/README.md`).
Every new or changed screen is checked against the conformance checklist at the end.

## 1. Character in one paragraph
Later is **light, flat, rounded and playful**, with a hand-made touch. Off-white pages, white cards that float on
soft shadows with big 25 px corners, one saturated **brand green** (`#56C92E`) that means "do it" (primary
buttons, the selected tab pill, toggles, success), a sunny **yellow** pill for places, and **hand-drawn icons**:
thick marker strokes in black or brand green, sometimes with white fills and a few bright dots (blue `#42A5F5`,
yellow, green). The font is **Inria Sans** (registered as `Irina`): friendly, slightly calligraphic, bold for
anything that matters. The mood is the early-iOS-7 kind of friendly: bright, uncluttered, nothing glossy, no
heavy gradients on chrome, no glassmorphism, no neon. The only gradients are content placeholders.

## 2. Palette (exact values and roles)
| Role | Value | Where |
|---|---|---|
| Brand green | `#56C92E` | primary buttons, selected segment/tab pill, toggles, links ("Forgot password?"), date pill, success toast, unread badge (chat) |
| Place yellow | `#FFD900` | location pill on capsules |
| Danger | `#FD4140` | destructive actions, Log Out, Delete account, error states in menus |
| Material red | `#F44336` | favourite heart, count badges, "Opens in" |
| Info blue | `#2196F3` | info toast, unread notification dot |
| Page background | `#F6F6F6` (`#F5F5F5` on settings and creation) | every page |
| Surface | `#FFFFFF` | cards, headers, nav pill, dialogs, sheets |
| Muted surface | `#EAEAEA` | search bars, grey pills, nested menu |
| Divider | `#D3D3D3` | list dividers |
| Text | `#000000` primary, `#5E5E5E` secondary, `#757575` muted, `black54` faint | |
| Skeleton / placeholder | `#E0E0E0` | loading rows, empty images |
| Scrim | black at 50 % | modal barriers |
Capsule colours (red, blue, green, yellow, orange, purple) exist only as the pin artwork and capsule gradients.
Everything is a token in `lib/core/theme/app_colors.dart`; `tool/check_design_tokens.dart` fails on raw colours.

## 3. Typography
- One family, two weights that matter: **bold** for titles, names, buttons and row titles; regular for body.
- Sizes scale with the screen (the look depends on it): page title `0.04·h` bold, header description
  `0.017·h` bold secondary, row titles `0.045·w` bold, usernames `0.04·w` secondary. Fixed sizes: 14 body,
  16 dialog buttons, 17 menu options, 18 section titles, 25 dialog titles, 32 auth buttons, 40 auth headings.
- No letter spacing except the auth headings (−1). Sentence case for body and descriptions; Title Case for a few
  short actions ("Log In", "Get Started", "Log Out").

## 4. Shape, spacing, elevation
- Radii: **25** dominant (cards, buttons, inputs, header bottoms, dialogs), 30 nav pill, 20 menus and preview
  images, 17 history thumbnails, 15 permission cards, 12 square avatars, 10 toasts and badges, 8 small pills.
- Spacing: 4/8 grid in tokens (`AppSpacing` 2–24); the classic gutters are 16 px and `0.04·w`.
- Elevation is shadow, not borders: `card` (black12, blur 9, offset 0/4) for white cards; `raised` (black26,
  blur 10) for the nav pill and floating cards. No outlines on cards.

## 5. Iconography
- Hand-drawn PNG line art (`assets/icons/<screen>/`, typed via `AppIcons`), thick round strokes, black or brand
  green, optional white fill and bright dots. Sizes follow their context (nav 46 px, header buttons ~0.11·w).
- Material icons appear only where the original design used them (allow-listed in the token check); new UI uses
  the existing hand-drawn set first.
- **Dark theme consequence:** icons cannot simply be tinted (white fills and colour dots would be lost). Dark
  variants invert only the achromatic pixels (black stroke becomes light, white fill becomes dark) and keep the
  coloured ones; see DECISIONS.md.

## 6. Components (as the app draws them)
- **Page header:** white, bottom corners 25, centred bold title, back arrow (hand-drawn) on the left, optional
  description line, search bar or segmented control inside.
- **Buttons:** primary = brand-green pill (radius 25), white bold text, press scale 0.97; destructive = danger
  red pill; text buttons are bold black text.
- **Cards and rows:** white card, radius 25, `card` shadow; rows are bold title + secondary subtitle + hand-drawn
  arrow (`goHere` at 30 % opacity) on the right; dividers `#D3D3D3`.
- **Segmented control:** the notifications filter: a brand-green pill slides behind the selected label, label turns
  white and bold, others black regular. **This is the motion reference.**
- **Menus and confirmations:** centred white cards (`showCenteredSheet`, 264 wide, radius 25) with 17 px bold
  options separated by dividers, an optional green title with a green rule (`OptionsMenuTitle`), destructive
  options in danger red, the current choice in green, a chevron for a submenu; confirm dialog = title, optional
  message, coloured confirm pill (red when destructive, green otherwise), grey "Cancel" text.
- **Sheets:** lists and threads come from the bottom edge (`showEdgeSheet` + `EdgeSheet`): rounded top 25, grab
  handle, page background. No stock `AlertDialog`s; the only `showDialog` is the capsule viewer
  (`CapsuleDetailDialog`), which fades in like opening a photo.
- **Toasts:** rounded 10, coloured (green success, red error, blue info), slide and fade in at top, centre or bottom.
- **Avatars:** circles for people in lists and chat, rounded squares (radius 12) on profiles.
- **Empty states:** hand-drawn icon (72), bold title, grey subtitle, optional green action.
- **Nav pill:** floating white pill (radius 30, `raised` shadow) with five hand-drawn icons, the centre "add"
  icon larger; the selected icon grows (×1.2) with a 200 ms ease.

## 7. Motion character
Quick and playful, never slow: 100–350 ms (`AppMotion`), ease-out on enter, ease-in on exit, the sliding
green pill as the signature move, a 0.97 press scale, 150 ms page fades. Things **slide and grow**, they do not
bounce wildly or spin. Reduced motion turns movement into instant changes.

## 8. Voice
Short, warm, second person, no jargon: "You have no friends yet", "Find capsules...", "Choose how your friends
will see you". Exclamation marks are rare and earned. Errors say what happened and what to do.

## 9. This app never...
- uses a second font, a new colour family, outlined Material icons in new UI, glass blur or neon gradients;
- shows grey boxes where content will be (it shows shaped skeletons or gradient placeholders);
- shows a control that does nothing;
- uses sharp corners on cards, buttons or inputs;
- puts text directly on a coloured background without the white/black contrast pairing above;
- animates with linear curves or for longer than 350 ms (except continuous loops such as the loading logo);
- hides the Google logo on the map (it moves it instead).

## 10. Conformance checklist (every new or changed screen)
- [ ] Colours only from tokens (light and dark), no raw values (token check passes).
- [ ] Shared components only (header, buttons, rows, sheets, avatars, empty/error/loading states).
- [ ] Icons from the hand-drawn set (or allow-listed Material where the design already does).
- [ ] Motion from `AppMotion`, reduced motion respected.
- [ ] All copy through localization (5 languages), no overflow in German or at 1.3× text.
- [ ] States complete: loading (shaped skeleton), empty, error, offline.
- [ ] Tap targets ≥ 44×44, instant press feedback.
- [ ] Checked on the running app in light and dark.
