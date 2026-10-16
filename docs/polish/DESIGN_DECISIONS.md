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

## 5. Decision log
- **D-01 Tokens over raw values.** Every colour outside `core/theme` is a token; the check script keeps it that way.
  Material greys became tokens instead of being snapped to the nearest existing token, so nothing changes visually.
- **D-02 Allow-listed debt.** Raw animation durations (until the motion tokens exist) and the chat port's Material
  icons are allow-listed with TODO markers; the script reports stale entries, so removing the debt is enforced.
