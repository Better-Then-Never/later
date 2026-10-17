# COMPONENTS.md: building blocks added or changed

## Theme and language
- `AppPalette` (`context.palette`): every colour that changes with the theme (surfaces, text, greys, dividers,
  shadows, highlights). `AppColors` now holds only theme-invariant colours (brand, accents, content on colour and
  on photos). Candidates `darkCharcoal` (in use), `darkForest`, `darkSlate`; `--dart-define=DARK_PALETTE=forest|slate`.
- `context.l10n` / `AppL10n.current` (`core/l10n/l10n.dart`); fragments per area in `tool/l10n/fragments/<area>`;
  `node tool/l10n/unused_keys.js` lists keys nothing uses.
- `AppearanceController` (theme, language, UI size), `UiScaleView` (whole-app scale), `ThemedAssetBundle`
  (dark icon set).
- `FeatureFlags` (`core/config/feature_flags.dart`): a feature's UI, settings and notification switches go together.

## Images
- `AppImageCache` (`data/services/app_image_cache.dart`): one disk cache manager, `decodeWidth` buckets,
  `provider(url, width)`, `evict`, `clear`.
- `AppNetworkImage`: photo with skeleton + fade-in, decode width from `cacheWidth` or the layout.
- `NetworkPicture` (in `user_profile_image.dart`): avatars/backgrounds; `UserProfileImage` / `UserBackgroundImage`
  show the skeleton while the URL lookup runs, the placeholder drawing only when there is no picture.
- `UserRoundAvatar.listRadius(width)`: list avatars that stay round inside `ListTile`.

## Sheets and menus (F-32)
- `showCenteredSheet` / `showEdgeSheet` (`shared/widgets/app_sheets.dart`): the only two ways to open an overlay;
  `EdgeSheet`, `SheetHandle`, `AppSheets.radius` / `cardWidth`.
- `OptionsMenuTitle`; `OptionsMenuItem.trailing`; `ConfirmDialog.message`; `MenuItemNode.selected`;
  `NestedMenu` rebuilt on the menu card (animated size between levels).
- `DefaultIconButton.semanticLabel`.

## Settings
- `SettingsChoiceRow` gained `subtitle`.
- `AppearanceSettingsPage`, `LanguageSettingsPage`, `PrivacySettingsPage`.

## Map
- `MapStyles.dark`; `NavbarWidget.coveredHeight(context)` (padding for anything floating above the bar);
  `_MyLocationButton`; the capsule card (`AnimatedSwitcher` above the bar, closes on tap/swipe/back/tab/zoom-out).
- `MarkerIcons.load(dark:)`.

## Capsules
- `CapsuleDetailDialog.show(context, capsule, onPlaceTap:)`: the one way to open a capsule (map, chat).
- `CapsuleSocialController`, `CapsuleSocialPanel`, `CapsuleReactionsBar`, `CapsuleCommentsSheet`, `reportFlow`.

## People
- `VerifiedName` (name + badge in rows); `UserNameAndUsername(showCounts:)` (badge + follower counts).
- `FriendSuggestionsController(friends:)`: friends of friends with `mutualCount`.

## Achievements
- `AchievementCatalog`, `AchievementIcon`, `AchievementStanding`, `AchievementsPanel`, `StreakChip`,
  `AchievementsPage`.

## Notifications
- `NotificationTexts` (sentences per type), `NewsTopics` (+ `TopicSubscriber`), `AppTabs` (tab indexes).

## Data
- `SocialRepository` (reactions, comments, reports, achievements, announcements) + `FakeSocialRepository`.
- `UserStats` (`streakAt`, `extendedToday`), `PrivacySettings`, `LocationPrecision`, `ReactionType`,
  `CapsuleComment`, `UnlockedAchievement`, `Announcement`, `ReportTarget`, `ReportReason`.
- `FirestoreMappers.legacyCapsule` / `notificationKeysAdded`: the fallbacks for older rules.

## Tools
- `tool/contact_sheet.dart` (screenshot sheets), `tool/perf_table.dart`, `integration_test/perf_test.dart`,
  `tools/admin/*` (admin claim, verified, announce, backfill).
