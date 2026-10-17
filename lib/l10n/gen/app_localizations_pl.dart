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
  String get commonUnknownUser => 'Nieznany użytkownik';

  @override
  String get commonUnknownUsername => 'nieznany';

  @override
  String get failureNotFound => 'Ten element już nie istnieje.';

  @override
  String get failurePermission => 'Nie masz uprawnień do tej czynności.';

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
  String get placeNoLocation => 'Brak lokalizacji';

  @override
  String get placeUnknown => 'Nieznane miejsce';
}
