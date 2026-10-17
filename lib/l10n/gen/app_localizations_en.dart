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
  String get authPermissionContactsText =>
      'Find and invite friends from your contacts!';

  @override
  String get authPermissionContactsTitle => 'Access contacts';

  @override
  String get authPermissionEnable => 'Enable';

  @override
  String get authPermissionGranted => 'Granted';

  @override
  String get authPermissionLocationText =>
      'And you will be able to find capsules near you!';

  @override
  String get authPermissionLocationTitle => 'Share geolocation with us';

  @override
  String get authPermissionMicrophoneText => 'Camera won\'t work without it';

  @override
  String get authPermissionMicrophoneTitle =>
      'Provide Later with microphone access';

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
