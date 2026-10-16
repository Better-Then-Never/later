import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/assets/app_assets.dart';

void main() {
  final declared = {...AppIcons.all, ...AppImages.all, ...AppAnimations.all};

  test('every typed asset path exists on disk', () {
    final missing = declared.where((path) => !File(path).existsSync());
    expect(missing, isEmpty, reason: 'Missing asset files: $missing');
  });

  test('every bundled icon, image and animation has a typed accessor', () {
    final bundled = ['assets/icons', 'assets/images', 'assets/animations']
        .expand((dir) => Directory(dir).listSync(recursive: true))
        .whereType<File>()
        .map((f) => f.path.replaceAll(r'\', '/'))
        .toSet();
    final unreferenced = bundled.difference(declared);
    expect(
      unreferenced,
      isEmpty,
      reason: 'Bundled but not exposed (move to design/unused_assets?)',
    );
  });

  test('capsule colours map to their pin icons, unknown falls back to red', () {
    expect(AppIcons.capsulePin('Blue'), 'assets/icons/capsule/pin_blue.png');
    expect(AppIcons.mapPin('purple'), 'assets/icons/map/pin_purple.png');
    expect(AppIcons.capsulePin('pink'), 'assets/icons/capsule/pin_red.png');
  });

  test('no Dart file under lib/ uses a raw asset path', () {
    final offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where(
          (f) => !f.path
              .replaceAll(r'\', '/')
              .endsWith('core/assets/app_assets.dart'),
        )
        .where((f) => RegExp(r'''['"]assets/''').hasMatch(f.readAsStringSync()))
        .map((f) => f.path)
        .toList();
    expect(offenders, isEmpty);
  });
}
