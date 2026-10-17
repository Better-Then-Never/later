import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:later/data/models/capsule.dart';
import 'package:later/data/models/geo_position.dart';
import 'package:later/features/map/map_clusters.dart';

Capsule _at(int i, double lat, double lng) => Capsule(
  id: 'c$i',
  ownerId: 'o',
  title: 't',
  privacy: CapsulePrivacy.public,
  color: CapsuleColor.red,
  location: GeoPosition(lat, lng),
);

/// About what a phone shows at zoom 13 over Warsaw.
const _warsaw = GeoBounds(south: 52.20, west: 20.98, north: 52.26, east: 21.04);

void main() {
  test('sparse capsules each get their own pin', () {
    final capsules = [
      _at(1, 52.21, 20.99),
      _at(2, 52.23, 21.01),
      _at(3, 52.25, 21.03),
    ];
    final items = clusterCapsules(capsules, view: _warsaw, zoom: 13);
    expect(items, hasLength(3));
    expect(items.every((i) => !i.isCluster), isTrue);
  });

  test('a crowd becomes few markers, and every capsule is counted', () {
    final random = math.Random(1);
    final capsules = [
      for (var i = 0; i < 1500; i++)
        _at(
          i,
          52.20 + random.nextDouble() * 0.06,
          20.98 + random.nextDouble() * 0.06,
        ),
    ];
    final items = clusterCapsules(capsules, view: _warsaw, zoom: 13);
    expect(items.length, lessThanOrEqualTo(150));
    expect(items.fold<int>(0, (n, i) => n + i.count), 1500);
    for (final cluster in items.where((i) => i.isCluster)) {
      expect(cluster.bounds!.contains(cluster.at), isTrue);
    }
  });

  test('capsules far outside the screen are left out', () {
    final capsules = [_at(1, 52.23, 21.01), _at(2, 48.85, 2.35)];
    final items = clusterCapsules(capsules, view: _warsaw, zoom: 13);
    expect(items.map((i) => i.capsule?.id), ['c1']);
  });

  test('just off screen counts, so a small pan has its pins ready', () {
    final items = clusterCapsules(
      [_at(1, 52.27, 21.01)],
      view: _warsaw,
      zoom: 13,
    );
    expect(items, hasLength(1));
  });

  test('a cluster keeps its id while the camera pans at the same zoom', () {
    final capsules = [
      for (var i = 0; i < 20; i++) _at(i, 52.2300 + i * 1e-5, 21.0100),
    ];
    String clusterId(GeoBounds view) => clusterCapsules(
      capsules,
      view: view,
      zoom: 13.4,
    ).singleWhere((i) => i.isCluster).id;
    const panned = GeoBounds(
      south: 52.21,
      west: 20.99,
      north: 52.27,
      east: 21.05,
    );
    expect(clusterId(_warsaw), clusterId(panned));
  });

  test('bounds across the 180° meridian contain both sides', () {
    const pacific = GeoBounds(south: -20, west: 170, north: 20, east: -170);
    expect(pacific.contains(const GeoPosition(0, 175)), isTrue);
    expect(pacific.contains(const GeoPosition(0, -175)), isTrue);
    expect(pacific.contains(const GeoPosition(0, 0)), isFalse);
  });

  test('at street level capsules in one spot are separate pins', () {
    final capsules = [for (var i = 0; i < 5; i++) _at(i, 52.23, 21.01)];
    final items = clusterCapsules(capsules, view: _warsaw, zoom: 19);
    expect(items.where((i) => i.isCluster), isEmpty);
    expect(items, hasLength(5));
  });
}
