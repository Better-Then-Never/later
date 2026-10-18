// The selected capsule's pin (M-02): it pops within the motion budget, and
// only its marker changes.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:later/core/theme/app_motion.dart';
import 'package:later/data/models/capsule.dart';
import 'package:later/features/map/marker_icons.dart';
import 'package:later/features/map/selected_pin.dart';

Marker _pin(String id) => Marker(
  markerId: MarkerId(id),
  position: const LatLng(52, 21),
  icon: BitmapDescriptor.defaultMarker,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a quick pop that settles, within the motion budget', () {
    final scales = [for (final f in SelectedPin.frames) f.scale];
    final peak = scales.reduce((a, b) => a > b ? a : b);
    expect(scales.first, greaterThan(1));
    expect(scales.last, lessThan(peak), reason: 'settles after the overshoot');
    expect(SelectedPin.frames.last.ring, 1);
    expect(
      SelectedPin.frameTime * SelectedPin.frames.length,
      lessThanOrEqualTo(AppMotion.reveal),
    );
  });

  test('only the selected marker changes, and it goes on top', () {
    final markers = {_pin('a'), _pin('b'), _pin('c')};
    final icon = BitmapDescriptor.defaultMarkerWithHue(1);
    final out = SelectedPin.apply(markers, 'b', icon);
    expect(out, hasLength(3));
    final b = out.firstWhere((m) => m.markerId == const MarkerId('b'));
    expect(b.icon, icon);
    expect(b.zIndexInt, SelectedPin.zIndex);
    expect(out.where((m) => m.markerId != const MarkerId('b')).toSet(), {
      _pin('a'),
      _pin('c'),
    });
    expect(SelectedPin.apply(markers, null, icon), same(markers));
    expect(
      SelectedPin.apply(markers, 'x', icon),
      same(markers),
      reason: 'not on the map (inside a cluster)',
    );
    expect(
      SelectedPin.apply(markers, 'b', null),
      same(markers),
      reason: 'frames not drawn yet',
    );
  });

  testWidgets('the frames are drawn for every colour once the pins load', (
    tester,
  ) async {
    await tester.runAsync(() async {
      // The pins come from the real assets.
      await rootBundle.load('assets/icons/map/pin_red.png');
      final icons = await MarkerIcons.load();
      for (var i = 0; i < 50; i++) {
        if (CapsuleColor.values.every((c) => icons.selectedFrames(c) != null)) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      for (final c in CapsuleColor.values) {
        expect(icons.selectedFrames(c), hasLength(SelectedPin.frames.length));
      }
    });
  });
}
