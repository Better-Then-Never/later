import 'package:flutter_test/flutter_test.dart';
import 'package:later/data/firebase/firestore_mappers.dart';
import 'package:later/data/models/profile_stamp.dart';

void main() {
  test('missing or unknown stamp values read as Classic, White', () {
    final p = FirestoreMappers.userProfile('a', {'name': 'A', 'username': 'a'});
    expect(p.stamp, const ProfileStampStyle());
    expect(p.homeTown, '');
    final q = FirestoreMappers.userProfile('a', {
      'name': 'A',
      'username': 'a',
      'stampShape': 'star',
      'stampColor': 'pink',
    });
    expect(q.stamp.shape, StampShape.classic);
    expect(q.stamp.color, StampColor.white);
  });

  test('a stored stamp and home town are read back', () {
    final p = FirestoreMappers.userProfile('a', {
      'name': 'A',
      'username': 'a',
      'stampShape': 'round',
      'stampColor': '#2a998f',
      'homeTown': 'Warszawa',
    });
    expect(p.stamp.shape, StampShape.round);
    expect(p.stamp.color.value, '#2A998F');
    expect(p.stamp.color.argb, 0xFF2A998F);
    expect(p.homeTown, 'Warszawa');
  });

  test('custom colours are stored as #RRGGBB, names as names', () {
    expect(StampColor.custom(0xFF2A998F).value, '#2A998F');
    expect(StampColor.named('forest').value, 'forest');
    expect(StampColor.named('nope'), StampColor.white);
    expect(StampColor.white.isCustom, isFalse);
  });
}
