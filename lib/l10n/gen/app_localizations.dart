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

  /// No description provided for @achievementAnimator.
  ///
  /// In en, this message translates to:
  /// **'Animator'**
  String get achievementAnimator;

  /// No description provided for @achievementAnimatorGoal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Make 1 loop capsule} other{Make {count} loop capsules}}'**
  String achievementAnimatorGoal(int count);

  /// No description provided for @achievementChatterbox.
  ///
  /// In en, this message translates to:
  /// **'Chatterbox'**
  String get achievementChatterbox;

  /// No description provided for @achievementChatterboxGoal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Write 1 comment} other{Write {count} comments}}'**
  String achievementChatterboxGoal(int count);

  /// No description provided for @achievementCollector.
  ///
  /// In en, this message translates to:
  /// **'Collector'**
  String get achievementCollector;

  /// No description provided for @achievementCollectorGoal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Create 1 capsule} other{Create {count} capsules}}'**
  String achievementCollectorGoal(int count);

  /// No description provided for @achievementCrowdPleaser.
  ///
  /// In en, this message translates to:
  /// **'Crowd pleaser'**
  String get achievementCrowdPleaser;

  /// No description provided for @achievementCrowdPleaserGoal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Receive 1 reaction} other{Receive {count} reactions}}'**
  String achievementCrowdPleaserGoal(int count);

  /// No description provided for @achievementEarlyBird.
  ///
  /// In en, this message translates to:
  /// **'Early bird'**
  String get achievementEarlyBird;

  /// No description provided for @achievementEarlyBirdGoal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Create a capsule between 5 and 8 am} other{Create {count} capsules between 5 and 8 am}}'**
  String achievementEarlyBirdGoal(int count);

  /// No description provided for @achievementExplorer.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get achievementExplorer;

  /// No description provided for @achievementExplorerGoal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Leave a capsule in 1 place} other{Leave capsules in {count} different places}}'**
  String achievementExplorerGoal(int count);

  /// No description provided for @achievementFirstCapsule.
  ///
  /// In en, this message translates to:
  /// **'First capsule'**
  String get achievementFirstCapsule;

  /// No description provided for @achievementFirstCapsuleGoal.
  ///
  /// In en, this message translates to:
  /// **'Create your first capsule'**
  String get achievementFirstCapsuleGoal;

  /// No description provided for @achievementFriendly.
  ///
  /// In en, this message translates to:
  /// **'Friendly'**
  String get achievementFriendly;

  /// No description provided for @achievementFriendlyGoal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Make 1 friend} other{Make {count} friends}}'**
  String achievementFriendlyGoal(int count);

  /// No description provided for @achievementNightOwl.
  ///
  /// In en, this message translates to:
  /// **'Night owl'**
  String get achievementNightOwl;

  /// No description provided for @achievementNightOwlGoal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Create a capsule between midnight and 5 am} other{Create {count} capsules between midnight and 5 am}}'**
  String achievementNightOwlGoal(int count);

  /// No description provided for @achievementOpenBook.
  ///
  /// In en, this message translates to:
  /// **'Open book'**
  String get achievementOpenBook;

  /// No description provided for @achievementOpenBookGoal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Share 1 public capsule} other{Share {count} public capsules}}'**
  String achievementOpenBookGoal(int count);

  /// No description provided for @achievementStreak.
  ///
  /// In en, this message translates to:
  /// **'On fire'**
  String get achievementStreak;

  /// No description provided for @achievementStreakGoal.
  ///
  /// In en, this message translates to:
  /// **'Keep a {count}-day streak'**
  String achievementStreakGoal(int count);

  /// No description provided for @achievementTraveler.
  ///
  /// In en, this message translates to:
  /// **'Traveler'**
  String get achievementTraveler;

  /// No description provided for @achievementTravelerGoal.
  ///
  /// In en, this message translates to:
  /// **'Travel {km} km between your capsules'**
  String achievementTravelerGoal(String km);

  /// No description provided for @achievementsDescription.
  ///
  /// In en, this message translates to:
  /// **'Unlocked by using Later, never by paying'**
  String get achievementsDescription;

  /// No description provided for @achievementsLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get achievementsLocked;

  /// No description provided for @achievementsNoneYet.
  ///
  /// In en, this message translates to:
  /// **'Your first one is a capsule away.'**
  String get achievementsNoneYet;

  /// No description provided for @achievementsSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get achievementsSeeAll;

  /// No description provided for @achievementsStreakDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1-day streak} other{{count}-day streak}}'**
  String achievementsStreakDays(int count);

  /// No description provided for @achievementsStreakKeep.
  ///
  /// In en, this message translates to:
  /// **'Make a capsule today to keep it'**
  String get achievementsStreakKeep;

  /// No description provided for @achievementsStreakTodayDone.
  ///
  /// In en, this message translates to:
  /// **'Today counts already'**
  String get achievementsStreakTodayDone;

  /// No description provided for @achievementsTier.
  ///
  /// In en, this message translates to:
  /// **'Level {tier} of {tiers}'**
  String achievementsTier(int tier, int tiers);

  /// No description provided for @achievementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievementsTitle;

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

  /// Button on a permission page that asks for the permission.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get authPermissionEnable;

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

  /// No description provided for @authPermissionNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get authPermissionNotNow;

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

  /// Camera screen when camera permission was denied. 'Settings' are the phone's settings.
  ///
  /// In en, this message translates to:
  /// **'Allow camera access in Settings to take a photo'**
  String get capsulesCameraAccessDenied;

  /// Camera flash button, screen reader: the flash fires when it is dark
  ///
  /// In en, this message translates to:
  /// **'Flash auto'**
  String get capsulesCameraFlashAuto;

  /// One letter on the flash icon for 'automatic'
  ///
  /// In en, this message translates to:
  /// **'A'**
  String get capsulesCameraFlashAutoBadge;

  /// Accessibility label of the flash button while the flash is off.
  ///
  /// In en, this message translates to:
  /// **'Flash off'**
  String get capsulesCameraFlashOff;

  /// Accessibility label of the flash button while the flash is on.
  ///
  /// In en, this message translates to:
  /// **'Flash on'**
  String get capsulesCameraFlashOn;

  /// Under the shutter: hold it to record several frames played as a loop
  ///
  /// In en, this message translates to:
  /// **'Hold for a loop'**
  String get capsulesCameraHoldForLoop;

  /// No description provided for @capsulesCameraStartFailed.
  ///
  /// In en, this message translates to:
  /// **'The camera could not be started'**
  String get capsulesCameraStartFailed;

  /// Accessibility label of the button that switches between the front and back camera.
  ///
  /// In en, this message translates to:
  /// **'Switch camera'**
  String get capsulesCameraSwitch;

  /// Accessibility label of the shutter button.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get capsulesCameraTakePhoto;

  /// Screen reader label of the shutter when loops are on
  ///
  /// In en, this message translates to:
  /// **'Take photo. Hold to record a loop'**
  String get capsulesCameraTakePhotoOrLoop;

  /// Shown on the camera screen when the phone has no camera.
  ///
  /// In en, this message translates to:
  /// **'No camera available'**
  String get capsulesCameraUnavailable;

  /// No description provided for @capsulesColorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get capsulesColorBlue;

  /// No description provided for @capsulesColorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get capsulesColorGreen;

  /// No description provided for @capsulesColorOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get capsulesColorOrange;

  /// No description provided for @capsulesColorPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get capsulesColorPurple;

  /// Colour of the capsule's map pin. Agrees with the word 'colour'.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get capsulesColorRed;

  /// No description provided for @capsulesColorYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get capsulesColorYellow;

  /// No description provided for @capsulesCommentDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete comment'**
  String get capsulesCommentDelete;

  /// No description provided for @capsulesCommentDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this comment?'**
  String get capsulesCommentDeleteConfirm;

  /// No description provided for @capsulesCommentDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the comment'**
  String get capsulesCommentDeleteFailed;

  /// No description provided for @capsulesCommentFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not post your comment'**
  String get capsulesCommentFailed;

  /// No description provided for @capsulesCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get capsulesCommentHint;

  /// No description provided for @capsulesCommentTooLong.
  ///
  /// In en, this message translates to:
  /// **'Comments can be up to 500 characters'**
  String get capsulesCommentTooLong;

  /// No description provided for @capsulesComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get capsulesComments;

  /// Button under a capsule that opens its comments.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Comment} =1{1 comment} other{{count} comments}}'**
  String capsulesCommentsCount(int count);

  /// No description provided for @capsulesCommentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get capsulesCommentsEmpty;

  /// No description provided for @capsulesCommentsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Be the first to say something.'**
  String get capsulesCommentsEmptyHint;

  /// No description provided for @capsulesCreationAllowComments.
  ///
  /// In en, this message translates to:
  /// **'Allow comments'**
  String get capsulesCreationAllowComments;

  /// No description provided for @capsulesCreationAllowReactions.
  ///
  /// In en, this message translates to:
  /// **'Allow reactions'**
  String get capsulesCreationAllowReactions;

  /// No description provided for @capsulesCreationApproximate.
  ///
  /// In en, this message translates to:
  /// **'Approximate location'**
  String get capsulesCreationApproximate;

  /// No description provided for @capsulesCreationApproximateHint.
  ///
  /// In en, this message translates to:
  /// **'About a kilometre off, not the exact spot'**
  String get capsulesCreationApproximateHint;

  /// Row title: the colour of the capsule's map pin (tapping cycles the colours).
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get capsulesCreationColor;

  /// Hint in the capsule description field.
  ///
  /// In en, this message translates to:
  /// **'Add description...'**
  String get capsulesCreationDescriptionHint;

  /// Row title: the day the capsule opens. The chosen date is shown next to it.
  ///
  /// In en, this message translates to:
  /// **'Open At'**
  String get capsulesCreationOpenAt;

  /// Section title above the card that shows how the capsule will look.
  ///
  /// In en, this message translates to:
  /// **'Capsule Preview'**
  String get capsulesCreationPreview;

  /// Row title: who can see the capsule (tapping cycles Public / Friends / Private).
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get capsulesCreationPrivacy;

  /// Shown in the open date row until a date is picked. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get capsulesCreationSelectDate;

  /// Section title above the privacy, open date and colour rows.
  ///
  /// In en, this message translates to:
  /// **'Capsule Settings'**
  String get capsulesCreationSettings;

  /// Button at the bottom of the creation screen that saves the new capsule. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Create Capsule'**
  String get capsulesCreationSubmit;

  /// Header title of the screen where a new capsule is set up after taking the photo.
  ///
  /// In en, this message translates to:
  /// **'Create Capsule'**
  String get capsulesCreationTitle;

  /// Hint in the capsule title field (one line, large bold font, narrow: keep it very short).
  ///
  /// In en, this message translates to:
  /// **'Add Title...'**
  String get capsulesCreationTitleHint;

  /// Title given to a capsule saved without one. It is stored with the capsule.
  ///
  /// In en, this message translates to:
  /// **'Capsule'**
  String get capsulesDefaultTitle;

  /// No description provided for @capsulesErrorNoLocation.
  ///
  /// In en, this message translates to:
  /// **'We could not detect your location'**
  String get capsulesErrorNoLocation;

  /// No description provided for @capsulesErrorSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save capsule'**
  String get capsulesErrorSaveFailed;

  /// The capsule for a friend was created but posting it to the chat failed; tapping the create button again retries.
  ///
  /// In en, this message translates to:
  /// **'The capsule was saved but not sent. Tap save to try again.'**
  String get capsulesErrorSavedNotSent;

  /// No description provided for @capsulesOpenInMonth.
  ///
  /// In en, this message translates to:
  /// **'In a month'**
  String get capsulesOpenInMonth;

  /// No description provided for @capsulesOpenInWeek.
  ///
  /// In en, this message translates to:
  /// **'In a week'**
  String get capsulesOpenInWeek;

  /// No description provided for @capsulesOpenInYear.
  ///
  /// In en, this message translates to:
  /// **'In a year'**
  String get capsulesOpenInYear;

  /// Open date menu: remove the date, the capsule is open at once
  ///
  /// In en, this message translates to:
  /// **'Open right away'**
  String get capsulesOpenNow;

  /// No description provided for @capsulesOpenPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date…'**
  String get capsulesOpenPickDate;

  /// Open date preset
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get capsulesOpenTomorrow;

  /// Capsule visibility: only the owner's friends can see it.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get capsulesPrivacyFriends;

  /// Capsule visibility: only the owner (and the friend it was sent to). Agrees with 'capsule'.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get capsulesPrivacyPrivate;

  /// Capsule visibility: everyone can see it. Agrees with 'capsule'.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get capsulesPrivacyPublic;

  /// No description provided for @capsulesQueued.
  ///
  /// In en, this message translates to:
  /// **'Saved on your phone. It will be uploaded when you are online again.'**
  String get capsulesQueued;

  /// Accessibility label of a reaction button.
  ///
  /// In en, this message translates to:
  /// **'React with {emoji}'**
  String capsulesReactWith(String emoji);

  /// No description provided for @capsulesReactionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your reaction'**
  String get capsulesReactionFailed;

  /// No description provided for @capsulesReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get capsulesReply;

  /// No description provided for @capsulesReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Reply to {name}...'**
  String capsulesReplyHint(String name);

  /// No description provided for @capsulesReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get capsulesReport;

  /// No description provided for @capsulesReportAbuse.
  ///
  /// In en, this message translates to:
  /// **'Harassment or hate'**
  String get capsulesReportAbuse;

  /// No description provided for @capsulesReportCapsule.
  ///
  /// In en, this message translates to:
  /// **'Report capsule'**
  String get capsulesReportCapsule;

  /// No description provided for @capsulesReportNudity.
  ///
  /// In en, this message translates to:
  /// **'Nudity'**
  String get capsulesReportNudity;

  /// No description provided for @capsulesReportOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get capsulesReportOther;

  /// No description provided for @capsulesReportPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Private information'**
  String get capsulesReportPrivacy;

  /// No description provided for @capsulesReportSent.
  ///
  /// In en, this message translates to:
  /// **'Thanks for telling us. The Later team will look at it.'**
  String get capsulesReportSent;

  /// No description provided for @capsulesReportSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get capsulesReportSpam;

  /// No description provided for @capsulesReportTitle.
  ///
  /// In en, this message translates to:
  /// **'What is wrong with it?'**
  String get capsulesReportTitle;

  /// No description provided for @capsulesReportViolence.
  ///
  /// In en, this message translates to:
  /// **'Violence'**
  String get capsulesReportViolence;

  /// No description provided for @capsulesYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get capsulesYou;

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

  /// Accessibility label of a red count badge (new messages, requests).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} new} other{{count} new}}'**
  String commonNewCount(int count);

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

  /// File size in bytes.
  ///
  /// In en, this message translates to:
  /// **'{size} B'**
  String commonSizeBytes(String size);

  /// No description provided for @commonSizeGigabytes.
  ///
  /// In en, this message translates to:
  /// **'{size} GB'**
  String commonSizeGigabytes(String size);

  /// No description provided for @commonSizeKilobytes.
  ///
  /// In en, this message translates to:
  /// **'{size} KB'**
  String commonSizeKilobytes(String size);

  /// No description provided for @commonSizeMegabytes.
  ///
  /// In en, this message translates to:
  /// **'{size} MB'**
  String commonSizeMegabytes(String size);

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

  /// Title of a capsule that has none.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get commonUntitled;

  /// No description provided for @commonUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a username'**
  String get commonUsernameRequired;

  /// Letters are a-z only (Latin, lower case).
  ///
  /// In en, this message translates to:
  /// **'Use 3-30 letters, numbers, dots, dashes or underscores'**
  String get commonUsernameRules;

  /// No description provided for @commonUsernameTaken.
  ///
  /// In en, this message translates to:
  /// **'Username already taken'**
  String get commonUsernameTaken;

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

  /// No description provided for @friendsFindByUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'Search by @username or scan a friend\'s QR code. People your friends know show up here.'**
  String get friendsFindByUsernameHint;

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

  /// After the @username of a suggested person.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 mutual friend} other{{count} mutual friends}}'**
  String friendsMutualCount(int count);

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

  /// Accessibility label of the heart on a capsule that is not a favourite.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get historyAddToFavorites;

  /// Countdown row of a capsule whose opening time has passed.
  ///
  /// In en, this message translates to:
  /// **'Capsule is opened!'**
  String get historyCapsuleOpened;

  /// No description provided for @historyColorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get historyColorBlue;

  /// No description provided for @historyColorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get historyColorGreen;

  /// No description provided for @historyColorOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get historyColorOrange;

  /// No description provided for @historyColorPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get historyColorPurple;

  /// Capsule pin colour in the filter menu and on the filter button.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get historyColorRed;

  /// No description provided for @historyColorYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get historyColorYellow;

  /// Time left until a capsule opens, ticking every second. One short line: use compact unit abbreviations.
  ///
  /// In en, this message translates to:
  /// **'{days}d {hours}h {minutes}m {seconds}s'**
  String historyCountdown(int days, int hours, int minutes, int seconds);

  /// Time left until a capsule opens when it is a year or more away. One short line: compact unit abbreviations.
  ///
  /// In en, this message translates to:
  /// **'{years}y {days}d {hours}h {minutes}m'**
  String historyCountdownYears(int years, int days, int hours, int minutes);

  /// No description provided for @historyCreateFirst.
  ///
  /// In en, this message translates to:
  /// **'Create a capsule'**
  String get historyCreateFirst;

  /// Title of the dialog that confirms deleting the selected capsules.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Delete {count} capsule?} other{Delete {count} capsules?}}'**
  String historyDeleteConfirm(int count);

  /// Selection bar button that deletes the selected capsules.
  ///
  /// In en, this message translates to:
  /// **'Delete ({count})'**
  String historyDeleteSelected(int count);

  /// Toast after the selected capsules were deleted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} capsule deleted} other{{count} capsules deleted}}'**
  String historyDeleted(int count);

  /// Distance between the user and the capsule. One short line.
  ///
  /// In en, this message translates to:
  /// **'{distance} km from you'**
  String historyDistanceFromYou(String distance);

  /// Distance row when the capsule or the user has no location.
  ///
  /// In en, this message translates to:
  /// **'Distance unknown'**
  String get historyDistanceUnknown;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No capsules yet'**
  String get historyEmpty;

  /// No description provided for @historyEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Take a photo, leave it at a place and choose when it opens.'**
  String get historyEmptySubtitle;

  /// No description provided for @historyErrorDelete.
  ///
  /// In en, this message translates to:
  /// **'Could not delete capsules'**
  String get historyErrorDelete;

  /// No description provided for @historyErrorFavorites.
  ///
  /// In en, this message translates to:
  /// **'Could not update favorites'**
  String get historyErrorFavorites;

  /// Toast after the heart is tapped.
  ///
  /// In en, this message translates to:
  /// **'{title} added to favorites'**
  String historyFavoriteAdded(String title);

  /// Toast after the heart is tapped again.
  ///
  /// In en, this message translates to:
  /// **'{title} removed from favorites'**
  String historyFavoriteRemoved(String title);

  /// Filter option: every capsule, favourite or not.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get historyFilterAny;

  /// Filter button (when no filter is chosen) and title of the filter menu. Short.
  ///
  /// In en, this message translates to:
  /// **'Filter By'**
  String get historyFilterBy;

  /// Filter menu group with 'Favorite' and 'Any'.
  ///
  /// In en, this message translates to:
  /// **'Capsule'**
  String get historyFilterCapsule;

  /// Filter menu group: the colour of the capsule pin.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get historyFilterColor;

  /// Filter option (also on the filter button): only capsules marked as favourite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get historyFilterFavorite;

  /// Filter menu group: who can see the capsule (public, private, friends).
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get historyFilterVisibility;

  /// No description provided for @historyLoadError.
  ///
  /// In en, this message translates to:
  /// **'Your capsules could not be loaded'**
  String get historyLoadError;

  /// No description provided for @historyNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No capsules match your search'**
  String get historyNoMatches;

  /// No description provided for @historyNoMatchesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try another word, or reset the filters.'**
  String get historyNoMatchesSubtitle;

  /// Title above the user's capsules made on today's date in earlier years
  ///
  /// In en, this message translates to:
  /// **'On this day'**
  String get historyOnThisDay;

  /// Capsule visibility: only friends can see it.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get historyPrivacyFriends;

  /// No description provided for @historyPrivacyPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get historyPrivacyPrivate;

  /// Capsule visibility in the filter menu and on the filter button.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get historyPrivacyPublic;

  /// Accessibility label of the heart on a favourite capsule.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get historyRemoveFromFavorites;

  /// Button and menu item that clear the sort and/or the filters. Short.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get historyReset;

  /// No description provided for @historySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Find Capsules...'**
  String get historySearchHint;

  /// Selection bar: how many capsules are selected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} selected} other{{count} selected}}'**
  String historySelectedCount(int count);

  /// Sort button (when no sort is chosen) and title of the sort menu. Short: the button is a third of the screen.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get historySortBy;

  /// Sort option: capsules closest to the user first.
  ///
  /// In en, this message translates to:
  /// **'From Closest'**
  String get historySortClosest;

  /// Sort menu group that holds 'From Closest' and 'From Farthest'.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get historySortDistance;

  /// No description provided for @historySortFarthest.
  ///
  /// In en, this message translates to:
  /// **'From Farthest'**
  String get historySortFarthest;

  /// No description provided for @historySortNewest.
  ///
  /// In en, this message translates to:
  /// **'From Newest'**
  String get historySortNewest;

  /// Sort option (also shown on the sort button): oldest capsules first.
  ///
  /// In en, this message translates to:
  /// **'From Oldest'**
  String get historySortOldest;

  /// Sort menu group that holds 'From Oldest' and 'From Newest'.
  ///
  /// In en, this message translates to:
  /// **'Relevance'**
  String get historySortRelevance;

  /// Title of the History tab: the user's own capsules.
  ///
  /// In en, this message translates to:
  /// **'My Capsules'**
  String get historyTitle;

  /// No description provided for @historyVisibilityFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends visibility'**
  String get historyVisibilityFriends;

  /// No description provided for @historyVisibilityPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private visibility'**
  String get historyVisibilityPrivate;

  /// Info row of a capsule in the list, next to a privacy icon. One short line.
  ///
  /// In en, this message translates to:
  /// **'Public visibility'**
  String get historyVisibilityPublic;

  /// No description provided for @historyWaitingUpload.
  ///
  /// In en, this message translates to:
  /// **'Waiting for connection'**
  String get historyWaitingUpload;

  /// Under an 'On this day' capsule.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 year ago} other{{count} years ago}}'**
  String historyYearsAgo(int count);

  /// Disabled button in the window above a capsule that has not opened yet. Agrees with 'capsule'.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get mapCapsuleLocked;

  /// Shown in the capsule card opened from the map when the capsule has no description.
  ///
  /// In en, this message translates to:
  /// **'This capsule has no description.'**
  String get mapCapsuleNoDescription;

  /// Button in the window above an open capsule's pin: shows the capsule. A verb.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get mapCapsuleOpen;

  /// Countdown in the small window above a locked capsule's pin. {time} is a compact duration made of the mapDuration* parts, e.g. '2d 5h 30m 15s'.
  ///
  /// In en, this message translates to:
  /// **'Opens in {time}'**
  String mapCapsuleOpensIn(String time);

  /// Line in the small window above a capsule pin when the capsule is already open.
  ///
  /// In en, this message translates to:
  /// **'Check out what\'s inside!'**
  String get mapCapsuleReady;

  /// Days part of the compact countdown. Keep it as short as possible.
  ///
  /// In en, this message translates to:
  /// **'{count}d'**
  String mapDurationDays(int count);

  /// Hours part of the compact countdown. Keep it as short as possible.
  ///
  /// In en, this message translates to:
  /// **'{count}h'**
  String mapDurationHours(int count);

  /// Minutes part of the compact countdown. Keep it as short as possible.
  ///
  /// In en, this message translates to:
  /// **'{count}m'**
  String mapDurationMinutes(int count);

  /// Seconds part of the compact countdown. Keep it as short as possible.
  ///
  /// In en, this message translates to:
  /// **'{count}s'**
  String mapDurationSeconds(int count);

  /// No description provided for @mapFirstCapsuleBody.
  ///
  /// In en, this message translates to:
  /// **'Take a photo here and choose when it opens.'**
  String get mapFirstCapsuleBody;

  /// No description provided for @mapFirstCapsuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave your first capsule'**
  String get mapFirstCapsuleTitle;

  /// Toast on the map when location permission was denied.
  ///
  /// In en, this message translates to:
  /// **'Allow location access to see capsules near you'**
  String get mapLocationDenied;

  /// Toast on the map when the phone's location service is switched off.
  ///
  /// In en, this message translates to:
  /// **'Turn on location to see capsules near you'**
  String get mapLocationServiceOff;

  /// Toast on the map when no position could be found although location is allowed.
  ///
  /// In en, this message translates to:
  /// **'We could not detect your location'**
  String get mapLocationUnknown;

  /// No description provided for @mapMyLocation.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get mapMyLocation;

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

  /// Toast after copying a message
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get messagesCopied;

  /// Message menu: copy the text
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get messagesCopy;

  /// No description provided for @messagesDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this message for both of you?'**
  String get messagesDeleteConfirmTitle;

  /// No description provided for @messagesDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the message'**
  String get messagesDeleteFailed;

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

  /// No description provided for @messagesReactFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your reaction'**
  String get messagesReactFailed;

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

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// No description provided for @navMyCapsules.
  ///
  /// In en, this message translates to:
  /// **'My capsules'**
  String get navMyCapsules;

  /// No description provided for @navNewCapsule.
  ///
  /// In en, this message translates to:
  /// **'New capsule'**
  String get navNewCapsule;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// {name} is the app's name (Later), shown in bold.
  ///
  /// In en, this message translates to:
  /// **'{name}: you unlocked a new achievement'**
  String notificationsAchievementBody(String name);

  /// Notification text: a friend created a capsule. The name is bold and cannot be inflected.
  ///
  /// In en, this message translates to:
  /// **'{name} created a new capsule'**
  String notificationsCapsuleBody(String name);

  /// No description provided for @notificationsChannelActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get notificationsChannelActivity;

  /// No description provided for @notificationsChannelActivityDescription.
  ///
  /// In en, this message translates to:
  /// **'Followers, friend requests, reactions, comments and new capsules'**
  String get notificationsChannelActivityDescription;

  /// No description provided for @notificationsChannelActivitySilent.
  ///
  /// In en, this message translates to:
  /// **'Activity (silent)'**
  String get notificationsChannelActivitySilent;

  /// No description provided for @notificationsChannelActivitySilentDescription.
  ///
  /// In en, this message translates to:
  /// **'Activity, without sound or vibration'**
  String get notificationsChannelActivitySilentDescription;

  /// Android notification channel name (phone settings).
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get notificationsChannelMessages;

  /// No description provided for @notificationsChannelMessagesDescription.
  ///
  /// In en, this message translates to:
  /// **'New messages from your friends'**
  String get notificationsChannelMessagesDescription;

  /// No description provided for @notificationsChannelMessagesSilent.
  ///
  /// In en, this message translates to:
  /// **'Messages (silent)'**
  String get notificationsChannelMessagesSilent;

  /// No description provided for @notificationsChannelMessagesSilentDescription.
  ///
  /// In en, this message translates to:
  /// **'New messages, without sound or vibration'**
  String get notificationsChannelMessagesSilentDescription;

  /// No description provided for @notificationsChannelOther.
  ///
  /// In en, this message translates to:
  /// **'Other notifications'**
  String get notificationsChannelOther;

  /// No description provided for @notificationsChannelOtherDescription.
  ///
  /// In en, this message translates to:
  /// **'Other notifications from Later'**
  String get notificationsChannelOtherDescription;

  /// Notification text: a comment on the user's capsule (no comment text stored). The name is bold and cannot be inflected.
  ///
  /// In en, this message translates to:
  /// **'{name} commented on your capsule'**
  String notificationsCommentBody(String name);

  /// Notification text: a comment on the user's capsule, followed by the comment itself. The name is bold and cannot be inflected.
  ///
  /// In en, this message translates to:
  /// **'{name} commented: {text}'**
  String notificationsCommentBodyWithText(String name, String text);

  /// Time of a notification less than a week old; older ones show the date.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count}d ago} other{{count}d ago}}'**
  String notificationsDaysAgo(int count);

  /// Title of the dialog that confirms deleting the selected notifications.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Delete {count} notification?} other{Delete {count} notifications?}}'**
  String notificationsDeleteConfirm(int count);

  /// Toast after the selected notifications were deleted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} notification deleted} other{{count} notifications deleted}}'**
  String notificationsDeleted(int count);

  /// No description provided for @notificationsEmptyAll.
  ///
  /// In en, this message translates to:
  /// **'Your notifications and activity will appear here'**
  String get notificationsEmptyAll;

  /// No description provided for @notificationsEmptyComments.
  ///
  /// In en, this message translates to:
  /// **'Comments on your Capsules will appear here'**
  String get notificationsEmptyComments;

  /// No description provided for @notificationsEmptyReplies.
  ///
  /// In en, this message translates to:
  /// **'Replies to your messages will appear here'**
  String get notificationsEmptyReplies;

  /// Notification text; the name is shown in bold. The name cannot be inflected: phrase it so the name stays in its base form.
  ///
  /// In en, this message translates to:
  /// **'{name} started following you'**
  String notificationsFollowBody(String name);

  /// No description provided for @notificationsFriendAcceptedBody.
  ///
  /// In en, this message translates to:
  /// **'{name} accepted your friend request'**
  String notificationsFriendAcceptedBody(String name);

  /// No description provided for @notificationsFriendRequestBody.
  ///
  /// In en, this message translates to:
  /// **'{name} wants to be your friend'**
  String notificationsFriendRequestBody(String name);

  /// Time of a notification less than a day old.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count}h ago} other{{count}h ago}}'**
  String notificationsHoursAgo(int count);

  /// Time of a notification less than a minute old.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get notificationsJustNow;

  /// Accessibility label of the selection bar button that marks the selected notifications as read.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get notificationsMarkAsRead;

  /// Toast after marking the selected notifications as read.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} notification marked as read} other{{count} notifications marked as read}}'**
  String notificationsMarkedRead(int count);

  /// Notification text: a chat message. The name is bold and cannot be inflected.
  ///
  /// In en, this message translates to:
  /// **'{name} sent you a message'**
  String notificationsMessageBody(String name);

  /// Time of a notification less than an hour old (English abbreviates; write it the way your language shows recent times).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count}m ago} other{{count}m ago}}'**
  String notificationsMinutesAgo(int count);

  /// No description provided for @notificationsReactionBody.
  ///
  /// In en, this message translates to:
  /// **'{name} reacted {emoji} to your capsule'**
  String notificationsReactionBody(String name, String emoji);

  /// Notification text: a reply to the user (no reply text stored). The name is bold and cannot be inflected.
  ///
  /// In en, this message translates to:
  /// **'{name} replied to you'**
  String notificationsReplyBody(String name);

  /// Notification text: a reply to the user, followed by the reply itself. The name is bold and cannot be inflected.
  ///
  /// In en, this message translates to:
  /// **'{name} replied: {text}'**
  String notificationsReplyBodyWithText(String name, String text);

  /// Selection bar: how many notifications are selected. Starts with the number, which is shown large and bold.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} selected} other{{count} selected}}'**
  String notificationsSelectedCount(int count);

  /// Filter tab: every notification. Tabs sit side by side: keep them short.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notificationsTabAll;

  /// Filter tab (and title of its empty state): comments on the user's capsules. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get notificationsTabComments;

  /// Filter tab (and title of its empty state): replies. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Replies'**
  String get notificationsTabReplies;

  /// Title of the notifications page and of its empty state.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsTypeAchievement.
  ///
  /// In en, this message translates to:
  /// **'Achievement'**
  String get notificationsTypeAchievement;

  /// No description provided for @notificationsTypeCapsule.
  ///
  /// In en, this message translates to:
  /// **'New Capsule'**
  String get notificationsTypeCapsule;

  /// No description provided for @notificationsTypeComment.
  ///
  /// In en, this message translates to:
  /// **'New Comment'**
  String get notificationsTypeComment;

  /// Title of a notification of this type.
  ///
  /// In en, this message translates to:
  /// **'New Follower'**
  String get notificationsTypeFollow;

  /// No description provided for @notificationsTypeFriendAccepted.
  ///
  /// In en, this message translates to:
  /// **'New Friend'**
  String get notificationsTypeFriendAccepted;

  /// No description provided for @notificationsTypeFriendRequest.
  ///
  /// In en, this message translates to:
  /// **'Friend Request'**
  String get notificationsTypeFriendRequest;

  /// No description provided for @notificationsTypeMessage.
  ///
  /// In en, this message translates to:
  /// **'New Message'**
  String get notificationsTypeMessage;

  /// No description provided for @notificationsTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notificationsTypeOther;

  /// No description provided for @notificationsTypeReaction.
  ///
  /// In en, this message translates to:
  /// **'New Reaction'**
  String get notificationsTypeReaction;

  /// No description provided for @notificationsTypeReply.
  ///
  /// In en, this message translates to:
  /// **'New Reply'**
  String get notificationsTypeReply;

  /// Accessibility label of the red badge on the notifications bell.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} unread notification} other{{count} unread notifications}}'**
  String notificationsUnreadBadge(int count);

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

  /// No description provided for @profileFollowers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 follower} other{{count} followers}}'**
  String profileFollowers(int count);

  /// No description provided for @profileFollowing.
  ///
  /// In en, this message translates to:
  /// **'{count} following'**
  String profileFollowing(int count);

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

  /// No description provided for @profileVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified account'**
  String get profileVerified;

  /// Option in the menu of a pinned friend: opens that friend's profile.
  ///
  /// In en, this message translates to:
  /// **'View profile page'**
  String get profileViewProfile;

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

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsAppearanceDescription.
  ///
  /// In en, this message translates to:
  /// **'How Later looks on this phone'**
  String get settingsAppearanceDescription;

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

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageDescription.
  ///
  /// In en, this message translates to:
  /// **'The language of the app and of your notifications'**
  String get settingsLanguageDescription;

  /// No description provided for @settingsLanguageFooter.
  ///
  /// In en, this message translates to:
  /// **'Notifications from Later arrive in this language too.'**
  String get settingsLanguageFooter;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'Phone\'s language'**
  String get settingsLanguageSystem;

  /// Under 'Phone's language': the language that choice gives right now, in its own name (e.g. 'Deutsch').
  ///
  /// In en, this message translates to:
  /// **'Now: {language}'**
  String settingsLanguageSystemHint(String language);

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

  /// No description provided for @settingsNotificationsAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get settingsNotificationsAchievements;

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

  /// No description provided for @settingsNotificationsComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get settingsNotificationsComments;

  /// No description provided for @settingsNotificationsCommentsHint.
  ///
  /// In en, this message translates to:
  /// **'On your capsules and replies to you'**
  String get settingsNotificationsCommentsHint;

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

  /// No description provided for @settingsNotificationsFriendRequests.
  ///
  /// In en, this message translates to:
  /// **'Friend requests'**
  String get settingsNotificationsFriendRequests;

  /// No description provided for @settingsNotificationsFriendRequestsHint.
  ///
  /// In en, this message translates to:
  /// **'Received and accepted'**
  String get settingsNotificationsFriendRequestsHint;

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

  /// No description provided for @settingsNotificationsNews.
  ///
  /// In en, this message translates to:
  /// **'News from Later'**
  String get settingsNotificationsNews;

  /// No description provided for @settingsNotificationsNewsHint.
  ///
  /// In en, this message translates to:
  /// **'Rare announcements from the team'**
  String get settingsNotificationsNewsHint;

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

  /// No description provided for @settingsNotificationsReactions.
  ///
  /// In en, this message translates to:
  /// **'Reactions'**
  String get settingsNotificationsReactions;

  /// No description provided for @settingsNotificationsSound.
  ///
  /// In en, this message translates to:
  /// **'Sound and vibration'**
  String get settingsNotificationsSound;

  /// No description provided for @settingsNotificationsStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak reminder'**
  String get settingsNotificationsStreak;

  /// No description provided for @settingsNotificationsStreakHint.
  ///
  /// In en, this message translates to:
  /// **'In the evening, when your streak would end tonight'**
  String get settingsNotificationsStreakHint;

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

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @settingsPrivacyAchievements.
  ///
  /// In en, this message translates to:
  /// **'Show my achievements'**
  String get settingsPrivacyAchievements;

  /// No description provided for @settingsPrivacyAchievementsHint.
  ///
  /// In en, this message translates to:
  /// **'Friends see them on your profile'**
  String get settingsPrivacyAchievementsHint;

  /// No description provided for @settingsPrivacyApproximate.
  ///
  /// In en, this message translates to:
  /// **'Approximate location'**
  String get settingsPrivacyApproximate;

  /// No description provided for @settingsPrivacyApproximateHint.
  ///
  /// In en, this message translates to:
  /// **'Places new capsules within about a kilometre, not at the exact spot'**
  String get settingsPrivacyApproximateHint;

  /// No description provided for @settingsPrivacyDescription.
  ///
  /// In en, this message translates to:
  /// **'What others see and what new capsules start with'**
  String get settingsPrivacyDescription;

  /// No description provided for @settingsPrivacyNewCapsulesFooter.
  ///
  /// In en, this message translates to:
  /// **'You can change both for each capsule when you create it.'**
  String get settingsPrivacyNewCapsulesFooter;

  /// No description provided for @settingsPrivacyReadReceipts.
  ///
  /// In en, this message translates to:
  /// **'Read receipts'**
  String get settingsPrivacyReadReceipts;

  /// No description provided for @settingsPrivacyReadReceiptsHint.
  ///
  /// In en, this message translates to:
  /// **'Turned off, friends do not see when you have read their messages, and you do not see theirs'**
  String get settingsPrivacyReadReceiptsHint;

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

  /// No description provided for @settingsSectionMoreActivity.
  ///
  /// In en, this message translates to:
  /// **'ACTIVITY'**
  String get settingsSectionMoreActivity;

  /// No description provided for @settingsSectionNewCapsules.
  ///
  /// In en, this message translates to:
  /// **'NEW CAPSULES'**
  String get settingsSectionNewCapsules;

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

  /// No description provided for @settingsSectionSize.
  ///
  /// In en, this message translates to:
  /// **'SIZE'**
  String get settingsSectionSize;

  /// No description provided for @settingsSectionSupport.
  ///
  /// In en, this message translates to:
  /// **'SUPPORT'**
  String get settingsSectionSupport;

  /// No description provided for @settingsSectionTheme.
  ///
  /// In en, this message translates to:
  /// **'THEME'**
  String get settingsSectionTheme;

  /// No description provided for @settingsSectionThisPhone.
  ///
  /// In en, this message translates to:
  /// **'THIS PHONE'**
  String get settingsSectionThisPhone;

  /// No description provided for @settingsSectionVisibility.
  ///
  /// In en, this message translates to:
  /// **'WHAT OTHERS SEE'**
  String get settingsSectionVisibility;

  /// Under the Password row for accounts that sign in with Google only.
  ///
  /// In en, this message translates to:
  /// **'Signed in with Google'**
  String get settingsSignedInWithGoogle;

  /// No description provided for @settingsSizeFooter.
  ///
  /// In en, this message translates to:
  /// **'Makes everything on screen smaller or larger, text included.'**
  String get settingsSizeFooter;

  /// No description provided for @settingsSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get settingsSizeLarge;

  /// No description provided for @settingsSizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get settingsSizeSmall;

  /// No description provided for @settingsSizeStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get settingsSizeStandard;

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

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'Same as phone'**
  String get settingsThemeSystem;

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

  /// No description provided for @settingsVisibilityFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get settingsVisibilityFriends;

  /// No description provided for @settingsVisibilityFriendsHint.
  ///
  /// In en, this message translates to:
  /// **'Only your friends'**
  String get settingsVisibilityFriendsHint;

  /// No description provided for @settingsVisibilityPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get settingsVisibilityPrivate;

  /// No description provided for @settingsVisibilityPrivateHint.
  ///
  /// In en, this message translates to:
  /// **'Only you'**
  String get settingsVisibilityPrivateHint;

  /// No description provided for @settingsVisibilityPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get settingsVisibilityPublic;

  /// No description provided for @settingsVisibilityPublicHint.
  ///
  /// In en, this message translates to:
  /// **'Everyone on the map'**
  String get settingsVisibilityPublicHint;

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
