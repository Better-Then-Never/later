import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The app's single font family (Inria Sans files registered as "Irina").
const String kAppFontFamily = 'Irina';

/// Named text styles from the design (DESIGN_SPEC.md §3). Screen-relative
/// sizes are part of the look and are exposed as functions of the screen size.
abstract final class AppTextStyles {
  static const body = TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: 14,
    color: AppColors.textPrimary,
  );

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
    color: AppColors.textOnPrimary,
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
    color: AppColors.textOnPrimary,
  );

  /// Page header title: 4% of the screen height, bold.
  static TextStyle pageTitle(Size screen) => TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: screen.height * 0.04,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// Page header description: 1.7% of the screen height, bold grey.
  static TextStyle pageDescription(Size screen) => TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: screen.height * 0.017,
    fontWeight: FontWeight.bold,
    color: AppColors.textSecondary,
  );

  /// Name in user lists: 4.5% of the screen width, bold.
  static TextStyle listName(Size screen) => TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: screen.width * 0.045,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
}
