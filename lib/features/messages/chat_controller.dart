import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/errors/app_failure.dart';
import '../../core/l10n/l10n.dart';
import '../../core/logging/app_logger.dart';
import '../../data/models/chat.dart';
import '../friends/friends_store.dart';
import 'chats_store.dart';

/// What to show under the user's newest message.
enum ReceiptStatus { sending, failed, sent, read }

/// State of one open conversation: messages (newest [pageSize] first, older
/// pages on demand), messages being sent, read receipts, the in-chat search
/// and whether either side blocked the other.
class ChatController extends ChangeNotifier {
  ChatController({
    required this.friendUid,
    required ChatsStore chats,
    required FriendsStore friends,
    this.pageSize = 50,
    bool Function()? readReceipts,
  }) : _chats = chats,
       _friends = friends,
       _readReceipts = readReceipts ?? (() => true) {
    _chats.addListener(_onChatsChanged);
    // Opened before: start from what it showed; the stream refreshes it.
    final recent = _chats.recentWith(friendUid);
    if (recent != null) {
      _server = recent;
      _loaded = true;
    }
    _subscribe();
    unawaited(_checkBlockedByFriend());
  }

  final String friendUid;
  final int pageSize;
  final ChatsStore _chats;
  final FriendsStore _friends;

  /// Settings > Privacy > Read receipts: off, the friend does not learn when
  /// the user read their messages, and the user does not see it either.
  final bool Function() _readReceipts;

  StreamSubscription<List<ChatMessage>>? _sub;
  late int _limit = pageSize;
  List<ChatMessage> _server = const [];

  /// Messages typed here that the server has not confirmed yet, by id.
  final Map<String, ChatMessage> _outbox = {};

  /// Deleted here, hidden until the server's list no longer has them.
  final Set<String> _deleting = {};
  bool _loaded = false;
  bool _failed = false;
  bool _loadingOlder = false;
  bool _blockedByFriend = false;
  bool _markingRead = false;
  bool _searching = false;
  String _query = '';
  bool _disposed = false;

  String? get myUid => _chats.uid;
  bool get isLoaded => _loaded;
  bool get hasError => _failed;
  bool get hasMessages => _server.isNotEmpty || _outbox.isNotEmpty;
  bool get isSearching => _searching;
  String get query => _query;

  /// More messages may exist before the oldest loaded one.
  bool get canLoadOlder => _server.length >= _limit;
  bool get isLoadingOlder => _loadingOlder;

  Chat? get chat => _chats.chatWith(friendUid);

  /// The chat's id, also before its first message.
  String? get chatId {
    final me = myUid;
    return me == null ? null : Chat.idBetween(me, friendUid);
  }

  bool get isMuted {
    final id = chatId;
    return id != null && _chats.isMuted(id);
  }

  /// Everything to show, oldest first: confirmed messages, then the ones
  /// still sending or failed.
  List<ChatMessage> get messages {
    final ids = {for (final m in _server) m.id};
    return [
      ..._server,
      ..._outbox.values.where((m) => !ids.contains(m.id)),
    ].where((m) => !_deleting.contains(m.id)).toList();
  }

  /// [messages], or the search matches.
  List<ChatMessage> get visibleMessages {
    final q = _query.trim().toLowerCase();
    final all = messages;
    if (q.isEmpty) return all;
    return all.where((m) => m.text.toLowerCase().contains(q)).toList();
  }

  bool get iBlockedThem => _friends.isBlocked(friendUid);
  bool get blockedByThem => _blockedByFriend;
  bool get canSend => !iBlockedThem && !_blockedByFriend;

  bool isMine(ChatMessage message) => message.senderId == myUid;

  /// Receipt for the user's newest message, or null when the friend wrote
  /// last (or nothing was sent yet).
  ReceiptStatus? get receipt {
    final all = messages;
    if (all.isEmpty || !isMine(all.last)) return null;
    final last = all.last;
    return switch (last.delivery) {
      MessageDelivery.sending => ReceiptStatus.sending,
      MessageDelivery.failed => ReceiptStatus.failed,
      MessageDelivery.sent =>
        _readReceipts() && last.readBy(chat?.readAtOf(friendUid))
            ? ReceiptStatus.read
            : ReceiptStatus.sent,
    };
  }

  void _subscribe() {
    unawaited(_sub?.cancel());
    _sub = _chats
        .messagesWith(friendUid, limit: _limit)
        .listen(
          _onMessages,
          onError: (Object e, StackTrace st) {
            AppLogger.warning(
              'Messages stream failed',
              error: e,
              stackTrace: st,
            );
            _failed = true;
            _loaded = true;
            _loadingOlder = false;
            _notify();
          },
        );
  }

  void _onMessages(List<ChatMessage> messages) {
    _server = messages;
    _chats.rememberMessages(friendUid, messages);
    _loaded = true;
    _failed = false;
    _loadingOlder = false;
    // Confirmed by the server: no longer pending.
    for (final m in messages) {
      _outbox.remove(m.id);
    }
    final ids = {for (final m in messages) m.id};
    _deleting.retainWhere(ids.contains);
    _notify();
    _markReadIfNeeded();
  }

  void _onChatsChanged() {
    _notify();
    _markReadIfNeeded();
  }

  /// One write per batch of new messages while the chat is open.
  void _markReadIfNeeded() {
    final me = myUid;
    final c = chat;
    if (_disposed || _markingRead || me == null || c == null) return;
    if (c.unreadFor(me) == 0) return;
    _markingRead = true;
    unawaited(
      _chats
          .markRead(friendUid, receipt: _readReceipts())
          .whenComplete(() => _markingRead = false),
    );
  }

  /// Subscribes again after the messages failed to load.
  void reload() {
    if (_disposed) return;
    _failed = false;
    _loaded = false;
    _notify();
    _subscribe();
  }

  /// Loads the next page of older messages (no-op while loading or when the
  /// oldest message is already shown).
  void loadOlder() {
    if (_loadingOlder || !canLoadOlder || _disposed) return;
    _loadingOlder = true;
    _limit += pageSize;
    _notify();
    _subscribe();
  }

  Future<void> _checkBlockedByFriend() async {
    final blocked = await _friends.isBlockedBy(friendUid);
    if (_disposed || blocked == _blockedByFriend) return;
    _blockedByFriend = blocked;
    _notify();
  }

  void toggleSearch() {
    _searching = !_searching;
    if (!_searching) _query = '';
    _notify();
  }

  void search(String query) {
    _query = query;
    _notify();
  }

  /// Shows [text] at once as "sending" and sends it; a failure keeps it in
  /// the list as "not sent" so it can be retried. Returns the failure to
  /// report, or null.
  Future<AppFailure?> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length > Chat.maxMessageLength) {
      return ValidationFailure(AppL10n.current.messagesTooLong);
    }
    final me = myUid;
    final id = _chats.newMessageId(friendUid);
    if (me == null || id == null) {
      return AuthFailure(AppL10n.current.messagesSignedOut);
    }
    _outbox[id] = ChatMessage(
      id: id,
      senderId: me,
      text: trimmed,
      delivery: MessageDelivery.sending,
    );
    _notify();
    return _deliver(id);
  }

  /// Sends a failed message again (same id: it cannot arrive twice).
  Future<AppFailure?> retry(String messageId) async {
    final pending = _outbox[messageId];
    if (pending == null || pending.delivery != MessageDelivery.failed) {
      return null;
    }
    _outbox[messageId] = pending.withDelivery(MessageDelivery.sending);
    _notify();
    return _deliver(messageId);
  }

  Future<AppFailure?> _deliver(String id) async {
    final pending = _outbox[id];
    if (pending == null) return null;
    final failure = await _chats.sendText(
      friendUid,
      pending.text,
      messageId: id,
    );
    if (_disposed) return failure;
    if (failure == null) return null;
    final still = _outbox[id];
    if (still != null) {
      _outbox[id] = still.withDelivery(MessageDelivery.failed);
      _notify();
    }
    if (failure is PermissionFailure) {
      // Most likely blocked since the chat was opened.
      unawaited(_checkBlockedByFriend());
      return PermissionFailure(AppL10n.current.messagesCantSend);
    }
    return failure;
  }

  Future<AppFailure?> clearHistory() => _chats.clearHistory(friendUid);

  /// Whether [message] can be deleted here: the user's own, sent or not.
  bool canDelete(ChatMessage message) =>
      isMine(message) && message.delivery != MessageDelivery.sending;

  /// Deletes the user's [message] for both: it disappears at once and comes
  /// back if the server refuses. One that never arrived (not sent) is only
  /// dropped from this phone.
  Future<AppFailure?> deleteMessage(ChatMessage message) async {
    if (!canDelete(message)) return null;
    final pending = _outbox[message.id];
    if (pending != null && pending.delivery == MessageDelivery.failed) {
      _outbox.remove(message.id);
      _notify();
      return null;
    }
    _deleting.add(message.id);
    _notify();
    final failure = await _chats.deleteMessage(friendUid, message.id);
    if (failure != null && !_disposed) {
      _deleting.remove(message.id);
      _notify();
    }
    return failure;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _chats.removeListener(_onChatsChanged);
    unawaited(_sub?.cancel());
    super.dispose();
  }
}
