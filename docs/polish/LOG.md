# LOG.md: interactive polish session, one entry per finished item

Branch `polish/interactive-fixes`. Newest last. Each entry: date, item, what changed, commit, how verified.

## 2026-10-18, M-01 Map control sizes
- **Was**: every map control was 52 dp (zoom pill halves, compass, my location, filter, the streak pill), heavy next
  to the markers.
- **Changed**: one token `AppSizes.mapControl` = 44 dp (the tap-target minimum) and `AppSizes.mapControlGap` = 10
  in `lib/core/theme/app_dimens.dart`, used by all five; insides scaled in proportion (icon padding 13 → 11 and
  10 → 8, filter dot 14 → 12, zoom signs and the compass needle drawn relative to the button, streak flame 20 → 17
  and number 18 → 16); the stacked positions use the gap token.
- **Verified**: phone (S20, debug): all five 132 px = 44 dp in the accessibility tree; light; dark + text 1.3
  (pill widens, stays 44 tall; compass needle scaled); controls lift above an open capsule card; tap audit: only
  markers cut off by the screen edge (known exception). Tests: map, compass (now checks the token and ≥ 44),
  moments, clusters, tap targets. No visible text changed, so no language check was needed.
