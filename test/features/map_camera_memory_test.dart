// Where the map last stopped, kept for a cold start (M-06).
import 'package:flutter_test/flutter_test.dart';
import 'package:later/features/map/engine/map_camera_memory.dart';

void main() {
  test('saved and read back', () {
    final saved = MapCameraMemory.format(52.229712345, 21.0122, 13.456);
    expect(saved, '52.22971,21.01220,13.46');
    expect(MapCameraMemory.parse(saved), (52.22971, 21.0122, 13.46));
  });

  test('missing or broken: none (the map waits for the start position)', () {
    expect(MapCameraMemory.parse(null), isNull);
    expect(MapCameraMemory.parse(''), isNull);
    expect(MapCameraMemory.parse('52,21'), isNull);
    expect(MapCameraMemory.parse('52,x,13'), isNull);
    expect(MapCameraMemory.parse('95,21,13'), isNull);
    expect(MapCameraMemory.parse('52,21,0'), isNull);
  });
}
