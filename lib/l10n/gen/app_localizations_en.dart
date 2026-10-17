// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Later';

  @override
  String get commonBack => 'Back';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonDone => 'Done';

  @override
  String get commonErrorGeneric => 'Something went wrong. Please try again.';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonNoConnection => 'No connection. Please try again.';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSearchHint => 'Search...';

  @override
  String get commonUnknownUser => 'Unknown user';

  @override
  String get commonUnknownUsername => 'unknown';

  @override
  String get failureNotFound => 'This item no longer exists.';

  @override
  String get failurePermission => 'You are not allowed to do that.';

  @override
  String get messagesBlockedByYou => 'You blocked this user';

  @override
  String get messagesCantSend => 'You can\'t send messages to this user';

  @override
  String get messagesCapsuleLabel => 'Capsule';

  @override
  String get messagesCapsuleUnavailable =>
      'This capsule is no longer available';

  @override
  String get messagesChatFallbackTitle => 'Chat';

  @override
  String get messagesChatOptions => 'Chat options';

  @override
  String get messagesChatsLoadError => 'Couldn\'t load your chats';

  @override
  String get messagesCheckConnection => 'Check your connection and try again';

  @override
  String get messagesClearConfirm => 'Clear';

  @override
  String get messagesClearConfirmTitle =>
      'Are you sure you want to clear chat history?';

  @override
  String get messagesClearFailed => 'Failed to clear history';

  @override
  String messagesEmptySubtitle(String name) {
    return 'Say hello to $name!';
  }

  @override
  String get messagesEmptyTitle => 'No messages yet';

  @override
  String get messagesFindChatsHint => 'Find chats';

  @override
  String get messagesInputHint => 'Write a message...';

  @override
  String get messagesLoadError => 'Couldn\'t load the messages';

  @override
  String get messagesMenuBlock => 'Block user';

  @override
  String get messagesMenuClearHistory => 'Clear history';

  @override
  String get messagesMenuMute => 'Mute notifications';

  @override
  String get messagesMenuSearch => 'Search';

  @override
  String get messagesMenuUnblock => 'Unblock user';

  @override
  String get messagesMenuUnmute => 'Unmute notifications';

  @override
  String get messagesMutedToast => 'Chat muted';

  @override
  String get messagesNewChatFindFriends => 'Find friends';

  @override
  String get messagesNewChatNoFriends => 'No friends yet';

  @override
  String get messagesNewChatNoFriendsSubtitle =>
      'Add some friends to start chatting!';

  @override
  String get messagesNewChatNoMatch => 'No friends found';

  @override
  String get messagesNewChatSearchHint => 'Search friends';

  @override
  String get messagesNewChatTitle => 'New Chat';

  @override
  String get messagesNoChatsFound => 'No chats found';

  @override
  String get messagesNoChatsSubtitle =>
      'Tap the new message button to start chatting with friends!';

  @override
  String get messagesNoChatsTitle => 'No conversations yet';

  @override
  String get messagesNoMatchTitle => 'No messages found';

  @override
  String messagesNothingMatches(String query) {
    return 'Nothing matches \"$query\"';
  }

  @override
  String get messagesNotificationsMuted => 'Notifications muted';

  @override
  String messagesOpenCapsule(String title) {
    return 'Open capsule $title';
  }

  @override
  String get messagesReceiptFailed => 'Not sent · Tap to retry';

  @override
  String get messagesReceiptRead => 'Read';

  @override
  String get messagesReceiptSending => 'Sending…';

  @override
  String get messagesReceiptSent => 'Sent';

  @override
  String get messagesScrollToLatest => 'Scroll to the latest message';

  @override
  String get messagesSearchHint => 'Search messages';

  @override
  String get messagesSend => 'Send';

  @override
  String get messagesSendCapsule => 'Send a capsule';

  @override
  String get messagesSendFailed => 'Failed to send message';

  @override
  String get messagesSignedOut => 'You are signed out';

  @override
  String messagesStartChatWith(String name) {
    return 'Start chat with $name';
  }

  @override
  String get messagesTitle => 'My Laters';

  @override
  String get messagesToday => 'Today';

  @override
  String get messagesTooLong => 'This message is too long';

  @override
  String get messagesUnmutedToast => 'Chat unmuted';

  @override
  String get messagesYesterday => 'Yesterday';

  @override
  String messagesYouPrefix(String message) {
    return 'You: $message';
  }

  @override
  String get placeNoLocation => 'No location';

  @override
  String get placeUnknown => 'Unknown location';
}
