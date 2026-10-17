// The entitlements/limits extension point (B7): tolerant reads, ceilings,
// one read per sign-in, defaults without it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/app/entitlements_store.dart';
import 'package:later/core/config/limits.dart';
import 'package:later/data/repositories/repositories.dart';
import 'package:provider/provider.dart';

class _Config implements ConfigRepository {
  _Config(this.data);

  Map<String, Object?>? data;
  int reads = 0;

  @override
  Future<Map<String, Object?>?> limits() async {
    reads++;
    return data;
  }
}

void main() {
  test('read tolerantly; never above the rules', () {
    expect(Limits.fromMap(null), Limits.standard);
    final l = Limits.fromMap({
      'capsulesPerWeek': 14,
      'loopFrames': 6,
      'coAuthors': 99,
      'groupMembers': 'many',
      'pinnedFriends': 0,
    });
    expect(l.capsulesPerWeek, 14);
    expect(l.loopFrames, 6);
    expect(l.coAuthors, Limits.maxCoAuthors, reason: 'above the rules');
    expect(l.groupMembers, Limits.maxGroupMembers, reason: 'not a number');
    expect(l.pinnedFriends, 3, reason: 'below one');
    expect(Limits.fromMap({'capsulesPerWeek': null}).capsulesPerWeek, isNull);
  });

  test('the store reads once per sign-in and forgets on sign-out', () async {
    final config = _Config({'loopFrames': 4});
    final store = EntitlementsStore(config)..attach('me');
    await pumpEventQueue();
    expect(store.limits.loopFrames, 4);
    expect(config.reads, 1);
    store.detach();
    expect(store.limits, Limits.standard);
  });

  testWidgets('pages without the store get the defaults', (tester) async {
    late Limits seen;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          seen = EntitlementsStore.of(context);
          return const SizedBox();
        },
      ),
    );
    expect(seen, Limits.standard);

    final store = EntitlementsStore(_Config({'coAuthors': 2}))..attach('me');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: store,
        child: Builder(
          builder: (context) {
            seen = EntitlementsStore.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pump();
    expect(store.limits.coAuthors, 2);
  });
}
