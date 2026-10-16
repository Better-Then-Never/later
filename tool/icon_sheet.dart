// Contact sheet of every hand-drawn icon: light variant on the light surface
// next to the dark variant on the dark surface.
//
//   dart run tool/icon_sheet.dart [out.png]   (default docs/ux/icons_light_dark.png)
import 'dart:io';

import 'package:image/image.dart' as img;

const _cell = 72;
const _icon = 52;
const _columns = 8;

void main(List<String> args) {
  final out = args.isNotEmpty ? args.first : 'docs/ux/icons_light_dark.png';
  final files =
      Directory('assets/icons')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.png'))
          .map((f) => f.path.replaceAll('\\', '/'))
          .toList()
        ..sort();
  final rows = (files.length / _columns).ceil();
  final sheet = img.Image(width: _columns * _cell * 2, height: rows * _cell);
  final light = img.ColorRgb8(0xFF, 0xFF, 0xFF);
  final dark = img.ColorRgb8(0x21, 0x21, 0x21);
  img.fill(sheet, color: light);
  img.fillRect(
    sheet,
    x1: _columns * _cell,
    y1: 0,
    x2: sheet.width,
    y2: sheet.height,
    color: dark,
  );
  for (var i = 0; i < files.length; i++) {
    final col = i % _columns, row = i ~/ _columns;
    for (final (variant, offset) in [
      (files[i], 0),
      (
        files[i].replaceFirst('assets/icons/', 'assets/icons_dark/'),
        _columns * _cell,
      ),
    ]) {
      final file = File(variant);
      if (!file.existsSync()) continue;
      final decoded = img.decodePng(file.readAsBytesSync());
      if (decoded == null) continue;
      final scale =
          _icon /
          (decoded.width > decoded.height ? decoded.width : decoded.height);
      final resized = img.copyResize(
        decoded,
        width: (decoded.width * scale).round(),
        height: (decoded.height * scale).round(),
        interpolation: img.Interpolation.average,
      );
      img.compositeImage(
        sheet,
        resized,
        dstX: offset + col * _cell + (_cell - resized.width) ~/ 2,
        dstY: row * _cell + (_cell - resized.height) ~/ 2,
      );
    }
  }
  File(out).writeAsBytesSync(img.encodePng(sheet));
  stdout.writeln('wrote $out (${files.length} icons)');
}
