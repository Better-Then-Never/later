// The selected capsule's pin (M-02): it grows and jumps, sways smoothly,
// hovers, and lands back. Flutter draws it while the map is still (its
// native marker hides: a native pin that moved blinked); while the map moves
// the map draws it, held in the same pose (an overlay trails a moving map).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:later/data/models/capsule.dart';
import 'package:later/features/map/map_projection.dart';
import 'package:later/features/map/map_viewport.dart';
import 'package:later/features/map/marker_icons.dart';
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
    expect(
      12,
      lessThanOrEqualTo(SelectedPin.maxLift),
      reason: 'the map can pose it at any height it reaches',
    );
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

  test('landing goes from where it was to the plain pin on its spot', () {
    final motion = PinMotion()..ms = 2000;
    final hovering = motion.pose;
    motion.land();
    expect(motion.pose, hovering, reason: 'no jump when it starts');
    motion.ms += SelectedPin.landing.inMilliseconds;
    expect(motion.landed, isTrue);
    expect(motion.pose, (lift: 0.0, scale: 1.0, degrees: 0.0));
    motion.jumpAgain();
    expect(motion.landing, isFalse);
    expect(motion.pose.lift, 0);
  });

  test('the floating pins hide, or the map draws them posed, only those on '
      'the map', () {
    final markers = {_pin('a'), _pin('b', const LatLng(52.1, 21.1)), _pin('c')};
    final hidden = SelectedPin.apply(markers, hidden: ['b', 'x']);
    expect(hidden, hasLength(3));
    for (final m in hidden) {
      expect(m.alpha, m.markerId.value == 'b' ? 0 : 1);
    }
    expect(
      SelectedPin.apply(markers, hidden: ['x']),
      same(markers),
      reason: 'not on the map (inside a cluster): nothing to send',
    );
    expect(SelectedPin.apply(markers), same(markers));
    expect(SelectedPin.spots(markers, ['b', 'x']), {
      'b': const LatLng(52.1, 21.1),
    });

    final bitmap = BitmapDescriptor.defaultMarkerWithHue(1);
    final shadow = BitmapDescriptor.defaultMarkerWithHue(2);
    const pose = (lift: 9.0, scale: SelectedPin.scale, degrees: 3.0);
    final posed = SelectedPin.apply(
      markers,
      posed: {'b': (pose, bitmap)},
      shadow: shadow,
    );
    expect(posed, hasLength(4));
    final b = posed.firstWhere((m) => m.markerId == const MarkerId('b'));
    expect(b.icon, bitmap);
    expect(b.alpha, 1);
    expect(b.rotation, 3);
    expect(b.anchor, SelectedPin.anchorFor(9));
    expect(b.zIndexInt, SelectedPin.pinZ);
    final s = posed.firstWhere((m) => m.markerId == SelectedPin.shadowId('b'));
    expect(s.position, b.position);
    expect(s.zIndexInt, lessThan(b.zIndexInt));
  });

  test('the posed pin stands on its spot, lifted by its anchor', () {
    // The anchor is at the bitmap's bottom for no lift, higher up the more
    // it floats, and always inside the bitmap.
    expect(
      SelectedPin.anchorFor(0).dy * SelectedPin.pinHeight,
      closeTo(SelectedPin.pinSide, 1e-9),
    );
    expect(
      SelectedPin.anchorFor(9).dy * SelectedPin.pinHeight,
      closeTo(SelectedPin.pinSide + 9, 1e-9),
    );
    expect(SelectedPin.anchorFor(99).dy, 1);
    expect(SelectedPin.shadowAnchor.dy, inInclusiveRange(0, 1));
  });

  testWidgets('the map pin bitmaps are drawn once the pins load', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await rootBundle.load('assets/icons/map/pin_red.png');
      final icons = await MarkerIcons.load();
      for (var i = 0; i < 50; i++) {
        if (icons.selectedShadow != null &&
            CapsuleColor.values.every((c) => icons.selectedPin(c) != null)) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(icons.selectedShadow, isNotNull);
      for (final c in CapsuleColor.values) {
        expect(icons.selectedPin(c), isNotNull);
      }
    });
  });

  group('the overlay', () {
    late MapViewport view;
    late PinMotion motion;

    setUp(() {
      view = MapViewport()
        ..start(const CameraPosition(target: _spot, zoom: 16), _padding);
      motion = PinMotion();
    });

    Future<void> pump(
      WidgetTester tester, {
      bool running = true,
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
              motion: motion,
              running: running,
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

    double lift(WidgetTester tester) => projected().dy - pinRect(tester).bottom;

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
      final hovering = lift(tester);
      expect(hovering, inInclusiveRange(6, 12));
      // The slow hover takes a step now and then, not a frame every vsync.
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pump(SelectedPin.hoverStep);
      expect(lift(tester), isNot(hovering));
    });

    testWidgets('held while the map moves, it goes on from the same pose', (
      tester,
    ) async {
      await pump(tester);
      await tester.pump(const Duration(milliseconds: 500));
      final held = motion.ms;
      final pose = motion.pose;
      await pump(tester, running: false);
      await tester.pump(const Duration(seconds: 2));
      expect(motion.ms, held, reason: 'no time passes for it');
      expect(tester.binding.hasScheduledFrame, isFalse);
      await pump(tester);
      expect(motion.pose, pose, reason: 'back exactly as the map drew it');
      await tester.pump(const Duration(milliseconds: 100));
      expect(motion.ms, greaterThan(held));
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
      motion.land();
      await pump(tester, onLanded: () => landed++);
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
      expect(lift(tester), closeTo(SelectedPin.hoverLift, 0.01));
      expect(tester.binding.hasScheduledFrame, isFalse);
      motion.land();
      await pump(tester, reduced: true, onLanded: () => landed++);
      await tester.pump();
      expect(landed, 1);
      expect(pinRect(tester).bottomCenter.dy, closeTo(projected().dy, 0.01));
    });
  });
}
