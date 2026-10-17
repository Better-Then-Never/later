// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appName => 'Later';

  @override
  String get authContinueWithGoogle => 'Kontynuuj z Google';

  @override
  String get authEmailHint => 'E-mail';

  @override
  String get authEnterEmail => 'Podaj swój adres e-mail';

  @override
  String get authErrorEmailInUse => 'Konto z tym adresem e-mail już istnieje.';

  @override
  String get authErrorEmailTaken =>
      'Ten adres e-mail jest już używany przez inne konto.';

  @override
  String get authErrorInvalidCredential => 'Nieprawidłowy e-mail lub hasło.';

  @override
  String get authErrorInvalidEmail => 'Adres e-mail jest nieprawidłowy.';

  @override
  String get authErrorMethodDisabled => 'Ta metoda logowania jest wyłączona.';

  @override
  String get authErrorPickGoogleAccount =>
      'Wybierz konto Google, przez które się logujesz.';

  @override
  String get authErrorRecentLogin => 'Potwierdź, że to ty, i spróbuj ponownie.';

  @override
  String get authErrorTooManyRequests =>
      'Zbyt wiele prób. Spróbuj ponownie później.';

  @override
  String get authErrorUserDisabled => 'To konto zostało wyłączone.';

  @override
  String get authErrorUserNotFound =>
      'Nie znaleziono użytkownika z tym adresem e-mail.';

  @override
  String get authErrorWeakPassword => 'Hasło jest za słabe.';

  @override
  String authErrorWithMessage(String message) {
    return 'Błąd: $message';
  }

  @override
  String get authErrorWrongPassword => 'Nieprawidłowe hasło.';

  @override
  String get authErrorWrongPasswordProvided => 'Podano nieprawidłowe hasło.';

  @override
  String get authFacebookSoon => 'Facebook (wkrótce)';

  @override
  String get authFillAllFields => 'Wypełnij wszystkie pola';

  @override
  String get authForgotPassword => 'Nie pamiętasz hasła?';

  @override
  String get authGetStarted => 'Zaczynamy';

  @override
  String get authGoToLogIn => 'Zaloguj się';

  @override
  String get authGoToSignUp => 'Zarejestruj się';

  @override
  String get authGoogleFailed =>
      'Nie udało się zalogować przez Google. Spróbuj ponownie.';

  @override
  String get authHaveAccount => 'Masz już konto?';

  @override
  String get authHidePassword => 'Ukryj hasło';

  @override
  String authLegalNotice(String terms, String privacy) {
    return 'Rejestrując się, akceptujesz $terms i $privacy';
  }

  @override
  String get authLinkOpenFailed => 'Nie udało się otworzyć strony.';

  @override
  String get authLogInButton => 'Zaloguj się';

  @override
  String get authLoginSubtitle =>
      'Zaloguj się, aby dalej korzystać z aplikacji';

  @override
  String get authLoginTitle => 'Logowanie';

  @override
  String get authNameHint => 'Imię';

  @override
  String get authNoAccount => 'Nie masz konta?';

  @override
  String get authNoFreeUsername =>
      'Nie udało się dobrać nazwy użytkownika. Zarejestruj się.';

  @override
  String get authOrConnectWith => 'Lub zaloguj się przez';

  @override
  String get authPasswordHint => 'Hasło';

  @override
  String get authPermissionCameraText => 'Dzięki temu stworzysz kapsuły czasu!';

  @override
  String get authPermissionCameraTitle => 'Daj Later dostęp do aparatu';

  @override
  String get authPermissionContactsText =>
      'Znajdź i zaproś znajomych z kontaktów!';

  @override
  String get authPermissionContactsTitle => 'Dostęp do kontaktów';

  @override
  String get authPermissionEnable => 'Zezwól';

  @override
  String get authPermissionGranted => 'Zezwolono';

  @override
  String get authPermissionLocationText =>
      'Dzięki temu znajdziesz kapsuły w pobliżu!';

  @override
  String get authPermissionLocationTitle => 'Udostępnij nam swoją lokalizację';

  @override
  String get authPermissionMicrophoneText => 'Bez niego aparat nie zadziała';

  @override
  String get authPermissionMicrophoneTitle => 'Daj Later dostęp do mikrofonu';

  @override
  String get authPermissionNotificationsText =>
      'Bądź na bieżąco z nowymi obserwującymi i kapsułami!';

  @override
  String get authPermissionNotificationsTitle => 'Włącz powiadomienia';

  @override
  String get authPrivacyPolicy => 'Politykę prywatności';

  @override
  String get authResetDescription =>
      'Podaj swój e-mail, a wyślemy ci link do zresetowania hasła';

  @override
  String get authResetInvalidEmail => 'Nieprawidłowy adres e-mail';

  @override
  String get authResetSend => 'Wyślij link';

  @override
  String get authResetSent =>
      'Wysłaliśmy e-mail do zresetowania hasła! Sprawdź skrzynkę.';

  @override
  String get authResetTitle => 'Resetowanie hasła';

  @override
  String get authResetUserNotFound =>
      'Nie znaleziono konta z tym adresem e-mail';

  @override
  String get authShowPassword => 'Pokaż hasło';

  @override
  String get authSignInAgain => 'Zaloguj się ponownie.';

  @override
  String get authSignUpButton => 'Zarejestruj się';

  @override
  String get authSignupSubtitle => 'Uzupełnij dane, aby założyć konto';

  @override
  String get authSignupTitle => 'Rejestracja';

  @override
  String get authTermsOfUse => 'Warunki korzystania';

  @override
  String get authUsernameHint => 'Nazwa użytkownika';

  @override
  String get authWelcomeSubtitle =>
      'Załóż konto i oglądaj swoje kapsuły\noraz kapsuły znajomych';

  @override
  String get authWelcomeTo => 'Witaj w';

  @override
  String get commonBack => 'Wstecz';

  @override
  String get commonCancel => 'Anuluj';

  @override
  String get commonClose => 'Zamknij';

  @override
  String get commonConfirm => 'Potwierdź';

  @override
  String get commonContinue => 'Dalej';

  @override
  String get commonDelete => 'Usuń';

  @override
  String get commonDone => 'Gotowe';

  @override
  String get commonErrorGeneric => 'Coś poszło nie tak. Spróbuj ponownie.';

  @override
  String get commonLoading => 'Ładowanie...';

  @override
  String get commonNoConnection => 'Brak połączenia. Spróbuj ponownie.';

  @override
  String get commonRetry => 'Spróbuj ponownie';

  @override
  String get commonSave => 'Zapisz';

  @override
  String get commonSearchHint => 'Szukaj...';

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
  String get commonUnknownUser => 'Nieznany użytkownik';

  @override
  String get commonUnknownUsername => 'nieznany';

  @override
  String get commonUntitled => 'Bez tytułu';

  @override
  String get commonUsernameRequired => 'Wpisz nazwę użytkownika';

  @override
  String get commonUsernameRules =>
      'Użyj od 3 do 30 liter łacińskich, cyfr, kropek, myślników lub podkreśleń';

  @override
  String get commonUsernameTaken => 'Ta nazwa użytkownika jest już zajęta';

  @override
  String get failureNotFound => 'Ten element już nie istnieje.';

  @override
  String get failurePermission => 'Nie masz uprawnień do tej czynności.';

  @override
  String get friendsAccept => 'Przyjmij';

  @override
  String get friendsAcceptRequestLabel => 'Przyjmij zaproszenie do znajomych';

  @override
  String get friendsAdd => 'Dodaj';

  @override
  String get friendsAddTitle => 'Dodaj znajomych';

  @override
  String get friendsBlock => 'Zablokuj';

  @override
  String get friendsBlockConfirm =>
      'Na pewno chcesz zablokować tego użytkownika?';

  @override
  String get friendsCapsulesSettings => 'Ustawienia kapsuł';

  @override
  String get friendsChatSettings => 'Ustawienia czatu';

  @override
  String get friendsEmpty => 'Nie masz jeszcze znajomych';

  @override
  String get friendsErrorAcceptRequest => 'Nie udało się przyjąć zaproszenia';

  @override
  String get friendsErrorBlock => 'Nie udało się zablokować użytkownika';

  @override
  String get friendsErrorCancelRequest => 'Nie udało się anulować zaproszenia';

  @override
  String get friendsErrorFollow => 'Nie udało się zacząć obserwować';

  @override
  String get friendsErrorLoadUsers => 'Nie udało się wczytać użytkowników';

  @override
  String get friendsErrorRejectRequest => 'Nie udało się odrzucić zaproszenia';

  @override
  String get friendsErrorRemoveFriend => 'Nie udało się usunąć ze znajomych';

  @override
  String get friendsErrorSendRequest =>
      'Nie udało się wysłać zaproszenia do znajomych';

  @override
  String get friendsErrorUnblock => 'Nie udało się odblokować użytkownika';

  @override
  String get friendsErrorUnfollow => 'Nie udało się przestać obserwować';

  @override
  String get friendsFollow => 'Obserwuj';

  @override
  String get friendsFollowed =>
      'Obserwujesz! Dostaniesz powiadomienia o nowych kapsułach';

  @override
  String get friendsFollowing => 'Obserwujesz';

  @override
  String get friendsFriendCapsulesEmpty =>
      'Tutaj pojawią się kapsuły znajomego';

  @override
  String get friendsFriendCapsulesTitle => 'Kapsuły znajomego';

  @override
  String get friendsHideSuggestionLabel => 'Ukryj propozycję';

  @override
  String get friendsMakeFriends => 'Poznaj nowych znajomych';

  @override
  String get friendsManageFriendship => 'Ustawienia znajomości';

  @override
  String get friendsMyFriendsTitle => 'Moi znajomi';

  @override
  String get friendsMyProfile => 'Mój profil';

  @override
  String get friendsNoMatches => 'Żaden znajomy nie pasuje do wyszukiwania';

  @override
  String get friendsNoSuggestions => 'Brak kolejnych propozycji';

  @override
  String get friendsOpenChat => 'Otwórz czat';

  @override
  String get friendsPending => 'Oczekuje';

  @override
  String get friendsQrHint => 'Skieruj aparat na kod QR, aby dodać znajomego';

  @override
  String get friendsQrInvalid =>
      'Nieprawidłowy kod QR. Zeskanuj kod QR profilu Later.';

  @override
  String get friendsQrTitle => 'Zeskanuj kod QR';

  @override
  String get friendsReject => 'Odrzuć';

  @override
  String get friendsRemove => 'Usuń ze znajomych';

  @override
  String get friendsRemoveAction => 'Usuń';

  @override
  String get friendsRemoveConfirm =>
      'Na pewno chcesz usunąć tę osobę ze znajomych?';

  @override
  String get friendsRemoving => 'Usuwanie...';

  @override
  String get friendsReport => 'Zgłoś';

  @override
  String get friendsRequestAccepted => 'Zaproszenie do znajomych przyjęte!';

  @override
  String get friendsRequestAlreadyExists =>
      'Zaproszenie do znajomych zostało już wysłane';

  @override
  String get friendsRequestCancelled => 'Zaproszenie do znajomych anulowane';

  @override
  String get friendsRequestPendingInfo =>
      'Zaproszenie do znajomych czeka na odpowiedź';

  @override
  String get friendsRequestReceivedInfo =>
      'Ta osoba wysłała ci zaproszenie do znajomych';

  @override
  String get friendsRequestRejected => 'Zaproszenie do znajomych odrzucone';

  @override
  String get friendsRequestSent => 'Zaproszenie do znajomych wysłane!';

  @override
  String get friendsRequestsButton => 'Zaproszenia';

  @override
  String get friendsRequestsEmptySubtitle =>
      'Gdy ktoś wyśle ci zaproszenie do znajomych,\npojawi się tutaj';

  @override
  String get friendsRequestsEmptyTitle => 'Brak zaproszeń do znajomych';

  @override
  String get friendsRequestsReceivedTab => 'Otrzymane';

  @override
  String get friendsRequestsSentTab => 'Wysłane';

  @override
  String get friendsRequestsTitle => 'Zaproszenia do znajomych';

  @override
  String get friendsSearchByTagHint => 'Szukaj po nicku';

  @override
  String get friendsSearchHint => 'Szukaj wśród znajomych';

  @override
  String get friendsSendCapsule => 'Wyślij kapsułę';

  @override
  String get friendsSendRequestLabel => 'Wyślij zaproszenie do znajomych';

  @override
  String get friendsSentEmptySubtitle =>
      'Tutaj pojawią się zaproszenia,\nktóre wyślesz';

  @override
  String get friendsSentEmptyTitle => 'Brak wysłanych zaproszeń';

  @override
  String get friendsShareProfile => 'Udostępnij profil';

  @override
  String get friendsShareProfileTo => 'Udostępnij profil ...';

  @override
  String get friendsSuggestionRemoved => 'Propozycja usunięta z listy!';

  @override
  String get friendsThisIsYou => 'To twoje konto';

  @override
  String get friendsUnfollowed => 'Już nie obserwujesz tej osoby';

  @override
  String get friendsViewProfile => 'Zobacz profil';

  @override
  String get historyAddToFavorites => 'Dodaj do ulubionych';

  @override
  String get historyCapsuleOpened => 'Kapsuła otwarta!';

  @override
  String get historyColorBlue => 'Niebieski';

  @override
  String get historyColorGreen => 'Zielony';

  @override
  String get historyColorOrange => 'Pomarańczowy';

  @override
  String get historyColorPurple => 'Fioletowy';

  @override
  String get historyColorRed => 'Czerwony';

  @override
  String get historyColorYellow => 'Żółty';

  @override
  String historyCountdown(int days, int hours, int minutes, int seconds) {
    return '${days}d ${hours}h ${minutes}min ${seconds}s';
  }

  @override
  String historyCountdownYears(int years, int days, int hours, int minutes) {
    return '${years}r ${days}d ${hours}h ${minutes}min';
  }

  @override
  String historyDeleteConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Usunąć $count kapsuły?',
      many: 'Usunąć $count kapsuł?',
      few: 'Usunąć $count kapsuły?',
      one: 'Usunąć $count kapsułę?',
    );
    return '$_temp0';
  }

  @override
  String historyDeleteSelected(int count) {
    return 'Usuń ($count)';
  }

  @override
  String historyDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Usunięto $count kapsuły',
      many: 'Usunięto $count kapsuł',
      few: 'Usunięto $count kapsuły',
      one: 'Usunięto $count kapsułę',
    );
    return '$_temp0';
  }

  @override
  String historyDistanceFromYou(String distance) {
    return '$distance km od ciebie';
  }

  @override
  String get historyDistanceUnknown => 'Odległość nieznana';

  @override
  String get historyEmpty => 'Nie masz jeszcze kapsuł';

  @override
  String get historyErrorDelete => 'Nie udało się usunąć kapsuł';

  @override
  String get historyErrorFavorites => 'Nie udało się zaktualizować ulubionych';

  @override
  String historyFavoriteAdded(String title) {
    return 'Kapsuła „$title” dodana do ulubionych';
  }

  @override
  String historyFavoriteRemoved(String title) {
    return 'Kapsuła „$title” usunięta z ulubionych';
  }

  @override
  String get historyFilterAny => 'Wszystkie';

  @override
  String get historyFilterBy => 'Filtruj';

  @override
  String get historyFilterCapsule => 'Kapsuły';

  @override
  String get historyFilterColor => 'Kolor';

  @override
  String get historyFilterFavorite => 'Ulubione';

  @override
  String get historyFilterVisibility => 'Widoczność';

  @override
  String get historyNoMatches => 'Żadna kapsuła nie pasuje do wyszukiwania';

  @override
  String get historyPrivacyFriends => 'Dla znajomych';

  @override
  String get historyPrivacyPrivate => 'Prywatna';

  @override
  String get historyPrivacyPublic => 'Publiczna';

  @override
  String get historyRemoveFromFavorites => 'Usuń z ulubionych';

  @override
  String get historyReset => 'Wyczyść';

  @override
  String get historySearchHint => 'Szukaj kapsuł...';

  @override
  String historySelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wybrano: $count',
      many: 'Wybrano: $count',
      few: 'Wybrano: $count',
      one: 'Wybrano: $count',
    );
    return '$_temp0';
  }

  @override
  String get historySortBy => 'Sortuj';

  @override
  String get historySortClosest => 'Od najbliższych';

  @override
  String get historySortDistance => 'Odległość';

  @override
  String get historySortFarthest => 'Od najdalszych';

  @override
  String get historySortNewest => 'Od najnowszych';

  @override
  String get historySortOldest => 'Od najstarszych';

  @override
  String get historySortRelevance => 'Trafność';

  @override
  String get historyTitle => 'Moje kapsuły';

  @override
  String get historyVisibilityFriends => 'Kapsuła dla znajomych';

  @override
  String get historyVisibilityPrivate => 'Kapsuła prywatna';

  @override
  String get historyVisibilityPublic => 'Kapsuła publiczna';

  @override
  String get messagesBlockedByYou => 'Ten użytkownik jest zablokowany';

  @override
  String get messagesCantSend =>
      'Nie możesz wysyłać wiadomości temu użytkownikowi';

  @override
  String get messagesCapsuleLabel => 'Kapsuła';

  @override
  String get messagesCapsuleUnavailable => 'Ta kapsuła nie jest już dostępna';

  @override
  String get messagesChatFallbackTitle => 'Czat';

  @override
  String get messagesChatOptions => 'Opcje czatu';

  @override
  String get messagesChatsLoadError => 'Nie udało się wczytać czatów';

  @override
  String get messagesCheckConnection => 'Sprawdź połączenie i spróbuj ponownie';

  @override
  String get messagesClearConfirm => 'Wyczyść';

  @override
  String get messagesClearConfirmTitle =>
      'Na pewno chcesz wyczyścić historię czatu?';

  @override
  String get messagesClearFailed => 'Nie udało się wyczyścić historii';

  @override
  String messagesEmptySubtitle(String name) {
    return '$name czeka na twoje „cześć”!';
  }

  @override
  String get messagesEmptyTitle => 'Nie ma jeszcze wiadomości';

  @override
  String get messagesFindChatsHint => 'Szukaj czatów';

  @override
  String get messagesInputHint => 'Napisz wiadomość...';

  @override
  String get messagesLoadError => 'Nie udało się wczytać wiadomości';

  @override
  String get messagesMenuBlock => 'Zablokuj użytkownika';

  @override
  String get messagesMenuClearHistory => 'Wyczyść historię';

  @override
  String get messagesMenuMute => 'Wycisz powiadomienia';

  @override
  String get messagesMenuSearch => 'Szukaj';

  @override
  String get messagesMenuUnblock => 'Odblokuj użytkownika';

  @override
  String get messagesMenuUnmute => 'Wyłącz wyciszenie';

  @override
  String get messagesMutedToast => 'Czat wyciszony';

  @override
  String get messagesNewChatFindFriends => 'Znajdź znajomych';

  @override
  String get messagesNewChatNoFriends => 'Nie masz jeszcze znajomych';

  @override
  String get messagesNewChatNoFriendsSubtitle =>
      'Dodaj znajomych, żeby zacząć rozmawiać!';

  @override
  String get messagesNewChatNoMatch => 'Nie znaleziono znajomych';

  @override
  String get messagesNewChatSearchHint => 'Szukaj znajomych';

  @override
  String get messagesNewChatTitle => 'Nowy czat';

  @override
  String get messagesNoChatsFound => 'Nie znaleziono czatów';

  @override
  String get messagesNoChatsSubtitle =>
      'Dotknij przycisku nowej wiadomości i zacznij pisać ze znajomymi!';

  @override
  String get messagesNoChatsTitle => 'Nie masz jeszcze rozmów';

  @override
  String get messagesNoMatchTitle => 'Nie znaleziono wiadomości';

  @override
  String messagesNothingMatches(String query) {
    return 'Brak wyników dla „$query”';
  }

  @override
  String get messagesNotificationsMuted => 'Czat wyciszony';

  @override
  String messagesOpenCapsule(String title) {
    return 'Otwórz kapsułę „$title”';
  }

  @override
  String get messagesReceiptFailed => 'Nie wysłano · Dotknij, aby ponowić';

  @override
  String get messagesReceiptRead => 'Przeczytano';

  @override
  String get messagesReceiptSending => 'Wysyłanie…';

  @override
  String get messagesReceiptSent => 'Wysłano';

  @override
  String get messagesScrollToLatest => 'Przewiń do najnowszej wiadomości';

  @override
  String get messagesSearchHint => 'Szukaj wiadomości';

  @override
  String get messagesSend => 'Wyślij';

  @override
  String get messagesSendCapsule => 'Wyślij kapsułę';

  @override
  String get messagesSendFailed => 'Nie udało się wysłać wiadomości';

  @override
  String get messagesSignedOut => 'Wylogowano z konta';

  @override
  String messagesStartChatWith(String name) {
    return 'Rozpocznij czat: $name';
  }

  @override
  String get messagesTitle => 'Moje Laters';

  @override
  String get messagesToday => 'Dzisiaj';

  @override
  String get messagesTooLong => 'Ta wiadomość jest za długa';

  @override
  String get messagesUnmutedToast => 'Wyciszenie czatu wyłączone';

  @override
  String get messagesYesterday => 'Wczoraj';

  @override
  String messagesYouPrefix(String message) {
    return 'Ty: $message';
  }

  @override
  String notificationsCapsuleBody(String name) {
    return '$name dzieli się nową kapsułą';
  }

  @override
  String notificationsCommentBody(String name) {
    return '$name komentuje twoją kapsułę';
  }

  @override
  String notificationsCommentBodyWithText(String name, String text) {
    return '$name komentuje: $text';
  }

  @override
  String notificationsDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dnia temu',
      many: '$count dni temu',
      few: '$count dni temu',
      one: '$count dzień temu',
    );
    return '$_temp0';
  }

  @override
  String notificationsDeleteConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Usunąć $count powiadomienia?',
      many: 'Usunąć $count powiadomień?',
      few: 'Usunąć $count powiadomienia?',
      one: 'Usunąć $count powiadomienie?',
    );
    return '$_temp0';
  }

  @override
  String notificationsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Usunięto $count powiadomienia',
      many: 'Usunięto $count powiadomień',
      few: 'Usunięto $count powiadomienia',
      one: 'Usunięto $count powiadomienie',
    );
    return '$_temp0';
  }

  @override
  String get notificationsEmptyAll =>
      'Tu pojawią się twoje powiadomienia i aktywność';

  @override
  String get notificationsEmptyComments =>
      'Tu pojawią się komentarze do twoich kapsuł';

  @override
  String get notificationsEmptyReplies =>
      'Tu pojawią się odpowiedzi na twoje wiadomości';

  @override
  String notificationsFollowBody(String name) {
    return '$name zaczyna cię obserwować';
  }

  @override
  String notificationsHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count godziny temu',
      many: '$count godzin temu',
      few: '$count godziny temu',
      one: '$count godzinę temu',
    );
    return '$_temp0';
  }

  @override
  String get notificationsJustNow => 'Przed chwilą';

  @override
  String get notificationsMarkAsRead => 'Oznacz jako przeczytane';

  @override
  String notificationsMarkedRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Oznaczono $count powiadomienia jako przeczytane',
      many: 'Oznaczono $count powiadomień jako przeczytane',
      few: 'Oznaczono $count powiadomienia jako przeczytane',
      one: 'Oznaczono $count powiadomienie jako przeczytane',
    );
    return '$_temp0';
  }

  @override
  String notificationsMessageBody(String name) {
    return '$name pisze do ciebie';
  }

  @override
  String notificationsMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minuty temu',
      many: '$count minut temu',
      few: '$count minuty temu',
      one: '$count minutę temu',
    );
    return '$_temp0';
  }

  @override
  String notificationsReplyBody(String name) {
    return '$name odpowiada ci';
  }

  @override
  String notificationsReplyBodyWithText(String name, String text) {
    return '$name odpowiada: $text';
  }

  @override
  String notificationsSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wybranego',
      many: '$count wybranych',
      few: '$count wybrane',
      one: '$count wybrane',
    );
    return '$_temp0';
  }

  @override
  String get notificationsTabAll => 'Wszystkie';

  @override
  String get notificationsTabComments => 'Komentarze';

  @override
  String get notificationsTabReplies => 'Odpowiedzi';

  @override
  String get notificationsTitle => 'Powiadomienia';

  @override
  String get notificationsTypeCapsule => 'Nowa kapsuła';

  @override
  String get notificationsTypeComment => 'Nowy komentarz';

  @override
  String get notificationsTypeFollow => 'Nowy obserwujący';

  @override
  String get notificationsTypeMessage => 'Nowa wiadomość';

  @override
  String get notificationsTypeOther => 'Powiadomienie';

  @override
  String get notificationsTypeReply => 'Nowa odpowiedź';

  @override
  String notificationsUnreadBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nieprzeczytanego powiadomienia',
      many: '$count nieprzeczytanych powiadomień',
      few: '$count nieprzeczytane powiadomienia',
      one: '$count nieprzeczytane powiadomienie',
    );
    return '$_temp0';
  }

  @override
  String get placeNoLocation => 'Brak lokalizacji';

  @override
  String get placeUnknown => 'Nieznane miejsce';

  @override
  String get profileAddFriends => 'Dodaj znajomych';

  @override
  String get profileAddToMapEveryone => 'Na mapę | Dla wszystkich';

  @override
  String get profileAddToMapFriends => 'Na mapę | Tylko dla znajomych';

  @override
  String get profileBackgroundDelete => 'Usuń zdjęcie w tle';

  @override
  String get profileBackgroundTitle => 'Zdjęcie w tle';

  @override
  String get profileBackgroundUpdated => 'Zdjęcie w tle zaktualizowane!';

  @override
  String get profileChoosePinned => 'Przypnij znajomych';

  @override
  String get profileCopyLink => 'Kopiuj link';

  @override
  String get profileErrorCopyLink => 'Nie udało się skopiować linku';

  @override
  String get profileErrorDeleteBackground =>
      'Nie udało się usunąć zdjęcia w tle';

  @override
  String get profileErrorDeletePicture =>
      'Nie udało się usunąć zdjęcia profilowego';

  @override
  String get profileErrorShare => 'Nie udało się udostępnić profilu';

  @override
  String get profileErrorUploadBackground =>
      'Nie udało się przesłać zdjęcia w tle';

  @override
  String get profileErrorUploadPicture =>
      'Nie udało się przesłać zdjęcia profilowego';

  @override
  String get profileImageFromGallery => 'Wybierz z galerii';

  @override
  String get profileImageTakePhoto => 'Zrób zdjęcie';

  @override
  String get profileLinkCopied => 'Link skopiowany!';

  @override
  String get profileMyCapsules => 'Moje kapsuły';

  @override
  String get profileMyFriends => 'Moi znajomi';

  @override
  String get profileNoFriends => 'Nie masz jeszcze znajomych';

  @override
  String get profilePictureDelete => 'Usuń zdjęcie profilowe';

  @override
  String get profilePictureTitle => 'Zdjęcie profilowe';

  @override
  String get profilePictureUpdated => 'Zdjęcie profilowe zaktualizowane!';

  @override
  String get profilePinnedHint =>
      'Jeśli wybierzesz mniej niż 3, pokażemy losowych znajomych z twojej listy';

  @override
  String get profilePinnedLimit => 'Możesz przypiąć maksymalnie 3 znajomych';

  @override
  String get profilePinnedTitle => 'Przypnij do 3 znajomych';

  @override
  String get profilePinnedUpdated => 'Przypięci znajomi zaktualizowani!';

  @override
  String get profileQrError => 'Coś poszło nie tak...';

  @override
  String get profileShare => 'Udostępnij';

  @override
  String get profileShareHeading => 'Udostępnij swój profil';

  @override
  String get profileShareHint =>
      'Inni mogą zeskanować ten kod aparatem lub w aplikacji, aby dodać cię do znajomych';

  @override
  String profileShareMessage(String name, String link) {
    return '$name jest w Later. Zajrzyj!\n$link';
  }

  @override
  String profileShareSubject(String name) {
    return '$name czeka na ciebie w Later';
  }

  @override
  String get profileShareSubtitle =>
      'Pokaż ten kod QR, aby inni mogli dodać cię do znajomych';

  @override
  String get profileShareTitle => 'Udostępnij profil';

  @override
  String get profileUpdating => 'Aktualizacja...';

  @override
  String get profileViewProfile => 'Zobacz profil';

  @override
  String get settingsAbout => 'O aplikacji';

  @override
  String get settingsAboutLicenses => 'Licencje open source';

  @override
  String get settingsAboutOpenFailed => 'Nie udało się otworzyć strony.';

  @override
  String get settingsAboutPrivacy => 'Polityka prywatności';

  @override
  String get settingsAboutTerms => 'Warunki korzystania';

  @override
  String get settingsAboutVersion => 'Wersja';

  @override
  String get settingsAboutVersionUnknown => 'nieznana';

  @override
  String get settingsAppPermissions => 'Uprawnienia aplikacji';

  @override
  String get settingsAppearance => 'Wygląd';

  @override
  String get settingsAppearanceDescription =>
      'Jak Later wygląda na tym telefonie';

  @override
  String settingsBlockedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count osoby',
      many: '$count osób',
      few: '$count osoby',
      one: '$count osoba',
    );
    return '$_temp0';
  }

  @override
  String get settingsBlockedDescription =>
      'Nie mogą do ciebie pisać ani wysyłać ci zaproszeń do znajomych';

  @override
  String get settingsBlockedEmpty => 'Nikogo nie blokujesz';

  @override
  String get settingsBlockedEmptyHint =>
      'Zablokujesz kogoś na jego profilu\nlub w czacie';

  @override
  String get settingsBlockedNobody => 'Nikt';

  @override
  String get settingsBlockedUsers => 'Zablokowani użytkownicy';

  @override
  String get settingsCameraBack => 'Tylny aparat';

  @override
  String get settingsCameraFooter =>
      'Aparat, który otwiera się, gdy tworzysz kapsułę.';

  @override
  String get settingsCameraFront => 'Przedni aparat';

  @override
  String get settingsCompleteProfileDescription =>
      'Wybierz, jak będą cię widzieć znajomi';

  @override
  String settingsCompleteProfileNoProfile(String email) {
    return 'Konto $email nie ma jeszcze profilu.';
  }

  @override
  String get settingsCompleteProfileTitle => 'Prawie gotowe';

  @override
  String get settingsCustomizeDescription => 'Stuknij zdjęcie, żeby je zmienić';

  @override
  String get settingsCustomizeProfile => 'Dostosuj profil';

  @override
  String get settingsDataAndStorage => 'Dane i pamięć';

  @override
  String get settingsDeleteAccount => 'Usuń konto';

  @override
  String get settingsDeleteButton => 'Usuń moje konto';

  @override
  String get settingsDeleteConfirm => 'Usunąć konto? Tego nie da się cofnąć.';

  @override
  String get settingsDeleteDescription =>
      'Usuwa twoje konto i wszystko, co się w nim znajduje';

  @override
  String get settingsDeleteNote =>
      'Usunięcie konta usuwa twój profil, zdjęcia, kapsuły, czaty, znajomych i obserwujących. Znajomi nie zobaczą już ani ciebie, ani twoich wiadomości. Tego nie da się cofnąć.';

  @override
  String get settingsDeletedAccount => 'Usunięte konto';

  @override
  String get settingsDeviceDescription =>
      'Jak Later wygląda i działa na tym telefonie';

  @override
  String get settingsEmail => 'E-mail';

  @override
  String settingsEmailDescription(String email) {
    return 'Logujesz się do Later adresem $email';
  }

  @override
  String settingsEmailGoogleDescription(String email) {
    return 'Logujesz się przez Google jako $email';
  }

  @override
  String get settingsEmailGoogleNote =>
      'Twój e-mail pochodzi z konta Google. Jeśli chcesz używać innego, zmień go na koncie Google.';

  @override
  String settingsEmailLinkSent(String newEmail, String currentEmail) {
    return 'Wysłaliśmy link na $newEmail. Otwórz go, żeby potwierdzić – wtedy e-mail się zmieni. Do tego czasu loguj się adresem $currentEmail.';
  }

  @override
  String get settingsEmailNewHint => 'Nowy e-mail';

  @override
  String get settingsEmailSendLink => 'Wyślij link';

  @override
  String get settingsErrorChatUpdateFailed =>
      'Nie udało się zaktualizować czatu.';

  @override
  String get settingsErrorCouldNotSave =>
      'Nie udało się zapisać. Spróbuj ponownie.';

  @override
  String get settingsErrorCurrentPassword => 'Wpisz obecne hasło.';

  @override
  String get settingsErrorEnterName => 'Wpisz swoje imię.';

  @override
  String get settingsErrorEnterNewName => 'Wpisz nowe imię!';

  @override
  String get settingsErrorEnterNewUsername => 'Wpisz nową nazwę użytkownika!';

  @override
  String get settingsErrorEnterPassword => 'Wpisz hasło.';

  @override
  String get settingsErrorInvalidEmail => 'Wpisz poprawny adres e-mail.';

  @override
  String get settingsErrorNameFailed => 'Nie udało się zmienić imienia!';

  @override
  String get settingsErrorPasswordSame =>
      'Nowe hasło jest takie samo jak obecne.';

  @override
  String settingsErrorPasswordTooShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nowe hasło musi mieć co najmniej $count znaku.',
      many: 'Nowe hasło musi mieć co najmniej $count znaków.',
      few: 'Nowe hasło musi mieć co najmniej $count znaki.',
      one: 'Nowe hasło musi mieć co najmniej $count znak.',
    );
    return '$_temp0';
  }

  @override
  String get settingsErrorPasswordsMismatch => 'Nowe hasła się różnią.';

  @override
  String get settingsErrorSameEmail => 'To już jest twój e-mail.';

  @override
  String get settingsErrorSaveFailed => 'Nie udało się zapisać ustawień.';

  @override
  String get settingsErrorSignInAgain => 'Zaloguj się ponownie.';

  @override
  String get settingsErrorUsernameFailed =>
      'Nie udało się zmienić nazwy użytkownika!';

  @override
  String get settingsFaqBlockAnswer =>
      'Zablokuj tę osobę na jej profilu lub w menu czatu. Odblokujesz ją w Ustawienia > Zablokowani użytkownicy.';

  @override
  String get settingsFaqBlockQuestion =>
      'Jak sprawić, żeby ktoś przestał się ze mną kontaktować?';

  @override
  String get settingsFaqCapsuleAnswer =>
      'To zdjęcie z tytułem i notatką, przypięte na mapie w miejscu, gdzie powstało. Możesz ustawić datę: do tego dnia kapsuła pozostanie zamknięta.';

  @override
  String get settingsFaqCapsuleQuestion => 'Czym jest kapsuła?';

  @override
  String get settingsFaqDeleteAnswer =>
      'Ustawienia > Usuń konto. Wszystkie twoje treści zostaną usunięte i nie da się ich przywrócić.';

  @override
  String get settingsFaqDeleteQuestion => 'Jak usunąć konto?';

  @override
  String get settingsFaqFriendsAnswer =>
      'Wyszukaj kogoś po nazwie użytkownika w Znajomych, zeskanuj jego kod QR albo udostępnij link do swojego profilu.';

  @override
  String get settingsFaqFriendsQuestion => 'Jak dodać znajomych?';

  @override
  String get settingsFaqNotificationsAnswer =>
      'Sprawdź Ustawienia > Powiadomienia: telefon musi pozwalać Later na powiadomienia, a powiadomienia push muszą być włączone. Godziny ciszy i wyciszone czaty też wstrzymują powiadomienia push.';

  @override
  String get settingsFaqNotificationsQuestion => 'Nie dostaję powiadomień';

  @override
  String get settingsFaqVisibilityAnswer =>
      'Wybierasz to przy tworzeniu: tylko ty (Prywatna), twoi znajomi (Dla znajomych) albo wszyscy (Publiczna).';

  @override
  String get settingsFaqVisibilityQuestion => 'Kto widzi moje kapsuły?';

  @override
  String get settingsGoogleConfirmsNote =>
      'Google potwierdzi, że to ty: gdy pojawi się prośba, wybierz swoje konto.';

  @override
  String get settingsHelp => 'Pomoc';

  @override
  String settingsHelpContactFooter(String email) {
    return 'E-maile wysłane z aplikacji zawierają wersję aplikacji i informacje o telefonie. Możesz też napisać na $email.';
  }

  @override
  String get settingsHelpContactSupport => 'Napisz do nas';

  @override
  String get settingsHelpCopied => 'Skopiowano. Wklej to do wiadomości do nas.';

  @override
  String get settingsHelpCopyInfo => 'Kopiuj informacje o aplikacji';

  @override
  String get settingsHelpDescription => 'Odpowiedzi i kontakt z nami';

  @override
  String settingsHelpNoEmailApp(String email) {
    return 'Brak aplikacji pocztowej. Napisz na $email';
  }

  @override
  String get settingsHelpReportProblem => 'Zgłoś problem';

  @override
  String get settingsHelpSubjectProblem => 'Later: zgłoszenie problemu';

  @override
  String get settingsHelpSubjectQuestion => 'Later: pytanie';

  @override
  String get settingsLanguage => 'Język';

  @override
  String get settingsLanguageDescription =>
      'Język aplikacji i twoich powiadomień';

  @override
  String get settingsLanguageFooter =>
      'Powiadomienia od Later też przyjdą w tym języku.';

  @override
  String get settingsLanguageSystem => 'Język telefonu';

  @override
  String settingsLanguageSystemHint(String language) {
    return 'Teraz: $language';
  }

  @override
  String get settingsLogOut => 'Wyloguj się';

  @override
  String get settingsLogOutConfirm => 'Na pewno chcesz się wylogować?';

  @override
  String get settingsMapAndCamera => 'Mapa i aparat';

  @override
  String get settingsMapLookHybrid => 'Satelitarna z nazwami';

  @override
  String get settingsMapLookSatellite => 'Satelitarna';

  @override
  String get settingsMapLookStandard => 'Standardowa';

  @override
  String get settingsName => 'Imię';

  @override
  String get settingsNameDescription =>
      'Tak zobaczą cię inni w Later. Wybierz imię, po którym rozpoznają cię znajomi';

  @override
  String get settingsNameHint => 'Nowe imię';

  @override
  String get settingsNameUpdated => 'Imię zaktualizowane!';

  @override
  String get settingsNotifications => 'Powiadomienia';

  @override
  String get settingsNotificationsAchievements => 'Osiągnięcia';

  @override
  String get settingsNotificationsAllow => 'Zezwól na powiadomienia';

  @override
  String get settingsNotificationsBlockedFooter =>
      'Twój telefon nie pozwala Later pokazywać powiadomień, więc nie dotrze żadne, niezależnie od ustawień poniżej.';

  @override
  String get settingsNotificationsCapsules => 'Nowe kapsuły';

  @override
  String get settingsNotificationsCapsulesHint =>
      'Od obserwowanych osób z włączonymi powiadomieniami';

  @override
  String get settingsNotificationsComments => 'Komentarze';

  @override
  String get settingsNotificationsCommentsHint =>
      'Pod twoimi kapsułami i odpowiedzi do ciebie';

  @override
  String get settingsNotificationsDescription =>
      'Wybierz, o czym Later ma ci mówić';

  @override
  String get settingsNotificationsFollowers => 'Nowi obserwujący';

  @override
  String get settingsNotificationsFriendRequests => 'Zaproszenia do znajomych';

  @override
  String get settingsNotificationsFriendRequestsHint =>
      'Otrzymane i zaakceptowane';

  @override
  String get settingsNotificationsMessages => 'Wiadomości';

  @override
  String get settingsNotificationsMuteHint =>
      'Pojedynczy czat wyciszysz w jego menu w Wiadomościach.';

  @override
  String get settingsNotificationsNews => 'Wiadomości od Later';

  @override
  String get settingsNotificationsNewsHint => 'Rzadkie ogłoszenia od zespołu';

  @override
  String get settingsNotificationsOff => 'Wyłączone';

  @override
  String get settingsNotificationsOffInPhone =>
      'Wyłączone w ustawieniach telefonu';

  @override
  String get settingsNotificationsOn => 'Włączone';

  @override
  String get settingsNotificationsPreview => 'Pokazuj treść wiadomości';

  @override
  String get settingsNotificationsPreviewOff =>
      'Powiadomienia pokazują tylko „Nowa wiadomość”';

  @override
  String get settingsNotificationsPush => 'Powiadomienia push';

  @override
  String get settingsNotificationsPushOff =>
      'Nie dostajesz powiadomień push z Later';

  @override
  String get settingsNotificationsReactions => 'Reakcje';

  @override
  String get settingsNotificationsSound => 'Dźwięk i wibracje';

  @override
  String get settingsNotificationsStreak => 'Przypomnienie o serii';

  @override
  String get settingsNotificationsStreakHint =>
      'Wieczorem, gdy seria dziś by się skończyła';

  @override
  String get settingsPassword => 'Hasło';

  @override
  String get settingsPasswordChanged => 'Hasło zmienione';

  @override
  String get settingsPasswordConfirmsNote => 'Hasło potwierdza, że to ty.';

  @override
  String get settingsPasswordCurrent => 'Obecne hasło';

  @override
  String get settingsPasswordDescription =>
      'Wybierz hasło, którego nie używasz nigdzie indziej';

  @override
  String get settingsPasswordForgot => 'Nie pamiętasz hasła?';

  @override
  String get settingsPasswordGoogleDescription => 'Logujesz się przez Google';

  @override
  String get settingsPasswordGoogleNote =>
      'Twoje konto nie ma hasła do Later: to Google potwierdza, że to ty. Hasło zmienisz na koncie Google.';

  @override
  String settingsPasswordNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nowe hasło (min. $count znaku)',
      many: 'Nowe hasło (min. $count znaków)',
      few: 'Nowe hasło (min. $count znaki)',
      one: 'Nowe hasło (min. $count znak)',
    );
    return '$_temp0';
  }

  @override
  String get settingsPasswordRepeat => 'Powtórz nowe hasło';

  @override
  String get settingsPasswordResetFailed =>
      'Nie udało się wysłać linku. Spróbuj ponownie.';

  @override
  String settingsPasswordResetSent(String email) {
    return 'Wysłaliśmy link do resetu hasła na $email';
  }

  @override
  String get settingsPermissionCamera => 'Aparat';

  @override
  String get settingsPermissionCameraDescription =>
      'Dostęp do aparatu, by tworzyć kapsuły czasu';

  @override
  String get settingsPermissionContacts => 'Kontakty';

  @override
  String get settingsPermissionContactsDescription =>
      'Zapraszaj znajomych i znajduj osoby, które znasz';

  @override
  String get settingsPermissionDenied => 'Odrzucone';

  @override
  String get settingsPermissionGranted => 'Przyznane';

  @override
  String get settingsPermissionLimited => 'Częściowe';

  @override
  String get settingsPermissionLocation => 'Lokalizacja';

  @override
  String get settingsPermissionLocationDescription =>
      'Kapsuły w pobliżu i funkcje oparte na lokalizacji';

  @override
  String get settingsPermissionMicrophone => 'Mikrofon';

  @override
  String get settingsPermissionMicrophoneDescription =>
      'Nagrywanie dźwięku do kapsuł czasu';

  @override
  String get settingsPermissionNotificationsDescription =>
      'Informacje o obserwujących i kapsułach';

  @override
  String get settingsPermissionOpenSettings => 'Otwórz ustawienia';

  @override
  String get settingsPermissionPermanentlyDenied => 'Trwale odrzucone';

  @override
  String get settingsPermissionProvisional => 'Tymczasowe';

  @override
  String get settingsPermissionRequiredBody =>
      'To uprawnienie zostało trwale odrzucone. Włącz je w ustawieniach urządzenia.';

  @override
  String get settingsPermissionRequiredTitle => 'Potrzebne uprawnienie';

  @override
  String get settingsPermissionRestricted => 'Ograniczone';

  @override
  String get settingsPermissionRevokeBody =>
      'Aby cofnąć to uprawnienie, przejdź do ustawień urządzenia. Powiązane funkcje aplikacji przestaną działać.';

  @override
  String get settingsPermissionRevokeTitle => 'Cofnij uprawnienie';

  @override
  String get settingsPermissionsDescription =>
      'Z czego Later może korzystać na tym telefonie';

  @override
  String get settingsPrivacy => 'Prywatność';

  @override
  String get settingsPrivacyAchievements => 'Pokazuj moje osiągnięcia';

  @override
  String get settingsPrivacyAchievementsHint =>
      'Znajomi widzą je w twoim profilu';

  @override
  String get settingsPrivacyApproximate => 'Przybliżona lokalizacja';

  @override
  String get settingsPrivacyApproximateHint =>
      'Nowe kapsuły trafiają w promieniu około kilometra, a nie w dokładne miejsce';

  @override
  String get settingsPrivacyDescription =>
      'Co widzą inni i jakie będą nowe kapsuły';

  @override
  String get settingsPrivacyNewCapsulesFooter =>
      'Oba ustawienia możesz zmienić dla każdej kapsuły przy tworzeniu.';

  @override
  String get settingsPrivacyReadReceipts => 'Potwierdzenia przeczytania';

  @override
  String get settingsPrivacyReadReceiptsHint =>
      'Po wyłączeniu znajomi nie zobaczą, kiedy przeczytasz ich wiadomości, a ty nie zobaczysz tego u nich';

  @override
  String get settingsPrivacyVisibility => 'Kto widzi';

  @override
  String get settingsQuietFrom => 'Cisza od';

  @override
  String get settingsQuietHours => 'Godziny ciszy';

  @override
  String get settingsQuietHoursFooter =>
      'W tych godzinach nie ma powiadomień push. Wiadomości i tak trafią do aplikacji.';

  @override
  String get settingsQuietHoursFrom => 'Od';

  @override
  String get settingsQuietHoursUntil => 'Do';

  @override
  String get settingsQuietUntil => 'Cisza do';

  @override
  String get settingsSectionAccount => 'MOJE KONTO';

  @override
  String get settingsSectionCamera => 'APARAT';

  @override
  String get settingsSectionContact => 'KONTAKT';

  @override
  String get settingsSectionHow => 'JAK';

  @override
  String get settingsSectionMap => 'MAPA';

  @override
  String get settingsSectionMoreActivity => 'AKTYWNOŚĆ';

  @override
  String get settingsSectionNewCapsules => 'NOWE KAPSUŁY';

  @override
  String get settingsSectionNotificationsPrivacy =>
      'POWIADOMIENIA I PRYWATNOŚĆ';

  @override
  String get settingsSectionNotifyAbout => 'O CZYM POWIADAMIAĆ';

  @override
  String get settingsSectionQuestions => 'PYTANIA';

  @override
  String get settingsSectionQuietHours => 'GODZINY CISZY';

  @override
  String get settingsSectionSize => 'ROZMIAR';

  @override
  String get settingsSectionSupport => 'WSPARCIE';

  @override
  String get settingsSectionTheme => 'MOTYW';

  @override
  String get settingsSectionThisPhone => 'TEN TELEFON';

  @override
  String get settingsSectionVisibility => 'CO WIDZĄ INNI';

  @override
  String get settingsSignedInWithGoogle => 'Logowanie przez Google';

  @override
  String get settingsSizeFooter =>
      'Zmniejsza lub powiększa wszystko na ekranie, także tekst.';

  @override
  String get settingsSizeLarge => 'Duży';

  @override
  String get settingsSizeSmall => 'Mały';

  @override
  String get settingsSizeStandard => 'Standardowy';

  @override
  String get settingsStorageCache => 'Pamięć podręczna';

  @override
  String get settingsStorageClear => 'Wyczyść';

  @override
  String get settingsStorageClearCache => 'Wyczyść pamięć podręczną';

  @override
  String get settingsStorageClearConfirm =>
      'Wyczyścić pamięć podręczną? Obrazy wczytają się ponownie, gdy będą potrzebne.';

  @override
  String get settingsStorageCleared => 'Pamięć podręczna wyczyszczona';

  @override
  String get settingsStorageClearing => 'Czyszczenie...';

  @override
  String get settingsStorageDescription =>
      'Miejsce, które Later zajmuje na tym telefonie';

  @override
  String get settingsStorageFooter =>
      'Zdjęcia zrobione lub wybrane do kapsuł i obrazy pobrane z internetu. Twoje kapsuły, czaty i konto zostaną.';

  @override
  String settingsSupportInfoApp(String version) {
    return 'Aplikacja: Later $version';
  }

  @override
  String settingsSupportInfoPhone(String system) {
    return 'Telefon: $system';
  }

  @override
  String settingsSupportInfoUserId(String uid) {
    return 'ID użytkownika: $uid';
  }

  @override
  String get settingsThemeDark => 'Ciemny';

  @override
  String get settingsThemeLight => 'Jasny';

  @override
  String get settingsThemeSystem => 'Jak w telefonie';

  @override
  String get settingsTitle => 'Ustawienia';

  @override
  String get settingsUnblock => 'Odblokuj';

  @override
  String get settingsUnblocking => 'Odblokowywanie...';

  @override
  String get settingsUsername => 'Nazwa użytkownika';

  @override
  String get settingsUsernameDescription =>
      'Po niej znajomi znajdą cię i dodadzą w Later';

  @override
  String get settingsUsernameHint => 'Nowa nazwa użytkownika';

  @override
  String get settingsUsernameUpdated => 'Nazwa użytkownika zaktualizowana!';

  @override
  String get settingsVisibilityFriends => 'Dla znajomych';

  @override
  String get settingsVisibilityFriendsHint => 'Tylko twoi znajomi';

  @override
  String get settingsVisibilityPrivate => 'Prywatna';

  @override
  String get settingsVisibilityPrivateHint => 'Tylko ty';

  @override
  String get settingsVisibilityPublic => 'Publiczna';

  @override
  String get settingsVisibilityPublicHint => 'Wszyscy na mapie';

  @override
  String get settingsYourPassword => 'Twoje hasło';
}
