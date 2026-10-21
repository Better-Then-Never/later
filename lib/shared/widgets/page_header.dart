import 'package:flutter/material.dart';
import 'package:later/shared/widgets/default_text.dart';
import 'package:later/shared/widgets/default_search_bar.dart';
import 'package:later/core/theme/app_motion.dart';
import 'package:later/core/theme/app_dimens.dart';
import '../../core/assets/app_assets.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';

/// The header of the app's pages (F-33): it starts below the real status
/// bar (not 4 % of the screen height, which collided with tall cutouts),
/// the title is a fixed size, and its row is at least 44 dp tall so the
/// buttons on either side are full tap targets (D-24).
class PageHeader extends StatelessWidget {
  final String mainText;
  final String? description;
  final Widget? leadingButton;
  final Widget? trailingButton;
  final DefaultSearchBar? searchBar;
  final Widget? actionButtonsRow;

  const PageHeader({
    super.key,
    required this.mainText,
    this.description,
    this.leadingButton,
    this.trailingButton,
    this.searchBar,
    this.actionButtonsRow,
  });

  /// Title size (what 4 % of the height gave on the reference phone).
  static const titleSize = 32.0;

  /// Height of the title row: a tap target for its buttons.
  static const rowHeight = 44.0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBar = MediaQuery.viewPaddingOf(context).top;

    return AnimatedSize(
      duration: AppMotion.of(context, AppMotion.emphasized),
      curve: AppMotion.emphasizedCurve,
      child: Container(
        width: screenWidth,
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: statusBar + AppSpacing.s),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: screenWidth,
                  maxWidth: screenWidth,
                  minHeight: rowHeight,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Long titles shrink instead of running under the
                    // buttons on either side.
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            leadingButton != null || trailingButton != null
                            ? screenWidth * 0.17
                            : AppSpacing.l,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: DefaultText(
                          mainText,
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                          maxLines: 1,
                        ),
                      ),
                    ),
                    if (leadingButton != null)
                      Positioned(
                        left: 16,
                        top: 0,
                        bottom: 0,
                        child: leadingButton!,
                      ),
                    if (trailingButton != null)
                      Positioned(
                        right: 16,
                        top: 0,
                        bottom: 0,
                        child: trailingButton!,
                      ),
                  ],
                ),
              ),
              if (description != null)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.07),
                  child: DefaultText(
                    description!,
                    color: context.palette.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

              if (searchBar != null)
                Padding(
                  padding: EdgeInsets.only(
                    left: screenWidth * 0.04,
                    right: screenWidth * 0.04,
                    top: screenHeight * 0.01,
                  ),
                  child: searchBar!,
                ),

              Padding(
                padding: EdgeInsets.only(
                  left: screenWidth * 0.04,
                  right: screenWidth * 0.04,
                  bottom: screenHeight * 0.01,
                ),
                child: AnimatedSwitcher(
                  duration: AppMotion.of(context, AppMotion.fast),
                  switchInCurve: AppMotion.enter,
                  switchOutCurve: AppMotion.exit,
                  child: actionButtonsRow == null
                      ? const SizedBox.shrink()
                      : actionButtonsRow!,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The page header of the v2 design (Figma "Header / Title row v2"): the
/// surface with rounded bottom corners, a 26 dp title in the middle and a
/// 34 dp back arrow on the left.
class PageHeaderV2 extends StatelessWidget {
  const PageHeaderV2({
    super.key,
    required this.title,
    required this.onBack,
    required this.backLabel,
  });

  final String title;
  final VoidCallback onBack;
  final String backLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.viewPaddingOf(context).top + 6,
        bottom: 10,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    fontSize: 26,
                    height: 1.1,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 11,
              top: 0,
              bottom: 0,
              child: Semantics(
                button: true,
                label: backLabel,
                child: InkResponse(
                  onTap: onBack,
                  radius: 24,
                  child: SizedBox(
                    width: 44,
                    child: Center(
                      child: Image.asset(AppIcons.goBack, width: 34),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
