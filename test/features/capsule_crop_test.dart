import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:later/data/firebase/firestore_mappers.dart';
import 'package:later/data/models/capsule.dart';
import 'package:later/data/models/geo_position.dart';
import 'package:later/data/services/image_processor.dart';
import 'package:later/features/capsules/creation/creation_draft.dart';
import 'package:later/features/capsules/creation/widgets/how_it_opens_sheet.dart';

import '../helpers/test_app.dart';

void main() {
  group('the square a capsule shows (Adjust)', () {
    test('the middle square of a wide and of a tall photo', () {
      final wide = CapsuleCrop.centre(2);
      expect(wide.x, 0.25);
      expect(wide.w, 0.5);
      expect(wide.h, 1);
      final tall = CapsuleCrop.centre(0.5);
      expect(tall.y, 0.25);
      expect(tall.h, 0.5);
      expect(tall.w, 1);
    });

    test('read only when it lies inside the photo', () {
      const ok = CapsuleCrop(x: 0.1, y: 0.2, w: 0.5, h: 0.3);
      expect(CapsuleCrop.parse(ok.toMap()), ok);
      expect(CapsuleCrop.parse({'x': 0.6, 'y': 0, 'w': 0.5, 'h': 0.3}), isNull);
      expect(CapsuleCrop.parse({'x': 0, 'y': 0, 'w': 0.5}), isNull);
      expect(CapsuleCrop.parse('middle'), isNull);
    });

    test('saved with the capsule; dropped first by an older server', () {
      const crop = CapsuleCrop(x: 0.1, y: 0.2, w: 0.5, h: 0.3);
      final map = FirestoreMappers.newCapsule(
        const CapsuleDraft(
          ownerId: 'u1',
          title: 'T',
          privacy: CapsulePrivacy.public,
          color: CapsuleColor.red,
          location: GeoPosition(1, 2),
          imagePath: '/tmp/x.jpg',
          crop: crop,
        ),
        imageUrl: 'https://i',
      );
      expect(map['crop'], crop.toMap());
      expect(FirestoreMappers.withoutLatest(map).containsKey('crop'), isFalse);
      expect(
        FirestoreMappers.capsule('c', {...map, 'crop': crop.toMap()}).crop,
        crop,
      );
    });

    test('kept in an unfinished capsule', () {
      const crop = CapsuleCrop(x: 0, y: 0.25, w: 1, h: 0.5);
      final draft = CreationDraft.fromJson(
        const CreationDraft(imagePath: '/p.jpg', crop: crop).toJson(),
      );
      expect(draft.crop, crop);
    });

    test('the thumbnail is the chosen square', () async {
      // A 400 x 200 photo: left half red, right half blue.
      final photo = img.Image(width: 400, height: 200);
      img.fill(photo, color: img.ColorRgb8(255, 0, 0));
      img.fillRect(
        photo,
        x1: 200,
        y1: 0,
        x2: 399,
        y2: 199,
        color: img.ColorRgb8(0, 0, 255),
      );
      final dir = await Directory.systemTemp.createTemp('crop');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/p.jpg')
        ..writeAsBytesSync(img.encodeJpg(photo, quality: 100));
      final bytes = await const ImageProcessor().capsuleSquareJpegFromFile(
        file.path,
        size: 100,
        crop: (x: 0.5, y: 0, w: 0.5, h: 1),
      );
      final square = img.decodeJpg(bytes)!;
      expect(square.width, 100);
      expect(square.height, 100);
      final middle = square.getPixel(50, 50);
      expect(middle.b, greaterThan(200), reason: 'the right, blue half');
      expect(middle.r, lessThan(60));
    });
  });

  group('How does it open?', () {
    testWidgets('a year from now, then Done', (tester) async {
      ({bool cancelled, DateTime? openAt, OpenWhere openWhere})? result;
      await tester.pumpWidget(
        testApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  result = await HowItOpensSheet.show(context, openAt: null),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('How does it open?'), findsOneWidget);
      expect(
        find.text('Opens anytime. It stays on the map where you left it.'),
        findsOneWidget,
      );
      await tester.tap(find.text('In a year'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Opens on '), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(result!.cancelled, isFalse);
      final now = DateTime.now();
      expect(result!.openAt!.year, now.year + 1);
    });

    testWidgets('only back here: within 150 m of the spot', (tester) async {
      ({bool cancelled, DateTime? openAt, OpenWhere openWhere})? result;
      await tester.pumpWidget(
        testApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  result = await HowItOpensSheet.show(context, openAt: null),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Only when I'm back here"));
      await tester.pumpAndSettle();
      expect(
        find.text('Opens anytime, only within 150 m of this spot.'),
        findsOneWidget,
      );
      await tester.tap(find.text('In a year'));
      await tester.pumpAndSettle();
      expect(find.textContaining('only within 150 m'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(result!.openWhere, OpenWhere.here);
      expect(result!.openAt!.year, DateTime.now().year + 1);
    });
  });
}
