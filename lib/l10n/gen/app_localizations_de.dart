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
  String get placeNoLocation => 'Kein Standort';

  @override
  String get placeUnknown => 'Unbekannter Ort';

  @override
  String get settingsAbout => 'Über die App';

  @override
  String get settingsAboutLicenses => 'Open-Source-Lizenzen';

  @override
  String get settingsAboutOpenFailed => 'Die Seite ließ sich nicht öffnen.';

  @override
  String get settingsAboutPrivacy => 'Datenschutzerklärung';

  @override
  String get settingsAboutTerms => 'Nutzungsbedingungen';

  @override
  String get settingsAboutVersion => 'Version';

  @override
  String get settingsAboutVersionUnknown => 'unbekannt';

  @override
  String get settingsAppPermissions => 'App-Berechtigungen';

  @override
  String settingsBlockedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count blockiert',
      one: '$count blockiert',
    );
    return '$_temp0';
  }

  @override
  String get settingsBlockedDescription =>
      'Sie können dir nicht schreiben und keine Freundschaftsanfragen schicken';

  @override
  String get settingsBlockedEmpty => 'Du hast niemanden blockiert';

  @override
  String get settingsBlockedEmptyHint =>
      'Blockieren kannst du über ein Profil\noder in einem Chat';

  @override
  String get settingsBlockedNobody => 'Niemand';

  @override
  String get settingsBlockedUsers => 'Blockierte Nutzer';

  @override
  String get settingsCameraBack => 'Rückkamera';

  @override
  String get settingsCameraFooter =>
      'Die Kamera, die sich öffnet, wenn du eine Kapsel erstellst.';

  @override
  String get settingsCameraFront => 'Frontkamera';

  @override
  String get settingsCompleteProfileDescription =>
      'Wähle, wie deine Freunde dich sehen';

  @override
  String settingsCompleteProfileNoProfile(String email) {
    return 'Dein Konto $email hat noch kein Profil.';
  }

  @override
  String get settingsCompleteProfileTitle => 'Fast geschafft';

  @override
  String get settingsCustomizeDescription =>
      'Tippe auf ein Bild, um es zu ändern';

  @override
  String get settingsCustomizeProfile => 'Profil anpassen';

  @override
  String get settingsDataAndStorage => 'Daten und Speicher';

  @override
  String get settingsDeleteAccount => 'Konto löschen';

  @override
  String get settingsDeleteButton => 'Mein Konto löschen';

  @override
  String get settingsDeleteConfirm =>
      'Konto löschen? Das kann nicht rückgängig gemacht werden.';

  @override
  String get settingsDeleteDescription => 'Entfernt dein Konto und alles darin';

  @override
  String get settingsDeleteNote =>
      'Wenn du dein Konto löschst, verschwinden dein Profil, deine Bilder, Kapseln, Chats, Freunde und Follower. Deine Freunde sehen dich und deine Nachrichten dann nicht mehr. Das kann nicht rückgängig gemacht werden.';

  @override
  String get settingsDeletedAccount => 'Gelöschtes Konto';

  @override
  String get settingsDeviceDescription =>
      'Wie Later auf diesem Handy aussieht und funktioniert';

  @override
  String get settingsEmail => 'E-Mail';

  @override
  String settingsEmailDescription(String email) {
    return 'Du meldest dich bei Later mit $email an';
  }

  @override
  String settingsEmailGoogleDescription(String email) {
    return 'Du meldest dich mit Google als $email an';
  }

  @override
  String get settingsEmailGoogleNote =>
      'Deine E-Mail-Adresse kommt aus deinem Google-Konto. Wenn du eine andere nutzen willst, ändere sie dort.';

  @override
  String settingsEmailLinkSent(String newEmail, String currentEmail) {
    return 'Wir haben einen Link an $newEmail geschickt. Öffne ihn zur Bestätigung, dann ändert sich deine E-Mail-Adresse. Bis dahin meldest du dich weiter mit $currentEmail an.';
  }

  @override
  String get settingsEmailNewHint => 'Neue E-Mail-Adresse';

  @override
  String get settingsEmailSendLink => 'Link senden';

  @override
  String get settingsErrorChatUpdateFailed =>
      'Chat konnte nicht aktualisiert werden.';

  @override
  String get settingsErrorCouldNotSave =>
      'Speichern hat nicht geklappt. Versuch es noch mal.';

  @override
  String get settingsErrorCurrentPassword => 'Gib dein aktuelles Passwort ein.';

  @override
  String get settingsErrorEnterName => 'Gib deinen Namen ein.';

  @override
  String get settingsErrorEnterNewName => 'Gib einen neuen Namen ein!';

  @override
  String get settingsErrorEnterNewUsername =>
      'Gib einen neuen Benutzernamen ein!';

  @override
  String get settingsErrorEnterPassword => 'Gib dein Passwort ein.';

  @override
  String get settingsErrorInvalidEmail =>
      'Gib eine gültige E-Mail-Adresse ein.';

  @override
  String get settingsErrorNameFailed => 'Name konnte nicht geändert werden!';

  @override
  String get settingsErrorPasswordSame =>
      'Das neue Passwort ist dasselbe wie das aktuelle.';

  @override
  String settingsErrorPasswordTooShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Das neue Passwort braucht mindestens $count Zeichen.',
      one: 'Das neue Passwort braucht mindestens $count Zeichen.',
    );
    return '$_temp0';
  }

  @override
  String get settingsErrorPasswordsMismatch =>
      'Die neuen Passwörter stimmen nicht überein.';

  @override
  String get settingsErrorSameEmail => 'Das ist schon deine E-Mail-Adresse.';

  @override
  String get settingsErrorSaveFailed =>
      'Einstellungen konnten nicht gespeichert werden.';

  @override
  String get settingsErrorSignInAgain => 'Bitte melde dich erneut an.';

  @override
  String get settingsErrorUsernameFailed =>
      'Benutzername konnte nicht geändert werden!';

  @override
  String get settingsFaqBlockAnswer =>
      'Blockiere die Person über ihr Profil oder das Chat-Menü. Aufheben kannst du das unter Einstellungen > Blockierte Nutzer.';

  @override
  String get settingsFaqBlockQuestion =>
      'Wie verhindere ich, dass mich jemand kontaktiert?';

  @override
  String get settingsFaqCapsuleAnswer =>
      'Ein Foto mit Titel und Notiz, angepinnt auf der Karte genau dort, wo du es gemacht hast. Du kannst ein Datum festlegen: Bis dahin bleibt die Kapsel verschlossen.';

  @override
  String get settingsFaqCapsuleQuestion => 'Was ist eine Kapsel?';

  @override
  String get settingsFaqDeleteAnswer =>
      'Einstellungen > Konto löschen. Alles, was du erstellt hast, wird gelöscht und lässt sich nicht wiederherstellen.';

  @override
  String get settingsFaqDeleteQuestion => 'Wie lösche ich mein Konto?';

  @override
  String get settingsFaqFriendsAnswer =>
      'Such unter Freunde nach dem Benutzernamen, scanne den QR-Code der Person oder teile den Link zu deinem Profil.';

  @override
  String get settingsFaqFriendsQuestion => 'Wie füge ich Freunde hinzu?';

  @override
  String get settingsFaqNotificationsAnswer =>
      'Schau unter Einstellungen > Benachrichtigungen nach: Dein Handy muss Later Benachrichtigungen erlauben und Push-Benachrichtigungen müssen an sein. Auch Ruhezeiten und stummgeschaltete Chats halten Pushes zurück.';

  @override
  String get settingsFaqNotificationsQuestion =>
      'Ich bekomme keine Benachrichtigungen';

  @override
  String get settingsFaqVisibilityAnswer =>
      'Das legst du beim Erstellen fest: nur du (Privat), deine Freunde (Freunde) oder alle (Öffentlich).';

  @override
  String get settingsFaqVisibilityQuestion => 'Wer kann meine Kapseln sehen?';

  @override
  String get settingsGoogleConfirmsNote =>
      'Google bestätigt, dass du es bist: Wähle dein Konto aus, wenn du gefragt wirst.';

  @override
  String get settingsHelp => 'Hilfe';

  @override
  String settingsHelpContactFooter(String email) {
    return 'E-Mails aus der App enthalten deine App-Version und Infos zu deinem Handy. Du kannst uns auch an $email schreiben.';
  }

  @override
  String get settingsHelpContactSupport => 'Support kontaktieren';

  @override
  String get settingsHelpCopied =>
      'Kopiert. Füg es in deine Nachricht an uns ein.';

  @override
  String get settingsHelpCopyInfo => 'App-Infos kopieren';

  @override
  String get settingsHelpDescription => 'Antworten und Kontakt zu uns';

  @override
  String settingsHelpNoEmailApp(String email) {
    return 'Keine E-Mail-App gefunden. Schreib uns an $email';
  }

  @override
  String get settingsHelpReportProblem => 'Problem melden';

  @override
  String get settingsHelpSubjectProblem => 'Later: Problembericht';

  @override
  String get settingsHelpSubjectQuestion => 'Later: Frage';

  @override
  String get settingsLogOut => 'Abmelden';

  @override
  String get settingsLogOutConfirm => 'Willst du dich wirklich abmelden?';

  @override
  String get settingsMapAndCamera => 'Karte und Kamera';

  @override
  String get settingsMapLookHybrid => 'Satellit mit Beschriftung';

  @override
  String get settingsMapLookSatellite => 'Satellit';

  @override
  String get settingsMapLookStandard => 'Standard';

  @override
  String get settingsName => 'Name';

  @override
  String get settingsNameDescription =>
      'So wirst du auf Later angezeigt. Wähle einen Namen, an dem dich deine Freunde erkennen';

  @override
  String get settingsNameHint => 'Neuer Name';

  @override
  String get settingsNameUpdated => 'Name geändert!';

  @override
  String get settingsNotifications => 'Benachrichtigungen';

  @override
  String get settingsNotificationsAllow => 'Benachrichtigungen erlauben';

  @override
  String get settingsNotificationsBlockedFooter =>
      'Dein Handy erlaubt Later keine Benachrichtigungen. Deshalb kommt keine an, egal was du unten auswählst.';

  @override
  String get settingsNotificationsCapsules => 'Neue Kapseln';

  @override
  String get settingsNotificationsCapsulesHint =>
      'Von Leuten, denen du mit Benachrichtigungen folgst';

  @override
  String get settingsNotificationsDescription =>
      'Wähle, worüber Later dich informiert';

  @override
  String get settingsNotificationsFollowers => 'Neue Follower';

  @override
  String get settingsNotificationsMessages => 'Nachrichten';

  @override
  String get settingsNotificationsMuteHint =>
      'Einzelne Chats schaltest du über ihr Menü in Nachrichten stumm.';

  @override
  String get settingsNotificationsOff => 'Aus';

  @override
  String get settingsNotificationsOffInPhone =>
      'In den Handy-Einstellungen aus';

  @override
  String get settingsNotificationsOn => 'An';

  @override
  String get settingsNotificationsPreview => 'Nachrichtentext anzeigen';

  @override
  String get settingsNotificationsPreviewOff =>
      'Pushes zeigen nur „Neue Nachricht“';

  @override
  String get settingsNotificationsPush => 'Push-Benachrichtigungen';

  @override
  String get settingsNotificationsPushOff =>
      'Du bekommst keine Pushes von Later';

  @override
  String get settingsNotificationsSound => 'Ton und Vibration';

  @override
  String get settingsPassword => 'Passwort';

  @override
  String get settingsPasswordChanged => 'Passwort geändert';

  @override
  String get settingsPasswordConfirmsNote =>
      'Dein Passwort bestätigt, dass du es bist.';

  @override
  String get settingsPasswordCurrent => 'Aktuelles Passwort';

  @override
  String get settingsPasswordDescription =>
      'Wähle ein Passwort, das du sonst nirgends nutzt';

  @override
  String get settingsPasswordForgot => 'Passwort vergessen?';

  @override
  String get settingsPasswordGoogleDescription =>
      'Du meldest dich mit Google an';

  @override
  String get settingsPasswordGoogleNote =>
      'Dein Konto hat kein Later-Passwort: Google bestätigt, dass du es bist. Dein Passwort änderst du in deinem Google-Konto.';

  @override
  String settingsPasswordNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Neues Passwort (mind. $count Zeichen)',
      one: 'Neues Passwort (mind. $count Zeichen)',
    );
    return '$_temp0';
  }

  @override
  String get settingsPasswordRepeat => 'Neues Passwort wiederholen';

  @override
  String get settingsPasswordResetFailed =>
      'Der Link konnte nicht gesendet werden. Versuch es noch mal.';

  @override
  String settingsPasswordResetSent(String email) {
    return 'Wir haben einen Link zum Zurücksetzen an $email geschickt';
  }

  @override
  String get settingsPermissionCamera => 'Kamera';

  @override
  String get settingsPermissionCameraDescription =>
      'Kamerazugriff, um Zeitkapseln zu erstellen';

  @override
  String get settingsPermissionContacts => 'Kontakte';

  @override
  String get settingsPermissionContactsDescription =>
      'Freunde einladen und Leute finden, die du kennst';

  @override
  String get settingsPermissionDenied => 'Abgelehnt';

  @override
  String get settingsPermissionGranted => 'Erlaubt';

  @override
  String get settingsPermissionLimited => 'Begrenzt';

  @override
  String get settingsPermissionLocation => 'Standort';

  @override
  String get settingsPermissionLocationDescription =>
      'Kapseln in der Nähe und standortbasierte Funktionen';

  @override
  String get settingsPermissionMicrophone => 'Mikrofon';

  @override
  String get settingsPermissionMicrophoneDescription =>
      'Ton für Zeitkapseln aufnehmen';

  @override
  String get settingsPermissionNotificationsDescription =>
      'Neuigkeiten zu Followern und Kapseln';

  @override
  String get settingsPermissionOpenSettings => 'Einstellungen öffnen';

  @override
  String get settingsPermissionPermanentlyDenied => 'Dauerhaft abgelehnt';

  @override
  String get settingsPermissionProvisional => 'Vorläufig';

  @override
  String get settingsPermissionRequiredBody =>
      'Diese Berechtigung wurde dauerhaft abgelehnt. Aktiviere sie in den Einstellungen deines Geräts.';

  @override
  String get settingsPermissionRequiredTitle => 'Berechtigung nötig';

  @override
  String get settingsPermissionRestricted => 'Eingeschränkt';

  @override
  String get settingsPermissionRevokeBody =>
      'Um diese Berechtigung zu entziehen, geh in die Einstellungen deines Geräts. Die zugehörigen Funktionen der App sind dann aus.';

  @override
  String get settingsPermissionRevokeTitle => 'Berechtigung entziehen';

  @override
  String get settingsPermissionsDescription =>
      'Was Later auf diesem Handy nutzen darf';

  @override
  String get settingsQuietFrom => 'Ruhe ab';

  @override
  String get settingsQuietHours => 'Ruhezeiten';

  @override
  String get settingsQuietHoursFooter =>
      'In dieser Zeit gibt es keine Pushes. Nachrichten kommen trotzdem in der App an.';

  @override
  String get settingsQuietHoursFrom => 'Von';

  @override
  String get settingsQuietHoursUntil => 'Bis';

  @override
  String get settingsQuietUntil => 'Ruhe bis';

  @override
  String get settingsSectionAccount => 'MEIN KONTO';

  @override
  String get settingsSectionCamera => 'KAMERA';

  @override
  String get settingsSectionContact => 'KONTAKT';

  @override
  String get settingsSectionHow => 'WIE';

  @override
  String get settingsSectionMap => 'KARTE';

  @override
  String get settingsSectionNotificationsPrivacy =>
      'BENACHRICHTIGUNGEN & DATENSCHUTZ';

  @override
  String get settingsSectionNotifyAbout => 'BENACHRICHTIGEN BEI';

  @override
  String get settingsSectionQuestions => 'FRAGEN';

  @override
  String get settingsSectionQuietHours => 'RUHEZEITEN';

  @override
  String get settingsSectionSupport => 'SUPPORT';

  @override
  String get settingsSectionThisPhone => 'DIESES HANDY';

  @override
  String get settingsSignedInWithGoogle => 'Angemeldet mit Google';

  @override
  String get settingsStorageCache => 'Cache';

  @override
  String get settingsStorageClear => 'Leeren';

  @override
  String get settingsStorageClearCache => 'Cache leeren';

  @override
  String get settingsStorageClearConfirm =>
      'Cache leeren? Bilder werden wieder geladen, wenn du sie brauchst.';

  @override
  String get settingsStorageCleared => 'Cache geleert';

  @override
  String get settingsStorageClearing => 'Wird geleert...';

  @override
  String get settingsStorageDescription =>
      'Speicherplatz, den Later auf diesem Handy belegt';

  @override
  String get settingsStorageFooter =>
      'Fotos, die du für Kapseln aufgenommen oder ausgewählt hast, und Bilder aus dem Internet. Deine Kapseln, Chats und dein Konto bleiben erhalten.';

  @override
  String settingsSupportInfoApp(String version) {
    return 'App: Later $version';
  }

  @override
  String settingsSupportInfoPhone(String system) {
    return 'Handy: $system';
  }

  @override
  String settingsSupportInfoUserId(String uid) {
    return 'Nutzer-ID: $uid';
  }

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsUnblock => 'Blockierung aufheben';

  @override
  String get settingsUnblocking => 'Wird aufgehoben...';

  @override
  String get settingsUsername => 'Benutzername';

  @override
  String get settingsUsernameDescription =>
      'Darüber finden dich deine Freunde auf Later und fügen dich hinzu';

  @override
  String get settingsUsernameHint => 'Neuer Benutzername';

  @override
  String get settingsUsernameUpdated => 'Benutzername geändert!';

  @override
  String get settingsYourPassword => 'Dein Passwort';
}
