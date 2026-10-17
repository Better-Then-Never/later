import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/errors/app_failure.dart';
import '../../core/l10n/l10n.dart';
import '../../core/logging/app_logger.dart';
import '../../core/session/session_scoped.dart';
import '../../data/models/capsule.dart';
import '../../data/models/chat.dart';
import '../../data/repositories/repositories.dart';

/// The signed-in user's chats, live, and the actions on a conversation.
///
/// Replaces main's ChatService (which read FirebaseAuth directly and threw
/// when signed out): one instance follows the session, failures are
/// reported as [AppFailure]s instead of raw exception text.
class ChatsStore extends ChangeNotifier implements SessionScoped {
  ChatsStore(this._chats);

  final ChatRepository _chats;

  StreamSubscription<List<Chat>>? _sub;
  StreamSubscription<List<Chat>>? _groupSub;
  String? _uid;
  List<Chat> _list = const [];
  List<Chat> _groups = const [];
  List<Chat>? _merged;
  bool _loaded = false;
  bool _failed = false;
  Set<String> _muted = const {};

  /// The last messages seen in each recently opened chat (by friend), so
  /// opening it again shows them at once instead of a spinner (F-03).
  final Map<String, List<ChatMessage>> _recent = {};
  static const _recentChats = 12;

  String? get uid => _uid;

  /// Two-person chats with messages and every group, most recently active
  /// first.
  List<Chat> get chats => _merged ??= [..._list, ..._groups]
    ..sort(
      (a, b) => (b.lastUpdated ?? DateTime(0)).compareTo(
        a.lastUpdated ?? DateTime(0),
      ),
    );
  bool get isLoaded => _loaded;
  bool get hasError => _failed;

  /// Chats the user muted (from their settings).
  Set<String> get muted => _muted;
  bool isMuted(String chatId) => _muted.contains(chatId);

  set muted(Set<String> value) {
    if (setEquals(value, _muted)) return;
    _muted = value;
    notifyListeners();
  }

  /// Unread messages over all chats that are not muted (navbar badge).
  int get totalUnread {
    final me = _uid;
    if (me == null) return 0;
    return chats
        .where((c) => !_muted.contains(c.id))
        .fold(0, (sum, c) => sum + c.unreadFor(me));
  }

  /// The chat with [friendUid], once it has messages.
  Chat? chatWith(String friendUid) {
    final me = _uid;
    if (me == null || me == friendUid) return null;
    final id = Chat.idBetween(me, friendUid);
    for (final c in _list) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// The chat (two-person or group) with id [chatId], once listed.
  Chat? chatById(String chatId) {
    for (final c in chats) {
      if (c.id == chatId) return c;
    }
    return null;
  }

  /// The id of the conversation with [friendUid], also before it exists.
  String? chatIdWith(String friendUid) {
    final me = _uid;
    if (me == null || me == friendUid) return null;
    return Chat.idBetween(me, friendUid);
  }

  @override
  void attach(String uid) {
    _uid = uid;
    _listen(uid);
  }

  /// Subscribes again after the chat list failed to load.
  void retry() {
    final uid = _uid;
    if (uid == null) return;
    _failed = false;
    _loaded = false;
    notifyListeners();
    _listen(uid);
  }

  void _listen(String uid) {
    unawaited(_groupSub?.cancel());
    _groupSub = _chats.watchGroups(uid).listen(
      (groups) {
        _groups = groups;
        _merged = null;
        notifyListeners();
      },
      onError: (Object e, StackTrace st) =>
          AppLogger.warning('Groups stream failed', error: e, stackTrace: st),
    );
    unawaited(_sub?.cancel());
    _sub = _chats
        .watchChats(uid)
        .listen(
          (chats) {
            _list = chats;
            _merged = null;
            _loaded = true;
            _failed = false;
            notifyListeners();
          },
          onError: (Object e, StackTrace st) {
            AppLogger.warning('Chats stream failed', error: e, stackTrace: st);
            _loaded = true;
            _failed = true;
            notifyListeners();
          },
        );
  }

  @override
  void detach() {
    unawaited(_sub?.cancel());
    _sub = null;
    unawaited(_groupSub?.cancel());
    _groupSub = null;
    _uid = null;
    _list = const [];
    _groups = const [];
    _merged = null;
    _loaded = false;
    _failed = false;
    _muted = const {};
    _recent.clear();
    notifyListeners();
  }

  /// What chat [chatId] showed when it was last open.
  List<ChatMessage>? recentIn(String chatId) => _recent[chatId];

  void rememberMessages(String chatId, List<ChatMessage> messages) {
    // Most recently used last; the oldest chat is forgotten first.
    _recent.remove(chatId);
    _recent[chatId] = messages;
    if (_recent.length > _recentChats) _recent.remove(_recent.keys.first);
  }

  @override
  Future<void> beforeSignOut(String uid) async {}

  /// The newest [limit] messages of [chatId].
  Stream<List<ChatMessage>> messagesIn(String chatId, {int limit = 50}) =>
      _uid == null
      ? Stream.value(const [])
      : _chats.watchMessages(chatId, limit: limit);

  /// An id for a new message in [chatId] (made on the device).
  String? newMessageIdIn(String chatId) =>
      _uid == null ? null : _chats.newMessageId(chatId);

  /// Sends [text] to group [groupId].
  Future<AppFailure?> sendToGroup(
    String groupId,
    String text, {
    required String messageId,
    MessageReply? replyTo,
  }) => _run(
    'Failed to send to a group',
    AppL10n.current.messagesSendFailed,
    (me) => _chats.sendToGroup(
      groupId: groupId,
      from: me,
      text: text,
      messageId: messageId,
      replyTo: replyTo,
    ),
  );

  /// A new group named [name], inviting [invitees]: its id, or why not.
  Future<(String?, AppFailure?)> createGroup(
    String name,
    List<String> invitees,
  ) async {
    String? id;
    final failure = await _run(
      'Failed to create a group',
      AppL10n.current.messagesGroupFailed,
      (me) async => id = await _chats.createGroup(
        creator: me,
        name: name,
        invitees: invitees,
      ),
    );
    return (id, failure);
  }

  Future<AppFailure?> inviteToGroup(String groupId, List<String> invitees) =>
      _run(
        'Failed to invite to a group',
        AppL10n.current.messagesGroupFailed,
        (me) => _chats.inviteToGroup(groupId, by: me, invitees: invitees),
      );

  Future<AppFailure?> renameGroup(String groupId, String name) => _run(
    'Failed to rename a group',
    AppL10n.current.messagesGroupFailed,
    (_) => _chats.renameGroup(groupId, name),
  );

  Future<AppFailure?> leaveGroup(String groupId) => _run(
    'Failed to leave a group',
    AppL10n.current.messagesGroupFailed,
    (me) => _chats.leaveGroup(groupId, me),
  );

  /// The user has read group [groupId]; failures are only logged.
  Future<void> markGroupRead(String groupId) async {
    final me = _uid;
    if (me == null) return;
    try {
      await _chats.markGroupRead(groupId, me);
    } catch (e) {
      AppLogger.debug('Marking the group read failed: $e');
    }
  }

  /// Tells the others in [chatId] the user is typing, or stopped; failures
  /// are only logged (it is a hint).
  Future<void> setTyping(String chatId, {required bool typing}) async {
    final me = _uid;
    if (me == null) return;
    try {
      await _chats.setTyping(chatId, me, typing: typing);
    } catch (e) {
      AppLogger.debug('Typing hint not sent: $e');
    }
  }

  /// Who else says they are typing in [chatId], and since when.
  Stream<Map<String, DateTime>> typingIn(String chatId) {
    final me = _uid;
    if (me == null) return const Stream.empty();
    return _chats.watchTyping(chatId).map((all) => {...all}..remove(me));
  }

  Future<AppFailure?> sendText(
    String to,
    String text, {
    required String messageId,
    MessageReply? replyTo,
    bool forwarded = false,
  }) => _run(
    'Failed to send message',
    AppL10n.current.messagesSendFailed,
    (me) => _chats.sendText(
      from: me,
      to: to,
      text: text,
      messageId: messageId,
      replyTo: replyTo,
      forwarded: forwarded,
    ),
  );

  /// Sends [text] on, marked "Forwarded", to a friend or a group.
  Future<AppFailure?> forward(
    String text, {
    String? friendUid,
    String? groupId,
  }) async {
    final chatId =
        groupId ?? (friendUid == null ? null : chatIdWith(friendUid));
    final id = chatId == null ? null : newMessageIdIn(chatId);
    if (id == null) return AuthFailure(AppL10n.current.messagesSignedOut);
    return groupId != null
        ? _run(
            'Failed to forward to a group',
            AppL10n.current.messagesSendFailed,
            (me) => _chats.sendToGroup(
              groupId: groupId,
              from: me,
              text: text,
              messageId: id,
              forwarded: true,
            ),
          )
        : sendText(friendUid!, text, messageId: id, forwarded: true);
  }

  /// Uploads the photo at [localPath] for message [messageId] to [to]:
  /// the stored photo, or why it failed.
  Future<(ChatPhoto?, AppFailure?)> uploadPhoto(
    String to,
    String localPath, {
    required String messageId,
  }) async {
    ChatPhoto? photo;
    final failure = await _run(
      'Failed to upload a chat photo',
      AppL10n.current.messagesSendFailed,
      (me) async {
        try {
          photo = await _chats.uploadPhoto(
            from: me,
            to: to,
            messageId: messageId,
            localPath: localPath,
          );
        } on FormatException catch (e) {
          throw ValidationFailure(
            AppL10n.current.messagesPhotoUnreadable,
            cause: e,
          );
        }
      },
    );
    return (photo, failure);
  }

  Future<AppFailure?> sendPhoto(
    String to,
    ChatPhoto photo, {
    required String messageId,
    String caption = '',
    MessageReply? replyTo,
  }) => _run(
    'Failed to send a photo',
    AppL10n.current.messagesSendFailed,
    (me) => _chats.sendPhoto(
      from: me,
      to: to,
      messageId: messageId,
      photo: photo,
      caption: caption,
      replyTo: replyTo,
    ),
  );

  /// Uploads the recording at [localPath] for message [messageId] to [to].
  Future<(ChatAudio?, AppFailure?)> uploadVoice(
    String to,
    String localPath, {
    required String messageId,
  }) async {
    ChatAudio? audio;
    final failure = await _run(
      'Failed to upload a voice message',
      AppL10n.current.messagesSendFailed,
      (me) async => audio = await _chats.uploadVoice(
        from: me,
        to: to,
        messageId: messageId,
        localPath: localPath,
      ),
    );
    return (audio, failure);
  }

  Future<AppFailure?> sendVoice(
    String to,
    ChatAudio audio, {
    required String messageId,
    required int durationMs,
    required List<int> waveform,
    MessageReply? replyTo,
  }) => _run(
    'Failed to send a voice message',
    AppL10n.current.messagesSendFailed,
    (me) => _chats.sendVoice(
      from: me,
      to: to,
      messageId: messageId,
      audio: audio,
      durationMs: durationMs,
      waveform: waveform,
      replyTo: replyTo,
    ),
  );

  Future<AppFailure?> setMessageReaction(
    String chatId,
    String messageId,
    ReactionType? type,
  ) => _run(
    'Failed to react to a message',
    AppL10n.current.messagesReactFailed,
    (me) => _chats.setMessageReaction(chatId, messageId, uid: me, type: type),
  );

  Future<AppFailure?> deleteMessage(
    String chatId,
    String messageId, {
    String? imagePath,
  }) => _run(
    'Failed to delete a message',
    AppL10n.current.messagesDeleteFailed,
    (_) => _chats.deleteMessage(chatId, messageId, imagePath: imagePath),
  );

  Future<AppFailure?> clearHistory(String friendUid) => _run(
    'Failed to clear history',
    AppL10n.current.messagesClearFailed,
    (me) => _chats.clearHistory(Chat.idBetween(me, friendUid)),
  );

  /// The user has read the chat with [friendUid] (without telling the friend
  /// when [receipt] is false); failures are only logged.
  Future<void> markRead(String friendUid, {bool receipt = true}) async {
    final me = _uid;
    if (me == null || me == friendUid) return;
    try {
      await _chats.markRead(
        Chat.idBetween(me, friendUid),
        reader: me,
        receipt: receipt,
      );
    } catch (e) {
      AppLogger.debug('Marking the chat read failed: $e');
    }
  }

  /// Runs [action] as the signed-in user. [logMessage] goes to the log (in
  /// English); [userMessage] is what the user sees when nothing more
  /// specific is known.
  Future<AppFailure?> _run(
    String logMessage,
    String userMessage,
    Future<void> Function(String me) action,
  ) async {
    final me = _uid;
    if (me == null) return AuthFailure(AppL10n.current.messagesSignedOut);
    try {
      await action(me);
      return null;
    } catch (e, st) {
      AppLogger.warning(logMessage, error: e, stackTrace: st);
      return AppFailure.from(e, fallbackMessage: userMessage);
    }
  }
}
