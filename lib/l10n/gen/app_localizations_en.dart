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
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authEmailHint => 'Email';

  @override
  String get authEnterEmail => 'Please enter your email';

  @override
  String get authErrorEmailInUse =>
      'The account already exists for that email.';

  @override
  String get authErrorEmailTaken => 'Another account already uses this email.';

  @override
  String get authErrorInvalidCredential => 'Wrong email or password.';

  @override
  String get authErrorInvalidEmail => 'The email address is not valid.';

  @override
  String get authErrorMethodDisabled => 'This sign-in method is not enabled.';

  @override
  String get authErrorPickGoogleAccount =>
      'Please pick the Google account you sign in with.';

  @override
  String get authErrorRecentLogin => 'Please confirm it is you and try again.';

  @override
  String get authErrorTooManyRequests =>
      'Too many attempts. Please try again later.';

  @override
  String get authErrorUserDisabled => 'This account has been disabled.';

  @override
  String get authErrorUserNotFound => 'No user found with this email.';

  @override
  String get authErrorWeakPassword => 'The password provided is too weak.';

  @override
  String authErrorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get authErrorWrongPassword => 'Wrong password.';

  @override
  String get authErrorWrongPasswordProvided => 'Wrong password provided.';

  @override
  String get authFacebookSoon => 'Facebook (coming soon)';

  @override
  String get authFillAllFields => 'Please fill in all fields';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authGetStarted => 'Get Started';

  @override
  String get authGoToLogIn => 'Log In';

  @override
  String get authGoToSignUp => 'Sign Up';

  @override
  String get authGoogleFailed => 'Google sign-in failed. Please try again.';

  @override
  String get authHaveAccount => 'Do you have an account?';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String authLegalNotice(String terms, String privacy) {
    return 'By signing up you agree to the $terms and $privacy';
  }

  @override
  String get authLinkOpenFailed => 'Could not open the page.';

  @override
  String get authLogInButton => 'Log In';

  @override
  String get authLoginSubtitle => 'Please log in to continue using our app';

  @override
  String get authLoginTitle => 'Log In Now';

  @override
  String get authNameHint => 'Name';

  @override
  String get authNoAccount => 'Don\'t have an account?';

  @override
  String get authNoFreeUsername => 'Could not pick a username. Please sign up.';

  @override
  String get authOrConnectWith => 'Or connect with';

  @override
  String get authPasswordHint => 'Password';

  @override
  String get authPermissionCameraText =>
      'And you will be able to create time capsules!';

  @override
  String get authPermissionCameraTitle => 'Share Camera access with Later';

  @override
  String get authPermissionEnable => 'Enable';

  @override
  String get authPermissionLocationText =>
      'And you will be able to find capsules near you!';

  @override
  String get authPermissionLocationTitle => 'Share geolocation with us';

  @override
  String get authPermissionNotNow => 'Not now';

  @override
  String get authPermissionNotificationsText =>
      'Stay updated with new followers and capsules!';

  @override
  String get authPermissionNotificationsTitle => 'Enable notifications';

  @override
  String get authPrivacyPolicy => 'Privacy Policy';

  @override
  String get authResetDescription =>
      'Enter your email to receive a password reset link';

  @override
  String get authResetInvalidEmail => 'Invalid email address';

  @override
  String get authResetSend => 'Send Reset Link';

  @override
  String get authResetSent => 'Password reset email sent! Check your inbox.';

  @override
  String get authResetTitle => 'Reset Password';

  @override
  String get authResetUserNotFound => 'No account found with this email';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authSignInAgain => 'Please sign in again.';

  @override
  String get authSignUpButton => 'Sign Up';

  @override
  String get authSignupSubtitle =>
      'Please fill in the details to create your account';

  @override
  String get authSignupTitle => 'Sign Up Now';

  @override
  String get authTermsOfUse => 'Terms of Use';

  @override
  String get authUsernameHint => 'Nickname';

  @override
  String get authWelcomeSubtitle =>
      'Create an account to see your capsules\nand your friends\'';

  @override
  String get authWelcomeTo => 'Welcome to';

  @override
  String get capsulesCameraAccessDenied =>
      'Allow camera access in Settings to take a photo';

  @override
  String get capsulesCameraFlashOff => 'Flash off';

  @override
  String get capsulesCameraFlashOn => 'Flash on';

  @override
  String get capsulesCameraStartFailed => 'The camera could not be started';

  @override
  String get capsulesCameraSwitch => 'Switch camera';

  @override
  String get capsulesCameraTakePhoto => 'Take photo';

  @override
  String get capsulesCameraUnavailable => 'No camera available';

  @override
  String get capsulesColorBlue => 'Blue';

  @override
  String get capsulesColorGreen => 'Green';

  @override
  String get capsulesColorOrange => 'Orange';

  @override
  String get capsulesColorPurple => 'Purple';

  @override
  String get capsulesColorRed => 'Red';

  @override
  String get capsulesColorYellow => 'Yellow';

  @override
  String get capsulesCreationColor => 'Color';

  @override
  String get capsulesCreationDescriptionHint => 'Add description...';

  @override
  String get capsulesCreationOpenAt => 'Open At';

  @override
  String get capsulesCreationPreview => 'Capsule Preview';

  @override
  String get capsulesCreationPrivacy => 'Privacy';

  @override
  String get capsulesCreationSelectDate => 'Select date';

  @override
  String get capsulesCreationSettings => 'Capsule Settings';

  @override
  String get capsulesCreationSubmit => 'Create Capsule';

  @override
  String get capsulesCreationTitle => 'Create Capsule';

  @override
  String get capsulesCreationTitleHint => 'Add Title...';

  @override
  String get capsulesDefaultTitle => 'Capsule';

  @override
  String get capsulesErrorNoLocation => 'We could not detect your location';

  @override
  String get capsulesErrorSaveFailed => 'Failed to save capsule';

  @override
  String get capsulesErrorSavedNotSent =>
      'The capsule was saved but not sent. Tap save to try again.';

  @override
  String get capsulesPrivacyFriends => 'Friends';

  @override
  String get capsulesPrivacyPrivate => 'Private';

  @override
  String get capsulesPrivacyPublic => 'Public';

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
  String commonSizeBytes(String size) {
    return '$size B';
  }

  @override
  String commonSizeGigabytes(String size) {
    return '$size GB';
  }

  @override
  String commonSizeKilobytes(String size) {
    return '$size KB';
  }

  @override
  String commonSizeMegabytes(String size) {
    return '$size MB';
  }

  @override
  String get commonUnknownUser => 'Unknown user';

  @override
  String get commonUnknownUsername => 'unknown';

  @override
  String get commonUntitled => 'Untitled';

  @override
  String get commonUsernameRequired => 'Please enter a username';

  @override
  String get commonUsernameRules =>
      'Use 3-30 letters, numbers, dots, dashes or underscores';

  @override
  String get commonUsernameTaken => 'Username already taken';

  @override
  String get failureNotFound => 'This item no longer exists.';

  @override
  String get failurePermission => 'You are not allowed to do that.';

  @override
  String get friendsAccept => 'Accept';

  @override
  String get friendsAcceptRequestLabel => 'Accept friend request';

  @override
  String get friendsAdd => 'Add';

  @override
  String get friendsAddTitle => 'Add Friends';

  @override
  String get friendsBlock => 'Block';

  @override
  String get friendsBlockConfirm => 'Are you sure you want to block this user?';

  @override
  String get friendsCapsulesSettings => 'Capsules settings';

  @override
  String get friendsChatSettings => 'Chat settings';

  @override
  String get friendsEmpty => 'No friends added yet';

  @override
  String get friendsErrorAcceptRequest => 'Failed to accept request';

  @override
  String get friendsErrorBlock => 'Failed to block user';

  @override
  String get friendsErrorCancelRequest => 'Failed to cancel request';

  @override
  String get friendsErrorFollow => 'Failed to follow user';

  @override
  String get friendsErrorLoadUsers => 'Could not load users';

  @override
  String get friendsErrorRejectRequest => 'Failed to reject request';

  @override
  String get friendsErrorRemoveFriend => 'Failed to remove friend';

  @override
  String get friendsErrorSendRequest => 'Failed to send friend request';

  @override
  String get friendsErrorUnblock => 'Failed to unblock user';

  @override
  String get friendsErrorUnfollow => 'Failed to unfollow user';

  @override
  String get friendsFindByUsernameHint =>
      'Search by @username or scan a friend\'s QR code. People your friends know show up here.';

  @override
  String get friendsFollow => 'Follow';

  @override
  String get friendsFollowed =>
      'Following! You\'ll get notifications about their capsules';

  @override
  String get friendsFollowing => 'Following';

  @override
  String get friendsFriendCapsulesEmpty =>
      'Friend\'s capsules will appear here';

  @override
  String get friendsFriendCapsulesTitle => 'Friend\'s capsules';

  @override
  String get friendsHideSuggestionLabel => 'Hide suggestion';

  @override
  String get friendsMakeFriends => 'Make friends';

  @override
  String get friendsManageFriendship => 'Manage friendship';

  @override
  String friendsMutualCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mutual friends',
      one: '1 mutual friend',
    );
    return '$_temp0';
  }

  @override
  String get friendsMyFriendsTitle => 'My friends';

  @override
  String get friendsMyProfile => 'My Profile';

  @override
  String get friendsNoMatches => 'No friends match your search';

  @override
  String get friendsNoSuggestions => 'No more suggested friends';

  @override
  String get friendsOpenChat => 'Open chat';

  @override
  String get friendsPending => 'Pending';

  @override
  String get friendsQrHint =>
      'Point your camera at the QR code to add a friend';

  @override
  String get friendsQrInvalid =>
      'Invalid QR code. Please scan a Later profile QR code.';

  @override
  String get friendsQrTitle => 'Scan QR Code';

  @override
  String get friendsReject => 'Reject';

  @override
  String get friendsRemove => 'Remove from friends';

  @override
  String get friendsRemoveAction => 'Remove';

  @override
  String get friendsRemoveConfirm =>
      'Are you sure you want to remove user from friends?';

  @override
  String get friendsRemoving => 'Removing...';

  @override
  String get friendsReport => 'Report';

  @override
  String get friendsRequestAccepted => 'Friend request accepted!';

  @override
  String get friendsRequestAlreadyExists => 'Friend request already exists';

  @override
  String get friendsRequestCancelled => 'Friend request cancelled';

  @override
  String get friendsRequestPendingInfo => 'Friend request is pending';

  @override
  String get friendsRequestReceivedInfo =>
      'This user sent you a friend request';

  @override
  String get friendsRequestRejected => 'Friend request rejected';

  @override
  String get friendsRequestSent => 'Friend request sent!';

  @override
  String get friendsRequestsButton => 'Requests';

  @override
  String get friendsRequestsEmptySubtitle =>
      'When someone sends you a friend request,\nit will appear here';

  @override
  String get friendsRequestsEmptyTitle => 'No friend requests';

  @override
  String get friendsRequestsReceivedTab => 'Received';

  @override
  String get friendsRequestsSentTab => 'Sent';

  @override
  String get friendsRequestsTitle => 'Friend Requests';

  @override
  String get friendsSearchByTagHint => 'Search by tag';

  @override
  String get friendsSearchHint => 'Find my friends';

  @override
  String get friendsSendCapsule => 'Send Capsule';

  @override
  String get friendsSendRequestLabel => 'Send friend request';

  @override
  String get friendsSentEmptySubtitle =>
      'Friend requests you send\nwill appear here';

  @override
  String get friendsSentEmptyTitle => 'No sent requests';

  @override
  String get friendsShareProfile => 'Share Profile';

  @override
  String get friendsShareProfileTo => 'Share profile to ...';

  @override
  String get friendsSuggestionRemoved =>
      'Suggested friend removed from the list!';

  @override
  String get friendsThisIsYou => 'This is your account';

  @override
  String get friendsUnfollowed => 'Unfollowed successfully';

  @override
  String get friendsViewProfile => 'View Profile';

  @override
  String get historyAddToFavorites => 'Add to favorites';

  @override
  String get historyCapsuleOpened => 'Capsule is opened!';

  @override
  String get historyColorBlue => 'Blue';

  @override
  String get historyColorGreen => 'Green';

  @override
  String get historyColorOrange => 'Orange';

  @override
  String get historyColorPurple => 'Purple';

  @override
  String get historyColorRed => 'Red';

  @override
  String get historyColorYellow => 'Yellow';

  @override
  String historyCountdown(int days, int hours, int minutes, int seconds) {
    return '${days}d ${hours}h ${minutes}m ${seconds}s';
  }

  @override
  String historyCountdownYears(int years, int days, int hours, int minutes) {
    return '${years}y ${days}d ${hours}h ${minutes}m';
  }

  @override
  String historyDeleteConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count capsules?',
      one: 'Delete $count capsule?',
    );
    return '$_temp0';
  }

  @override
  String historyDeleteSelected(int count) {
    return 'Delete ($count)';
  }

  @override
  String historyDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count capsules deleted',
      one: '$count capsule deleted',
    );
    return '$_temp0';
  }

  @override
  String historyDistanceFromYou(String distance) {
    return '$distance km from you';
  }

  @override
  String get historyDistanceUnknown => 'Distance unknown';

  @override
  String get historyEmpty => 'No capsules yet';

  @override
  String get historyErrorDelete => 'Could not delete capsules';

  @override
  String get historyErrorFavorites => 'Could not update favorites';

  @override
  String historyFavoriteAdded(String title) {
    return '$title added to favorites';
  }

  @override
  String historyFavoriteRemoved(String title) {
    return '$title removed from favorites';
  }

  @override
  String get historyFilterAny => 'Any';

  @override
  String get historyFilterBy => 'Filter By';

  @override
  String get historyFilterCapsule => 'Capsule';

  @override
  String get historyFilterColor => 'Color';

  @override
  String get historyFilterFavorite => 'Favorite';

  @override
  String get historyFilterVisibility => 'Visibility';

  @override
  String get historyNoMatches => 'No capsules match your search';

  @override
  String get historyPrivacyFriends => 'Friends';

  @override
  String get historyPrivacyPrivate => 'Private';

  @override
  String get historyPrivacyPublic => 'Public';

  @override
  String get historyRemoveFromFavorites => 'Remove from favorites';

  @override
  String get historyReset => 'Reset';

  @override
  String get historySearchHint => 'Find Capsules...';

  @override
  String historySelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '$count selected',
    );
    return '$_temp0';
  }

  @override
  String get historySortBy => 'Sort By';

  @override
  String get historySortClosest => 'From Closest';

  @override
  String get historySortDistance => 'Distance';

  @override
  String get historySortFarthest => 'From Farthest';

  @override
  String get historySortNewest => 'From Newest';

  @override
  String get historySortOldest => 'From Oldest';

  @override
  String get historySortRelevance => 'Relevance';

  @override
  String get historyTitle => 'My Capsules';

  @override
  String get historyVisibilityFriends => 'Friends visibility';

  @override
  String get historyVisibilityPrivate => 'Private visibility';

  @override
  String get historyVisibilityPublic => 'Public visibility';

  @override
  String get mapCapsuleLocked => 'Locked';

  @override
  String get mapCapsuleNoDescription => 'This capsule has no description.';

  @override
  String get mapCapsuleOpen => 'Open';

  @override
  String mapCapsuleOpensIn(String time) {
    return 'Opens in $time';
  }

  @override
  String get mapCapsuleReady => 'Check out what\'s inside!';

  @override
  String mapDurationDays(int count) {
    return '${count}d';
  }

  @override
  String mapDurationHours(int count) {
    return '${count}h';
  }

  @override
  String mapDurationMinutes(int count) {
    return '${count}m';
  }

  @override
  String mapDurationSeconds(int count) {
    return '${count}s';
  }

  @override
  String get mapLocationDenied =>
      'Allow location access to see capsules near you';

  @override
  String get mapLocationServiceOff =>
      'Turn on location to see capsules near you';

  @override
  String get mapLocationUnknown => 'We could not detect your location';

  @override
  String get mapMyLocation => 'My location';

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
  String notificationsAchievementBody(String name) {
    return '$name: you unlocked a new achievement';
  }

  @override
  String notificationsCapsuleBody(String name) {
    return '$name created a new capsule';
  }

  @override
  String get notificationsChannelActivity => 'Activity';

  @override
  String get notificationsChannelActivityDescription =>
      'Followers, friend requests, reactions, comments and new capsules';

  @override
  String get notificationsChannelActivitySilent => 'Activity (silent)';

  @override
  String get notificationsChannelActivitySilentDescription =>
      'Activity, without sound or vibration';

  @override
  String get notificationsChannelMessages => 'Messages';

  @override
  String get notificationsChannelMessagesDescription =>
      'New messages from your friends';

  @override
  String get notificationsChannelMessagesSilent => 'Messages (silent)';

  @override
  String get notificationsChannelMessagesSilentDescription =>
      'New messages, without sound or vibration';

  @override
  String get notificationsChannelOther => 'Other notifications';

  @override
  String get notificationsChannelOtherDescription =>
      'Other notifications from Later';

  @override
  String notificationsCommentBody(String name) {
    return '$name commented on your capsule';
  }

  @override
  String notificationsCommentBodyWithText(String name, String text) {
    return '$name commented: $text';
  }

  @override
  String notificationsDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}d ago',
      one: '${count}d ago',
    );
    return '$_temp0';
  }

  @override
  String notificationsDeleteConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count notifications?',
      one: 'Delete $count notification?',
    );
    return '$_temp0';
  }

  @override
  String notificationsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notifications deleted',
      one: '$count notification deleted',
    );
    return '$_temp0';
  }

  @override
  String get notificationsEmptyAll =>
      'Your notifications and activity will appear here';

  @override
  String get notificationsEmptyComments =>
      'Comments on your Capsules will appear here';

  @override
  String get notificationsEmptyReplies =>
      'Replies to your messages will appear here';

  @override
  String notificationsFollowBody(String name) {
    return '$name started following you';
  }

  @override
  String notificationsFriendAcceptedBody(String name) {
    return '$name accepted your friend request';
  }

  @override
  String notificationsFriendRequestBody(String name) {
    return '$name wants to be your friend';
  }

  @override
  String notificationsHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}h ago',
      one: '${count}h ago',
    );
    return '$_temp0';
  }

  @override
  String get notificationsJustNow => 'Just now';

  @override
  String get notificationsMarkAsRead => 'Mark as read';

  @override
  String notificationsMarkedRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notifications marked as read',
      one: '$count notification marked as read',
    );
    return '$_temp0';
  }

  @override
  String notificationsMessageBody(String name) {
    return '$name sent you a message';
  }

  @override
  String notificationsMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}m ago',
      one: '${count}m ago',
    );
    return '$_temp0';
  }

  @override
  String notificationsReactionBody(String name, String emoji) {
    return '$name reacted $emoji to your capsule';
  }

  @override
  String notificationsReplyBody(String name) {
    return '$name replied to you';
  }

  @override
  String notificationsReplyBodyWithText(String name, String text) {
    return '$name replied: $text';
  }

  @override
  String notificationsSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '$count selected',
    );
    return '$_temp0';
  }

  @override
  String get notificationsTabAll => 'All';

  @override
  String get notificationsTabComments => 'Comments';

  @override
  String get notificationsTabReplies => 'Replies';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsTypeAchievement => 'Achievement';

  @override
  String get notificationsTypeCapsule => 'New Capsule';

  @override
  String get notificationsTypeComment => 'New Comment';

  @override
  String get notificationsTypeFollow => 'New Follower';

  @override
  String get notificationsTypeFriendAccepted => 'New Friend';

  @override
  String get notificationsTypeFriendRequest => 'Friend Request';

  @override
  String get notificationsTypeMessage => 'New Message';

  @override
  String get notificationsTypeOther => 'Notification';

  @override
  String get notificationsTypeReaction => 'New Reaction';

  @override
  String get notificationsTypeReply => 'New Reply';

  @override
  String notificationsUnreadBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread notifications',
      one: '$count unread notification',
    );
    return '$_temp0';
  }

  @override
  String get placeNoLocation => 'No location';

  @override
  String get placeUnknown => 'Unknown location';

  @override
  String get profileAddFriends => 'Add friends';

  @override
  String get profileAddToMapEveryone => 'Add to map | Everyone';

  @override
  String get profileAddToMapFriends => 'Add to map | Only for friends';

  @override
  String get profileBackgroundDelete => 'Delete background picture';

  @override
  String get profileBackgroundTitle => 'Background picture';

  @override
  String get profileBackgroundUpdated =>
      'Background picture updated successfully!';

  @override
  String get profileChoosePinned => 'Choose pinned friends';

  @override
  String get profileCopyLink => 'Copy Link';

  @override
  String get profileErrorCopyLink => 'Failed to copy link';

  @override
  String get profileErrorDeleteBackground =>
      'Failed to delete background picture';

  @override
  String get profileErrorDeletePicture => 'Failed to delete profile picture';

  @override
  String get profileErrorShare => 'Failed to share profile';

  @override
  String get profileErrorUploadBackground =>
      'Failed to upload background picture';

  @override
  String get profileErrorUploadPicture => 'Failed to upload profile picture';

  @override
  String get profileImageFromGallery => 'Choose from gallery';

  @override
  String get profileImageTakePhoto => 'Take a photo';

  @override
  String get profileLinkCopied => 'Link copied to clipboard!';

  @override
  String get profileMyCapsules => 'My capsules';

  @override
  String get profileMyFriends => 'My friends';

  @override
  String get profileNoFriends => 'You have no friends yet';

  @override
  String get profilePictureDelete => 'Delete profile icon';

  @override
  String get profilePictureTitle => 'Profile picture';

  @override
  String get profilePictureUpdated => 'Profile picture updated successfully!';

  @override
  String get profilePinnedHint =>
      'If you choose fewer than 3, random friends from your list will be shown';

  @override
  String get profilePinnedLimit => 'You can only pin up to 3 friends';

  @override
  String get profilePinnedTitle => 'Choose up to 3 pinned friends';

  @override
  String get profilePinnedUpdated => 'Pinned friends updated successfully!';

  @override
  String get profileQrError => 'Something went wrong...';

  @override
  String get profileShare => 'Share';

  @override
  String get profileShareHeading => 'Share Your Profile';

  @override
  String get profileShareHint =>
      'Others can scan this code with their camera or the app to add you as a friend';

  @override
  String profileShareMessage(String name, String link) {
    return 'Check out $name on Later!\n$link';
  }

  @override
  String profileShareSubject(String name) {
    return 'Connect with $name on Later';
  }

  @override
  String get profileShareSubtitle =>
      'Let others scan this QR code to add you as a friend';

  @override
  String get profileShareTitle => 'Share Profile';

  @override
  String get profileUpdating => 'Updating...';

  @override
  String get profileViewProfile => 'View profile page';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAboutLicenses => 'Open-source licenses';

  @override
  String get settingsAboutOpenFailed => 'Could not open the page.';

  @override
  String get settingsAboutPrivacy => 'Privacy policy';

  @override
  String get settingsAboutTerms => 'Terms of use';

  @override
  String get settingsAboutVersion => 'Version';

  @override
  String get settingsAboutVersionUnknown => 'unknown';

  @override
  String get settingsAppPermissions => 'App permissions';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsAppearanceDescription => 'How Later looks on this phone';

  @override
  String settingsBlockedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count blocked',
      one: '$count blocked',
    );
    return '$_temp0';
  }

  @override
  String get settingsBlockedDescription =>
      'They cannot message you or send you friend requests';

  @override
  String get settingsBlockedEmpty => 'Nobody is blocked';

  @override
  String get settingsBlockedEmptyHint =>
      'Block someone from their profile\nor from a chat';

  @override
  String get settingsBlockedNobody => 'Nobody';

  @override
  String get settingsBlockedUsers => 'Blocked users';

  @override
  String get settingsCameraBack => 'Back camera';

  @override
  String get settingsCameraFooter =>
      'The camera that opens when you create a capsule.';

  @override
  String get settingsCameraFront => 'Front camera';

  @override
  String get settingsCompleteProfileDescription =>
      'Choose how your friends will see you';

  @override
  String settingsCompleteProfileNoProfile(String email) {
    return 'Your account $email has no profile yet.';
  }

  @override
  String get settingsCompleteProfileTitle => 'Almost there';

  @override
  String get settingsCustomizeDescription => 'Tap a picture to change it';

  @override
  String get settingsCustomizeProfile => 'Customize profile';

  @override
  String get settingsDataAndStorage => 'Data and storage';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsDeleteButton => 'Delete my account';

  @override
  String get settingsDeleteConfirm =>
      'Delete your account? This cannot be undone.';

  @override
  String get settingsDeleteDescription =>
      'This removes your account and everything in it';

  @override
  String get settingsDeleteNote =>
      'Deleting your account removes your profile, pictures, capsules, chats, friends and followers. Your friends will no longer see you or your messages. This cannot be undone.';

  @override
  String get settingsDeletedAccount => 'Deleted account';

  @override
  String get settingsDeviceDescription =>
      'How Later looks and works on this phone';

  @override
  String get settingsEmail => 'Email';

  @override
  String settingsEmailDescription(String email) {
    return 'You sign in to Later with $email';
  }

  @override
  String settingsEmailGoogleDescription(String email) {
    return 'You sign in with Google as $email';
  }

  @override
  String get settingsEmailGoogleNote =>
      'Your email comes from your Google account. To use another one, change it in your Google account.';

  @override
  String settingsEmailLinkSent(String newEmail, String currentEmail) {
    return 'We sent a link to $newEmail. Open it to confirm: your email changes then. Until you do, keep signing in with $currentEmail.';
  }

  @override
  String get settingsEmailNewHint => 'New email';

  @override
  String get settingsEmailSendLink => 'Send confirmation link';

  @override
  String get settingsErrorChatUpdateFailed => 'Could not update the chat.';

  @override
  String get settingsErrorCouldNotSave => 'Could not save. Please try again.';

  @override
  String get settingsErrorCurrentPassword =>
      'Please enter your current password.';

  @override
  String get settingsErrorEnterName => 'Please enter your name.';

  @override
  String get settingsErrorEnterNewName => 'Please enter a new name!';

  @override
  String get settingsErrorEnterNewUsername => 'Please enter a new username!';

  @override
  String get settingsErrorEnterPassword => 'Please enter your password.';

  @override
  String get settingsErrorInvalidEmail => 'Please enter a valid email address.';

  @override
  String get settingsErrorNameFailed => 'Failed to update name!';

  @override
  String get settingsErrorPasswordSame =>
      'The new password is the same as the current one.';

  @override
  String settingsErrorPasswordTooShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The new password needs at least $count characters.',
      one: 'The new password needs at least $count character.',
    );
    return '$_temp0';
  }

  @override
  String get settingsErrorPasswordsMismatch =>
      'The new passwords do not match.';

  @override
  String get settingsErrorSameEmail => 'This is already your email.';

  @override
  String get settingsErrorSaveFailed => 'Could not save settings.';

  @override
  String get settingsErrorSignInAgain => 'Please sign in again.';

  @override
  String get settingsErrorUsernameFailed => 'Failed to update username!';

  @override
  String get settingsFaqBlockAnswer =>
      'Block them from their profile or from the chat menu. You can unblock them in Settings > Blocked users.';

  @override
  String get settingsFaqBlockQuestion => 'How do I stop someone contacting me?';

  @override
  String get settingsFaqCapsuleAnswer =>
      'A photo with a title and a note, pinned on the map where you made it. You can set a date: until then the capsule stays locked.';

  @override
  String get settingsFaqCapsuleQuestion => 'What is a capsule?';

  @override
  String get settingsFaqDeleteAnswer =>
      'Settings > Delete account. Everything you made is removed and cannot be brought back.';

  @override
  String get settingsFaqDeleteQuestion => 'How do I delete my account?';

  @override
  String get settingsFaqFriendsAnswer =>
      'Search by username in Friends, scan their QR code, or share your profile link from your profile.';

  @override
  String get settingsFaqFriendsQuestion => 'How do I add friends?';

  @override
  String get settingsFaqNotificationsAnswer =>
      'Check Settings > Notifications: the phone must allow Later to notify you, and push notifications must be on. Quiet hours and muted chats also keep pushes silent.';

  @override
  String get settingsFaqNotificationsQuestion => 'I do not get notifications';

  @override
  String get settingsFaqVisibilityAnswer =>
      'You choose when you create one: only you (Private), your friends (Friends) or everyone (Public).';

  @override
  String get settingsFaqVisibilityQuestion => 'Who can see my capsules?';

  @override
  String get settingsGoogleConfirmsNote =>
      'Google confirms it is you: pick your account when asked.';

  @override
  String get settingsHelp => 'Help';

  @override
  String settingsHelpContactFooter(String email) {
    return 'Emails from the app include your app version and phone. You can also write to $email.';
  }

  @override
  String get settingsHelpContactSupport => 'Contact support';

  @override
  String get settingsHelpCopied => 'Copied. Paste it into your message to us.';

  @override
  String get settingsHelpCopyInfo => 'Copy app information';

  @override
  String get settingsHelpDescription => 'Answers and ways to reach us';

  @override
  String settingsHelpNoEmailApp(String email) {
    return 'No email app found. Write to $email';
  }

  @override
  String get settingsHelpReportProblem => 'Report a problem';

  @override
  String get settingsHelpSubjectProblem => 'Later: problem report';

  @override
  String get settingsHelpSubjectQuestion => 'Later: question';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageDescription =>
      'The language of the app and of your notifications';

  @override
  String get settingsLanguageFooter =>
      'Notifications from Later arrive in this language too.';

  @override
  String get settingsLanguageSystem => 'Phone\'s language';

  @override
  String settingsLanguageSystemHint(String language) {
    return 'Now: $language';
  }

  @override
  String get settingsLogOut => 'Log Out';

  @override
  String get settingsLogOutConfirm => 'Are you sure you want to log out?';

  @override
  String get settingsMapAndCamera => 'Map and camera';

  @override
  String get settingsMapLookHybrid => 'Satellite with labels';

  @override
  String get settingsMapLookSatellite => 'Satellite';

  @override
  String get settingsMapLookStandard => 'Standard';

  @override
  String get settingsName => 'Name';

  @override
  String get settingsNameDescription =>
      'This is how you will be shown on Later, pick a name wisely, so your friends know you by';

  @override
  String get settingsNameHint => 'Enter new name';

  @override
  String get settingsNameUpdated => 'Name updated successfully!';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsAchievements => 'Achievements';

  @override
  String get settingsNotificationsAllow => 'Allow notifications';

  @override
  String get settingsNotificationsBlockedFooter =>
      'Your phone does not let Later show notifications, so none arrive whatever you choose below.';

  @override
  String get settingsNotificationsCapsules => 'New capsules';

  @override
  String get settingsNotificationsCapsulesHint =>
      'From people you follow with notifications on';

  @override
  String get settingsNotificationsComments => 'Comments';

  @override
  String get settingsNotificationsCommentsHint =>
      'On your capsules and replies to you';

  @override
  String get settingsNotificationsDescription =>
      'Choose what Later tells you about';

  @override
  String get settingsNotificationsFollowers => 'New followers';

  @override
  String get settingsNotificationsFriendRequests => 'Friend requests';

  @override
  String get settingsNotificationsFriendRequestsHint => 'Received and accepted';

  @override
  String get settingsNotificationsMessages => 'Messages';

  @override
  String get settingsNotificationsMuteHint =>
      'Mute a single chat from its menu in Messages.';

  @override
  String get settingsNotificationsNews => 'News from Later';

  @override
  String get settingsNotificationsNewsHint =>
      'Rare announcements from the team';

  @override
  String get settingsNotificationsOff => 'Off';

  @override
  String get settingsNotificationsOffInPhone => 'Off in your phone settings';

  @override
  String get settingsNotificationsOn => 'On';

  @override
  String get settingsNotificationsPreview => 'Show message text';

  @override
  String get settingsNotificationsPreviewOff =>
      'Pushes say \"New message\" only';

  @override
  String get settingsNotificationsPush => 'Push notifications';

  @override
  String get settingsNotificationsPushOff => 'You get no pushes from Later';

  @override
  String get settingsNotificationsReactions => 'Reactions';

  @override
  String get settingsNotificationsSound => 'Sound and vibration';

  @override
  String get settingsNotificationsStreak => 'Streak reminder';

  @override
  String get settingsNotificationsStreakHint =>
      'In the evening, when your streak would end tonight';

  @override
  String get settingsPassword => 'Password';

  @override
  String get settingsPasswordChanged => 'Password changed';

  @override
  String get settingsPasswordConfirmsNote =>
      'Your password confirms it is you.';

  @override
  String get settingsPasswordCurrent => 'Current password';

  @override
  String get settingsPasswordDescription =>
      'Choose a password you do not use anywhere else';

  @override
  String get settingsPasswordForgot => 'Forgot your password?';

  @override
  String get settingsPasswordGoogleDescription => 'You sign in with Google';

  @override
  String get settingsPasswordGoogleNote =>
      'Your account has no Later password: Google confirms it is you. Change your password in your Google account.';

  @override
  String settingsPasswordNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'New password ($count+ characters)',
      one: 'New password ($count+ character)',
    );
    return '$_temp0';
  }

  @override
  String get settingsPasswordRepeat => 'Repeat new password';

  @override
  String get settingsPasswordResetFailed =>
      'Could not send the link. Please try again.';

  @override
  String settingsPasswordResetSent(String email) {
    return 'We sent a reset link to $email';
  }

  @override
  String get settingsPermissionCamera => 'Camera';

  @override
  String get settingsPermissionCameraDescription =>
      'Access camera to create time capsules';

  @override
  String get settingsPermissionDenied => 'Denied';

  @override
  String get settingsPermissionGranted => 'Granted';

  @override
  String get settingsPermissionLimited => 'Limited';

  @override
  String get settingsPermissionLocation => 'Location';

  @override
  String get settingsPermissionLocationDescription =>
      'Find capsules nearby and location-based features';

  @override
  String get settingsPermissionNotificationsDescription =>
      'Receive updates about followers and capsules';

  @override
  String get settingsPermissionOpenSettings => 'Open Settings';

  @override
  String get settingsPermissionPermanentlyDenied => 'Permanently Denied';

  @override
  String get settingsPermissionProvisional => 'Provisional';

  @override
  String get settingsPermissionRequiredBody =>
      'This permission has been permanently denied. Please enable it in your device settings.';

  @override
  String get settingsPermissionRequiredTitle => 'Permission Required';

  @override
  String get settingsPermissionRestricted => 'Restricted';

  @override
  String get settingsPermissionRevokeBody =>
      'To revoke this permission, you need to go to your device settings. This will disable the related features in the app.';

  @override
  String get settingsPermissionRevokeTitle => 'Revoke Permission';

  @override
  String get settingsPermissionsDescription =>
      'What Later may use on this phone';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsPrivacyAchievements => 'Show my achievements';

  @override
  String get settingsPrivacyAchievementsHint =>
      'Friends see them on your profile';

  @override
  String get settingsPrivacyApproximate => 'Approximate location';

  @override
  String get settingsPrivacyApproximateHint =>
      'Places new capsules within about a kilometre, not at the exact spot';

  @override
  String get settingsPrivacyDescription =>
      'What others see and what new capsules start with';

  @override
  String get settingsPrivacyNewCapsulesFooter =>
      'You can change both for each capsule when you create it.';

  @override
  String get settingsPrivacyReadReceipts => 'Read receipts';

  @override
  String get settingsPrivacyReadReceiptsHint =>
      'Turned off, friends do not see when you have read their messages, and you do not see theirs';

  @override
  String get settingsQuietFrom => 'Quiet from';

  @override
  String get settingsQuietHours => 'Quiet hours';

  @override
  String get settingsQuietHoursFooter =>
      'No pushes during these hours. Messages still arrive in the app.';

  @override
  String get settingsQuietHoursFrom => 'From';

  @override
  String get settingsQuietHoursUntil => 'Until';

  @override
  String get settingsQuietUntil => 'Quiet until';

  @override
  String get settingsSectionAccount => 'MY ACCOUNT';

  @override
  String get settingsSectionCamera => 'CAMERA';

  @override
  String get settingsSectionContact => 'CONTACT';

  @override
  String get settingsSectionHow => 'HOW';

  @override
  String get settingsSectionMap => 'MAP';

  @override
  String get settingsSectionMoreActivity => 'ACTIVITY';

  @override
  String get settingsSectionNewCapsules => 'NEW CAPSULES';

  @override
  String get settingsSectionNotificationsPrivacy => 'NOTIFICATIONS AND PRIVACY';

  @override
  String get settingsSectionNotifyAbout => 'NOTIFY ME ABOUT';

  @override
  String get settingsSectionQuestions => 'QUESTIONS';

  @override
  String get settingsSectionQuietHours => 'QUIET HOURS';

  @override
  String get settingsSectionSize => 'SIZE';

  @override
  String get settingsSectionSupport => 'SUPPORT';

  @override
  String get settingsSectionTheme => 'THEME';

  @override
  String get settingsSectionThisPhone => 'THIS PHONE';

  @override
  String get settingsSectionVisibility => 'WHAT OTHERS SEE';

  @override
  String get settingsSignedInWithGoogle => 'Signed in with Google';

  @override
  String get settingsSizeFooter =>
      'Makes everything on screen smaller or larger, text included.';

  @override
  String get settingsSizeLarge => 'Large';

  @override
  String get settingsSizeSmall => 'Small';

  @override
  String get settingsSizeStandard => 'Standard';

  @override
  String get settingsStorageCache => 'Cache';

  @override
  String get settingsStorageClear => 'Clear';

  @override
  String get settingsStorageClearCache => 'Clear cache';

  @override
  String get settingsStorageClearConfirm =>
      'Clear the cache? Pictures load again when you need them.';

  @override
  String get settingsStorageCleared => 'Cache cleared';

  @override
  String get settingsStorageClearing => 'Clearing...';

  @override
  String get settingsStorageDescription => 'Space Later uses on this phone';

  @override
  String get settingsStorageFooter =>
      'Photos taken or picked for capsules and pictures loaded from the internet. Your capsules, chats and account stay.';

  @override
  String settingsSupportInfoApp(String version) {
    return 'App: Later $version';
  }

  @override
  String settingsSupportInfoPhone(String system) {
    return 'Phone: $system';
  }

  @override
  String settingsSupportInfoUserId(String uid) {
    return 'User id: $uid';
  }

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeSystem => 'Same as phone';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsUnblock => 'Unblock';

  @override
  String get settingsUnblocking => 'Unblocking...';

  @override
  String get settingsUsername => 'Username';

  @override
  String get settingsUsernameDescription =>
      'This is how your friends find and add you on Later';

  @override
  String get settingsUsernameHint => 'Enter new username';

  @override
  String get settingsUsernameUpdated => 'Username updated successfully!';

  @override
  String get settingsVisibilityFriends => 'Friends';

  @override
  String get settingsVisibilityFriendsHint => 'Only your friends';

  @override
  String get settingsVisibilityPrivate => 'Private';

  @override
  String get settingsVisibilityPrivateHint => 'Only you';

  @override
  String get settingsVisibilityPublic => 'Public';

  @override
  String get settingsVisibilityPublicHint => 'Everyone on the map';

  @override
  String get settingsYourPassword => 'Your password';
}
