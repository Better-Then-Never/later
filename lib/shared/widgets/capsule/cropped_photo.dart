import 'package:flutter/material.dart';

import '../../../data/models/capsule.dart';

/// A photo shown as the square a capsule chose with Adjust ([crop]), or its
/// middle square when there is none. [image] is the whole photo drawn to
/// fill the box it is given (`BoxFit.fill`): this widget sizes and places it
/// so only the chosen square shows.
class CroppedPhoto extends StatelessWidget {
  const CroppedPhoto({super.key, required this.crop, required this.image});

  final CapsuleCrop? crop;
  final Widget Function(BoxFit fit) image;

  @override
  Widget build(BuildContext context) {
    final crop = this.crop;
    if (crop == null) return image(BoxFit.cover);
    return LayoutBuilder(
      builder: (context, box) {
        final side = box.biggest;
        // The whole photo, as large as it must be for the square to fill
        // the box (its width over height comes out right by itself).
        final width = side.width / crop.w;
        final height = side.height / crop.h;
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: width,
            maxWidth: width,
            minHeight: height,
            maxHeight: height,
            child: Transform.translate(
              offset: Offset(-crop.x * width, -crop.y * height),
              child: SizedBox(
                width: width,
                height: height,
                child: image(BoxFit.fill),
              ),
            ),
          ),
        );
      },
    );
  }
}
