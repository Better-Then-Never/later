import 'package:flutter/material.dart';

/// The colours that change between light and dark, by role. Widgets read them
/// with `context.palette`; colours that never change (brand green, accents,
/// white on green, overlays on photos) stay in `AppColors`.
///
/// [light] reproduces the original design exactly (DESIGN_SPEC.md §2).
/// [dark] is the chosen dark palette (docs/ux/DECISIONS.md D-03); the other
/// candidates stay here so the comparison can be repeated.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.backgroundAlt,
    required this.surface,
    required this.surfaceMuted,
    required this.pill,
    required this.divider,
    required this.cardBorder,
    required this.skeleton,
    required this.emptyAvatar,
    required this.emptyBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textMuted,
    required this.textFaint,
    required this.icon,
    required this.iconMuted,
    required this.disabled,
    required this.selectedHighlight,
    required this.unreadHighlight,
    required this.selectedCapsule,
    required this.infoCardFill,
    required this.infoCardBorder,
    required this.toastNeutral,
    required this.scrim,
    required this.shadowCard,
    required this.shadowRaised,
    required this.shadowHeader,
  });

  final Brightness brightness;

  /// Pages (`#F6F6F6`), and the slightly different settings/creation pages.
  final Color background;
  final Color backgroundAlt;

  /// Cards, headers, the nav pill, dialogs and sheets.
  final Color surface;

  /// Search bars, grey pills and nested menus.
  final Color surfaceMuted;
  final Color pill;
  final Color divider;

  /// Edge of cards: transparent in light (shadows carry elevation), a hairline
  /// in dark where shadows are invisible.
  final Color cardBorder;

  /// Skeletons and image placeholders.
  final Color skeleton;
  final Color emptyAvatar;
  final Color emptyBackground;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textMuted;
  final Color textFaint;

  /// Glyphs drawn in code (Material icons, the hand-drawn set is swapped by
  /// asset, see `ThemedAssetBundle`).
  final Color icon;
  final Color iconMuted;
  final Color disabled;

  final Color selectedHighlight;
  final Color unreadHighlight;
  final Color selectedCapsule;
  final Color infoCardFill;
  final Color infoCardBorder;
  final Color toastNeutral;

  final Color scrim;
  final Color shadowCard;
  final Color shadowRaised;
  final Color shadowHeader;

  bool get isDark => brightness == Brightness.dark;

  static const light = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFF6F6F6),
    backgroundAlt: Color(0xFFF5F5F5),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEAEAEA),
    pill: Color(0xD9D9D9D9),
    divider: Color(0xFFD3D3D3),
    cardBorder: Color(0x00000000),
    skeleton: Color(0xFFE0E0E0),
    emptyAvatar: Color(0xFFDFDFDF),
    emptyBackground: Color(0xFFBBBBBB),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF5E5E5E),
    textTertiary: Color(0xFF6A6A6A),
    textMuted: Color(0xFF757575),
    textFaint: Color(0x8A000000),
    icon: Color(0xFF000000),
    iconMuted: Color(0xFF9E9E9E),
    disabled: Color(0xFFBDBDBD),
    selectedHighlight: Color(0xFFBBDEFB),
    unreadHighlight: Color(0xFFE3F2FD),
    selectedCapsule: Color(0x6467CFFF),
    infoCardFill: Color(0x1A2196F3),
    infoCardBorder: Color(0x4D2196F3),
    toastNeutral: Color(0xFF424242),
    scrim: Color(0x80000000),
    shadowCard: Color(0x1F000000),
    shadowRaised: Color(0x42000000),
    shadowHeader: Color(0x78000000),
  );

  /// Candidate A: neutral charcoal.
  static const darkCharcoal = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF141414),
    backgroundAlt: Color(0xFF141414),
    surface: Color(0xFF212121),
    surfaceMuted: Color(0xFF2C2C2C),
    pill: Color(0xFF3A3A3A),
    divider: Color(0xFF353535),
    cardBorder: Color(0x14FFFFFF),
    skeleton: Color(0xFF2E2E2E),
    emptyAvatar: Color(0xFF3A3A3A),
    emptyBackground: Color(0xFF4A4A4A),
    textPrimary: Color(0xFFF4F4F4),
    textSecondary: Color(0xFFB4B4B4),
    textTertiary: Color(0xFFA6A6A6),
    textMuted: Color(0xFF9A9A9A),
    textFaint: Color(0x99FFFFFF),
    icon: Color(0xFFF4F4F4),
    iconMuted: Color(0xFF8C8C8C),
    disabled: Color(0xFF5C5C5C),
    selectedHighlight: Color(0xFF1D3A5C),
    unreadHighlight: Color(0xFF17283A),
    selectedCapsule: Color(0x5567CFFF),
    infoCardFill: Color(0x262196F3),
    infoCardBorder: Color(0x662196F3),
    toastNeutral: Color(0xFF3A3A3A),
    scrim: Color(0xB3000000),
    shadowCard: Color(0x66000000),
    shadowRaised: Color(0x8C000000),
    shadowHeader: Color(0xA0000000),
  );

  /// Candidate B: night forest, surfaces faintly tinted towards the brand green.
  static const darkForest = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF111612),
    backgroundAlt: Color(0xFF111612),
    surface: Color(0xFF1C231D),
    surfaceMuted: Color(0xFF273028),
    pill: Color(0xFF334034),
    divider: Color(0xFF2F3A30),
    cardBorder: Color(0x14E8FFE0),
    skeleton: Color(0xFF2A332B),
    emptyAvatar: Color(0xFF34403A),
    emptyBackground: Color(0xFF45524A),
    textPrimary: Color(0xFFF2F6F1),
    textSecondary: Color(0xFFB1BCB0),
    textTertiary: Color(0xFFA3AEA2),
    textMuted: Color(0xFF97A296),
    textFaint: Color(0x99F2F6F1),
    icon: Color(0xFFF2F6F1),
    iconMuted: Color(0xFF889386),
    disabled: Color(0xFF56615A),
    selectedHighlight: Color(0xFF1D3A5C),
    unreadHighlight: Color(0xFF172A33),
    selectedCapsule: Color(0x5567CFFF),
    infoCardFill: Color(0x262196F3),
    infoCardBorder: Color(0x662196F3),
    toastNeutral: Color(0xFF34403A),
    scrim: Color(0xB3000000),
    shadowCard: Color(0x66000000),
    shadowRaised: Color(0x8C000000),
    shadowHeader: Color(0xA0000000),
  );

  /// Candidate C: blue slate, like a night sky over the map.
  static const darkSlate = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF0F131A),
    backgroundAlt: Color(0xFF0F131A),
    surface: Color(0xFF1A202A),
    surfaceMuted: Color(0xFF242C38),
    pill: Color(0xFF2F3947),
    divider: Color(0xFF2C3644),
    cardBorder: Color(0x14DCE8FF),
    skeleton: Color(0xFF262F3C),
    emptyAvatar: Color(0xFF323C4A),
    emptyBackground: Color(0xFF434E5D),
    textPrimary: Color(0xFFF1F4F8),
    textSecondary: Color(0xFFB0B8C4),
    textTertiary: Color(0xFFA2AAB6),
    textMuted: Color(0xFF959EAB),
    textFaint: Color(0x99F1F4F8),
    icon: Color(0xFFF1F4F8),
    iconMuted: Color(0xFF86909E),
    disabled: Color(0xFF535D6B),
    selectedHighlight: Color(0xFF1D3A5C),
    unreadHighlight: Color(0xFF16263A),
    selectedCapsule: Color(0x5567CFFF),
    infoCardFill: Color(0x262196F3),
    infoCardBorder: Color(0x662196F3),
    toastNeutral: Color(0xFF2F3947),
    scrim: Color(0xB3000000),
    shadowCard: Color(0x66000000),
    shadowRaised: Color(0x8C000000),
    shadowHeader: Color(0xA0000000),
  );

  /// The dark palette in use (chosen in DECISIONS.md D-03). Builds with
  /// `--dart-define=DARK_PALETTE=forest` (or `slate`) show another candidate,
  /// so the comparison can be repeated on a device.
  static const dark = _darkCandidate == 'forest'
      ? darkForest
      : _darkCandidate == 'slate'
      ? darkSlate
      : darkCharcoal;

  static const _darkCandidate = String.fromEnvironment('DARK_PALETTE');

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: l(background, other.background),
      backgroundAlt: l(backgroundAlt, other.backgroundAlt),
      surface: l(surface, other.surface),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      pill: l(pill, other.pill),
      divider: l(divider, other.divider),
      cardBorder: l(cardBorder, other.cardBorder),
      skeleton: l(skeleton, other.skeleton),
      emptyAvatar: l(emptyAvatar, other.emptyAvatar),
      emptyBackground: l(emptyBackground, other.emptyBackground),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textTertiary: l(textTertiary, other.textTertiary),
      textMuted: l(textMuted, other.textMuted),
      textFaint: l(textFaint, other.textFaint),
      icon: l(icon, other.icon),
      iconMuted: l(iconMuted, other.iconMuted),
      disabled: l(disabled, other.disabled),
      selectedHighlight: l(selectedHighlight, other.selectedHighlight),
      unreadHighlight: l(unreadHighlight, other.unreadHighlight),
      selectedCapsule: l(selectedCapsule, other.selectedCapsule),
      infoCardFill: l(infoCardFill, other.infoCardFill),
      infoCardBorder: l(infoCardBorder, other.infoCardBorder),
      toastNeutral: l(toastNeutral, other.toastNeutral),
      scrim: l(scrim, other.scrim),
      shadowCard: l(shadowCard, other.shadowCard),
      shadowRaised: l(shadowRaised, other.shadowRaised),
      shadowHeader: l(shadowHeader, other.shadowHeader),
    );
  }
}

extension AppPaletteX on BuildContext {
  /// The light or dark palette of the current theme.
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
