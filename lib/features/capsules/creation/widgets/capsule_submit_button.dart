import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/motion/app_motion_widgets.dart';

/// "Create capsule" that answers the tap: it draws in to a green circle with
/// a spinner while saving, turns into a check when the capsule is made, and
/// the page closes a moment later; a failure opens it back into the button
/// (MOTION_CATALOG.md, "Creation"). Reduced motion: no morph, no wait.
class CapsuleSubmitButton extends StatefulWidget {
  const CapsuleSubmitButton({
    super.key,
    required this.label,
    required this.saving,
    required this.onSave,
    required this.onDone,
  });

  final String label;
  final bool saving;
  final Future<bool> Function() onSave;
  final VoidCallback onDone;

  @override
  State<CapsuleSubmitButton> createState() => _CapsuleSubmitButtonState();
}

class _CapsuleSubmitButtonState extends State<CapsuleSubmitButton> {
  bool _done = false;

  Future<void> _tap() async {
    if (widget.saving || _done) return;
    final ok = await widget.onSave();
    if (!mounted || !ok) return;
    setState(() => _done = true);
    await Future<void>.delayed(AppMotion.of(context, AppMotion.slow));
    if (mounted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.06;
    final compact = widget.saving || _done;
    final motion = AppMotion.of(context, AppMotion.emphasized);
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, box) => Center(
          // As tall as the button: in a bottom bar a plain Center takes the
          // whole height and leaves the page none.
          heightFactor: 1,
          child: AppPressable(
            enabled: !compact,
            child: GestureDetector(
              onTap: _tap,
              child: AnimatedContainer(
                duration: motion,
                curve: AppMotion.emphasizedCurve,
                width: compact ? height : box.maxWidth,
                height: height,
                decoration: BoxDecoration(
                  color: AppColors.brandGreen,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: AppMotion.of(context, AppMotion.fast),
                  child: _done
                      ? const SizedBox.square(
                          key: ValueKey('done'),
                          dimension: 28,
                          child: CustomPaint(painter: _CheckPainter()),
                        )
                      : widget.saving
                      ? const SizedBox(
                          key: ValueKey('saving'),
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.onAccent,
                            strokeWidth: 2,
                          ),
                        )
                      : Padding(
                          key: const ValueKey('label'),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.label,
                              maxLines: 1,
                              style: const TextStyle(
                                fontFamily: kAppFontFamily,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onAccent,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The check of a saved capsule, in the hand-drawn icons' rounded stroke.
class _CheckPainter extends CustomPainter {
  const _CheckPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.52)
      ..lineTo(size.width * 0.42, size.height * 0.72)
      ..lineTo(size.width * 0.8, size.height * 0.3);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.onAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => false;
}
