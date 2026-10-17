import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_palette.dart';

/// The app's single font family (Inria Sans files registered as "Irina").
const String kAppFontFamily = 'Irina';

/// Named text styles from the design (DESIGN_SPEC.md §3). Screen-relative
/// sizes are part of the look and are exposed as functions of the context
/// (screen size and theme colours).
abstract final class AppTextStyles {
  /// Body text; the colour comes from the caller (context.palette).
  static const body = TextStyle(fontFamily: kAppFontFamily, fontSize: 14);

  static const authHeading = TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: 40,
    letterSpacing: -1,
    fontWeight: FontWeight.bold,
  );

  static const authSubheading = TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: 16,
    letterSpacing: 0.1,
    fontWeight: FontWeight.w500,
  );

  static const buttonLarge = TextStyle(
    fontFamily: kAppFontFamily,
    fontWeight: FontWeight.bold,
    color: AppColors.onAccent,
    fontSize: 32,
  );

  static const dialogTitle = TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: 25,
    fontWeight: FontWeight.bold,
  );

  static const modalOption = TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: 17,
    fontWeight: FontWeight.bold,
  );

  static const sectionTitle = TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const pill = TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: 50,
    fontWeight: FontWeight.bold,
    color: AppColors.onAccent,
  );

  /// Page header title: 4% of the screen height, bold.
  static TextStyle pageTitle(BuildContext context) => TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: MediaQuery.sizeOf(context).height * 0.04,
    fontWeight: FontWeight.bold,
    color: context.palette.textPrimary,
  );

  /// Page header description: 1.7% of the screen height, bold grey.
  static TextStyle pageDescription(BuildContext context) => TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: MediaQuery.sizeOf(context).height * 0.017,
    fontWeight: FontWeight.bold,
    color: context.palette.textSecondary,
  );

  /// Name in user lists: 4.5% of the screen width, bold.
  static TextStyle listName(BuildContext context) => TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: MediaQuery.sizeOf(context).width * 0.045,
    fontWeight: FontWeight.bold,
    color: context.palette.textPrimary,
  );
}
