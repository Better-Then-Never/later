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
  String get authContinueWithGoogle => 'Weiter mit Google';

  @override
  String get authEmailHint => 'E-Mail';

  @override
  String get authEnterEmail => 'Bitte gib deine E-Mail-Adresse ein';

  @override
  String get authErrorEmailInUse =>
      'Für diese E-Mail-Adresse gibt es bereits ein Konto.';

  @override
  String get authErrorEmailTaken =>
      'Diese E-Mail-Adresse wird schon von einem anderen Konto verwendet.';

  @override
  String get authErrorInvalidCredential => 'E-Mail oder Passwort ist falsch.';

  @override
  String get authErrorInvalidEmail => 'Die E-Mail-Adresse ist ungültig.';

  @override
  String get authErrorMethodDisabled =>
      'Diese Anmeldemethode ist nicht aktiviert.';

  @override
  String get authErrorPickGoogleAccount =>
      'Bitte wähle das Google-Konto, mit dem du dich anmeldest.';

  @override
  String get authErrorRecentLogin =>
      'Bitte bestätige, dass du es bist, und versuche es erneut.';

  @override
  String get authErrorTooManyRequests =>
      'Zu viele Versuche. Bitte versuche es später erneut.';

  @override
  String get authErrorUserDisabled => 'Dieses Konto wurde deaktiviert.';

  @override
  String get authErrorUserNotFound =>
      'Kein Nutzer mit dieser E-Mail-Adresse gefunden.';

  @override
  String get authErrorWeakPassword => 'Das Passwort ist zu schwach.';

  @override
  String authErrorWithMessage(String message) {
    return 'Fehler: $message';
  }

  @override
  String get authErrorWrongPassword => 'Falsches Passwort.';

  @override
  String get authErrorWrongPasswordProvided => 'Das Passwort ist falsch.';

  @override
  String get authFacebookSoon => 'Facebook (bald verfügbar)';

  @override
  String get authFillAllFields => 'Bitte fülle alle Felder aus';

  @override
  String get authForgotPassword => 'Passwort vergessen?';

  @override
  String get authGetStarted => 'Los geht\'s';

  @override
  String get authGoToLogIn => 'Anmelden';

  @override
  String get authGoToSignUp => 'Registrieren';

  @override
  String get authGoogleFailed =>
      'Anmeldung mit Google fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String get authHaveAccount => 'Du hast schon ein Konto?';

  @override
  String get authHidePassword => 'Passwort verbergen';

  @override
  String authLegalNotice(String terms, String privacy) {
    return 'Mit der Registrierung stimmst du den $terms und der $privacy zu';
  }

  @override
  String get authLinkOpenFailed => 'Die Seite konnte nicht geöffnet werden.';

  @override
  String get authLogInButton => 'Anmelden';

  @override
  String get authLoginSubtitle => 'Melde dich an, um die App weiter zu nutzen';

  @override
  String get authLoginTitle => 'Jetzt anmelden';

  @override
  String get authNameHint => 'Name';

  @override
  String get authNoAccount => 'Noch kein Konto?';

  @override
  String get authNoFreeUsername =>
      'Wir konnten keinen Benutzernamen wählen. Bitte registriere dich.';

  @override
  String get authOrConnectWith => 'Oder weiter mit';

  @override
  String get authPasswordHint => 'Passwort';

  @override
  String get authPermissionCameraText =>
      'Dann kannst du Zeitkapseln erstellen!';

  @override
  String get authPermissionCameraTitle => 'Gib Later Zugriff auf die Kamera';

  @override
  String get authPermissionContactsText =>
      'Finde Freunde in deinen Kontakten und lade sie ein!';

  @override
  String get authPermissionContactsTitle => 'Zugriff auf Kontakte';

  @override
  String get authPermissionEnable => 'Erlauben';

  @override
  String get authPermissionGranted => 'Erlaubt';

  @override
  String get authPermissionLocationText =>
      'Dann findest du Kapseln in deiner Nähe!';

  @override
  String get authPermissionLocationTitle => 'Teile deinen Standort mit uns';

  @override
  String get authPermissionMicrophoneText =>
      'Ohne Mikrofon funktioniert die Kamera nicht';

  @override
  String get authPermissionMicrophoneTitle => 'Gib Later Zugriff aufs Mikrofon';

  @override
  String get authPermissionNotificationsText =>
      'Erfahre von neuen Followern und Kapseln!';

  @override
  String get authPermissionNotificationsTitle => 'Aktiviere Benachrichtigungen';

  @override
  String get authPrivacyPolicy => 'Datenschutzerklärung';

  @override
  String get authResetDescription =>
      'Gib deine E-Mail-Adresse ein, dann schicken wir dir einen Link zum Zurücksetzen';

  @override
  String get authResetInvalidEmail => 'Ungültige E-Mail-Adresse';

  @override
  String get authResetSend => 'Link senden';

  @override
  String get authResetSent =>
      'E-Mail zum Zurücksetzen gesendet! Schau in dein Postfach.';

  @override
  String get authResetTitle => 'Passwort zurücksetzen';

  @override
  String get authResetUserNotFound =>
      'Kein Konto mit dieser E-Mail-Adresse gefunden';

  @override
  String get authShowPassword => 'Passwort anzeigen';

  @override
  String get authSignInAgain => 'Bitte melde dich erneut an.';

  @override
  String get authSignUpButton => 'Registrieren';

  @override
  String get authSignupSubtitle =>
      'Gib deine Daten ein, um dein Konto zu erstellen';

  @override
  String get authSignupTitle => 'Jetzt registrieren';

  @override
  String get authTermsOfUse => 'Nutzungsbedingungen';

  @override
  String get authUsernameHint => 'Benutzername';

  @override
  String get authWelcomeSubtitle =>
      'Erstelle ein Konto, um deine Kapseln\nund die deiner Freunde zu sehen';

  @override
  String get authWelcomeTo => 'Willkommen bei';

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
