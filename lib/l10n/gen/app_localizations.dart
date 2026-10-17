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

  /// Accessibility label of the Google sign-in icon.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// Placeholder of the email field (login, sign-up, password reset).
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailHint;

  /// No description provided for @authEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get authEnterEmail;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'The account already exists for that email.'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorEmailTaken.
  ///
  /// In en, this message translates to:
  /// **'Another account already uses this email.'**
  String get authErrorEmailTaken;

  /// No description provided for @authErrorInvalidCredential.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password.'**
  String get authErrorInvalidCredential;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'The email address is not valid.'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorMethodDisabled.
  ///
  /// In en, this message translates to:
  /// **'This sign-in method is not enabled.'**
  String get authErrorMethodDisabled;

  /// No description provided for @authErrorPickGoogleAccount.
  ///
  /// In en, this message translates to:
  /// **'Please pick the Google account you sign in with.'**
  String get authErrorPickGoogleAccount;

  /// No description provided for @authErrorRecentLogin.
  ///
  /// In en, this message translates to:
  /// **'Please confirm it is you and try again.'**
  String get authErrorRecentLogin;

  /// No description provided for @authErrorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get authErrorTooManyRequests;

  /// No description provided for @authErrorUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get authErrorUserDisabled;

  /// No description provided for @authErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No user found with this email.'**
  String get authErrorUserNotFound;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'The password provided is too weak.'**
  String get authErrorWeakPassword;

  /// Snack bar when the password reset email could not be sent.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String authErrorWithMessage(String message);

  /// Changing the password, email or deleting the account: the current password is wrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong password.'**
  String get authErrorWrongPassword;

  /// No description provided for @authErrorWrongPasswordProvided.
  ///
  /// In en, this message translates to:
  /// **'Wrong password provided.'**
  String get authErrorWrongPasswordProvided;

  /// Accessibility label of the Facebook icon (not available yet).
  ///
  /// In en, this message translates to:
  /// **'Facebook (coming soon)'**
  String get authFacebookSoon;

  /// No description provided for @authFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get authFillAllFields;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// Big green button on the welcome page that opens the login page.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get authGetStarted;

  /// Bold link after authHaveAccount that opens the login page.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get authGoToLogIn;

  /// Bold link after authNoAccount that opens the sign-up page.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get authGoToSignUp;

  /// No description provided for @authGoogleFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Please try again.'**
  String get authGoogleFailed;

  /// Sign-up page, followed by the authGoToLogIn link.
  ///
  /// In en, this message translates to:
  /// **'Do you have an account?'**
  String get authHaveAccount;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// Small print on the sign-up page. {terms} and {privacy} are tappable links (authTermsOfUse, authPrivacyPolicy).
  ///
  /// In en, this message translates to:
  /// **'By signing up you agree to the {terms} and {privacy}'**
  String authLegalNotice(String terms, String privacy);

  /// No description provided for @authLinkOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the page.'**
  String get authLinkOpenFailed;

  /// Big green button that signs in. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get authLogInButton;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please log in to continue using our app'**
  String get authLoginSubtitle;

  /// Large heading of the login page.
  ///
  /// In en, this message translates to:
  /// **'Log In Now'**
  String get authLoginTitle;

  /// Placeholder of the display name field on the sign-up page.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get authNameHint;

  /// Login page, followed by the authGoToSignUp link.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authNoAccount;

  /// Google sign-in could not choose a free username automatically; the user should use the sign-up form.
  ///
  /// In en, this message translates to:
  /// **'Could not pick a username. Please sign up.'**
  String get authNoFreeUsername;

  /// Above the Google and Facebook sign-in icons.
  ///
  /// In en, this message translates to:
  /// **'Or connect with'**
  String get authOrConnectWith;

  /// Placeholder of the password field.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordHint;

  /// No description provided for @authPermissionCameraText.
  ///
  /// In en, this message translates to:
  /// **'And you will be able to create time capsules!'**
  String get authPermissionCameraText;

  /// Title of a permission page shown after sign-in (shrinks to fit one line).
  ///
  /// In en, this message translates to:
  /// **'Share Camera access with Later'**
  String get authPermissionCameraTitle;

  /// No description provided for @authPermissionContactsText.
  ///
  /// In en, this message translates to:
  /// **'Find and invite friends from your contacts!'**
  String get authPermissionContactsText;

  /// No description provided for @authPermissionContactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Access contacts'**
  String get authPermissionContactsTitle;

  /// Button on a permission page that asks for the permission.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get authPermissionEnable;

  /// The same button once the permission is granted (disabled).
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get authPermissionGranted;

  /// No description provided for @authPermissionLocationText.
  ///
  /// In en, this message translates to:
  /// **'And you will be able to find capsules near you!'**
  String get authPermissionLocationText;

  /// No description provided for @authPermissionLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Share geolocation with us'**
  String get authPermissionLocationTitle;

  /// "it" is the microphone: video capsules need sound.
  ///
  /// In en, this message translates to:
  /// **'Camera won\'t work without it'**
  String get authPermissionMicrophoneText;

  /// No description provided for @authPermissionMicrophoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Provide Later with microphone access'**
  String get authPermissionMicrophoneTitle;

  /// No description provided for @authPermissionNotificationsText.
  ///
  /// In en, this message translates to:
  /// **'Stay updated with new followers and capsules!'**
  String get authPermissionNotificationsText;

  /// No description provided for @authPermissionNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get authPermissionNotificationsTitle;

  /// Link inside authLegalNotice: use the grammatical form that fits that sentence.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get authPrivacyPolicy;

  /// No description provided for @authResetDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a password reset link'**
  String get authResetDescription;

  /// No description provided for @authResetInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get authResetInvalidEmail;

  /// Button of the password reset dialog. Keep it short (narrow button).
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get authResetSend;

  /// No description provided for @authResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent! Check your inbox.'**
  String get authResetSent;

  /// Title of the password reset dialog.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get authResetTitle;

  /// No description provided for @authResetUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email'**
  String get authResetUserNotFound;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again.'**
  String get authSignInAgain;

  /// Big green button that creates the account. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get authSignUpButton;

  /// No description provided for @authSignupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please fill in the details to create your account'**
  String get authSignupSubtitle;

  /// Large heading of the sign-up page.
  ///
  /// In en, this message translates to:
  /// **'Sign Up Now'**
  String get authSignupTitle;

  /// Link inside authLegalNotice: use the grammatical form that fits that sentence.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get authTermsOfUse;

  /// Placeholder of the username field on the sign-up page (the unique @name).
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get authUsernameHint;

  /// Welcome page text under the title. The line break splits it into two balanced lines.
  ///
  /// In en, this message translates to:
  /// **'Create an account to see your capsules\nand your friends\''**
  String get authWelcomeSubtitle;

  /// First line of the welcome page title; the next line is the app name "Later" in bold. Keep it short: one line in a large font.
  ///
  /// In en, this message translates to:
  /// **'Welcome to'**
  String get authWelcomeTo;

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
