import 'package:flutter/material.dart';
import 'package:later/app/session/session_controller.dart';
import 'package:later/data/models/user_profile.dart';
import 'package:later/data/repositories/repositories.dart';
import 'package:later/data/services/geocoding_service.dart';
import 'package:later/data/services/profile_image_cache.dart';
import 'package:later/features/users/user_directory.dart';
import 'package:provider/provider.dart';

import '../fakes/fake_repositories.dart';

/// A signed-in session for widget tests: only [uid] is real.
class FakeSession extends ChangeNotifier implements SessionController {
  FakeSession([this._uid = 'me']);

  final String? _uid;

  @override
  String? get uid => _uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// What the capsule screens read around [child]: who is signed in ([uid]),
/// the [people] they show by name, their pictures, place names and, when
/// given, the [social] repository.
Widget capsuleHost({
  required Widget child,
  String? uid = 'me',
  List<UserProfile> people = const [],
  SocialRepository? social,
}) {
  final users = FakeUserRepository();
  for (final p in people) {
    users.put(p);
  }
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SessionController>.value(value: FakeSession(uid)),
      ChangeNotifierProvider(create: (_) => UserDirectory(users)),
      ChangeNotifierProvider(
        create: (_) => ProfileImageCache(
          FakeImageStorageRepository(),
          evict: (_) async {},
        ),
      ),
      Provider(create: (_) => GeocodingService()),
      if (social != null) Provider<SocialRepository>.value(value: social),
    ],
    child: child,
  );
}
