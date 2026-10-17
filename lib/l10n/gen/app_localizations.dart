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

  /// No description provided for @historyNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No capsules match your search'**
  String get historyNoMatches;

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

  /// Notification text: a friend created a capsule. The name is bold and cannot be inflected.
  ///
  /// In en, this message translates to:
  /// **'{name} created a new capsule'**
  String notificationsCapsuleBody(String name);

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
