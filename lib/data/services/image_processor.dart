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

  /// Background picture: longest side ≤ [maxDimension].
  Future<Uint8List> backgroundJpeg(
    Uint8List bytes, {
    int maxDimension = 1600,
    int quality = 85,
  }) => Isolate.run(() => _fit(bytes, maxDimension, quality));

  /// Avatar: centre-cropped square (no distortion) of [size] px.
  Future<Uint8List> squareJpeg(
    Uint8List bytes, {
    required int size,
    int quality = 85,
  }) => Isolate.run(() => _square(bytes, size, quality));

  static Uint8List _fit(Uint8List bytes, int maxDimension, int quality) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    var image = img.bakeOrientation(decoded);
    final longest = image.width > image.height ? image.width : image.height;
    if (longest > maxDimension) {
      image = image.width >= image.height
          ? img.copyResize(image, width: maxDimension)
          : img.copyResize(image, height: maxDimension);
    }
    return Uint8List.fromList(img.encodeJpg(image, quality: quality));
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
