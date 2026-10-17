import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/features/achievements/achievement_icon.dart';

/// An asset bundle with one achievement artwork (a 1 × 1 PNG).
class _ArtBundle extends CachingAssetBundle {
  static final _png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage({
        'assets/achievements/collector.png': [
          {'asset': 'assets/achievements/collector.png'},
        ],
      })!;
    }
    if (key == 'assets/achievements/collector.png') {
      return ByteData.sublistView(_png);
    }
    throw FlutterError('no asset $key');
  }
}

void main() {
  testWidgets('an achievement with artwork shows it; others keep the icon', (
    tester,
  ) async {
    final bundle = _ArtBundle();
    await tester.runAsync(() => AchievementIcon.preloadArt(bundle));
    expect(
      AchievementIcon.artFor('collector'),
      'assets/achievements/collector.png',
    );
    expect(AchievementIcon.artFor('streak'), isNull);

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: bundle,
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              AchievementIcon(
                id: 'collector',
                icon: Icons.collections,
                tier: 1,
                tiers: 4,
              ),
              AchievementIcon(
                id: 'streak',
                icon: Icons.local_fire_department,
                tier: 0,
                tiers: 5,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
    expect(find.byIcon(Icons.collections), findsNothing);
  });
}
