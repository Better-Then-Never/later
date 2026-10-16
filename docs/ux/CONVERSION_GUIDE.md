# CONVERSION_GUIDE.md: colours to the theme, strings to five languages

The rules every feature folder follows when it moves to dark mode and localization. The shared layer
(`lib/shared`, `lib/core`, `lib/app`) is already converted and is the reference.

## Scope of a conversion
Only two things change in a feature folder: colours and user-visible strings. **The light theme must look exactly
the same** (same values; goldens and screenshots are compared). No redesign, no renames, no behaviour changes.
Do not edit files outside your folder(s), except adding the keys for your area under
`tool/l10n/fragments/<area>/` and updating tests under `test/` that assert on your strings.

## 1. Colours
Theme-dependent colours come from `context.palette` (`lib/core/theme/app_palette.dart`). Colours that are the
same in both themes stay in `AppColors`. Mapping (light values are identical, so nothing changes in light):

| Old | New | Notes |
|---|---|---|
| `AppColors.pageBackground` | `context.palette.background` | |
| `AppColors.pageBackgroundAlt`, `grey100` | `context.palette.backgroundAlt` | |
| `AppColors.white` / `surface` as a card, header, sheet, dialog, input or button background | `context.palette.surface` | |
| `AppColors.white` / `textOnPrimary` as text or icon **on** green, red, blue, yellow fills | `AppColors.onAccent` | stays white in dark |
| `AppColors.white` / `white70` over a **photo** or the camera | `AppColors.onMedia` / `onMediaMuted` | |
| `AppColors.black` / `textPrimary` as text | `context.palette.textPrimary` | |
| `AppColors.black` as an icon tint | `context.palette.icon` | |
| `AppColors.black` as a background over photos/camera, `black45`, `black87` | `AppColors.mediaBlack`, `mediaScrim`, `mediaScrimStrong` | |
| `AppColors.textSecondary` / `textTertiary` / `textFaint` | `context.palette.textSecondary` / `textTertiary` / `textFaint` | |
| `AppColors.grey600`, `textMuted` | `context.palette.textMuted` | |
| `AppColors.grey500`, `iconGrey` | `context.palette.iconMuted` | also for disabled text (same value) |
| `AppColors.grey400` | `context.palette.disabled` | |
| `AppColors.grey300`, `placeholderGrey` | `context.palette.skeleton` | |
| `AppColors.grey200`, `surfaceMuted` | `context.palette.surfaceMuted` | |
| `AppColors.grey700`, `grey800`, `popupDefault` | `context.palette.textSecondary` (text) / `toastNeutral` (fill) | judge by use |
| `AppColors.divider`, `pill`, `emptyAvatar`, `emptyBackground` | same name on `context.palette` | |
| `AppColors.barrier` | `context.palette.scrim` | |
| `AppColors.shadowCard`, `shadowRaised`, `shadowHeader` | `context.palette.*` (or `AppShadows.card(context)` etc.) | |
| `selectedNotification`, `unreadNotification` | `context.palette.selectedHighlight`, `unreadHighlight` | |
| `selectedCapsule`, `infoCardFill`, `infoCardBorder` | same name on `context.palette` | |
| brand and accent colours (`brandGreen`, `danger`, `materialRed`, `infoBlue`, `placeYellow`, ...) | unchanged `AppColors.*` | |

Helpers changed signature: `BoxDecorations.whiteCard(context, ...)`, `greyCard(context)`,
`softBlackShadow(context)`, `lightBlueInfo(context)`, `AppShadows.card(context)` / `raised` / `mapInfo` / `softCard`,
`AppTextStyles.pageTitle(context)` / `pageDescription(context)` / `listName(context)`.

Values used in a `const` expression stop being constant. After converting a file run
`flutter analyze > /tmp/a.txt; node tool/fix_const.js /tmp/a.txt` (repeat until it removes nothing), then
`dart fix --apply --code=prefer_const_constructors lib/features/<area>` and `dart format`.
Default parameter values cannot read the theme: make the parameter nullable and resolve it in `build`.
Material `Icon(..., color: AppColors.black)` becomes `context.palette.icon`. Hand-drawn PNG icons need nothing:
`ThemedAssetBundle` swaps them.

## 2. Strings
Every string a user can see moves to localization: labels, hints, titles, buttons, toasts, errors, empty states,
semantics labels, dialog texts, enum labels, plurals, dates. Not: log messages, keys, asset paths, URLs.

- Keys live in `tool/l10n/fragments/<area>/<lang>.json` for `en`, `ru`, `pl`, `de`, `es` (create the folder; flat
  JSON). `en.json` holds the English text plus `"@key": {"description": "...", "placeholders": {...}}` where a
  placeholder or plural is used. Keys are camelCase and start with the area name (`settingsTitle`,
  `friendsRequestSent`, `chatInputHint`). Reuse `common*` keys (Cancel, Save, Delete, Close, Try again,
  Loading..., Continue, Done, Back, errors) instead of duplicating them.
- Placeholders: `"chatTyping": "{name} is typing"` with `"@chatTyping": {"placeholders": {"name": {"type": "String"}}}`.
- Plurals (ICU): `"friendsCount": "{count, plural, =0{No friends} =1{1 friend} other{{count} friends}}"` with
  `"placeholders": {"count": {"type": "int"}}`. Russian and Polish need `one`, `few`, `many`, `other`.
- Translate into Russian, Polish, German and Spanish yourself, naturally and idiomatically (not word by word),
  following `docs/ux/GLOSSARY.md` (terms and the informal/formal address). Keep the same placeholders.
- After editing fragments: `dart run tool/l10n/build_arb.dart && flutter gen-l10n`.
- Widgets: `context.l10n.key` (import `core/l10n/l10n.dart`). Code without a context (controllers,
  repositories, enum labels, failure messages): `AppL10n.current.key`.
- Dates/times: `DateFormat(pattern, Localizations.localeOf(context).toLanguageTag())` or the named
  constructors (`DateFormat.yMMMd(locale)`); never English-only patterns for words (weekday and month names).
- Strings inside `const` widgets: drop the `const` (see above).
- Tests that pump widgets need localizations: use `testApp(home: ...)` from `test/helpers/test_app.dart` (English).
  Tests asserting English text keep working because the test locale is English.

## 3. Checks before you finish
`dart run tool/l10n/build_arb.dart && flutter gen-l10n`, `dart format lib test`, `flutter analyze` (zero issues),
`flutter test` (all pass; `test/l10n` checks that every language has every key with the same placeholders),
`dart run tool/check_design_tokens.dart`. Then `grep -rn "AppColors\.\(white\|black\|grey\|surface\|page\|text\|divider\|barrier\|shadow\|placeholder\|pill\|empty\|selected\|unread\|infoCard\|popup\|icon\)" <your folders>` must be empty.
