# DESIGN_DECISIONS.md — the design system as enforced by the polish mission

The visual language is the one documented in `docs/refactor/DESIGN_SPEC.md` (reverse-engineered from the original
app). This file records the token inventory as it is now, every token added by this mission (each one a value the
app already used), and every judgement call. Enforcement: `dart run tool/check_design_tokens.dart` (also run by
`.github/workflows/pr-build.yml`).

## 1. Colours (`lib/core/theme/app_colors.dart`)
Brand/accent, surface, text, selection, overlay and heatmap tokens as in DESIGN_SPEC §2.

**Added (value-identical names for colours screens already used as raw `Colors.*`):**
| Token | Value | Was |
|---|---|---|
| `white`, `black` | `#FFFFFF`, `#000000` | `Colors.white` (72×), `Colors.black` (54×) |
| `black45`, `black87`, `white70` | `#73000000`, `#DD000000`, `#B3FFFFFF` | `Colors.black45/87`, `Colors.white70` |
| `grey100`…`grey800` | Material grey 100/200/300/400/500/600/700/800 | `Colors.grey[n]`, `Colors.grey.shadeN`, `Colors.grey` (= `grey500`, same value as `iconGrey`) |
| `infoBlue600`, `infoBlue700` | `#1E88E5`, `#1976D2` | `Colors.blue[600/700]` (share profile info card) |

Existing tokens absorbed the rest: `Colors.red` → `materialRed`, `Colors.blue` → `infoBlue`, `Colors.blue.shade50/100`
→ `unreadNotification`/`selectedNotification`, `Colors.orange` → `warningOrange`, `black12/26/54` →
`shadowCard`/`shadowRaised`/`textFaint`, black α128 → `barrier`, black α120 → `shadowHeader`. 217 replacements in
75 files (codemod); golden tests unchanged.

**Merged:** the history tile's "created" pill used `#55C92E`, one unit off `brandGreen`. DESIGN_SPEC already merged
that value elsewhere; it now uses `brandGreen` (golden updated: 2,495 channel values changed by exactly 1/255).

## 2. Typography (`lib/core/theme/app_text_styles.dart`)
Family `kAppFontFamily` ("Irina" = Inria Sans 400/700/italic). 37 hard-coded `fontFamily: 'Irina'` literals now use
the constant. Screen-relative sizes remain part of the look (DESIGN_SPEC §3).

## 3. Shape, spacing, shadows
`AppRadii`, `AppSpacing`, `AppShadows` (`app_dimens.dart`) as in DESIGN_SPEC §4–6.

## 4. Icons
Custom hand-drawn PNGs through `AppIcons` (`lib/core/assets/app_assets.dart`); inventory in ICONS.md. Material icons
that are part of the original design (history hearts and selection bars, notification selection bar, toasts, share
page, QR flash, follow bell, filter menu) are kept and listed in `tool/design_tokens_allowlist.txt`; new Material
icons fail the check.

## 5. Motion (`lib/core/theme/app_motion.dart`, `lib/shared/motion/`)
Character of the original app: quick and subtle; ease-out to enter, ease-in to leave, ease-in-out for in-place
changes, fast-out-slow-in for size changes. The tokens are exactly the values it already used:

| Token | Value | Used for | Was |
|---|---|---|---|
| `quick` | 100 ms | press feedback, navbar icon scale | navbar icon scale (10 ms, i.e. a jump), add-friends slide |
| `fast` | 150 ms | page transitions, cross-fades | header switcher (150 ms); pages were a 10 ms fade |
| `standard` | 200 ms | state changes (navbar selection, list item enter) | navbar (200 ms) |
| `emphasized` | 250 ms | size changes, sheets (Material default) | page header resize (250 ms) |
| `slow` | 300 ms | toasts, scroll to latest, selection bar | popup, notifications bar, chat scroll (300 ms) |
| `reveal` | 350 ms | permission gate pages | permission gate (350 ms) |
| curves `enter`/`exit`/`standardCurve`/`emphasizedCurve` | easeOut / easeIn / easeInOut / fastOutSlowIn | | the same |
| `pressedScale` | 0.97 | press feedback | — |

Shared widgets: `AppPressable` (scale to 0.97 while pressed; on every shared button and the navbar),
`AppFadeSwitcher` (cross-fade between loading/content/empty/error), `AppEnter` (fade + small lift for items that
just arrived). **Reduce motion:** with the system's "remove animations" setting (`MediaQuery.disableAnimations`),
page transitions are instant, `AppPressable` adds nothing, `AppEnter` shows at once and `AppMotion.of(context, d)`
returns zero for the in-place animations. `raw-duration` in the token check blocks new hard-coded animation
timings.

## 6. Decision log
- **D-01 Tokens over raw values.** Every colour outside `core/theme` is a token; the check script keeps it that way.
  Material greys became tokens instead of being snapped to the nearest existing token, so nothing changes visually.
- **D-02 Allow-listed debt.** Raw animation durations (until the motion tokens exist) and the chat port's Material
  icons are allow-listed with TODO markers; the script reports stale entries, so removing the debt is enforced.
- **D-03 One page transition.** Every push now fades in 150 ms (`AppMotion.fast`); "Add friends" keeps its
  slide-up with the same timing. Before: a 10 ms fade (an instant swap) for most pages, 100 ms slide-up for one,
  and the Android platform transition (about 300 ms zoom) for the camera and signup. The 150 ms fade keeps the quick,
  subtle character and removes the hard cut.
- **D-04 Press feedback.** No consistent feedback existed (some buttons had an ink splash, menus had none). A 0.97
  scale in 100 ms on the shared buttons and the navbar matches the navbar's own scale animation.
- **D-05 Near-duplicates snap to tokens.** `Color.fromARGB` / `fromRGBO` literals slipped past the first check
  (it only matched `Color(0x…)`); a `raw-argb` rule now catches them. Values within 2/255 of a token became the
  token: `#5F5F5F` dialog buttons → `textSecondary` (`#5E5E5E`), `#E2E2E2` QR frame → `grey300` (`#E0E0E0`), the
  image menu's red at alpha 253 → `danger` (golden updated, 1 % of pixels by 1/255). The QR scanner overlay was
  `fromRGBO(0, 0, 0, 80)`, which is opaque black (opacity is 0–1); kept as `black` so nothing changes.
- **D-06 Settings components.** Settings pages share `SettingsScaffold` (PageHeader + list + optional green
  button), `OptionsSection` (the existing label + white card of the Settings page), `OptionsSwitchRow` and
  `AppSwitch` (brand green on, `grey400` off; the permissions page used a raw green thumb on a grey track), and
  `SettingsChoiceRow` (the success toast's `check_circle` in brand green marks the chosen option). No new
  colours, radii or shadows.
- **D-07 No fake settings.** Language and App appearance were removed rather than kept as "coming soon": the
  app has no translations and no dark palette (IDEAS_NOT_DONE.md). Rows for a support email, privacy policy and
  terms appear only once the links exist (`lib/core/config/app_links.dart`, BLOCKERS.md B-01/B-02).
- **D-08 A fade behind the system buttons, not a blur.** The page colour fades in behind Android's navigation
  bar on the tab pages (`SystemBarFade`, G-03): 80 dp with three buttons, a 24 dp eased edge to 70 %, 80 % at the
  bottom, the same in light and dark (lighter after the owner saw it on the phone). The owner chose it over a frosted strip in Figma (20 Oct 2026); it costs nothing.
