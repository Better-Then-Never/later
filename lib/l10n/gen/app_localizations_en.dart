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
  String get placeNoLocation => 'No location';

  @override
  String get placeUnknown => 'Unknown location';

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
  String get settingsNotificationsDescription =>
      'Choose what Later tells you about';

  @override
  String get settingsNotificationsFollowers => 'New followers';

  @override
  String get settingsNotificationsMessages => 'Messages';

  @override
  String get settingsNotificationsMuteHint =>
      'Mute a single chat from its menu in Messages.';

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
  String get settingsNotificationsSound => 'Sound and vibration';

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
  String get settingsPermissionContacts => 'Contacts';

  @override
  String get settingsPermissionContactsDescription =>
      'Invite friends and find people you know';

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
  String get settingsPermissionMicrophone => 'Microphone';

  @override
  String get settingsPermissionMicrophoneDescription =>
      'Record audio for time capsules';

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
  String get settingsSectionNotificationsPrivacy => 'NOTIFICATIONS AND PRIVACY';

  @override
  String get settingsSectionNotifyAbout => 'NOTIFY ME ABOUT';

  @override
  String get settingsSectionQuestions => 'QUESTIONS';

  @override
  String get settingsSectionQuietHours => 'QUIET HOURS';

  @override
  String get settingsSectionSupport => 'SUPPORT';

  @override
  String get settingsSectionThisPhone => 'THIS PHONE';

  @override
  String get settingsSignedInWithGoogle => 'Signed in with Google';

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
  String get settingsYourPassword => 'Your password';
}
