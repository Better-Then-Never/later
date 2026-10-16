import 'package:flutter_test/flutter_test.dart';
import 'package:later/app/later_app.dart';

void main() {
  test('snow falls from December 31st through February', () {
    expect(isSnowSeason(DateTime(2026, 12, 30)), isFalse);
    expect(isSnowSeason(DateTime(2026, 12, 31)), isTrue);
    expect(isSnowSeason(DateTime(2027, 1, 15)), isTrue);
    expect(isSnowSeason(DateTime(2027, 2, 28)), isTrue);
    expect(isSnowSeason(DateTime(2027, 3, 1)), isFalse);
    expect(isSnowSeason(DateTime(2027, 7, 1)), isFalse);
  });
}
