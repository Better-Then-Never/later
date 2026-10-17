import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/errors/app_failure.dart';
import '../../core/l10n/l10n.dart';
import '../../core/logging/app_logger.dart';
import '../../core/session/session_scoped.dart';
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
  String? _uid;
  List<Chat> _list = const [];
  bool _loaded = false;
  bool _failed = false;
  Set<String> _muted = const {};

  /// The last messages seen in each recently opened chat (by friend), so
  /// opening it again shows them at once instead of a spinner (F-03).
  final Map<String, List<ChatMessage>> _recent = {};
  static const _recentChats = 12;

  String? get uid => _uid;
  List<Chat> get chats => _list;
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
    return _list
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
    unawaited(_sub?.cancel());
    _sub = _chats
        .watchChats(uid)
        .listen(
          (chats) {
            _list = chats;
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
    _uid = null;
    _list = const [];
    _loaded = false;
    _failed = false;
    _muted = const {};
    _recent.clear();
    notifyListeners();
  }

  /// What the chat with [friendUid] showed when it was last open.
  List<ChatMessage>? recentWith(String friendUid) => _recent[friendUid];

  void rememberMessages(String friendUid, List<ChatMessage> messages) {
    // Most recently used last; the oldest chat is forgotten first.
    _recent.remove(friendUid);
    _recent[friendUid] = messages;
    if (_recent.length > _recentChats) _recent.remove(_recent.keys.first);
  }

  @override
  Future<void> beforeSignOut(String uid) async {}

  /// The newest [limit] messages exchanged with [friendUid].
  Stream<List<ChatMessage>> messagesWith(String friendUid, {int limit = 50}) {
    final me = _uid;
    if (me == null || me == friendUid) return Stream.value(const []);
    return _chats.watchMessages(Chat.idBetween(me, friendUid), limit: limit);
  }

  /// An id for a new message to [friendUid] (made on the device).
  String? newMessageId(String friendUid) {
    final me = _uid;
    if (me == null || me == friendUid) return null;
    return _chats.newMessageId(Chat.idBetween(me, friendUid));
  }

  Future<AppFailure?> sendText(
    String to,
    String text, {
    required String messageId,
  }) => _run(
    'Failed to send message',
    AppL10n.current.messagesSendFailed,
    (me) => _chats.sendText(from: me, to: to, text: text, messageId: messageId),
  );

  Future<AppFailure?> deleteMessage(String friendUid, String messageId) => _run(
    'Failed to delete a message',
    AppL10n.current.messagesDeleteFailed,
    (me) => _chats.deleteMessage(Chat.idBetween(me, friendUid), messageId),
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
