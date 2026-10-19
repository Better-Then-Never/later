import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:later/features/map/engine/maplibre_images.dart';

void main() {
  test('the kept marker pictures read back as they were', () {
    final images = {
      'pin_red': Uint8List.fromList([1, 2, 3]),
      'bubble_99+': Uint8List.fromList(List.filled(70000, 7)),
      'me': Uint8List(0),
    };
    final back = MapLibreImages.decode(MapLibreImages.encode(images));
    expect(back.keys, images.keys);
    for (final name in images.keys) {
      expect(back[name], images[name]);
    }
  });

  test('anything else reads as no pictures (they are drawn again)', () {
    final good = MapLibreImages.encode({
      'me': Uint8List.fromList([1, 2]),
    });
    expect(MapLibreImages.decode(Uint8List(3)), isEmpty);
    expect(MapLibreImages.decode(Uint8List.sublistView(good, 0, 12)), isEmpty);
  });

  test('the cache is complete only with every picture', () {
    // 6 pins, the shadow, bubbles 2 to 99 and "99+", the user's figure.
    expect(MapLibreImages.count, 6 + 1 + 99 + 1);
  });
}
