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
