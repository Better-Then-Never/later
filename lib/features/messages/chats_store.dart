import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/errors/app_failure.dart';
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
    notifyListeners();
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
    (me) => _chats.sendText(from: me, to: to, text: text, messageId: messageId),
  );

  Future<AppFailure?> clearHistory(String friendUid) => _run(
    'Failed to clear history',
    (me) => _chats.clearHistory(Chat.idBetween(me, friendUid)),
  );

  /// The user has read the chat with [friendUid]; failures are only logged.
  Future<void> markRead(String friendUid) async {
    final me = _uid;
    if (me == null || me == friendUid) return;
    try {
      await _chats.markRead(Chat.idBetween(me, friendUid), reader: me);
    } catch (e) {
      AppLogger.debug('Marking the chat read failed: $e');
    }
  }

  Future<AppFailure?> _run(
    String fallbackMessage,
    Future<void> Function(String me) action,
  ) async {
    final me = _uid;
    if (me == null) return const AuthFailure('You are signed out');
    try {
      await action(me);
      return null;
    } catch (e, st) {
      AppLogger.warning(fallbackMessage, error: e, stackTrace: st);
      return AppFailure.from(e, fallbackMessage: fallbackMessage);
    }
  }
}
