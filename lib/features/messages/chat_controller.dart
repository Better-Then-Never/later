import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/errors/app_failure.dart';
import '../../core/logging/app_logger.dart';
import '../../data/models/chat.dart';
import '../friends/friends_store.dart';
import 'chats_store.dart';

/// State of one open conversation: its messages, the in-chat search and
/// whether either side blocked the other.
///
/// Unlike main's page, messages that arrive while the chat is open are
/// marked read too (not only the ones there when it opened).
class ChatController extends ChangeNotifier {
  ChatController({
    required this.friendUid,
    required ChatsStore chats,
    required FriendsStore friends,
  }) : _chats = chats,
       _friends = friends {
    _sub = _chats
        .messagesWith(friendUid)
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
            if (!_disposed) notifyListeners();
          },
        );
    unawaited(_checkBlockedByFriend());
  }

  final String friendUid;
  final ChatsStore _chats;
  final FriendsStore _friends;

  StreamSubscription<List<ChatMessage>>? _sub;
  List<ChatMessage> _messages = const [];
  bool _loaded = false;
  bool _failed = false;
  bool _blockedByFriend = false;
  bool _markingRead = false;
  bool _searching = false;
  String _query = '';
  bool _disposed = false;

  String? get myUid => _chats.uid;
  bool get isLoaded => _loaded;
  bool get hasError => _failed;
  bool get hasMessages => _messages.isNotEmpty;
  bool get isSearching => _searching;
  String get query => _query;

  /// The messages to show: all of them, or the search matches.
  List<ChatMessage> get visibleMessages {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _messages;
    return _messages.where((m) => m.text.toLowerCase().contains(q)).toList();
  }

  bool get iBlockedThem => _friends.isBlocked(friendUid);
  bool get blockedByThem => _blockedByFriend;
  bool get canSend => !iBlockedThem && !_blockedByFriend;

  bool isMine(ChatMessage message) => message.senderId == myUid;

  void _onMessages(List<ChatMessage> messages) {
    _messages = messages;
    _loaded = true;
    _failed = false;
    if (!_disposed) notifyListeners();
    if (messages.any((m) => m.senderId == friendUid && !m.isRead)) {
      unawaited(_markRead());
    }
  }

  Future<void> _markRead() async {
    if (_markingRead) return;
    _markingRead = true;
    try {
      await _chats.markRead(friendUid);
    } finally {
      _markingRead = false;
    }
  }

  Future<void> _checkBlockedByFriend() async {
    final blocked = await _friends.isBlockedBy(friendUid);
    if (_disposed || blocked == _blockedByFriend) return;
    _blockedByFriend = blocked;
    notifyListeners();
  }

  void toggleSearch() {
    _searching = !_searching;
    if (!_searching) _query = '';
    notifyListeners();
  }

  void search(String query) {
    _query = query;
    notifyListeners();
  }

  /// Sends [text]; returns the failure to show, or null.
  Future<AppFailure?> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length > Chat.maxMessageLength) {
      return const ValidationFailure('This message is too long');
    }
    final failure = await _chats.sendText(friendUid, trimmed);
    if (failure is PermissionFailure) {
      // Most likely blocked since the chat was opened.
      unawaited(_checkBlockedByFriend());
      return const PermissionFailure("You can't send messages to this user");
    }
    return failure;
  }

  Future<AppFailure?> clearHistory() => _chats.clearHistory(friendUid);

  @override
  void dispose() {
    _disposed = true;
    unawaited(_sub?.cancel());
    super.dispose();
  }
}
