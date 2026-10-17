// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Later';

  @override
  String get commonBack => 'Zurück';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonClose => 'Schließen';

  @override
  String get commonConfirm => 'Bestätigen';

  @override
  String get commonContinue => 'Weiter';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonDone => 'Fertig';

  @override
  String get commonErrorGeneric =>
      'Etwas ist schiefgelaufen. Bitte versuche es erneut.';

  @override
  String get commonLoading => 'Wird geladen...';

  @override
  String get commonNoConnection =>
      'Keine Verbindung. Bitte versuche es erneut.';

  @override
  String get commonRetry => 'Erneut versuchen';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonSearchHint => 'Suchen...';

  @override
  String get commonUnknownUser => 'Unbekannter Nutzer';

  @override
  String get commonUnknownUsername => 'unbekannt';

  @override
  String get failureNotFound => 'Dieses Element gibt es nicht mehr.';

  @override
  String get failurePermission => 'Das darfst du nicht.';

  @override
  String get messagesBlockedByYou => 'Du hast diesen Nutzer blockiert';

  @override
  String get messagesCantSend =>
      'Du kannst diesem Nutzer keine Nachrichten senden';

  @override
  String get messagesCapsuleLabel => 'Kapsel';

  @override
  String get messagesCapsuleUnavailable =>
      'Diese Kapsel ist nicht mehr verfügbar';

  @override
  String get messagesChatFallbackTitle => 'Chat';

  @override
  String get messagesChatOptions => 'Chat-Optionen';

  @override
  String get messagesChatsLoadError =>
      'Deine Chats konnten nicht geladen werden';

  @override
  String get messagesCheckConnection =>
      'Prüf deine Verbindung und versuch es noch mal';

  @override
  String get messagesClearConfirm => 'Löschen';

  @override
  String get messagesClearConfirmTitle =>
      'Möchtest du den Chatverlauf wirklich löschen?';

  @override
  String get messagesClearFailed => 'Verlauf konnte nicht gelöscht werden';

  @override
  String messagesEmptySubtitle(String name) {
    return 'Sag $name Hallo!';
  }

  @override
  String get messagesEmptyTitle => 'Noch keine Nachrichten';

  @override
  String get messagesFindChatsHint => 'Chats suchen';

  @override
  String get messagesInputHint => 'Schreib eine Nachricht...';

  @override
  String get messagesLoadError =>
      'Die Nachrichten konnten nicht geladen werden';

  @override
  String get messagesMenuBlock => 'Nutzer blockieren';

  @override
  String get messagesMenuClearHistory => 'Verlauf löschen';

  @override
  String get messagesMenuMute => 'Stummschalten';

  @override
  String get messagesMenuSearch => 'Suchen';

  @override
  String get messagesMenuUnblock => 'Blockierung aufheben';

  @override
  String get messagesMenuUnmute => 'Stummschaltung aufheben';

  @override
  String get messagesMutedToast => 'Chat stummgeschaltet';

  @override
  String get messagesNewChatFindFriends => 'Freunde finden';

  @override
  String get messagesNewChatNoFriends => 'Noch keine Freunde';

  @override
  String get messagesNewChatNoFriendsSubtitle =>
      'Füge Freunde hinzu und leg los mit dem Chatten!';

  @override
  String get messagesNewChatNoMatch => 'Keine Freunde gefunden';

  @override
  String get messagesNewChatSearchHint => 'Freunde suchen';

  @override
  String get messagesNewChatTitle => 'Neuer Chat';

  @override
  String get messagesNoChatsFound => 'Keine Chats gefunden';

  @override
  String get messagesNoChatsSubtitle =>
      'Tippe auf den Button für eine neue Nachricht und chatte mit deinen Freunden!';

  @override
  String get messagesNoChatsTitle => 'Noch keine Unterhaltungen';

  @override
  String get messagesNoMatchTitle => 'Keine Nachrichten gefunden';

  @override
  String messagesNothingMatches(String query) {
    return 'Keine Treffer für „$query“';
  }

  @override
  String get messagesNotificationsMuted => 'Stummgeschaltet';

  @override
  String messagesOpenCapsule(String title) {
    return 'Kapsel „$title“ öffnen';
  }

  @override
  String get messagesReceiptFailed => 'Nicht gesendet · Tippen zum Wiederholen';

  @override
  String get messagesReceiptRead => 'Gelesen';

  @override
  String get messagesReceiptSending => 'Wird gesendet…';

  @override
  String get messagesReceiptSent => 'Gesendet';

  @override
  String get messagesScrollToLatest => 'Zur neuesten Nachricht scrollen';

  @override
  String get messagesSearchHint => 'Nachrichten suchen';

  @override
  String get messagesSend => 'Senden';

  @override
  String get messagesSendCapsule => 'Kapsel senden';

  @override
  String get messagesSendFailed => 'Nachricht konnte nicht gesendet werden';

  @override
  String get messagesSignedOut => 'Du bist abgemeldet';

  @override
  String messagesStartChatWith(String name) {
    return 'Chat mit $name starten';
  }

  @override
  String get messagesTitle => 'Meine Laters';

  @override
  String get messagesToday => 'Heute';

  @override
  String get messagesTooLong => 'Diese Nachricht ist zu lang';

  @override
  String get messagesUnmutedToast => 'Stummschaltung aufgehoben';

  @override
  String get messagesYesterday => 'Gestern';

  @override
  String messagesYouPrefix(String message) {
    return 'Du: $message';
  }

  @override
  String get placeNoLocation => 'Kein Standort';

  @override
  String get placeUnknown => 'Unbekannter Ort';
}
