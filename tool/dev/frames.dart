// Frame by frame, what the phone showed: reads a raw recording from
// `adb shell screenrecord --output-format=frames` (each frame: a 4-byte
// length, then width, height, stride and bytes per pixel as 4-byte values,
// then RGB rows) and lays a crop of every frame that changed side by side,
// numbered, in one PNG. For blinks and jumps too short to see in a video.
//
//   adb shell screenrecord --output-format=frames --size 270x600 \
//       --time-limit 3 /sdcard/f.raw
//   adb pull /sdcard/f.raw build/dev/f.raw
//   dart run tool/dev/frames.dart build/dev/f.raw out.png x y w h [scale]
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

void main(List<String> args) {
  if (args.length < 6) {
    stderr.writeln('usage: frames.dart <in.raw> <out.png> x y w h [scale]');
    exit(64);
  }
  final bytes = File(args[0]).readAsBytesSync();
  final data = ByteData.sublistView(bytes);
  final x = int.parse(args[2]), y = int.parse(args[3]);
  final w = int.parse(args[4]), h = int.parse(args[5]);
  final scale = args.length > 6 ? int.parse(args[6]) : 2;

  final crops = <(int, img.Image)>[];
  Uint8List? previous;
  var offset = 0;
  var index = 0;
  while (offset + 20 <= bytes.length) {
    final length = data.getUint32(offset, Endian.little);
    final width = data.getUint32(offset + 4, Endian.little);
    final stride = data.getUint32(offset + 12, Endian.little);
    final pixels = offset + 20;
    if (pixels + length - 16 > bytes.length) break;
    final crop = Uint8List(w * h * 3);
    for (var row = 0; row < h; row++) {
      final from = pixels + (y + row) * stride + x * 3;
      crop.setRange(row * w * 3, (row + 1) * w * 3, bytes, from);
    }
    final inRange = index >= _from && index <= _to;
    if (inRange && (_all || previous == null || _differs(previous, crop))) {
      if (_boxes) stdout.writeln('$index ${_box(crop, w, h)}');
      final frame = img.Image.fromBytes(
        width: w,
        height: h,
        bytes: crop.buffer,
        numChannels: 3,
      );
      crops.add((index, frame));
    }
    previous = crop;
    offset += 4 + length;
    index++;
    if (width == 0) break;
  }
  stdout.writeln('$index frames, ${crops.length} changed');

  const columns = 10;
  final cellW = w * scale, cellH = h * scale + 16;
  final rows = (crops.length / columns).ceil();
  final sheet = img.Image(width: columns * cellW, height: rows * cellH);
  img.fill(sheet, color: img.ColorRgb8(255, 255, 255));
  for (var i = 0; i < crops.length; i++) {
    final (n, frame) = crops[i];
    final cx = (i % columns) * cellW, cy = (i ~/ columns) * cellH;
    img.compositeImage(
      sheet,
      img.copyResize(
        frame,
        width: cellW,
        interpolation: img.Interpolation.nearest,
      ),
      dstX: cx,
      dstY: cy + 16,
    );
    img.drawString(
      sheet,
      '$n',
      font: img.arial14,
      x: cx + 2,
      y: cy,
      color: img.ColorRgb8(0, 0, 0),
    );
  }
  File(args[1]).writeAsBytesSync(img.encodePng(sheet));
}

// FROM and TO keep only those frames; BOXES=1 prints where the pin's dark
// outline is (left, top, right, bottom) in each kept frame.
final _env = Platform.environment;
final _from = int.tryParse(_env['FROM'] ?? '') ?? 0;
final _to = int.tryParse(_env['TO'] ?? '') ?? 1 << 30;
final _boxes = _env['BOXES'] == '1';

// ALL=1 keeps every frame in range, changed or not.
final _all = _env['ALL'] == '1';

String _box(Uint8List rgb, int w, int h) {
  var l = w, t = h, r = -1, b = -1;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = (y * w + x) * 3;
      if (rgb[i] < 40 && rgb[i + 1] < 40 && rgb[i + 2] < 40) {
        if (x < l) l = x;
        if (x > r) r = x;
        if (y < t) t = y;
        if (y > b) b = y;
      }
    }
  }
  return r < 0 ? 'none' : '$l $t $r $b';
}

bool _differs(Uint8List a, Uint8List b) {
  var sum = 0;
  for (var i = 0; i < a.length; i++) {
    sum += (a[i] - b[i]).abs();
  }
  return sum > a.length; // more than 1 per channel on average
}
