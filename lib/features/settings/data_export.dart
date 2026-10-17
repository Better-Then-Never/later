import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/session/session_controller.dart';
import '../../core/errors/app_failure.dart';
import '../../core/l10n/l10n.dart';
import '../../core/logging/app_logger.dart';
import '../../data/firebase/firestore_mappers.dart';
import '../../data/models/capsule.dart';
import '../../data/models/chat.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/user_settings.dart';
import '../friends/friends_store.dart';
import '../history/own_capsules_store.dart';
import '../messages/chats_store.dart';
import '../users/user_directory.dart';
import 'settings_store.dart';

/// "Download my data": what Later keeps about the user, as one JSON file
/// shared through the system sheet. Photos and recordings are listed by
/// their links (the files stay where they are); chats are listed with
/// their last message, not every message.
abstract final class DataExport {
  static String _date(DateTime? d) => d?.toUtc().toIso8601String() ?? '';

  /// The file's content (tests read it as a map).
  static Map<String, Object?> build({
    required UserProfile profile,
    String? email,
    required UserSettings settings,
    required List<Capsule> capsules,
    required Map<String, String> friends,
    required Set<String> blocked,
    required List<Chat> chats,
    required DateTime now,
  }) => {
    'exportedAt': _date(now),
    'profile': {
      'uid': profile.uid,
      'name': profile.name,
      'username': profile.username,
      'email': ?email,
      'about': profile.about,
      'verified': profile.verified,
      'followers': profile.followerCount,
      'following': profile.followingCount,
      'favorites': profile.favorites.toList()..sort(),
    },
    'settings': {
      'language': ?settings.language,
      'notifications': FirestoreMappers.notificationSettings(
        settings.notifications,
      ),
      'privacy': FirestoreMappers.privacySettings(settings.privacy),
      'mutedChats': settings.mutedChats.toList()..sort(),
      'pinnedChats': settings.pinnedChats,
      'pinnedFriends': settings.pinnedFriends,
    },
    'capsules': [
      for (final c in capsules)
        {
          'id': c.id,
          'owner': c.ownerId == profile.uid ? 'me' : c.ownerId,
          'title': c.title,
          'description': ?c.description,
          'privacy': c.privacy.name,
          'color': c.color.name,
          'createdAt': _date(c.createdAt),
          'openAt': ?(c.openAt == null ? null : _date(c.openAt)),
          if (c.location case final at?)
            'location': {'latitude': at.latitude, 'longitude': at.longitude},
          'place': ?c.placeName,
          'photo': ?c.imageUrl,
          if (c.coAuthors.isNotEmpty) 'coAuthors': c.coAuthors,
        },
    ],
    'friends': [
      for (final e in friends.entries) {'uid': e.key, 'name': e.value},
    ],
    'blocked': blocked.toList()..sort(),
    'chats': [
      for (final c in chats)
        {
          'id': c.id,
          if (c.isGroup) 'group': c.name,
          'with': c.othersThan(profile.uid),
          'lastMessage': c.lastMessage,
          'lastUpdated': _date(c.lastUpdated),
        },
    ],
  };

  /// Builds the file from what the app has loaded and opens the share
  /// sheet. Null when shared, otherwise why it could not be.
  static Future<AppFailure?> share(BuildContext context) async {
    final session = context.read<SessionController>();
    final profile = session.profile;
    if (profile == null) {
      return ValidationFailure(AppL10n.current.settingsDownloadDataFailed);
    }
    final settings = context.read<SettingsStore>().settings;
    final capsules = context.read<OwnCapsulesStore>().capsules;
    final friendsStore = context.read<FriendsStore>();
    final chats = context.read<ChatsStore>().chats;
    final directory = context.read<UserDirectory>();
    try {
      final names = await directory.resolveAll(friendsStore.friendIds);
      final now = DateTime.now();
      final data = build(
        profile: profile,
        email: session.email,
        settings: settings,
        capsules: capsules,
        friends: {
          for (final id in friendsStore.friendIds) id: names[id]?.name ?? '',
        },
        blocked: friendsStore.blocked,
        chats: chats,
        now: now,
      );
      final dir = await getTemporaryDirectory();
      final day = now.toIso8601String().substring(0, 10);
      final file = File('${dir.path}/later-data-$day.json');
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(data),
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          subject: AppL10n.current.settingsDownloadData,
        ),
      );
      return null;
    } catch (e, st) {
      AppLogger.warning('Exporting the data failed', error: e, stackTrace: st);
      return AppFailure.from(
        e,
        fallbackMessage: AppL10n.current.settingsDownloadDataFailed,
      );
    }
  }
}
