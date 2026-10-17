import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../capsule_creation_controller.dart';

/// The frames of a loop being created, in a row: drag one to move it, tap
/// its cross to take it out (two stay at least).
class LoopFrameStrip extends StatelessWidget {
  const LoopFrameStrip({super.key, required this.controller});

  final CapsuleCreationController controller;

  static const _width = 54.0;
  static const _height = 80.0;

  @override
  Widget build(BuildContext context) {
    final frames = controller.framePaths;
    final l10n = context.l10n;
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            '${l10n.capsulesFramesTitle} · ${frames.length}  ·  '
            '${l10n.capsulesFramesHint}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              fontSize: 13,
              color: palette.textSecondary,
            ),
          ),
        ),
        SizedBox(
          height: _height + 8,
          child: ReorderableListView.builder(
            scrollDirection: Axis.horizontal,
            buildDefaultDragHandles: false,
            itemCount: frames.length,
            onReorderStart: (_) => HapticFeedback.selectionClick(),
            onReorder: controller.moveFrame,
            itemBuilder: (context, i) => ReorderableDelayedDragStartListener(
              key: ValueKey(frames[i]),
              index: i,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(2, 4, 4, 4),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(frames[i]),
                        width: _width,
                        height: _height,
                        fit: BoxFit.cover,
                        cacheWidth: 160,
                      ),
                    ),
                    if (controller.canRemoveFrame)
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Semantics(
                          button: true,
                          label: l10n.capsulesFrameRemove(i + 1),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => controller.removeFrame(i),
                            // A 32 dp target around a small cross.
                            child: SizedBox.square(
                              dimension: 32,
                              child: Center(
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: AppColors.mediaScrim,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const CustomPaint(
                                    painter: _CrossPainter(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CrossPainter extends CustomPainter {
  const _CrossPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.onMedia
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final a = size.width * 0.32;
    final b = size.width * 0.68;
    canvas
      ..drawLine(Offset(a, a), Offset(b, b), paint)
      ..drawLine(Offset(b, a), Offset(a, b), paint);
  }

  @override
  bool shouldRepaint(_CrossPainter old) => false;
}
