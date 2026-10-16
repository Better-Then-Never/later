# DESIGN_SPEC.md — the existing design, extracted

There are no design documents, Figma exports or theme files in the repository; this spec is reverse-engineered from the code (every widget file was read, see `audit/WIDGETS_AUDIT_A.md` §3 and `audit/WIDGETS_AUDIT_B.md` §3 for every literal with file:line) and from the baseline screenshots in `screenshots/before/`. **The refactor must reproduce these values exactly.** Values that differ by an invisible amount (≤ 1/255 per channel, or alpha 253 vs 255) are merged into one token; everything else keeps its own token even where it looks inconsistent, because changing it would change the look.

## 1. Brand & mood
Light, flat, rounded, playful. Off-white page backgrounds, white cards with soft shadows and 25 px corners, a saturated green as the single action colour, a yellow "place" pill, hand-drawn black line icons (PNG), the Inria Sans typeface, and a seasonal snowfall overlay over every screen.

## 2. Colours (tokens → `lib/core/theme/app_colors.dart`)

| Token | Value | Used for |
|---|---|---|
| `brandGreen` | `#56C92E` | primary buttons, active tab pill, date pill, links ("Forgot password?"), toggles, success popup, selected segment. `#55C92E` (2 sites) merged here (1/255 difference) |
| `placeYellow` | `#FFD900` | location/address pill |
| `danger` | `#FD4140` | destructive buttons (Reject, Cancel request, Confirm log-out/delete), "Log Out" row, Report/Block. `ARGB(253,253,65,64)` (2 sites) merged here |
| `materialRed` | `#F44336` (`Colors.red`) | favourite heart, "Opens in", request-count badge, "Remove from friends", notification badge default, QR error text — kept separate (visibly different from `danger`) |
| `redAccent` | `#FF5252` | selection action bars (delete) |
| `errorPopup` | `#FF5757` | error popup background, permission "denied" status |
| `infoBlue` | `#2196F3` | info popup, notification selection icons, unread dot, permission dialogs |
| `viewProfileBlue` | `#3690FF` | "View Profile" button |
| `neutralButton` | `#6C757D` | "My Profile" button |
| `pendingYellow` | `#FDDB07` | "Pending" button |
| `warningOrange` | `#FF9800` | permission "limited" status |
| `pageBackground` | `#F6F6F6` | most pages (welcome, auth, home, history, notifications, friends, profile, share) |
| `pageBackgroundAlt` | `#F5F5F5` | settings, settings sub-pages, capsule creation (kept separate: it is a different value) |
| `surface` | `#FFFFFF` | cards, headers, navbar, dialogs |
| `surfaceMuted` | `#EAEAEA` | search bars, grey cards, nested menu |
| `pill` | `#D9D9D9` @ alpha 217 (`0xD9D9D9D9`) | capsule settings value pills |
| `divider` | `#D3D3D3` | list/option dividers |
| `textPrimary` | `#000000` | |
| `textSecondary` | `#5E5E5E` | usernames, header descriptions, confirm-dialog cancel (`#5F5F5F` merged) |
| `textTertiary` | `#6A6A6A` | capsule creation pill text |
| `textMuted` | `#757575` (`grey[600]`) | empty-state subtitles, timestamps, request usernames |
| `textFaint` | `#8A000000` (`black54`) | descriptions, placeholder pages |
| `placeholderGrey` | `#E0E0E0` (`grey[300]`) | skeletons, avatar placeholders |
| `iconGrey` | `#9E9E9E` (`grey`) | inactive heart, locked button |
| `emptyAvatar` | `#DFDFDF` | own avatar without image |
| `emptyBackground` | `#BBBBBB` | own background without image |
| `selectedNotification` | `#BBDEFB` (`blue.shade100`) | selected notification card |
| `unreadNotification` | `#E3F2FD` (`blue.shade50`) | unread notification card |
| `selectedCapsule` | `#67CFFF` @ alpha 100 | selected history tile |
| `infoCardFill` / `infoCardBorder` | `#2196F3` @ 0.1 / @ 0.3 | share-profile info card |
| `barrier` | black @ alpha 128 | modal barriers |
| `popupDefault` | `#424242` (`grey[800]`) | neutral popup |
| Capsule colours | red/blue/green/yellow/orange/purple → pin assets | map pins, history pins |
| Map heatmap gradient | `Colors.green` 0.2 → `Colors.yellow` 0.5 → `Colors.red` 1.0, radius 50 px | map |

## 3. Typography (`lib/core/theme/app_text_styles.dart`)
- Family: **`Irina`** (files are Inria Sans Regular 400 / Bold 700 / Italic). The theme sets it globally; a few widgets omit it and inherit it. One widget misspells it as `Inria` (falls back to the system font; fixed as an obvious bug, BUG-087).
- No letter spacing anywhere except auth headings (`-1` on "Log In Now"/"Sign Up Now", `0.1` on their subtitles).
- Fixed sizes in use: 12, 14 (body default of `DefaultText`), 15, 16, 17 (modal options), 18 (section/list titles, selection bars), 20, 22, 25 (modal/dialog titles, capsule title input), 28 ("Get Started"), 30 (`DefaultGreenButton` default, FittedBox-shrunk), 32 (auth submit button, own-profile name), 35, 40 (welcome & auth headings), 50 (pill text, FittedBox-shrunk).
- **Screen-relative sizes are part of the current look** and are preserved as functions of the screen size (not converted to fixed sizes): page header title `0.04·h` bold, header description `0.017·h` bold `#5E5E5E`; settings row title `0.045·w` bold; list names `0.045·w` bold; usernames `0.04·w` / `0.035·w`; capsule tile title `0.04·w` w500; permission page title `0.095·w`; friend profile name `0.07·w` / `0.05·w`; empty inbox title `0.048·w` w900 / subtitle `0.033·w`.

## 4. Shape
| Token | Value | Notes |
|---|---|---|
| `radiusL` | 25 | dominant: cards, pills, buttons, inputs, dialogs, header bottoms |
| `radiusXL` | 30 | navbar, password-reset input |
| `radiusM` | 20 | nested menu, preview image, request toggle, invite pill |
| `radius17` | 17 | history thumbnail |
| `radius16` | 16 | own-profile header shade |
| `radius15` | 15 | share buttons, permission cards |
| `radiusS` | 12 | info card, square avatar |
| `radiusXS` | 10 | popup notification, badge |
| `radius8` | 8 | loading container, notification thumbnail, status pill |
| `radius5` | 5 | checkboxes |

## 5. Elevation & shadows (`lib/core/theme/app_shadows.dart`)
| Token | Spec | Used by |
|---|---|---|
| `card` | black12, blur 9, spread 1, offset (0,4) | white cards (`BoxDecorations.whiteCard`), options input |
| `softCard` | black12, blur 16, spread 1, offset (0,6) | add-friend main/handle buttons |
| `raised` | black26, blur 10, offset (0,4) | navbar, capsule preview card |
| `mapInfo` | black26, blur 8, offset (0,0) | map info window |
| `headerShade` | black α120, blur 20, spread 15, offset (0,6) on a 1 px bar | own profile header top shade |
| `subtle` | black α0.05, blur 5, offset (0,2) | permission cards; (blur 10 variant for notification selection bar) |
| `popup` | black α0.2, blur 8, offset (0,4) | popup notification |
| `selectedNotification` | blue α0.2, blur 8, offset (0,2) | selected notification |
Material elevations: 0 for styled ElevatedButtons, 8 for nested menu and round avatar, M3 default on `DefaultGreenButton`.

## 6. Spacing
Scale actually used: 1, 2, 4, 5, 6, 8, 10, 12, 14, 15, 16, 18, 20, 24, 40 px, plus many screen-ratio paddings (`0.01–0.07·w`, `0.004–0.04·h`). Content width on profile screens is `w − 32` (16 px gutters). Tokens: `xxs 2, xs 4, s 8, m 12, l 16, xl 20, xxl 24`, odd values kept inline where they occur.

## 7. Components (current inventory → target shared library)
| Current widgets | Target shared component |
|---|---|
| `PageHeader` (+ hand-built header in permissions page) | `AppPageHeader` (white, bottom radius 25, centred title `0.04·h`, optional leading/trailing, description, search bar, action row) |
| `DefaultGreenButton`, `SubmitButton`, `LogOutButton`, welcome "Get Started", permission "Enable", `DefaultButtonWithIcon`, share buttons, request action pills, confirm buttons | `AppButton` variants: `primary` (green, r25, white bold Irina), `pill`, `iconLabel`, `danger`; loading state with white spinner |
| `RegistrationInputField`, `OptionsInputField`, `DefaultSearchBar`, password-reset field | `AppTextField` (auth outline 1.5 black r25 h55 w325, options card, search bar `#EAEAEA` r25) |
| `ConfirmDialog`, friend options modal pieces, profile/background picture modals, pinned options dialog, password reset sheet | `showCenteredSheet()` + `AppOptionsCard` (264 wide, 37 px rows, 17 bold, 2 px `#D3D3D3` dividers, title variants) + `AppConfirmDialog` |
| `PopupNotification` + service | `AppToast` (unchanged visuals) |
| `LaterLoadingBar`, `WhiteCircularProgressIndicator`, `DefaultLoadingContainer`, invisible `Center()` loaders | `AppLoader` variants |
| `DefaultEmptyInboxInfo`, various empty texts | `AppEmptyState` |
| `UserListTile`, `SuggestedFriendRow`, request rows, pinned dialog tiles | `UserRow` (avatar + name + @username + trailing) |
| `UserRoundAvatar`, `UserSquareAvatar`, `UserProfileImage`, `NotificationAvatar`, `PinnedFriendAvatar` | `UserAvatar(shape: round/square)` backed by the profile image cache |
| `BoxDecorations.*` | `AppDecorations` built from tokens |
| `NavbarWidget` | `AppNavBar` (unchanged visuals) |
| Pills: datestamp, location label, cycled info, request count badge, unread badge | `AppPill`, `CountBadge` |
| Five identical "coming soon" settings pages | `ComingSoonPage(message)` |

## 8. Motion
Page transitions: 10 ms fade (effectively instant) for almost every push; 100 ms bottom-to-top for "Add friends"; Material default for the routes declared in `MaterialApp.routes`. Navbar: 200 ms easeInOut container, selected icon ×1.2 size × 1.1 scale. Page header: 250 ms fastOutSlowIn size, 150 ms switcher. Popup: 300 ms slide/fade, shown 2 s (3 s for some errors). Countdown timers tick every second.

## 9. Assets
85 files under `assets/` (icons as black/colour PNGs grouped by screen, a loading GIF, the Inria Sans fonts). See `audit/WIDGETS_AUDIT_*.md` §5 for every reference. The artwork is part of the design and is not replaced; only file locations/names change, through a typed accessor.

## 10. States per screen (as built)
Loading: `LaterLoadingBar` (animated logo GIF, 150×150) for app-level and map loading; spinners elsewhere; several invisible loaders. Empty: `DefaultEmptyInboxInfo` (icon 72, bold title, grey subtitle) for notifications/requests; plain text for history ("No capsules yet") and pinned friends. Error: popup toasts (red), snackbars on auth screens. Dark mode: not supported (light theme only) — out of scope.
