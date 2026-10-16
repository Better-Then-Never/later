import 'package:flutter_test/flutter_test.dart';
import 'package:later/data/models/capsule.dart';
import 'package:later/features/map/current_location.dart';
import 'package:later/features/map/map_controller.dart';
import 'package:later/features/map/map_focus.dart';
import 'package:later/data/models/geo_position.dart';

Capsule _c(String owner, CapsulePrivacy privacy) => Capsule(
  id: '$owner-${privacy.name}',
  ownerId: owner,
  title: 't',
  privacy: privacy,
  color: CapsuleColor.red,
);

void main() {
  group('capsule visibility on the map', () {
    bool visible(Capsule c) =>
        MapController.isVisibleTo(c, uid: 'me', friendIds: {'friend'});

    test('own capsules are always visible', () {
      for (final p in CapsulePrivacy.values) {
        expect(visible(_c('me', p)), isTrue, reason: p.name);
      }
    });

    test('public capsules of anyone are visible', () {
      expect(visible(_c('stranger', CapsulePrivacy.public)), isTrue);
    });

    test('friends-only capsules only from friends', () {
      expect(visible(_c('friend', CapsulePrivacy.friends)), isTrue);
      expect(visible(_c('stranger', CapsulePrivacy.friends)), isFalse);
    });

    test("other people's private capsules are never visible", () {
      expect(visible(_c('friend', CapsulePrivacy.private)), isFalse);
      expect(visible(_c('stranger', CapsulePrivacy.private)), isFalse);
    });
  });

  test('MapFocus hands a capsule over exactly once', () {
    final focus = MapFocus();
    var notified = 0;
    focus.addListener(() => notified++);
    final capsule = _c('me', CapsulePrivacy.public);
    focus.focus(capsule);
    expect(notified, 1);
    expect(focus.take(), capsule);
    expect(focus.take(), isNull);
  });

  test('CurrentLocation notifies only on real changes', () {
    final location = CurrentLocation();
    var notified = 0;
    location.addListener(() => notified++);
    location.update(const GeoPosition(1, 2));
    location.update(const GeoPosition(1, 2));
    location.update(null);
    expect(notified, 1);
    expect(location.position, const GeoPosition(1, 2));
  });
}
