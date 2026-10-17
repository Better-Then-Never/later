import 'package:flutter/widgets.dart';

/// Motion tokens (docs/polish/DESIGN_DECISIONS.md §6). Every value is one the
/// app already used: quick and subtle, ease-out to enter, ease-in to leave.
abstract final class AppMotion {
  /// Press feedback, icon swaps.
  static const quick = Duration(milliseconds: 100);

  /// Fades, cross-fades and page transitions.
  static const fast = Duration(milliseconds: 150);

  /// State changes: navbar selection, toggles, badges.
  static const standard = Duration(milliseconds: 200);

  /// Size changes and bottom sheets.
  static const emphasized = Duration(milliseconds: 250);

  /// Toasts and scrolling to a position.
  static const slow = Duration(milliseconds: 300);

  /// Larger reveals (permission gate pages).
  static const reveal = Duration(milliseconds: 350);

  /// Something appearing or arriving.
  static const enter = Curves.easeOut;

  /// Something leaving.
  static const exit = Curves.easeIn;

  /// A state changing in place.
  static const standardCurve = Curves.easeInOut;

  /// Size and layout changes.
  static const emphasizedCurve = Curves.fastOutSlowIn;

  /// Scale of a pressed button or card.
  static const pressedScale = 0.97;

  /// Whether the user asked the system to reduce motion.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [duration], or zero when motion is reduced.
  static Duration of(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}
