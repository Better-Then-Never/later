// A tapped MapLibre bubble: the camera fits the capsules it holds.
import 'package:flutter_test/flutter_test.dart';
import 'package:later/features/map/engine/bubble_members.dart';

Map<String, dynamic> _leaf(double lat, double lng) => {
  'type': 'Feature',
  'id': 'c$lat',
  'geometry': {
    'type': 'Point',
    'coordinates': [lng, lat],
  },
  'properties': <String, dynamic>{},
};

void main() {
  test('the area around all of the bubble\'s capsules', () {
    final area = bubbleArea([
      _leaf(52.2300, 21.0100),
      _leaf(52.2303, 21.0104),
      _leaf(52.2297, 21.0098),
    ])!;
    expect(area.south, 52.2297);
    expect(area.north, 52.2303);
    expect(area.west, 21.0098);
    expect(area.east, 21.0104);
  });

  test(
    'fewer than two, or all in one spot: none (the camera moves closer)',
    () {
      expect(bubbleArea([_leaf(52.23, 21.01)]), isNull);
      expect(bubbleArea(const []), isNull);
      expect(
        bubbleArea([_leaf(52.23, 21.01), _leaf(52.23001, 21.01001)]),
        isNull,
      );
    },
  );

  test('leaves without a point are skipped', () {
    expect(
      bubbleArea([
        _leaf(52.23, 21.01),
        {'type': 'Feature', 'geometry': null},
        {
          'type': 'Feature',
          'geometry': {'type': 'Point', 'coordinates': <Object>[]},
        },
      ]),
      isNull,
    );
  });
}
