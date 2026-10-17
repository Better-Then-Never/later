import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('pl'),
    Locale('ru'),
  ];

  /// The app's name. Never translated.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get appName;

  /// Accessibility label of the back arrow.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get commonErrorGeneric;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @commonNoConnection.
  ///
  /// In en, this message translates to:
  /// **'No connection. Please try again.'**
  String get commonNoConnection;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get commonSearchHint;

  /// No description provided for @commonUnknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown user'**
  String get commonUnknownUser;

  /// No description provided for @commonUnknownUsername.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get commonUnknownUsername;

  /// No description provided for @failureNotFound.
  ///
  /// In en, this message translates to:
  /// **'This item no longer exists.'**
  String get failureNotFound;

  /// No description provided for @failurePermission.
  ///
  /// In en, this message translates to:
  /// **'You are not allowed to do that.'**
  String get failurePermission;

  /// Button that accepts a received friend request.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get friendsAccept;

  /// Accessibility label of the add icon on a suggestion when that user already sent a request.
  ///
  /// In en, this message translates to:
  /// **'Accept friend request'**
  String get friendsAcceptRequestLabel;

  /// Main button on the profile of someone who is not a friend yet: sends a friend request.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get friendsAdd;

  /// No description provided for @friendsAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Friends'**
  String get friendsAddTitle;

  /// Menu item and confirm button that block a user.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get friendsBlock;

  /// No description provided for @friendsBlockConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to block this user?'**
  String get friendsBlockConfirm;

  /// No description provided for @friendsCapsulesSettings.
  ///
  /// In en, this message translates to:
  /// **'Capsules settings'**
  String get friendsCapsulesSettings;

  /// No description provided for @friendsChatSettings.
  ///
  /// In en, this message translates to:
  /// **'Chat settings'**
  String get friendsChatSettings;

  /// No description provided for @friendsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No friends added yet'**
  String get friendsEmpty;

  /// No description provided for @friendsErrorAcceptRequest.
  ///
  /// In en, this message translates to:
  /// **'Failed to accept request'**
  String get friendsErrorAcceptRequest;

  /// No description provided for @friendsErrorBlock.
  ///
  /// In en, this message translates to:
  /// **'Failed to block user'**
  String get friendsErrorBlock;

  /// No description provided for @friendsErrorCancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel request'**
  String get friendsErrorCancelRequest;

  /// No description provided for @friendsErrorFollow.
  ///
  /// In en, this message translates to:
  /// **'Failed to follow user'**
  String get friendsErrorFollow;

  /// Shown instead of the suggestions on Add Friends when the search fails; tapping it retries.
  ///
  /// In en, this message translates to:
  /// **'Could not load users'**
  String get friendsErrorLoadUsers;

  /// No description provided for @friendsErrorRejectRequest.
  ///
  /// In en, this message translates to:
  /// **'Failed to reject request'**
  String get friendsErrorRejectRequest;

  /// No description provided for @friendsErrorRemoveFriend.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove friend'**
  String get friendsErrorRemoveFriend;

  /// No description provided for @friendsErrorSendRequest.
  ///
  /// In en, this message translates to:
  /// **'Failed to send friend request'**
  String get friendsErrorSendRequest;

  /// No description provided for @friendsErrorUnblock.
  ///
  /// In en, this message translates to:
  /// **'Failed to unblock user'**
  String get friendsErrorUnblock;

  /// No description provided for @friendsErrorUnfollow.
  ///
  /// In en, this message translates to:
  /// **'Failed to unfollow user'**
  String get friendsErrorUnfollow;

  /// Button in Manage friendship: get notified about this friend's capsules.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get friendsFollow;

  /// No description provided for @friendsFollowed.
  ///
  /// In en, this message translates to:
  /// **'Following! You\'ll get notifications about their capsules'**
  String get friendsFollowed;

  /// State of the follow button when the user already follows this friend.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get friendsFollowing;

  /// No description provided for @friendsFriendCapsulesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Friend\'s capsules will appear here'**
  String get friendsFriendCapsulesEmpty;

  /// No description provided for @friendsFriendCapsulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Friend\'s capsules'**
  String get friendsFriendCapsulesTitle;

  /// Accessibility label of the cross that hides a suggested friend.
  ///
  /// In en, this message translates to:
  /// **'Hide suggestion'**
  String get friendsHideSuggestionLabel;

  /// Section title above the suggested people on Add Friends.
  ///
  /// In en, this message translates to:
  /// **'Make friends'**
  String get friendsMakeFriends;

  /// No description provided for @friendsManageFriendship.
  ///
  /// In en, this message translates to:
  /// **'Manage friendship'**
  String get friendsManageFriendship;

  /// No description provided for @friendsMyFriendsTitle.
  ///
  /// In en, this message translates to:
  /// **'My friends'**
  String get friendsMyFriendsTitle;

  /// Main button when the opened profile is the user's own.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get friendsMyProfile;

  /// No description provided for @friendsNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No friends match your search'**
  String get friendsNoMatches;

  /// No description provided for @friendsNoSuggestions.
  ///
  /// In en, this message translates to:
  /// **'No more suggested friends'**
  String get friendsNoSuggestions;

  /// No description provided for @friendsOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Open chat'**
  String get friendsOpenChat;

  /// Main button on a profile the user already sent a friend request to.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get friendsPending;

  /// No description provided for @friendsQrHint.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at the QR code to add a friend'**
  String get friendsQrHint;

  /// No description provided for @friendsQrInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid QR code. Please scan a Later profile QR code.'**
  String get friendsQrInvalid;

  /// No description provided for @friendsQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get friendsQrTitle;

  /// Button that rejects a received friend request.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get friendsReject;

  /// No description provided for @friendsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from friends'**
  String get friendsRemove;

  /// Confirm button of the remove-friend dialog.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get friendsRemoveAction;

  /// No description provided for @friendsRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove user from friends?'**
  String get friendsRemoveConfirm;

  /// No description provided for @friendsRemoving.
  ///
  /// In en, this message translates to:
  /// **'Removing...'**
  String get friendsRemoving;

  /// Menu item that reports a user.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get friendsReport;

  /// No description provided for @friendsRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Friend request accepted!'**
  String get friendsRequestAccepted;

  /// Toast when the user taps add on someone they already sent a request to.
  ///
  /// In en, this message translates to:
  /// **'Friend request already exists'**
  String get friendsRequestAlreadyExists;

  /// No description provided for @friendsRequestCancelled.
  ///
  /// In en, this message translates to:
  /// **'Friend request cancelled'**
  String get friendsRequestCancelled;

  /// No description provided for @friendsRequestPendingInfo.
  ///
  /// In en, this message translates to:
  /// **'Friend request is pending'**
  String get friendsRequestPendingInfo;

  /// No description provided for @friendsRequestReceivedInfo.
  ///
  /// In en, this message translates to:
  /// **'This user sent you a friend request'**
  String get friendsRequestReceivedInfo;

  /// No description provided for @friendsRequestRejected.
  ///
  /// In en, this message translates to:
  /// **'Friend request rejected'**
  String get friendsRequestRejected;

  /// No description provided for @friendsRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent!'**
  String get friendsRequestSent;

  /// Button on Add Friends that opens the friend requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get friendsRequestsButton;

  /// No description provided for @friendsRequestsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'When someone sends you a friend request,\nit will appear here'**
  String get friendsRequestsEmptySubtitle;

  /// No description provided for @friendsRequestsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No friend requests'**
  String get friendsRequestsEmptyTitle;

  /// Toggle on Friend Requests: requests other people sent to the user.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get friendsRequestsReceivedTab;

  /// Toggle on Friend Requests: requests the user sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get friendsRequestsSentTab;

  /// No description provided for @friendsRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Friend Requests'**
  String get friendsRequestsTitle;

  /// Search hint on Add Friends; the search looks people up by @username. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Search by tag'**
  String get friendsSearchByTagHint;

  /// Search hint on My friends (searches only among the user's friends). Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Find my friends'**
  String get friendsSearchHint;

  /// No description provided for @friendsSendCapsule.
  ///
  /// In en, this message translates to:
  /// **'Send Capsule'**
  String get friendsSendCapsule;

  /// Accessibility label of the add icon on a suggested friend.
  ///
  /// In en, this message translates to:
  /// **'Send friend request'**
  String get friendsSendRequestLabel;

  /// No description provided for @friendsSentEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Friend requests you send\nwill appear here'**
  String get friendsSentEmptySubtitle;

  /// No description provided for @friendsSentEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No sent requests'**
  String get friendsSentEmptyTitle;

  /// No description provided for @friendsShareProfile.
  ///
  /// In en, this message translates to:
  /// **'Share Profile'**
  String get friendsShareProfile;

  /// No description provided for @friendsShareProfileTo.
  ///
  /// In en, this message translates to:
  /// **'Share profile to ...'**
  String get friendsShareProfileTo;

  /// No description provided for @friendsSuggestionRemoved.
  ///
  /// In en, this message translates to:
  /// **'Suggested friend removed from the list!'**
  String get friendsSuggestionRemoved;

  /// No description provided for @friendsThisIsYou.
  ///
  /// In en, this message translates to:
  /// **'This is your account'**
  String get friendsThisIsYou;

  /// No description provided for @friendsUnfollowed.
  ///
  /// In en, this message translates to:
  /// **'Unfollowed successfully'**
  String get friendsUnfollowed;

  /// Main button on the profile of someone who is already a friend: opens their friend profile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get friendsViewProfile;

  /// No description provided for @messagesBlockedByYou.
  ///
  /// In en, this message translates to:
  /// **'You blocked this user'**
  String get messagesBlockedByYou;

  /// No description provided for @messagesCantSend.
  ///
  /// In en, this message translates to:
  /// **'You can\'t send messages to this user'**
  String get messagesCantSend;

  /// Small label on the photo of a capsule sent in a chat.
  ///
  /// In en, this message translates to:
  /// **'Capsule'**
  String get messagesCapsuleLabel;

  /// No description provided for @messagesCapsuleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This capsule is no longer available'**
  String get messagesCapsuleUnavailable;

  /// Chat header title while the friend's name is not known yet.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get messagesChatFallbackTitle;

  /// Accessibility label of the chat menu button.
  ///
  /// In en, this message translates to:
  /// **'Chat options'**
  String get messagesChatOptions;

  /// No description provided for @messagesChatsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your chats'**
  String get messagesChatsLoadError;

  /// No description provided for @messagesCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again'**
  String get messagesCheckConnection;

  /// Confirm button of the clear-history dialog.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get messagesClearConfirm;

  /// No description provided for @messagesClearConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear chat history?'**
  String get messagesClearConfirmTitle;

  /// No description provided for @messagesClearFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear history'**
  String get messagesClearFailed;

  /// Empty chat. The name cannot be inflected: phrase it so the name stays in its base form.
  ///
  /// In en, this message translates to:
  /// **'Say hello to {name}!'**
  String messagesEmptySubtitle(String name);

  /// No description provided for @messagesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get messagesEmptyTitle;

  /// No description provided for @messagesFindChatsHint.
  ///
  /// In en, this message translates to:
  /// **'Find chats'**
  String get messagesFindChatsHint;

  /// No description provided for @messagesInputHint.
  ///
  /// In en, this message translates to:
  /// **'Write a message...'**
  String get messagesInputHint;

  /// No description provided for @messagesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the messages'**
  String get messagesLoadError;

  /// No description provided for @messagesMenuBlock.
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get messagesMenuBlock;

  /// No description provided for @messagesMenuClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get messagesMenuClearHistory;

  /// No description provided for @messagesMenuMute.
  ///
  /// In en, this message translates to:
  /// **'Mute notifications'**
  String get messagesMenuMute;

  /// Chat menu item. Menu items are one short line (about 22 characters at most).
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get messagesMenuSearch;

  /// No description provided for @messagesMenuUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock user'**
  String get messagesMenuUnblock;

  /// No description provided for @messagesMenuUnmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute notifications'**
  String get messagesMenuUnmute;

  /// No description provided for @messagesMutedToast.
  ///
  /// In en, this message translates to:
  /// **'Chat muted'**
  String get messagesMutedToast;

  /// No description provided for @messagesNewChatFindFriends.
  ///
  /// In en, this message translates to:
  /// **'Find friends'**
  String get messagesNewChatFindFriends;

  /// No description provided for @messagesNewChatNoFriends.
  ///
  /// In en, this message translates to:
  /// **'No friends yet'**
  String get messagesNewChatNoFriends;

  /// No description provided for @messagesNewChatNoFriendsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add some friends to start chatting!'**
  String get messagesNewChatNoFriendsSubtitle;

  /// No description provided for @messagesNewChatNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No friends found'**
  String get messagesNewChatNoMatch;

  /// No description provided for @messagesNewChatSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search friends'**
  String get messagesNewChatSearchHint;

  /// No description provided for @messagesNewChatTitle.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get messagesNewChatTitle;

  /// No description provided for @messagesNoChatsFound.
  ///
  /// In en, this message translates to:
  /// **'No chats found'**
  String get messagesNoChatsFound;

  /// No description provided for @messagesNoChatsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the new message button to start chatting with friends!'**
  String get messagesNoChatsSubtitle;

  /// No description provided for @messagesNoChatsTitle.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get messagesNoChatsTitle;

  /// No description provided for @messagesNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No messages found'**
  String get messagesNoMatchTitle;

  /// Empty search result in the chat list, a chat and the new-chat sheet.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches \"{query}\"'**
  String messagesNothingMatches(String query);

  /// Small line under the friend's name in a muted chat. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Notifications muted'**
  String get messagesNotificationsMuted;

  /// Accessibility label of a capsule's photo in a chat.
  ///
  /// In en, this message translates to:
  /// **'Open capsule {title}'**
  String messagesOpenCapsule(String title);

  /// No description provided for @messagesReceiptFailed.
  ///
  /// In en, this message translates to:
  /// **'Not sent · Tap to retry'**
  String get messagesReceiptFailed;

  /// Receipt: the friend has read the message (past participle).
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get messagesReceiptRead;

  /// Receipt under the user's newest message.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get messagesReceiptSending;

  /// No description provided for @messagesReceiptSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get messagesReceiptSent;

  /// Accessibility label of the round button that jumps to the newest message.
  ///
  /// In en, this message translates to:
  /// **'Scroll to the latest message'**
  String get messagesScrollToLatest;

  /// No description provided for @messagesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search messages'**
  String get messagesSearchHint;

  /// Accessibility label of the send button.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get messagesSend;

  /// Accessibility label of the capsule button next to the message field.
  ///
  /// In en, this message translates to:
  /// **'Send a capsule'**
  String get messagesSendCapsule;

  /// No description provided for @messagesSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message'**
  String get messagesSendFailed;

  /// No description provided for @messagesSignedOut.
  ///
  /// In en, this message translates to:
  /// **'You are signed out'**
  String get messagesSignedOut;

  /// Accessibility label of a friend in the new-chat sheet.
  ///
  /// In en, this message translates to:
  /// **'Start chat with {name}'**
  String messagesStartChatWith(String name);

  /// Title of the messages tab (the list of chats).
  ///
  /// In en, this message translates to:
  /// **'My Laters'**
  String get messagesTitle;

  /// Day separator in a chat.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get messagesToday;

  /// No description provided for @messagesTooLong.
  ///
  /// In en, this message translates to:
  /// **'This message is too long'**
  String get messagesTooLong;

  /// No description provided for @messagesUnmutedToast.
  ///
  /// In en, this message translates to:
  /// **'Chat unmuted'**
  String get messagesUnmutedToast;

  /// Day separator in a chat and the time label in the chat list.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get messagesYesterday;

  /// Chat list preview when the user sent the last message.
  ///
  /// In en, this message translates to:
  /// **'You: {message}'**
  String messagesYouPrefix(String message);

  /// Place pill on a capsule when the phone has no location yet.
  ///
  /// In en, this message translates to:
  /// **'No location'**
  String get placeNoLocation;

  /// No description provided for @placeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown location'**
  String get placeUnknown;

  /// Card on the own profile page that opens Add Friends.
  ///
  /// In en, this message translates to:
  /// **'Add friends'**
  String get profileAddFriends;

  /// Row in My capsules on the profile page: opens the camera for a public capsule.
  ///
  /// In en, this message translates to:
  /// **'Add to map | Everyone'**
  String get profileAddToMapEveryone;

  /// Row in My capsules on the profile page: opens the camera for a friends-only capsule.
  ///
  /// In en, this message translates to:
  /// **'Add to map | Only for friends'**
  String get profileAddToMapFriends;

  /// Red option in the background picture menu.
  ///
  /// In en, this message translates to:
  /// **'Delete background picture'**
  String get profileBackgroundDelete;

  /// Title of the menu shown when the user taps their profile background (narrow, large bold text).
  ///
  /// In en, this message translates to:
  /// **'Background picture'**
  String get profileBackgroundTitle;

  /// No description provided for @profileBackgroundUpdated.
  ///
  /// In en, this message translates to:
  /// **'Background picture updated successfully!'**
  String get profileBackgroundUpdated;

  /// Option in the menu of a pinned friend: opens the list to choose which friends are pinned to the profile.
  ///
  /// In en, this message translates to:
  /// **'Choose pinned friends'**
  String get profileChoosePinned;

  /// Button on Share Profile that copies the profile link (half-width button with an icon: keep it short).
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get profileCopyLink;

  /// No description provided for @profileErrorCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Failed to copy link'**
  String get profileErrorCopyLink;

  /// No description provided for @profileErrorDeleteBackground.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete background picture'**
  String get profileErrorDeleteBackground;

  /// No description provided for @profileErrorDeletePicture.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete profile picture'**
  String get profileErrorDeletePicture;

  /// No description provided for @profileErrorShare.
  ///
  /// In en, this message translates to:
  /// **'Failed to share profile'**
  String get profileErrorShare;

  /// No description provided for @profileErrorUploadBackground.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload background picture'**
  String get profileErrorUploadBackground;

  /// No description provided for @profileErrorUploadPicture.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload profile picture'**
  String get profileErrorUploadPicture;

  /// Option in the profile / background picture menu.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get profileImageFromGallery;

  /// Option in the profile / background picture menu: opens the camera.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get profileImageTakePhoto;

  /// No description provided for @profileLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard!'**
  String get profileLinkCopied;

  /// Section title on the own profile page.
  ///
  /// In en, this message translates to:
  /// **'My capsules'**
  String get profileMyCapsules;

  /// Row under the pinned friends on the profile page: opens the friends list.
  ///
  /// In en, this message translates to:
  /// **'My friends'**
  String get profileMyFriends;

  /// Shown instead of the pinned friends on the profile page when the user has no friends.
  ///
  /// In en, this message translates to:
  /// **'You have no friends yet'**
  String get profileNoFriends;

  /// Red option in the profile picture menu.
  ///
  /// In en, this message translates to:
  /// **'Delete profile icon'**
  String get profilePictureDelete;

  /// Title of the menu shown when the user taps their profile picture (narrow, large bold text).
  ///
  /// In en, this message translates to:
  /// **'Profile picture'**
  String get profilePictureTitle;

  /// No description provided for @profilePictureUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile picture updated successfully!'**
  String get profilePictureUpdated;

  /// Explanation under the title of the pinned friends chooser.
  ///
  /// In en, this message translates to:
  /// **'If you choose fewer than 3, random friends from your list will be shown'**
  String get profilePinnedHint;

  /// Error when the user ticks a fourth pinned friend.
  ///
  /// In en, this message translates to:
  /// **'You can only pin up to 3 friends'**
  String get profilePinnedLimit;

  /// Title of the sheet where the user picks the friends pinned to their profile.
  ///
  /// In en, this message translates to:
  /// **'Choose up to 3 pinned friends'**
  String get profilePinnedTitle;

  /// No description provided for @profilePinnedUpdated.
  ///
  /// In en, this message translates to:
  /// **'Pinned friends updated successfully!'**
  String get profilePinnedUpdated;

  /// Shown in place of the QR code on Share Profile if it cannot be drawn.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong...'**
  String get profileQrError;

  /// Button on Share Profile that opens the system share sheet (half-width button with an icon: keep it short).
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get profileShare;

  /// Heading above the QR code on Share Profile.
  ///
  /// In en, this message translates to:
  /// **'Share Your Profile'**
  String get profileShareHeading;

  /// Blue info card at the bottom of Share Profile.
  ///
  /// In en, this message translates to:
  /// **'Others can scan this code with their camera or the app to add you as a friend'**
  String get profileShareHint;

  /// Text passed to the system share sheet when sharing a profile (the user's own or a friend's).
  ///
  /// In en, this message translates to:
  /// **'Check out {name} on Later!\n{link}'**
  String profileShareMessage(String name, String link);

  /// Subject passed to the system share sheet (used by e-mail apps) when sharing a profile.
  ///
  /// In en, this message translates to:
  /// **'Connect with {name} on Later'**
  String profileShareSubject(String name);

  /// Grey line under the heading on Share Profile.
  ///
  /// In en, this message translates to:
  /// **'Let others scan this QR code to add you as a friend'**
  String get profileShareSubtitle;

  /// Page title of Share Profile.
  ///
  /// In en, this message translates to:
  /// **'Share Profile'**
  String get profileShareTitle;

  /// Shown on the profile or background picture while it uploads or is deleted.
  ///
  /// In en, this message translates to:
  /// **'Updating...'**
  String get profileUpdating;

  /// Option in the menu of a pinned friend: opens that friend's profile.
  ///
  /// In en, this message translates to:
  /// **'View profile page'**
  String get profileViewProfile;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'pl', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pl':
      return AppLocalizationsPl();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
