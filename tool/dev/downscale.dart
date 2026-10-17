// Scales a PNG down to a given width (tool/dev/shot.sh).
//
//   dart run tool/dev/downscale.dart <in.png> <out.png> [width]
import 'dart:io';

import 'package:image/image.dart' as img;

void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln('usage: downscale.dart <in.png> <out.png> [width]');
    exit(64);
  }
  final width = args.length > 2 ? int.parse(args[2]) : 540;
  final source = img.decodePng(File(args[0]).readAsBytesSync());
  if (source == null) {
    stderr.writeln('not a PNG: ${args[0]}');
    exit(1);
  }
  final small = source.width <= width
      ? source
      : img.copyResize(
          source,
          width: width,
          interpolation: img.Interpolation.average,
        );
  File(args[1]).writeAsBytesSync(img.encodePng(small));
}
