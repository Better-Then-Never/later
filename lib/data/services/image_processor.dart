import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// CPU-heavy image work, always off the UI isolate.
class ImageProcessor {
  const ImageProcessor();

  /// Capsule photo: longest side ≤ [maxDimension], JPEG [quality], EXIF
  /// orientation applied.
  Future<Uint8List> capsuleJpegFromFile(
    String path, {
    int maxDimension = 1600,
    int quality = 85,
  }) async {
    final bytes = await File(path).readAsBytes();
    return Isolate.run(() => _fit(bytes, maxDimension, quality));
  }

  /// Photo for a chat message: like a capsule photo, a little smaller, with
  /// its size in pixels (the bubble's shape).
  Future<({Uint8List bytes, int width, int height})> chatJpegFromFile(
    String path, {
    int maxDimension = 1600,
    int quality = 82,
  }) async {
    final bytes = await File(path).readAsBytes();
    return Isolate.run(() => _fitSized(bytes, maxDimension, quality));
  }

  /// Background picture: longest side ≤ [maxDimension].
  Future<Uint8List> backgroundJpeg(
    Uint8List bytes, {
    int maxDimension = 1600,
    int quality = 85,
  }) => Isolate.run(() => _fit(bytes, maxDimension, quality));

  /// A capsule's square (capsule v3 thumbnail): the part of the photo at
  /// [x], [y], [w], [h] (shares of its width and height; the middle square
  /// when null) as a [size] px square.
  Future<Uint8List> capsuleSquareJpegFromFile(
    String path, {
    required int size,
    ({double x, double y, double w, double h})? crop,
    int quality = 80,
  }) async {
    final bytes = await File(path).readAsBytes();
    return Isolate.run(() => _cropSquare(bytes, crop, size, quality));
  }

  /// Avatar: centre-cropped square (no distortion) of [size] px.
  Future<Uint8List> squareJpeg(
    Uint8List bytes, {
    required int size,
    int quality = 85,
  }) => Isolate.run(() => _square(bytes, size, quality));

  /// Undecodable bytes are kept as they are (capsules and backgrounds did
  /// so before); chat photos need a size, so [_fitSized] refuses them.
  static Uint8List _fit(Uint8List bytes, int maxDimension, int quality) {
    try {
      return _fitSized(bytes, maxDimension, quality).bytes;
    } on FormatException {
      return bytes;
    }
  }

  static ({Uint8List bytes, int width, int height}) _fitSized(
    Uint8List bytes,
    int maxDimension,
    int quality,
  ) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('Not a picture this app can read');
    }
    var image = img.bakeOrientation(decoded);
    final longest = image.width > image.height ? image.width : image.height;
    if (longest > maxDimension) {
      image = image.width >= image.height
          ? img.copyResize(image, width: maxDimension)
          : img.copyResize(image, height: maxDimension);
    }
    return (
      bytes: Uint8List.fromList(img.encodeJpg(image, quality: quality)),
      width: image.width,
      height: image.height,
    );
  }

  static Uint8List _cropSquare(
    Uint8List bytes,
    ({double x, double y, double w, double h})? crop,
    int size,
    int quality,
  ) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    final image = img.bakeOrientation(decoded);
    if (crop == null) {
      final square = img.copyResizeCropSquare(image, size: size);
      return Uint8List.fromList(img.encodeJpg(square, quality: quality));
    }
    final x = (crop.x * image.width).round().clamp(0, image.width - 1);
    final y = (crop.y * image.height).round().clamp(0, image.height - 1);
    final side = (crop.w * image.width).round().clamp(1, image.width - x);
    final square = img.copyCrop(
      image,
      x: x,
      y: y,
      width: side,
      height: side.clamp(1, image.height - y),
    );
    final out = img.copyResize(square, width: size, height: size);
    return Uint8List.fromList(img.encodeJpg(out, quality: quality));
  }

  static Uint8List _square(Uint8List bytes, int size, int quality) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    final image = img.copyResizeCropSquare(
      img.bakeOrientation(decoded),
      size: size,
    );
    return Uint8List.fromList(img.encodeJpg(image, quality: quality));
  }
}
