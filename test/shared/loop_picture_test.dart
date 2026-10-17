import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:later/shared/widgets/loop_picture.dart';

void main() {
  late Directory dir;
  late List<String> frames;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('loop_test');
    frames = [
      for (var i = 0; i < 3; i++)
        (File('${dir.path}/frame_$i.png')
              ..writeAsBytesSync(img.encodePng(img.Image(width: 4, height: 4))))
            .path,
    ];
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  Widget app({bool reduceMotion = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: SizedBox(
        width: 100,
        height: 100,
        child: LoopPicture(
          sources: frames,
          frameDelay: const Duration(milliseconds: 100),
        ),
      ),
    ),
  );

  String shown(WidgetTester tester) {
    final image = tester.widget<Image>(find.byType(Image)).image;
    return (image is ResizeImage ? image.imageProvider : image).toString();
  }

  Future<void> loadFrames(WidgetTester tester) async {
    // Precaching reads the files: real time, not the test clock.
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
  }

  testWidgets('plays the frames once they are loaded, over and over', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await loadFrames(tester);
    final seen = <String>{shown(tester)};
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      seen.add(shown(tester));
    }
    expect(seen, hasLength(3), reason: 'every frame came round');
    expect(seen.first, contains('frame_0'));
  });

  testWidgets('rests on the first frame with reduced motion', (tester) async {
    await tester.pumpWidget(app(reduceMotion: true));
    await loadFrames(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(shown(tester), contains('frame_0'));
  });
}
