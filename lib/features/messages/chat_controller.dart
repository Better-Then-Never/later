import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/errors/app_failure.dart';
import '../../core/l10n/l10n.dart';
import '../../core/logging/app_logger.dart';
import '../../data/models/capsule.dart';
import '../../data/models/chat.dart';
import '../../data/models/social.dart';
import '../../data/repositories/repositories.dart';
import '../friends/friends_store.dart';
import 'chats_store.dart';
import 'hidden_messages.dart';

/// What to show under the user's newest message.
enum ReceiptStatus { sending, failed, sent, read }

/// State of one open conversation, with one friend or in a group: messages
/// (newest [pageSize] first, older pages on demand), messages being sent,
/// read receipts, who is typing, the in-chat search and, with a friend,
/// whether either side blocked the other.
class ChatController extends ChangeNotifier {
  /// The conversation with [friendUid].
  ChatController({
    required String friendUid,
    required ChatsStore chats,
    required FriendsStore friends,
    int pageSize = 50,
    bool Function()? readReceipts,
    Duration typingRefresh = const Duration(seconds: 4),
    Duration typingShown = const Duration(seconds: 6),
    HiddenMessages? hidden,
    SocialRepository? social,
  }) : this._(
         friendUid: friendUid,
         groupId: null,
         chats: chats,
         friends: friends,
         pageSize: pageSize,
         readReceipts: readReceipts,
         typingRefresh: typingRefresh,
         typingShown: typingShown,
         hidden: hidden,
         social: social,
       );

  /// The group [groupId].
  ChatController.group({
    required String groupId,
    required ChatsStore chats,
    required FriendsStore friends,
    int pageSize = 50,
    bool Function()? readReceipts,
    Duration typingRefresh = const Duration(seconds: 4),
    Duration typingShown = const Duration(seconds: 6),
    HiddenMessages? hidden,
    SocialRepository? social,
  }) : this._(
         friendUid: null,
         groupId: groupId,
         chats: chats,
         friends: friends,
         pageSize: pageSize,
         readReceipts: readReceipts,
         typingRefresh: typingRefresh,
         typingShown: typingShown,
         hidden: hidden,
         social: social,
       );

  ChatController._({
    required this.friendUid,
    required this.groupId,
    required ChatsStore chats,
    required FriendsStore friends,
    required this.pageSize,
    required bool Function()? readReceipts,
    required this.typingRefresh,
    required this.typingShown,
    required HiddenMessages? hidden,
    required SocialRepository? social,
  }) : _chats = chats,
       _friends = friends,
       _hiddenStore = hidden,
       _social = social,
       _readReceipts = readReceipts ?? (() => true) {
    _chats.addListener(_onChatsChanged);
    _seenGroup = isGroup && chat != null;
    final id = chatId;
    // What was unread when the chat opened (reading it resets the count).
    final me = myUid;
    final opened = chat;
    _unreadAtOpen = me == null || opened == null ? 0 : opened.unreadFor(me);
    _readAtOpen = me == null ? null : opened?.readAtOf(me);
    if (id != null && me != null && hidden != null) {
      unawaited(
        hidden.load(me, id).then((ids) {
          _hidden.addAll(ids);
          _notify();
        }),
      );
    }
    // Opened before: start from what it showed; the stream refreshes it.
    final recent = id == null ? null : _chats.recentIn(id);
    if (recent != null) {
      _server = recent;
      _loaded = true;
    }
    _subscribe();
    if (id != null) _typingSub = _chats.typingIn(id).listen(_onTyping);
    if (!isGroup) unawaited(_checkBlockedByFriend());
  }

  /// The friend of a two-person chat; null in a group.
  final String? friendUid;

  /// The group's id; null in a two-person chat.
  final String? groupId;

  bool get isGroup => groupId != null;

  final int pageSize;
  final ChatsStore _chats;
  final FriendsStore _friends;
  final HiddenMessages? _hiddenStore;
  final SocialRepository? _social;

  /// Deleted for this user only (kept on this phone).
  final Set<String> _hidden = {};

  late final int _unreadAtOpen;
  late final DateTime? _readAtOpen;
  String? _firstUnreadId;
  bool _unreadMarked = false;

  /// The first message the user had not read when the chat opened (a line
  /// marks it until they leave); null when everything was read.
  String? get firstUnreadId => _firstUnreadId;

  /// While the user types, the others are told at most this often.
  final Duration typingRefresh;

  /// Someone counts as typing for this long after each hint (a hint that
  /// stops coming means they stopped, also when their app died).
  final Duration typingShown;

  /// Settings > Privacy > Read receipts: off, the friend does not learn when
  /// the user read their messages, and the user does not see it either.
  final bool Function() _readReceipts;

  StreamSubscription<List<ChatMessage>>? _sub;
  StreamSubscription<Map<String, DateTime>>? _typingSub;
  Timer? _typingTimer;
  late int _limit = pageSize;
  List<ChatMessage> _server = const [];

  /// Messages typed here that the server has not confirmed yet, by id.
  final Map<String, ChatMessage> _outbox = {};

  /// Photos sent from here: the picture on the phone, by message id. Kept
  /// after the server confirms, so the bubble never reloads its picture.
  final Map<String, String> _localPhotos = {};

  /// Photos uploaded whose message is not sent yet: a retry sends, it does
  /// not upload again.
  final Map<String, ChatPhoto> _uploaded = {};

  /// The same for recordings.
  final Map<String, ChatAudio> _uploadedAudio = {};

  /// Deleted here, hidden until the server's list no longer has them.
  final Set<String> _deleting = {};

  /// Reactions set here and not confirmed yet (null: removed), by message.
  final Map<String, ReactionType?> _reacting = {};

  /// The last typing hint seen from each person, and until when they count
  /// as typing.
  final Map<String, DateTime> _hintAt = {};
  final Map<String, DateTime> _typingUntil = {};
  bool _firstTypingHint = true;
  DateTime? _typingSentAt;

  MessageReply? _replyTo;

  /// The message the next one answers (shown above the composer).
  MessageReply? get replyingTo => _replyTo;
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

  /// The chat's id, also before its first message.
  String? get chatId {
    final group = groupId;
    if (group != null) return group;
    return _chats.chatIdWith(friendUid!);
  }

  Chat? get chat {
    final id = chatId;
    return id == null ? null : _chats.chatById(id);
  }

  bool get isMuted {
    final id = chatId;
    return id != null && _chats.isMuted(id);
  }

  /// Everything to show, oldest first: confirmed messages, then the ones
  /// still sending or failed.
  List<ChatMessage> get messages {
    final ids = {for (final m in _server) m.id};
    final me = myUid;
    return [..._server, ..._outbox.values.where((m) => !ids.contains(m.id))]
        .where((m) => !_deleting.contains(m.id) && !_hidden.contains(m.id))
        .map((m) {
          final local = _localPhotos[m.id];
          if (local != null && m.localPath == null) m = m.withLocalPath(local);
          if (me == null || !_reacting.containsKey(m.id)) return m;
          return m.withReaction(me, _reacting[m.id]);
        })
        .toList();
  }

  /// [messages], or the search matches.
  List<ChatMessage> get visibleMessages {
    final q = _query.trim().toLowerCase();
    final all = messages;
    if (q.isEmpty) return all;
    return all.where((m) => m.text.toLowerCase().contains(q)).toList();
  }

  bool get iBlockedThem {
    final friend = friendUid;
    return friend != null && _friends.isBlocked(friend);
  }

  bool get blockedByThem => _blockedByFriend;

  /// The group was listed for the user once (so no longer listed means they
  /// left, not that it was just created).
  bool _seenGroup = false;

  /// Whether the user may write here: not blocked either way with the
  /// friend; still a member of the group (it may not be listed yet just
  /// after creating it).
  bool get canSend {
    if (!isGroup) return !iBlockedThem && !_blockedByFriend;
    final group = chat;
    final me = myUid;
    if (group == null) return !_seenGroup;
    return me != null && group.members.contains(me);
  }

  bool isMine(ChatMessage message) => message.senderId == myUid;

  /// Receipt for the user's newest message, or null when someone else wrote
  /// last (or nothing was sent yet). In a group, "read" once everyone has.
  ReceiptStatus? get receipt {
    final all = messages;
    if (all.isEmpty || !isMine(all.last)) return null;
    final last = all.last;
    return switch (last.delivery) {
      MessageDelivery.sending => ReceiptStatus.sending,
      MessageDelivery.failed => ReceiptStatus.failed,
      MessageDelivery.sent =>
        _readReceipts() && _readByEveryone(last)
            ? ReceiptStatus.read
            : ReceiptStatus.sent,
    };
  }

  bool _readByEveryone(ChatMessage message) {
    final c = chat;
    final me = myUid;
    if (me == null) return false;
    if (!isGroup) return message.readBy(c?.readAtOf(friendUid!));
    final others = c?.othersThan(me) ?? const <String>[];
    return others.isNotEmpty &&
        others.every((uid) => message.readBy(c!.readAtOf(uid)));
  }

  // ---- typing --------------------------------------------------------------

  /// The others typing right now, in the order they started.
  List<String> get typingPeople {
    final now = DateTime.now();
    return [
      for (final e in _typingUntil.entries)
        if (now.isBefore(e.value)) e.key,
    ];
  }

  /// Someone else is typing (the friend, in a two-person chat).
  bool get friendTyping => typingPeople.isNotEmpty;

  void _onTyping(Map<String, DateTime> hints) {
    final first = _firstTypingHint;
    _firstTypingHint = false;
    final now = DateTime.now();
    _typingUntil.removeWhere((uid, _) => !hints.containsKey(uid));
    _hintAt.removeWhere((uid, _) => !hints.containsKey(uid));
    for (final MapEntry(key: uid, value: at) in hints.entries) {
      if (_hintAt[uid] == at) continue;
      _hintAt[uid] = at;
      // A hint left behind long ago (their app stopped mid-sentence) when
      // the chat opens: not typing. Later hints are live, whatever the
      // clocks say.
      if (first && now.difference(at).abs() > typingShown * 3) continue;
      _typingUntil[uid] = now.add(typingShown);
    }
    _scheduleTypingExpiry();
    _notify();
  }

  void _scheduleTypingExpiry() {
    _typingTimer?.cancel();
    final now = DateTime.now();
    _typingUntil.removeWhere((_, until) => !now.isBefore(until));
    if (_typingUntil.isEmpty) return;
    final next = _typingUntil.values.reduce((a, b) => a.isBefore(b) ? a : b);
    _typingTimer = Timer(next.difference(now), () {
      _scheduleTypingExpiry();
      _notify();
    });
  }

  /// The text in the message field changed: the others learn the user is
  /// typing (at most every [typingRefresh]), or that they stopped.
  void onInputChanged(String text) {
    final id = chatId;
    if (_disposed || !canSend || id == null) return;
    if (text.trim().isEmpty) {
      _stopTyping();
      return;
    }
    final now = DateTime.now();
    final last = _typingSentAt;
    if (last != null && now.difference(last) < typingRefresh) return;
    _typingSentAt = now;
    unawaited(_chats.setTyping(id, typing: true));
  }

  void _stopTyping() {
    final id = chatId;
    if (_typingSentAt == null || id == null) return;
    _typingSentAt = null;
    unawaited(_chats.setTyping(id, typing: false));
  }

  // ---- messages ------------------------------------------------------------

  void _subscribe() {
    final id = chatId;
    if (id == null) return;
    unawaited(_sub?.cancel());
    _sub = _chats
        .messagesIn(id, limit: _limit)
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
    // A new message from someone: they are done typing it.
    final newest = messages.lastOrNull;
    if (newest != null && newest.id != _server.lastOrNull?.id) {
      _typingUntil.remove(newest.senderId);
    }
    _server = messages;
    if (!_unreadMarked) {
      _unreadMarked = true;
      _firstUnreadId = _findFirstUnread(messages);
    }
    final id = chatId;
    if (id != null) _chats.rememberMessages(id, messages);
    _loaded = true;
    _failed = false;
    _loadingOlder = false;
    // Confirmed by the server: no longer pending.
    for (final m in messages) {
      _outbox.remove(m.id);
    }
    final ids = {for (final m in messages) m.id};
    _deleting.retainWhere(ids.contains);
    // Confirmed: the server's list shows the reaction now.
    final me = myUid;
    _reacting.removeWhere((id, type) {
      final m = messages.where((m) => m.id == id).firstOrNull;
      return m == null || me == null || m.reactions[me] == type;
    });
    _notify();
    _markReadIfNeeded();
  }

  /// In a two-person chat, the unread count says how many of the newest
  /// messages from the friend are new; in a group, those after the user's
  /// read mark are.
  String? _findFirstUnread(List<ChatMessage> messages) {
    if (_unreadAtOpen <= 0) return null;
    final me = myUid;
    if (isGroup) {
      final readAt = _readAtOpen;
      return messages
          .where(
            (m) =>
                m.senderId != me &&
                (readAt == null || (m.sentAt?.isAfter(readAt) ?? false)),
          )
          .firstOrNull
          ?.id;
    }
    var left = _unreadAtOpen;
    for (final m in messages.reversed) {
      if (m.senderId == me) continue;
      if (--left == 0) return m.id;
    }
    return messages.where((m) => m.senderId != me).firstOrNull?.id;
  }

  void _onChatsChanged() {
    if (isGroup && chat != null) _seenGroup = true;
    _notify();
    _markReadIfNeeded();
  }

  /// The chat as it was when last marked read here: the same state is not
  /// marked twice while the change is on its way back.
  (DateTime?, String, int)? _markedState;

  /// One write per batch of new messages while the chat is open.
  void _markReadIfNeeded() {
    final me = myUid;
    final c = chat;
    if (_disposed || _markingRead || me == null || c == null) return;
    final unread = c.unreadFor(me);
    if (unread == 0) return;
    final state = (c.lastUpdated, c.lastMessage, unread);
    if (state == _markedState) return;
    _markedState = state;
    _markingRead = true;
    final marking = isGroup
        ? _chats.markGroupRead(groupId!)
        : _chats.markRead(friendUid!, receipt: _readReceipts());
    unawaited(marking.whenComplete(() => _markingRead = false));
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
    final friend = friendUid;
    if (friend == null) return;
    final blocked = await _friends.isBlockedBy(friend);
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
    final chat = chatId;
    final id = chat == null ? null : _chats.newMessageIdIn(chat);
    if (me == null || id == null) {
      return AuthFailure(AppL10n.current.messagesSignedOut);
    }
    _stopTyping();
    _outbox[id] = ChatMessage(
      id: id,
      senderId: me,
      text: trimmed,
      delivery: MessageDelivery.sending,
      replyTo: _replyTo,
    );
    _replyTo = null;
    _notify();
    return _deliver(id);
  }

  /// Photos can be sent to a friend (not yet in groups).
  bool get canSendPhotos => !isGroup;

  /// Shows the photo at [localPath] at once as "sending", uploads it and
  /// sends it with [caption]; a failure keeps it as "not sent" to retry.
  Future<AppFailure?> sendPhoto(String localPath, {String caption = ''}) async {
    if (!canSendPhotos) return null;
    final trimmed = caption.trim();
    if (trimmed.length > Chat.maxMessageLength) {
      return ValidationFailure(AppL10n.current.messagesTooLong);
    }
    final me = myUid;
    final chat = chatId;
    final id = chat == null ? null : _chats.newMessageIdIn(chat);
    if (me == null || id == null) {
      return AuthFailure(AppL10n.current.messagesSignedOut);
    }
    _stopTyping();
    _localPhotos[id] = localPath;
    _outbox[id] = ChatMessage(
      id: id,
      senderId: me,
      text: trimmed.isEmpty ? ChatMessage.photoSign : trimmed,
      type: ChatMessageType.image,
      localPath: localPath,
      delivery: MessageDelivery.sending,
      replyTo: _replyTo,
    );
    _replyTo = null;
    _notify();
    return _deliver(id);
  }

  /// Voice messages can be sent to a friend (not yet in groups).
  bool get canSendVoice => !isGroup;

  /// Shows the recording at [localPath] at once as "sending", uploads it and
  /// sends it; a failure keeps it as "not sent" to retry.
  Future<AppFailure?> sendVoice(
    String localPath, {
    required int durationMs,
    required List<int> waveform,
  }) async {
    if (!canSendVoice) return null;
    final me = myUid;
    final chat = chatId;
    final id = chat == null ? null : _chats.newMessageIdIn(chat);
    if (me == null || id == null) {
      return AuthFailure(AppL10n.current.messagesSignedOut);
    }
    _stopTyping();
    _localPhotos[id] = localPath;
    _outbox[id] = ChatMessage(
      id: id,
      senderId: me,
      text: ChatMessage.voiceSign,
      type: ChatMessageType.voice,
      localPath: localPath,
      durationMs: durationMs,
      waveform: waveform,
      delivery: MessageDelivery.sending,
      replyTo: _replyTo,
    );
    _replyTo = null;
    _notify();
    return _deliver(id);
  }

  /// Whether [message] can be answered: it is on the server and the user
  /// may write here.
  bool canReply(ChatMessage message) =>
      canSend && message.delivery == MessageDelivery.sent;

  /// The next message answers [message].
  void replyTo(ChatMessage message) {
    if (!canReply(message)) return;
    _replyTo = switch (message.type) {
      ChatMessageType.image => MessageReply.of(
        message,
        text:
            '${ChatMessage.photoSign} '
            '${message.caption.isEmpty ? AppL10n.current.messagesPhoto : message.caption}',
      ),
      ChatMessageType.voice => MessageReply.of(
        message,
        text: '${ChatMessage.voiceSign} ${AppL10n.current.messagesVoice}',
      ),
      _ => MessageReply.of(message),
    };
    _notify();
  }

  void cancelReply() {
    if (_replyTo == null) return;
    _replyTo = null;
    _notify();
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
    final group = groupId;
    final failure = group != null
        ? await _chats.sendToGroup(
            group,
            pending.text,
            messageId: id,
            replyTo: pending.replyTo,
          )
        : pending.type == ChatMessageType.image
        ? await _deliverPhoto(pending)
        : pending.type == ChatMessageType.voice
        ? await _deliverVoice(pending)
        : await _chats.sendText(
            friendUid!,
            pending.text,
            messageId: id,
            replyTo: pending.replyTo,
          );
    if (_disposed) return failure;
    if (failure == null) return null;
    // Back from the server's list too when the write was queued (shown from
    // the phone's copy) and then refused.
    _outbox[id] = (_outbox[id] ?? pending).withDelivery(MessageDelivery.failed);
    _notify();
    if (failure is PermissionFailure) {
      // Most likely blocked (or out of the group) since the chat was opened.
      unawaited(_checkBlockedByFriend());
      return PermissionFailure(AppL10n.current.messagesCantSend);
    }
    return failure;
  }

  /// Uploads [pending]'s picture (once) and sends the message.
  Future<AppFailure?> _deliverPhoto(ChatMessage pending) async {
    final friend = friendUid;
    if (friend == null) return null;
    final id = pending.id;
    var photo = _uploaded[id];
    if (photo == null) {
      final local = pending.localPath;
      if (local == null) return null;
      final (uploaded, failure) = await _chats.uploadPhoto(
        friend,
        local,
        messageId: id,
      );
      if (uploaded == null) return failure;
      photo = _uploaded[id] = uploaded;
    }
    final failure = await _chats.sendPhoto(
      friend,
      photo,
      messageId: id,
      caption: pending.caption,
      replyTo: pending.replyTo,
    );
    if (failure == null) _uploaded.remove(id);
    return failure;
  }

  /// Uploads [pending]'s recording (once) and sends the message.
  Future<AppFailure?> _deliverVoice(ChatMessage pending) async {
    final friend = friendUid;
    if (friend == null) return null;
    final id = pending.id;
    var audio = _uploadedAudio[id];
    if (audio == null) {
      final local = pending.localPath;
      if (local == null) return null;
      final (uploaded, failure) = await _chats.uploadVoice(
        friend,
        local,
        messageId: id,
      );
      if (uploaded == null) return failure;
      audio = _uploadedAudio[id] = uploaded;
    }
    final failure = await _chats.sendVoice(
      friend,
      audio,
      messageId: id,
      durationMs: pending.durationMs ?? 0,
      waveform: pending.waveform,
      replyTo: pending.replyTo,
    );
    if (failure == null) _uploadedAudio.remove(id);
    return failure;
  }

  /// Clears a two-person chat for both (groups have no shared clear).
  Future<AppFailure?> clearHistory() async {
    final friend = friendUid;
    if (friend == null) return null;
    return _chats.clearHistory(friend);
  }

  /// The user's reaction to [message]: tapping the same one again removes
  /// it. Shown at once, undone if the server refuses.
  Future<AppFailure?> react(ChatMessage message, ReactionType type) async {
    final me = myUid;
    final id = chatId;
    if (me == null || id == null || message.delivery != MessageDelivery.sent) {
      return null;
    }
    final next = message.reactions[me] == type ? null : type;
    _reacting[message.id] = next;
    _notify();
    final failure = await _chats.setMessageReaction(id, message.id, next);
    if (failure != null && !_disposed) {
      _reacting.remove(message.id);
      _notify();
    }
    return failure;
  }

  /// Whether [message] can be deleted here: the user's own, sent or not.
  bool canDelete(ChatMessage message) =>
      isMine(message) && message.delivery != MessageDelivery.sending;

  /// Deletes the user's [message] for everyone: it disappears at once and
  /// comes back if the server refuses. One that never arrived (not sent) is
  /// only dropped from this phone.
  Future<AppFailure?> deleteMessage(ChatMessage message) async {
    final id = chatId;
    if (!canDelete(message) || id == null) return null;
    final pending = _outbox[message.id];
    if (pending != null && pending.delivery == MessageDelivery.failed) {
      _outbox.remove(message.id);
      _notify();
      return null;
    }
    _deleting.add(message.id);
    _notify();
    final failure = await _chats.deleteMessage(
      id,
      message.id,
      imagePath: message.imagePath ?? message.audioPath,
    );
    if (failure != null && !_disposed) {
      _deleting.remove(message.id);
      _notify();
    }
    return failure;
  }

  /// Hides [message] for this user only (on this phone); the others keep
  /// it.
  Future<void> deleteForMe(ChatMessage message) async {
    final id = chatId;
    final me = myUid;
    if (id == null || me == null) return;
    _hidden.add(message.id);
    _outbox.remove(message.id);
    _notify();
    await _hiddenStore?.hide(me, id, message.id);
  }

  /// Can be reported: someone else's message, on the server.
  bool canReport(ChatMessage message) =>
      !isMine(message) &&
      message.delivery == MessageDelivery.sent &&
      _social != null;

  /// Reports [message] for [reason] (moderators read it).
  Future<AppFailure?> reportMessage(
    ChatMessage message,
    ReportReason reason,
  ) async {
    final social = _social;
    final me = myUid;
    final id = chatId;
    if (social == null || me == null || id == null) return null;
    try {
      await social.report(
        reporterId: me,
        target: ReportTarget.message,
        targetPath: 'chats/$id/messages/${message.id}',
        reason: reason,
      );
      return null;
    } catch (e, st) {
      AppLogger.warning('Reporting a message failed', error: e, stackTrace: st);
      return AppFailure.from(
        e,
        fallbackMessage: AppL10n.current.messagesReportFailed,
      );
    }
  }

  // ---- group -----------------------------------------------------------------

  Future<AppFailure?> renameGroup(String name) async {
    final group = groupId;
    final trimmed = name.trim();
    if (group == null || trimmed.isEmpty) return null;
    if (trimmed.length > Chat.maxGroupName) {
      return ValidationFailure(AppL10n.current.messagesGroupNameTooLong);
    }
    return _chats.renameGroup(group, trimmed);
  }

  /// Invites [uids] (the server adds those who are the user's friends).
  Future<AppFailure?> invite(List<String> uids) async {
    final group = groupId;
    if (group == null || uids.isEmpty) return null;
    return _chats.inviteToGroup(group, uids);
  }

  Future<AppFailure?> leaveGroup() async {
    final group = groupId;
    if (group == null) return null;
    _stopTyping();
    return _chats.leaveGroup(group);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _stopTyping();
    _disposed = true;
    _typingTimer?.cancel();
    unawaited(_typingSub?.cancel());
    _chats.removeListener(_onChatsChanged);
    unawaited(_sub?.cancel());
    super.dispose();
  }
}
