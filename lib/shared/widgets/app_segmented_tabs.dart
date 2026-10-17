import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';

/// A small choice between a few views, in the look of the notifications tabs
/// (F-41: the requests page had its own outlined pills): the chosen one is a
/// green pill with white bold text, the others plain text.
class AppSegmentedTabs extends StatelessWidget {
  const AppSegmentedTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final duration = AppMotion.of(context, AppMotion.standard);
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, label) in labels.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              child: Semantics(
                button: true,
                selected: i == selected,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(i),
                  // Taps land 6 dp above and below the 32 dp pill too: a
                  // 44 dp target in the same 48 dp row (D-24).
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: AnimatedContainer(
                      duration: duration,
                      curve: AppMotion.standardCurve,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: i == selected
                            ? AppColors.brandGreen
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: AnimatedDefaultTextStyle(
                        duration: duration,
                        style: TextStyle(
                          fontFamily: kAppFontFamily,
                          fontSize: 14,
                          fontWeight: i == selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: i == selected
                              ? AppColors.onAccent
                              : palette.textPrimary,
                        ),
                        child: Text(label, maxLines: 1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
