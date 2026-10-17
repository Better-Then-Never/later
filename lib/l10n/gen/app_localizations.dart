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

  /// Settings row and page with the app version and legal documents.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsAboutLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get settingsAboutLicenses;

  /// No description provided for @settingsAboutOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the page.'**
  String get settingsAboutOpenFailed;

  /// No description provided for @settingsAboutPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsAboutPrivacy;

  /// No description provided for @settingsAboutTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get settingsAboutTerms;

  /// No description provided for @settingsAboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsAboutVersion;

  /// Shown as the app version when it could not be read.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get settingsAboutVersionUnknown;

  /// No description provided for @settingsAppPermissions.
  ///
  /// In en, this message translates to:
  /// **'App permissions'**
  String get settingsAppPermissions;

  /// Under the Blocked users row: how many people are blocked (1 or more).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} blocked} other{{count} blocked}}'**
  String settingsBlockedCount(int count);

  /// No description provided for @settingsBlockedDescription.
  ///
  /// In en, this message translates to:
  /// **'They cannot message you or send you friend requests'**
  String get settingsBlockedDescription;

  /// No description provided for @settingsBlockedEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nobody is blocked'**
  String get settingsBlockedEmpty;

  /// Empty state of the blocked users list. Two short lines.
  ///
  /// In en, this message translates to:
  /// **'Block someone from their profile\nor from a chat'**
  String get settingsBlockedEmptyHint;

  /// Under the Blocked users row when nobody is blocked.
  ///
  /// In en, this message translates to:
  /// **'Nobody'**
  String get settingsBlockedNobody;

  /// No description provided for @settingsBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Blocked users'**
  String get settingsBlockedUsers;

  /// No description provided for @settingsCameraBack.
  ///
  /// In en, this message translates to:
  /// **'Back camera'**
  String get settingsCameraBack;

  /// No description provided for @settingsCameraFooter.
  ///
  /// In en, this message translates to:
  /// **'The camera that opens when you create a capsule.'**
  String get settingsCameraFooter;

  /// No description provided for @settingsCameraFront.
  ///
  /// In en, this message translates to:
  /// **'Front camera'**
  String get settingsCameraFront;

  /// No description provided for @settingsCompleteProfileDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose how your friends will see you'**
  String get settingsCompleteProfileDescription;

  /// No description provided for @settingsCompleteProfileNoProfile.
  ///
  /// In en, this message translates to:
  /// **'Your account {email} has no profile yet.'**
  String settingsCompleteProfileNoProfile(String email);

  /// Title of the page that asks a signed-in account without a profile for a name and username.
  ///
  /// In en, this message translates to:
  /// **'Almost there'**
  String get settingsCompleteProfileTitle;

  /// No description provided for @settingsCustomizeDescription.
  ///
  /// In en, this message translates to:
  /// **'Tap a picture to change it'**
  String get settingsCustomizeDescription;

  /// No description provided for @settingsCustomizeProfile.
  ///
  /// In en, this message translates to:
  /// **'Customize profile'**
  String get settingsCustomizeProfile;

  /// No description provided for @settingsDataAndStorage.
  ///
  /// In en, this message translates to:
  /// **'Data and storage'**
  String get settingsDataAndStorage;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get settingsDeleteButton;

  /// No description provided for @settingsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete your account? This cannot be undone.'**
  String get settingsDeleteConfirm;

  /// No description provided for @settingsDeleteDescription.
  ///
  /// In en, this message translates to:
  /// **'This removes your account and everything in it'**
  String get settingsDeleteDescription;

  /// No description provided for @settingsDeleteNote.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account removes your profile, pictures, capsules, chats, friends and followers. Your friends will no longer see you or your messages. This cannot be undone.'**
  String get settingsDeleteNote;

  /// Name shown for a blocked user whose account no longer exists.
  ///
  /// In en, this message translates to:
  /// **'Deleted account'**
  String get settingsDeletedAccount;

  /// No description provided for @settingsDeviceDescription.
  ///
  /// In en, this message translates to:
  /// **'How Later looks and works on this phone'**
  String get settingsDeviceDescription;

  /// No description provided for @settingsEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get settingsEmail;

  /// No description provided for @settingsEmailDescription.
  ///
  /// In en, this message translates to:
  /// **'You sign in to Later with {email}'**
  String settingsEmailDescription(String email);

  /// No description provided for @settingsEmailGoogleDescription.
  ///
  /// In en, this message translates to:
  /// **'You sign in with Google as {email}'**
  String settingsEmailGoogleDescription(String email);

  /// No description provided for @settingsEmailGoogleNote.
  ///
  /// In en, this message translates to:
  /// **'Your email comes from your Google account. To use another one, change it in your Google account.'**
  String get settingsEmailGoogleNote;

  /// No description provided for @settingsEmailLinkSent.
  ///
  /// In en, this message translates to:
  /// **'We sent a link to {newEmail}. Open it to confirm: your email changes then. Until you do, keep signing in with {currentEmail}.'**
  String settingsEmailLinkSent(String newEmail, String currentEmail);

  /// No description provided for @settingsEmailNewHint.
  ///
  /// In en, this message translates to:
  /// **'New email'**
  String get settingsEmailNewHint;

  /// Button: sends a confirmation link to the new email address. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Send confirmation link'**
  String get settingsEmailSendLink;

  /// No description provided for @settingsErrorChatUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update the chat.'**
  String get settingsErrorChatUpdateFailed;

  /// No description provided for @settingsErrorCouldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Please try again.'**
  String get settingsErrorCouldNotSave;

  /// No description provided for @settingsErrorCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current password.'**
  String get settingsErrorCurrentPassword;

  /// No description provided for @settingsErrorEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name.'**
  String get settingsErrorEnterName;

  /// No description provided for @settingsErrorEnterNewName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a new name!'**
  String get settingsErrorEnterNewName;

  /// No description provided for @settingsErrorEnterNewUsername.
  ///
  /// In en, this message translates to:
  /// **'Please enter a new username!'**
  String get settingsErrorEnterNewUsername;

  /// No description provided for @settingsErrorEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password.'**
  String get settingsErrorEnterPassword;

  /// No description provided for @settingsErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get settingsErrorInvalidEmail;

  /// No description provided for @settingsErrorNameFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update name!'**
  String get settingsErrorNameFailed;

  /// No description provided for @settingsErrorPasswordSame.
  ///
  /// In en, this message translates to:
  /// **'The new password is the same as the current one.'**
  String get settingsErrorPasswordSame;

  /// No description provided for @settingsErrorPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{The new password needs at least {count} character.} other{The new password needs at least {count} characters.}}'**
  String settingsErrorPasswordTooShort(int count);

  /// No description provided for @settingsErrorPasswordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'The new passwords do not match.'**
  String get settingsErrorPasswordsMismatch;

  /// No description provided for @settingsErrorSameEmail.
  ///
  /// In en, this message translates to:
  /// **'This is already your email.'**
  String get settingsErrorSameEmail;

  /// No description provided for @settingsErrorSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save settings.'**
  String get settingsErrorSaveFailed;

  /// No description provided for @settingsErrorSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again.'**
  String get settingsErrorSignInAgain;

  /// No description provided for @settingsErrorUsernameFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update username!'**
  String get settingsErrorUsernameFailed;

  /// No description provided for @settingsFaqBlockAnswer.
  ///
  /// In en, this message translates to:
  /// **'Block them from their profile or from the chat menu. You can unblock them in Settings > Blocked users.'**
  String get settingsFaqBlockAnswer;

  /// No description provided for @settingsFaqBlockQuestion.
  ///
  /// In en, this message translates to:
  /// **'How do I stop someone contacting me?'**
  String get settingsFaqBlockQuestion;

  /// No description provided for @settingsFaqCapsuleAnswer.
  ///
  /// In en, this message translates to:
  /// **'A photo with a title and a note, pinned on the map where you made it. You can set a date: until then the capsule stays locked.'**
  String get settingsFaqCapsuleAnswer;

  /// No description provided for @settingsFaqCapsuleQuestion.
  ///
  /// In en, this message translates to:
  /// **'What is a capsule?'**
  String get settingsFaqCapsuleQuestion;

  /// No description provided for @settingsFaqDeleteAnswer.
  ///
  /// In en, this message translates to:
  /// **'Settings > Delete account. Everything you made is removed and cannot be brought back.'**
  String get settingsFaqDeleteAnswer;

  /// No description provided for @settingsFaqDeleteQuestion.
  ///
  /// In en, this message translates to:
  /// **'How do I delete my account?'**
  String get settingsFaqDeleteQuestion;

  /// No description provided for @settingsFaqFriendsAnswer.
  ///
  /// In en, this message translates to:
  /// **'Search by username in Friends, scan their QR code, or share your profile link from your profile.'**
  String get settingsFaqFriendsAnswer;

  /// No description provided for @settingsFaqFriendsQuestion.
  ///
  /// In en, this message translates to:
  /// **'How do I add friends?'**
  String get settingsFaqFriendsQuestion;

  /// No description provided for @settingsFaqNotificationsAnswer.
  ///
  /// In en, this message translates to:
  /// **'Check Settings > Notifications: the phone must allow Later to notify you, and push notifications must be on. Quiet hours and muted chats also keep pushes silent.'**
  String get settingsFaqNotificationsAnswer;

  /// No description provided for @settingsFaqNotificationsQuestion.
  ///
  /// In en, this message translates to:
  /// **'I do not get notifications'**
  String get settingsFaqNotificationsQuestion;

  /// The words in brackets are the visibility options of a capsule (see the glossary).
  ///
  /// In en, this message translates to:
  /// **'You choose when you create one: only you (Private), your friends (Friends) or everyone (Public).'**
  String get settingsFaqVisibilityAnswer;

  /// No description provided for @settingsFaqVisibilityQuestion.
  ///
  /// In en, this message translates to:
  /// **'Who can see my capsules?'**
  String get settingsFaqVisibilityQuestion;

  /// No description provided for @settingsGoogleConfirmsNote.
  ///
  /// In en, this message translates to:
  /// **'Google confirms it is you: pick your account when asked.'**
  String get settingsGoogleConfirmsNote;

  /// No description provided for @settingsHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get settingsHelp;

  /// No description provided for @settingsHelpContactFooter.
  ///
  /// In en, this message translates to:
  /// **'Emails from the app include your app version and phone. You can also write to {email}.'**
  String settingsHelpContactFooter(String email);

  /// No description provided for @settingsHelpContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get settingsHelpContactSupport;

  /// No description provided for @settingsHelpCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied. Paste it into your message to us.'**
  String get settingsHelpCopied;

  /// No description provided for @settingsHelpCopyInfo.
  ///
  /// In en, this message translates to:
  /// **'Copy app information'**
  String get settingsHelpCopyInfo;

  /// No description provided for @settingsHelpDescription.
  ///
  /// In en, this message translates to:
  /// **'Answers and ways to reach us'**
  String get settingsHelpDescription;

  /// No description provided for @settingsHelpNoEmailApp.
  ///
  /// In en, this message translates to:
  /// **'No email app found. Write to {email}'**
  String settingsHelpNoEmailApp(String email);

  /// No description provided for @settingsHelpReportProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get settingsHelpReportProblem;

  /// Subject of the problem report email that the app prepares. Keep "Later".
  ///
  /// In en, this message translates to:
  /// **'Later: problem report'**
  String get settingsHelpSubjectProblem;

  /// Subject of the email to support that the app prepares. Keep "Later".
  ///
  /// In en, this message translates to:
  /// **'Later: question'**
  String get settingsHelpSubjectQuestion;

  /// No description provided for @settingsLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get settingsLogOut;

  /// No description provided for @settingsLogOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get settingsLogOutConfirm;

  /// No description provided for @settingsMapAndCamera.
  ///
  /// In en, this message translates to:
  /// **'Map and camera'**
  String get settingsMapAndCamera;

  /// Map type: satellite imagery with street and place names.
  ///
  /// In en, this message translates to:
  /// **'Satellite with labels'**
  String get settingsMapLookHybrid;

  /// Map type: satellite imagery without labels.
  ///
  /// In en, this message translates to:
  /// **'Satellite'**
  String get settingsMapLookSatellite;

  /// Map type: the normal street map.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get settingsMapLookStandard;

  /// The display name: settings row, page title and input hint.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get settingsName;

  /// No description provided for @settingsNameDescription.
  ///
  /// In en, this message translates to:
  /// **'This is how you will be shown on Later, pick a name wisely, so your friends know you by'**
  String get settingsNameDescription;

  /// No description provided for @settingsNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter new name'**
  String get settingsNameHint;

  /// No description provided for @settingsNameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Name updated successfully!'**
  String get settingsNameUpdated;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get settingsNotificationsAllow;

  /// No description provided for @settingsNotificationsBlockedFooter.
  ///
  /// In en, this message translates to:
  /// **'Your phone does not let Later show notifications, so none arrive whatever you choose below.'**
  String get settingsNotificationsBlockedFooter;

  /// No description provided for @settingsNotificationsCapsules.
  ///
  /// In en, this message translates to:
  /// **'New capsules'**
  String get settingsNotificationsCapsules;

  /// No description provided for @settingsNotificationsCapsulesHint.
  ///
  /// In en, this message translates to:
  /// **'From people you follow with notifications on'**
  String get settingsNotificationsCapsulesHint;

  /// No description provided for @settingsNotificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose what Later tells you about'**
  String get settingsNotificationsDescription;

  /// No description provided for @settingsNotificationsFollowers.
  ///
  /// In en, this message translates to:
  /// **'New followers'**
  String get settingsNotificationsFollowers;

  /// No description provided for @settingsNotificationsMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get settingsNotificationsMessages;

  /// No description provided for @settingsNotificationsMuteHint.
  ///
  /// In en, this message translates to:
  /// **'Mute a single chat from its menu in Messages.'**
  String get settingsNotificationsMuteHint;

  /// Under the Notifications row: push notifications are off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsNotificationsOff;

  /// No description provided for @settingsNotificationsOffInPhone.
  ///
  /// In en, this message translates to:
  /// **'Off in your phone settings'**
  String get settingsNotificationsOffInPhone;

  /// Under the Notifications row: push notifications are on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get settingsNotificationsOn;

  /// No description provided for @settingsNotificationsPreview.
  ///
  /// In en, this message translates to:
  /// **'Show message text'**
  String get settingsNotificationsPreview;

  /// No description provided for @settingsNotificationsPreviewOff.
  ///
  /// In en, this message translates to:
  /// **'Pushes say \"New message\" only'**
  String get settingsNotificationsPreviewOff;

  /// No description provided for @settingsNotificationsPush.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get settingsNotificationsPush;

  /// No description provided for @settingsNotificationsPushOff.
  ///
  /// In en, this message translates to:
  /// **'You get no pushes from Later'**
  String get settingsNotificationsPushOff;

  /// No description provided for @settingsNotificationsSound.
  ///
  /// In en, this message translates to:
  /// **'Sound and vibration'**
  String get settingsNotificationsSound;

  /// No description provided for @settingsPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get settingsPassword;

  /// No description provided for @settingsPasswordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get settingsPasswordChanged;

  /// No description provided for @settingsPasswordConfirmsNote.
  ///
  /// In en, this message translates to:
  /// **'Your password confirms it is you.'**
  String get settingsPasswordConfirmsNote;

  /// No description provided for @settingsPasswordCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get settingsPasswordCurrent;

  /// No description provided for @settingsPasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose a password you do not use anywhere else'**
  String get settingsPasswordDescription;

  /// No description provided for @settingsPasswordForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get settingsPasswordForgot;

  /// No description provided for @settingsPasswordGoogleDescription.
  ///
  /// In en, this message translates to:
  /// **'You sign in with Google'**
  String get settingsPasswordGoogleDescription;

  /// No description provided for @settingsPasswordGoogleNote.
  ///
  /// In en, this message translates to:
  /// **'Your account has no Later password: Google confirms it is you. Change your password in your Google account.'**
  String get settingsPasswordGoogleNote;

  /// Hint of the new password field with the minimum length.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{New password ({count}+ character)} other{New password ({count}+ characters)}}'**
  String settingsPasswordNew(int count);

  /// No description provided for @settingsPasswordRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat new password'**
  String get settingsPasswordRepeat;

  /// No description provided for @settingsPasswordResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send the link. Please try again.'**
  String get settingsPasswordResetFailed;

  /// No description provided for @settingsPasswordResetSent.
  ///
  /// In en, this message translates to:
  /// **'We sent a reset link to {email}'**
  String settingsPasswordResetSent(String email);

  /// No description provided for @settingsPermissionCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get settingsPermissionCamera;

  /// No description provided for @settingsPermissionCameraDescription.
  ///
  /// In en, this message translates to:
  /// **'Access camera to create time capsules'**
  String get settingsPermissionCameraDescription;

  /// No description provided for @settingsPermissionContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get settingsPermissionContacts;

  /// No description provided for @settingsPermissionContactsDescription.
  ///
  /// In en, this message translates to:
  /// **'Invite friends and find people you know'**
  String get settingsPermissionContactsDescription;

  /// No description provided for @settingsPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get settingsPermissionDenied;

  /// Status of an app permission.
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get settingsPermissionGranted;

  /// No description provided for @settingsPermissionLimited.
  ///
  /// In en, this message translates to:
  /// **'Limited'**
  String get settingsPermissionLimited;

  /// No description provided for @settingsPermissionLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get settingsPermissionLocation;

  /// No description provided for @settingsPermissionLocationDescription.
  ///
  /// In en, this message translates to:
  /// **'Find capsules nearby and location-based features'**
  String get settingsPermissionLocationDescription;

  /// No description provided for @settingsPermissionMicrophone.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get settingsPermissionMicrophone;

  /// No description provided for @settingsPermissionMicrophoneDescription.
  ///
  /// In en, this message translates to:
  /// **'Record audio for time capsules'**
  String get settingsPermissionMicrophoneDescription;

  /// No description provided for @settingsPermissionNotificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Receive updates about followers and capsules'**
  String get settingsPermissionNotificationsDescription;

  /// No description provided for @settingsPermissionOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get settingsPermissionOpenSettings;

  /// No description provided for @settingsPermissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Permanently Denied'**
  String get settingsPermissionPermanentlyDenied;

  /// Status of an app permission: iOS allows quiet notifications for now.
  ///
  /// In en, this message translates to:
  /// **'Provisional'**
  String get settingsPermissionProvisional;

  /// No description provided for @settingsPermissionRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'This permission has been permanently denied. Please enable it in your device settings.'**
  String get settingsPermissionRequiredBody;

  /// No description provided for @settingsPermissionRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get settingsPermissionRequiredTitle;

  /// No description provided for @settingsPermissionRestricted.
  ///
  /// In en, this message translates to:
  /// **'Restricted'**
  String get settingsPermissionRestricted;

  /// No description provided for @settingsPermissionRevokeBody.
  ///
  /// In en, this message translates to:
  /// **'To revoke this permission, you need to go to your device settings. This will disable the related features in the app.'**
  String get settingsPermissionRevokeBody;

  /// No description provided for @settingsPermissionRevokeTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke Permission'**
  String get settingsPermissionRevokeTitle;

  /// No description provided for @settingsPermissionsDescription.
  ///
  /// In en, this message translates to:
  /// **'What Later may use on this phone'**
  String get settingsPermissionsDescription;

  /// Title of the time picker for the start of quiet hours.
  ///
  /// In en, this message translates to:
  /// **'Quiet from'**
  String get settingsQuietFrom;

  /// No description provided for @settingsQuietHours.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get settingsQuietHours;

  /// No description provided for @settingsQuietHoursFooter.
  ///
  /// In en, this message translates to:
  /// **'No pushes during these hours. Messages still arrive in the app.'**
  String get settingsQuietHoursFooter;

  /// Row with the start time of quiet hours.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get settingsQuietHoursFrom;

  /// Row with the end time of quiet hours.
  ///
  /// In en, this message translates to:
  /// **'Until'**
  String get settingsQuietHoursUntil;

  /// Title of the time picker for the end of quiet hours.
  ///
  /// In en, this message translates to:
  /// **'Quiet until'**
  String get settingsQuietUntil;

  /// Upper-case label above a card of rows on the Settings page.
  ///
  /// In en, this message translates to:
  /// **'MY ACCOUNT'**
  String get settingsSectionAccount;

  /// No description provided for @settingsSectionCamera.
  ///
  /// In en, this message translates to:
  /// **'CAMERA'**
  String get settingsSectionCamera;

  /// No description provided for @settingsSectionContact.
  ///
  /// In en, this message translates to:
  /// **'CONTACT'**
  String get settingsSectionContact;

  /// Label above the switches that shape how pushes look and sound.
  ///
  /// In en, this message translates to:
  /// **'HOW'**
  String get settingsSectionHow;

  /// No description provided for @settingsSectionMap.
  ///
  /// In en, this message translates to:
  /// **'MAP'**
  String get settingsSectionMap;

  /// No description provided for @settingsSectionNotificationsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS AND PRIVACY'**
  String get settingsSectionNotificationsPrivacy;

  /// Label above the switches Messages / New followers / New capsules.
  ///
  /// In en, this message translates to:
  /// **'NOTIFY ME ABOUT'**
  String get settingsSectionNotifyAbout;

  /// No description provided for @settingsSectionQuestions.
  ///
  /// In en, this message translates to:
  /// **'QUESTIONS'**
  String get settingsSectionQuestions;

  /// No description provided for @settingsSectionQuietHours.
  ///
  /// In en, this message translates to:
  /// **'QUIET HOURS'**
  String get settingsSectionQuietHours;

  /// No description provided for @settingsSectionSupport.
  ///
  /// In en, this message translates to:
  /// **'SUPPORT'**
  String get settingsSectionSupport;

  /// No description provided for @settingsSectionThisPhone.
  ///
  /// In en, this message translates to:
  /// **'THIS PHONE'**
  String get settingsSectionThisPhone;

  /// Under the Password row for accounts that sign in with Google only.
  ///
  /// In en, this message translates to:
  /// **'Signed in with Google'**
  String get settingsSignedInWithGoogle;

  /// No description provided for @settingsStorageCache.
  ///
  /// In en, this message translates to:
  /// **'Cache'**
  String get settingsStorageCache;

  /// No description provided for @settingsStorageClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get settingsStorageClear;

  /// No description provided for @settingsStorageClearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get settingsStorageClearCache;

  /// No description provided for @settingsStorageClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear the cache? Pictures load again when you need them.'**
  String get settingsStorageClearConfirm;

  /// No description provided for @settingsStorageCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get settingsStorageCleared;

  /// No description provided for @settingsStorageClearing.
  ///
  /// In en, this message translates to:
  /// **'Clearing...'**
  String get settingsStorageClearing;

  /// No description provided for @settingsStorageDescription.
  ///
  /// In en, this message translates to:
  /// **'Space Later uses on this phone'**
  String get settingsStorageDescription;

  /// No description provided for @settingsStorageFooter.
  ///
  /// In en, this message translates to:
  /// **'Photos taken or picked for capsules and pictures loaded from the internet. Your capsules, chats and account stay.'**
  String get settingsStorageFooter;

  /// Line of the app information for support (copied or added to support emails).
  ///
  /// In en, this message translates to:
  /// **'App: Later {version}'**
  String settingsSupportInfoApp(String version);

  /// Line of the app information for support: the phone's operating system and its version.
  ///
  /// In en, this message translates to:
  /// **'Phone: {system}'**
  String settingsSupportInfoPhone(String system);

  /// Line of the app information for support: the account's technical id.
  ///
  /// In en, this message translates to:
  /// **'User id: {uid}'**
  String settingsSupportInfoUserId(String uid);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get settingsUnblock;

  /// No description provided for @settingsUnblocking.
  ///
  /// In en, this message translates to:
  /// **'Unblocking...'**
  String get settingsUnblocking;

  /// No description provided for @settingsUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get settingsUsername;

  /// No description provided for @settingsUsernameDescription.
  ///
  /// In en, this message translates to:
  /// **'This is how your friends find and add you on Later'**
  String get settingsUsernameDescription;

  /// No description provided for @settingsUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter new username'**
  String get settingsUsernameHint;

  /// No description provided for @settingsUsernameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Username updated successfully!'**
  String get settingsUsernameUpdated;

  /// Hint of the password field that confirms an account change.
  ///
  /// In en, this message translates to:
  /// **'Your password'**
  String get settingsYourPassword;
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
