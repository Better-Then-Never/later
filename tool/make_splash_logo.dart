// Writes the Android launch-screen logo from assets/images/later_logo.png at
// the size it is shown (132 dp wide at 4x density), so launch decodes little.
//
//   dart run tool/make_splash_logo.dart
import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  final logo = img.decodePng(
    File('assets/images/later_logo.png').readAsBytesSync(),
  )!;
  final resized = img.copyResize(
    logo,
    width: 528,
    interpolation: img.Interpolation.average,
  );
  const out = 'android/app/src/main/res/drawable-nodpi/splash_logo.png';
  File(out).writeAsBytesSync(img.encodePng(resized, level: 9));
  stdout.writeln('wrote $out (${resized.width}x${resized.height})');
}
