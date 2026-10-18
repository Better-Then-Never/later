// The selected capsule's pin (M-02): it grows and jumps, sways smoothly,
// hovers, and lands back, drawn by Flutter over the map while its native
// marker hides (a native pin that moved blinked).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:later/data/models/capsule.dart';
import 'package:later/features/map/map_projection.dart';
import 'package:later/features/map/map_viewport.dart';
import 'package:later/features/map/selected_pin.dart';
import 'package:later/features/map/widgets/selected_pin_overlay.dart';

Marker _pin(String id, [LatLng at = const LatLng(52, 21)]) => Marker(
  markerId: MarkerId(id),
  position: at,
  icon: BitmapDescriptor.defaultMarker,
);

const _spot = LatLng(52.23, 21.01);
const _size = Size(400, 800);
const _padding = EdgeInsets.only(top: 30, bottom: 120);

void main() {
  test('it grows and jumps, lands near the hover, then bobs gently', () {
    expect(SelectedPin.liftAt(0), 0, reason: 'starts on its spot');
    expect(SelectedPin.scaleAt(0), 1, reason: 'as big as the native pin');
    expect(
      SelectedPin.liftAt(110),
      closeTo(14, 0.01),
      reason: 'the top of the jump',
    );
    expect(SelectedPin.scaleAt(110), SelectedPin.scale);
    expect(SelectedPin.liftAt(SelectedPin.jumpEnd), SelectedPin.hoverLift);
    final bob = [
      for (
        var ms = SelectedPin.swayEnd;
        ms < SelectedPin.swayEnd + 1600;
        ms += 50
      )
        SelectedPin.liftAt(ms),
    ];
    expect(bob.reduce((a, b) => a > b ? a : b), lessThanOrEqualTo(12));
    expect(bob.reduce((a, b) => a < b ? a : b), greaterThanOrEqualTo(6));
  });

  test('the sway is smooth and dies down before the hover', () {
    var previous = 0.0;
    for (var ms = SelectedPin.jumpEnd; ms < SelectedPin.swayEnd; ms += 8) {
      final r = SelectedPin.rotationAt(ms);
      expect(r.abs(), lessThanOrEqualTo(6));
      // One frame never turns it by more than a fraction of a degree.
      expect((r - previous).abs(), lessThan(0.7));
      previous = r;
    }
    expect(
      SelectedPin.rotationAt(SelectedPin.swayEnd - 8).abs(),
      lessThan(0.2),
    );
    expect(SelectedPin.rotationAt(SelectedPin.swayEnd + 500), 0);
  });

  test('only the floating pins hide, and only those on the map', () {
    final markers = {_pin('a'), _pin('b', const LatLng(52.1, 21.1)), _pin('c')};
    final out = SelectedPin.hide(markers, ['b', 'x']);
    expect(out, hasLength(3));
    for (final m in out) {
      expect(m.alpha, m.markerId.value == 'b' ? 0 : 1);
    }
    expect(
      SelectedPin.hide(markers, ['x']),
      same(markers),
      reason: 'not on the map (inside a cluster): nothing to send',
    );
    expect(SelectedPin.hide(markers, const []), same(markers));
    expect(SelectedPin.spots(markers, ['b', 'x']), {
      'b': const LatLng(52.1, 21.1),
    });
  });

  group('the overlay', () {
    late MapViewport view;

    setUp(() {
      view = MapViewport()
        ..start(const CameraPosition(target: _spot, zoom: 16), _padding);
    });

    Future<void> pump(
      WidgetTester tester, {
      bool landing = false,
      VoidCallback? onLanded,
      bool reduced = false,
    }) async {
      tester.view.physicalSize = _size * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: _size, disableAnimations: reduced),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SelectedPinOverlay(
              color: CapsuleColor.blue,
              spot: _spot,
              view: view,
              landing: landing,
              onLanded: onLanded,
            ),
          ),
        ),
      );
    }

    Rect pinRect(WidgetTester tester) => tester.getRect(find.byType(Image));

    Offset projected() => MapProjection.toScreen(
      _spot,
      view.value!.camera,
      _size,
      view.value!.padding,
    );

    testWidgets('starts exactly as the native pin: 48 dp, on its spot', (
      tester,
    ) async {
      await pump(tester);
      final rect = pinRect(tester);
      expect(rect.size, const Size.square(SelectedPin.side));
      expect(rect.bottomCenter, projected());
    });

    testWidgets('jumps, grows, then hovers above its spot', (tester) async {
      await pump(tester);
      await tester.pump(const Duration(milliseconds: 110));
      final top = pinRect(tester);
      expect(top.width, closeTo(SelectedPin.side * SelectedPin.scale, 0.01));
      expect(projected().dy - top.bottom, closeTo(14, 0.5));
      await tester.pump(const Duration(seconds: 3));
      final lift = projected().dy - pinRect(tester).bottom;
      expect(lift, inInclusiveRange(6, 12));
      // The slow hover takes a step now and then, not a frame every vsync.
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pump(SelectedPin.hoverStep);
      expect(projected().dy - pinRect(tester).bottom, isNot(lift));
    });

    testWidgets('follows the map, with the padding of each camera', (
      tester,
    ) async {
      await pump(tester);
      final before = pinRect(tester).bottomCenter;
      view.moved(const CameraPosition(target: LatLng(52.231, 21.01), zoom: 16));
      await tester.pump();
      expect(pinRect(tester).bottomCenter.dy, greaterThan(before.dy));
      expect(pinRect(tester).bottomCenter.dy, closeTo(projected().dy, 0.5));
      // A new padding the map has taken, then a camera relative to it.
      view
        ..asked(_padding.copyWith(bottom: 300))
        ..confirmed()
        ..moved(const CameraPosition(target: LatLng(52.23, 21.01), zoom: 16));
      await tester.pump();
      expect(view.value!.padding.bottom, 300);
      expect(pinRect(tester).bottomCenter.dy, closeTo(projected().dy, 0.5));
    });

    testWidgets('lands back on its spot, as the native pin, and says so', (
      tester,
    ) async {
      var landed = 0;
      await pump(tester, onLanded: () => landed++);
      await tester.pump(const Duration(seconds: 2));
      await pump(tester, landing: true, onLanded: () => landed++);
      await tester.pump(SelectedPin.landing);
      await tester.pump(const Duration(milliseconds: 16));
      expect(landed, 1);
      final rect = pinRect(tester);
      expect(rect.size, const Size.square(SelectedPin.side));
      expect(rect.bottomCenter.dy, closeTo(projected().dy, 0.01));
      // Down, it stops: no more frames.
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('reduced motion: it hovers at once and lands at once', (
      tester,
    ) async {
      var landed = 0;
      await pump(tester, reduced: true, onLanded: () => landed++);
      expect(
        projected().dy - pinRect(tester).bottom,
        closeTo(SelectedPin.hoverLift, 0.01),
      );
      expect(tester.binding.hasScheduledFrame, isFalse);
      await pump(
        tester,
        reduced: true,
        landing: true,
        onLanded: () => landed++,
      );
      await tester.pump();
      expect(landed, 1);
      expect(pinRect(tester).bottomCenter.dy, closeTo(projected().dy, 0.01));
    });
  });
}
