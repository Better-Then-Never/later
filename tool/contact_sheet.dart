// Side-by-side sheet of screenshots: one row per prefix, one column per
// suffix, each shot scaled to [width] pixels.
//
//   dart run tool/contact_sheet.dart <dir> <out.png> <prefixes,> <suffixes,>
//   e.g. dart run tool/contact_sheet.dart docs/ux/dark_candidates
//        docs/ux/dark_candidates/sheet.png charcoal,forest,slate
//        map,history,messages,profile
import 'dart:io';

import 'package:image/image.dart' as img;

const _width = 270;
const _gap = 12;

void main(List<String> args) {
  if (args.length < 4) {
    stderr.writeln(
      'usage: contact_sheet.dart <dir> <out.png> <rows,> <columns,>',
    );
    exit(64);
  }
  final dir = args[0];
  final rows = args[2].split(',');
  final columns = args[3].split(',');
  img.Image? first;
  final shots = <List<img.Image>>[];
  for (final r in rows) {
    final row = <img.Image>[];
    for (final c in columns) {
      final file = File('$dir/${r}_$c.png');
      final shot = img.decodePng(file.readAsBytesSync())!;
      final scaled = img.copyResize(shot, width: _width);
      first ??= scaled;
      row.add(scaled);
    }
    shots.add(row);
  }
  final h = first!.height;
  final sheet = img.Image(
    width: columns.length * (_width + _gap) + _gap,
    height: rows.length * (h + _gap) + _gap,
  );
  img.fill(sheet, color: img.ColorRgb8(0x80, 0x80, 0x80));
  for (var y = 0; y < rows.length; y++) {
    for (var x = 0; x < columns.length; x++) {
      img.compositeImage(
        sheet,
        shots[y][x],
        dstX: _gap + x * (_width + _gap),
        dstY: _gap + y * (h + _gap),
      );
    }
  }
  File(args[1]).writeAsBytesSync(img.encodePng(sheet));
  stdout.writeln('wrote ${args[1]}');
}
