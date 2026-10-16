import 'package:flutter/material.dart';
import 'package:later/shared/widgets/default_text.dart';
import 'package:later/shared/widgets/default_search_bar.dart';
import 'package:later/core/theme/app_colors.dart';
import 'package:later/core/theme/app_motion.dart';
import 'package:later/core/theme/app_dimens.dart';

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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedSize(
      duration: AppMotion.of(context, AppMotion.emphasized),
      curve: AppMotion.emphasizedCurve,
      child: Container(
        width: screenWidth,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: screenHeight * 0.04),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: screenWidth,
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
                          fontSize: screenHeight * 0.04,
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
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: screenHeight * 0.017,
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
