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

  test('a jump, a sway and a hover, within the motion budget', () {
    final lifts = [for (final f in SelectedPin.frames) f.lift];
    expect(lifts.first, greaterThan(lifts.last), reason: 'jumps, then lands');
    expect(lifts.last, greaterThan(0), reason: 'rests hovering');
    expect(SelectedPin.rotationAt(0), 0, reason: 'no sway mid-jump');
    expect(
      SelectedPin.rotationAt(SelectedPin.steps - 1),
      0,
      reason: 'rests upright',
    );
    expect(
      SelectedPin.frameAt(SelectedPin.steps - 1),
      SelectedPin.frames.length - 1,
    );
    expect(
      SelectedPin.stepTime * SelectedPin.steps,
      lessThanOrEqualTo(AppMotion.reveal),
    );
  });

  test('only the selected marker changes, and it goes on top', () {
    final markers = {_pin('a'), _pin('b'), _pin('c')};
    final icon = BitmapDescriptor.defaultMarkerWithHue(1);
    final out = SelectedPin.apply(markers, 'b', icon, rotation: 7);
    expect(out, hasLength(3));
    final b = out.firstWhere((m) => m.markerId == const MarkerId('b'));
    expect(b.icon, icon);
    expect(b.zIndexInt, SelectedPin.zIndex);
    expect(b.rotation, 7);
    expect(b.anchor, SelectedPin.anchor, reason: 'anchored at its spot');
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
