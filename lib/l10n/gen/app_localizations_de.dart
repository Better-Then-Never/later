// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get achievementAnimator => 'Animator';

  @override
  String achievementAnimatorGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Erstelle $count Loop-Kapseln',
      one: 'Erstelle 1 Loop-Kapsel',
    );
    return '$_temp0';
  }

  @override
  String get achievementChatterbox => 'Plaudertasche';

  @override
  String achievementChatterboxGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Schreibe $count Kommentare',
      one: 'Schreibe 1 Kommentar',
    );
    return '$_temp0';
  }

  @override
  String get achievementCollector => 'Sammler';

  @override
  String achievementCollectorGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Erstelle $count Kapseln',
      one: 'Erstelle 1 Kapsel',
    );
    return '$_temp0';
  }

  @override
  String get achievementCrowdPleaser => 'Publikumsliebling';

  @override
  String achievementCrowdPleaserGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Erhalte $count Reaktionen',
      one: 'Erhalte 1 Reaktion',
    );
    return '$_temp0';
  }

  @override
  String get achievementEarlyBird => 'Frühaufsteher';

  @override
  String achievementEarlyBirdGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Erstelle $count Kapseln zwischen 5 und 8 Uhr',
      one: 'Erstelle eine Kapsel zwischen 5 und 8 Uhr',
    );
    return '$_temp0';
  }

  @override
  String get achievementExplorer => 'Entdecker';

  @override
  String achievementExplorerGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hinterlasse Kapseln an $count verschiedenen Orten',
      one: 'Hinterlasse eine Kapsel an 1 Ort',
    );
    return '$_temp0';
  }

  @override
  String get achievementFirstCapsule => 'Erste Kapsel';

  @override
  String get achievementFirstCapsuleGoal => 'Erstelle deine erste Kapsel';

  @override
  String get achievementFriendly => 'Gesellig';

  @override
  String achievementFriendlyGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Finde $count Freunde',
      one: 'Finde 1 Freund',
    );
    return '$_temp0';
  }

  @override
  String get achievementNightOwl => 'Nachteule';

  @override
  String achievementNightOwlGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Erstelle $count Kapseln zwischen Mitternacht und 5 Uhr',
      one: 'Erstelle eine Kapsel zwischen Mitternacht und 5 Uhr',
    );
    return '$_temp0';
  }

  @override
  String get achievementOpenBook => 'Offenes Buch';

  @override
  String achievementOpenBookGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Teile $count öffentliche Kapseln',
      one: 'Teile 1 öffentliche Kapsel',
    );
    return '$_temp0';
  }

  @override
  String get achievementStreak => 'Feuer und Flamme';

  @override
  String achievementStreakGoal(int count) {
    return 'Halte eine Serie von $count Tagen';
  }

  @override
  String get achievementTraveler => 'Weltenbummler';

  @override
  String achievementTravelerGoal(String km) {
    return 'Lege $km km zwischen deinen Kapseln zurück';
  }

  @override
  String get achievementsDescription =>
      'Freigeschaltet durch Nutzung von Later, nie durch Bezahlen';

  @override
  String get achievementsLocked => 'Gesperrt';

  @override
  String get achievementsNoneYet => 'Dein erster ist nur eine Kapsel entfernt.';

  @override
  String get achievementsSeeAll => 'Alle';

  @override
  String achievementsStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Serie: $count Tage',
      one: 'Serie: 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get achievementsStreakKeep =>
      'Erstelle heute eine Kapsel, um sie zu halten';

  @override
  String get achievementsStreakTodayDone => 'Heute zählt schon';

  @override
  String achievementsTier(int tier, int tiers) {
    return 'Stufe $tier von $tiers';
  }

  @override
  String get achievementsTitle => 'Erfolge';

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
  String get authPermissionEnable => 'Erlauben';

  @override
  String get authPermissionLocationText =>
      'Dann findest du Kapseln in deiner Nähe!';

  @override
  String get authPermissionLocationTitle => 'Teile deinen Standort mit uns';

  @override
  String get authPermissionNotNow => 'Nicht jetzt';

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
  String capsulesBy(String name) {
    return 'Von $name';
  }

  @override
  String capsulesByWith(String name, String others) {
    return '$name mit $others';
  }

  @override
  String get capsulesCameraAccessDenied =>
      'Erlaube den Kamerazugriff in den Einstellungen, um ein Foto aufzunehmen';

  @override
  String get capsulesCameraExposure => 'Helligkeit';

  @override
  String get capsulesCameraFlashAuto => 'Blitz automatisch';

  @override
  String get capsulesCameraFlashAutoBadge => 'A';

  @override
  String get capsulesCameraFlashOff => 'Blitz aus';

  @override
  String get capsulesCameraFlashOn => 'Blitz an';

  @override
  String get capsulesCameraFlashTorch => 'Licht an';

  @override
  String get capsulesCameraFlashTorchBadge => 'L';

  @override
  String get capsulesCameraHoldForLoop => 'Halten für einen Loop';

  @override
  String get capsulesCameraModeLoop => 'Loop';

  @override
  String get capsulesCameraModePhoto => 'Foto';

  @override
  String get capsulesCameraStartFailed =>
      'Die Kamera konnte nicht gestartet werden';

  @override
  String get capsulesCameraStartLoop => 'Loop starten';

  @override
  String get capsulesCameraStopLoop => 'Loop stoppen';

  @override
  String get capsulesCameraSwitch => 'Kamera wechseln';

  @override
  String get capsulesCameraTakePhoto => 'Foto aufnehmen';

  @override
  String get capsulesCameraTakePhotoOrLoop =>
      'Foto aufnehmen. Halten für einen Loop';

  @override
  String get capsulesCameraTapForLoop =>
      'Tippen zum Starten, nochmal zum Stoppen';

  @override
  String get capsulesCameraUnavailable => 'Keine Kamera verfügbar';

  @override
  String capsulesCameraZoomTo(String zoom) {
    return 'Zoom $zoom×';
  }

  @override
  String get capsulesCoAuthorsDone => 'Fertig';

  @override
  String get capsulesCoAuthorsPick => 'Mit wem du sie gemacht hast';

  @override
  String capsulesCoAuthorsTooMany(int count) {
    return 'Höchstens $count Mitautoren';
  }

  @override
  String get capsulesColorBlue => 'Blau';

  @override
  String get capsulesColorGreen => 'Grün';

  @override
  String get capsulesColorOrange => 'Orange';

  @override
  String get capsulesColorPurple => 'Lila';

  @override
  String get capsulesColorRed => 'Rot';

  @override
  String get capsulesColorYellow => 'Gelb';

  @override
  String get capsulesCommentDelete => 'Kommentar löschen';

  @override
  String get capsulesCommentDeleteConfirm => 'Diesen Kommentar löschen?';

  @override
  String get capsulesCommentDeleteFailed =>
      'Der Kommentar konnte nicht gelöscht werden';

  @override
  String get capsulesCommentFailed =>
      'Dein Kommentar konnte nicht gesendet werden';

  @override
  String get capsulesCommentHint => 'Kommentar schreiben...';

  @override
  String get capsulesCommentTooLong =>
      'Kommentare dürfen höchstens 500 Zeichen lang sein';

  @override
  String get capsulesComments => 'Kommentare';

  @override
  String capsulesCommentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kommentare',
      one: '1 Kommentar',
      zero: 'Kommentieren',
    );
    return '$_temp0';
  }

  @override
  String get capsulesCommentsEarlier => 'Frühere Kommentare zeigen';

  @override
  String get capsulesCommentsEmpty => 'Noch keine Kommentare';

  @override
  String get capsulesCommentsEmptyHint => 'Schreib als Erstes etwas.';

  @override
  String get capsulesCreationAllowComments => 'Kommentare erlauben';

  @override
  String get capsulesCreationAllowReactions => 'Reaktionen erlauben';

  @override
  String get capsulesCreationApproximate => 'Ungefährer Standort';

  @override
  String get capsulesCreationApproximateHint =>
      'Etwa einen Kilometer daneben, nicht genau';

  @override
  String get capsulesCreationCoAuthors => 'Mitautoren';

  @override
  String capsulesCreationCoAuthorsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Freunde',
      one: '1 Freund',
    );
    return '$_temp0';
  }

  @override
  String get capsulesCreationCoAuthorsNone => 'Nur ich';

  @override
  String get capsulesCreationColor => 'Farbe';

  @override
  String get capsulesCreationDescriptionHint => 'Beschreibung hinzufügen...';

  @override
  String get capsulesCreationOpenAt => 'Öffnet sich am';

  @override
  String get capsulesCreationPreview => 'Kapselvorschau';

  @override
  String get capsulesCreationPrivacy => 'Sichtbarkeit';

  @override
  String get capsulesCreationSelectDate => 'Datum wählen';

  @override
  String get capsulesCreationSettings => 'Kapseleinstellungen';

  @override
  String get capsulesCreationShowAuthor => 'Meinen Namen zeigen';

  @override
  String get capsulesCreationShowAuthorHint =>
      'Andere sehen, wer sie hinterlassen hat';

  @override
  String get capsulesCreationSpeed => 'Tempo';

  @override
  String get capsulesCreationSubmit => 'Kapsel erstellen';

  @override
  String get capsulesCreationTitle => 'Kapsel erstellen';

  @override
  String get capsulesCreationTitleHint => 'Titel...';

  @override
  String get capsulesDefaultTitle => 'Kapsel';

  @override
  String get capsulesErrorNoLocation =>
      'Wir konnten deinen Standort nicht ermitteln';

  @override
  String get capsulesErrorSaveFailed =>
      'Die Kapsel konnte nicht gespeichert werden';

  @override
  String get capsulesErrorSavedNotSent =>
      'Die Kapsel wurde gespeichert, aber nicht gesendet. Tippe noch einmal auf den Button, um es erneut zu versuchen.';

  @override
  String capsulesFrameRemove(int number) {
    return 'Bild $number entfernen';
  }

  @override
  String get capsulesFramesHint => 'halten und ziehen';

  @override
  String get capsulesFramesTitle => 'Bilder';

  @override
  String get capsulesLeaveCoAuthors => 'Mich als Mitautor entfernen';

  @override
  String get capsulesLeftCoAuthors => 'Du bist kein Mitautor mehr';

  @override
  String get capsulesLinkNotShared => 'Diese Kapsel ist nicht mit dir geteilt';

  @override
  String get capsulesLoopMark => 'Loop';

  @override
  String get capsulesOpenInMonth => 'In einem Monat';

  @override
  String get capsulesOpenInWeek => 'In einer Woche';

  @override
  String get capsulesOpenInYear => 'In einem Jahr';

  @override
  String get capsulesOpenNow => 'Sofort öffnen';

  @override
  String get capsulesOpenPickDate => 'Datum wählen…';

  @override
  String get capsulesOpenTomorrow => 'Morgen';

  @override
  String get capsulesPrivacyFriends => 'Freunde';

  @override
  String get capsulesPrivacyPrivate => 'Privat';

  @override
  String get capsulesPrivacyPublic => 'Öffentlich';

  @override
  String get capsulesQueued =>
      'Auf deinem Handy gespeichert. Wird hochgeladen, sobald du wieder online bist.';

  @override
  String get capsulesQuickReply => 'Dem Autor antworten';

  @override
  String capsulesQuickReplyHint(String name) {
    return 'Schreib $name…';
  }

  @override
  String capsulesQuickReplySent(String name) {
    return 'An $name gesendet';
  }

  @override
  String capsulesReactWith(String emoji) {
    return 'Mit $emoji reagieren';
  }

  @override
  String get capsulesReactionFailed =>
      'Deine Reaktion konnte nicht gespeichert werden';

  @override
  String get capsulesReply => 'Antworten';

  @override
  String capsulesReplyHint(String name) {
    return 'Antwort an $name...';
  }

  @override
  String get capsulesReport => 'Melden';

  @override
  String get capsulesReportAbuse => 'Belästigung oder Hass';

  @override
  String get capsulesReportCapsule => 'Kapsel melden';

  @override
  String get capsulesReportNudity => 'Nacktheit';

  @override
  String get capsulesReportOther => 'Etwas anderes';

  @override
  String get capsulesReportPrivacy => 'Private Informationen';

  @override
  String get capsulesReportSent =>
      'Danke für den Hinweis. Das Later-Team sieht es sich an.';

  @override
  String get capsulesReportSpam => 'Spam';

  @override
  String get capsulesReportTitle => 'Was stimmt damit nicht?';

  @override
  String get capsulesReportViolence => 'Gewalt';

  @override
  String get capsulesShare => 'Teilen';

  @override
  String capsulesShareMessage(String title, String link) {
    return 'Eine Zeitkapsel in Later: $title\n$link';
  }

  @override
  String get capsulesSpeedFast => 'Schnell';

  @override
  String get capsulesSpeedNormal => 'Normal';

  @override
  String get capsulesSpeedSlow => 'Langsam';

  @override
  String capsulesWith(String names) {
    return 'Mit $names';
  }

  @override
  String get capsulesYou => 'Du';

  @override
  String get commonBack => 'Zurück';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonConfirm => 'Bestätigen';

  @override
  String get commonContinue => 'Weiter';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonErrorGeneric =>
      'Etwas ist schiefgelaufen. Bitte versuche es erneut.';

  @override
  String get commonLoading => 'Wird geladen...';

  @override
  String commonNewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count neu',
      one: '$count neu',
    );
    return '$_temp0';
  }

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
  String get commonUnknownUser => 'Unbekannter Nutzer';

  @override
  String get commonUnknownUsername => 'unbekannt';

  @override
  String get commonUntitled => 'Ohne Titel';

  @override
  String get commonUsernameRequired => 'Gib einen Benutzernamen ein';

  @override
  String get commonUsernameRules =>
      'Verwende 3 bis 30 Buchstaben (a–z), Ziffern, Punkte, Bindestriche oder Unterstriche';

  @override
  String get commonUsernameTaken => 'Dieser Benutzername ist schon vergeben';

  @override
  String get failureNotFound => 'Dieses Element gibt es nicht mehr.';

  @override
  String get failurePermission => 'Das darfst du nicht.';

  @override
  String get friendsAccept => 'Annehmen';

  @override
  String get friendsAcceptRequestLabel => 'Freundschaftsanfrage annehmen';

  @override
  String get friendsAdd => 'Hinzufügen';

  @override
  String get friendsAddTitle => 'Freunde hinzufügen';

  @override
  String get friendsBlock => 'Blockieren';

  @override
  String get friendsBlockConfirm =>
      'Möchtest du diese Person wirklich blockieren?';

  @override
  String get friendsEmpty => 'Du hast noch keine Freunde hinzugefügt';

  @override
  String get friendsErrorAcceptRequest =>
      'Anfrage konnte nicht angenommen werden';

  @override
  String get friendsErrorBlock => 'Blockieren hat nicht geklappt';

  @override
  String get friendsErrorCancelRequest =>
      'Anfrage konnte nicht zurückgezogen werden';

  @override
  String get friendsErrorFollow => 'Folgen hat nicht geklappt';

  @override
  String get friendsErrorLoadUsers => 'Nutzer konnten nicht geladen werden';

  @override
  String get friendsErrorRejectRequest =>
      'Anfrage konnte nicht abgelehnt werden';

  @override
  String get friendsErrorRemoveFriend => 'Entfernen hat nicht geklappt';

  @override
  String get friendsErrorSendRequest =>
      'Freundschaftsanfrage konnte nicht gesendet werden';

  @override
  String get friendsErrorUnblock =>
      'Blockierung konnte nicht aufgehoben werden';

  @override
  String get friendsErrorUnfollow => 'Entfolgen hat nicht geklappt';

  @override
  String get friendsFindByUsernameHint =>
      'Suche nach @Nutzername oder scanne den QR-Code eines Freundes. Hier erscheinen Leute, die deine Freunde kennen.';

  @override
  String get friendsFollow => 'Folgen';

  @override
  String get friendsFollowed =>
      'Du folgst jetzt! Du bekommst Benachrichtigungen über neue Kapseln';

  @override
  String get friendsFollowing => 'Gefolgt';

  @override
  String get friendsFriendCapsulesEmpty =>
      'Hier erscheinen die Kapseln deines Freundes';

  @override
  String get friendsFriendCapsulesTitle => 'Kapseln deines Freundes';

  @override
  String get friendsFromContacts => 'Aus deinen Kontakten';

  @override
  String get friendsFromContactsDenied =>
      'Dafür braucht Later Zugriff auf deine Kontakte';

  @override
  String get friendsFromContactsExplain =>
      'Later liest die E-Mail-Adressen in den Kontakten auf diesem Telefon und sendet nur verschlüsselte Fingerabdrücke davon. Du siehst die Leute, die gefunden werden wollen; aus deinen Kontakten wird nichts gespeichert. Einmal pro Stunde.';

  @override
  String get friendsFromContactsFailed => 'Die Suche hat gerade nicht geklappt';

  @override
  String get friendsFromContactsGo => 'Freunde suchen';

  @override
  String get friendsFromContactsNone =>
      'Noch keiner deiner Kontakte ist in Later auffindbar';

  @override
  String get friendsFromContactsTooSoon =>
      'Du hast gerade erst gesucht. Versuch es in einer Stunde.';

  @override
  String get friendsHideSuggestionLabel => 'Vorschlag ausblenden';

  @override
  String get friendsMakeFriends => 'Freunde finden';

  @override
  String get friendsManageFriendship => 'Freundschaft verwalten';

  @override
  String friendsMutualCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gemeinsame Freunde',
      one: '1 gemeinsamer Freund',
    );
    return '$_temp0';
  }

  @override
  String get friendsMyFriendsTitle => 'Meine Freunde';

  @override
  String get friendsMyProfile => 'Mein Profil';

  @override
  String get friendsNoMatches => 'Keine Freunde passen zu deiner Suche';

  @override
  String get friendsNoSuggestions => 'Keine weiteren Vorschläge';

  @override
  String get friendsOpenChat => 'Chat öffnen';

  @override
  String get friendsPending => 'Ausstehend';

  @override
  String get friendsQrHint =>
      'Richte die Kamera auf den QR-Code, um einen Freund hinzuzufügen';

  @override
  String get friendsQrInvalid =>
      'Ungültiger QR-Code. Scanne den QR-Code eines Later-Profils.';

  @override
  String get friendsQrTitle => 'QR-Code scannen';

  @override
  String get friendsReject => 'Ablehnen';

  @override
  String get friendsRemove => 'Aus Freunden entfernen';

  @override
  String get friendsRemoveAction => 'Entfernen';

  @override
  String get friendsRemoveConfirm =>
      'Möchtest du diese Person wirklich aus deinen Freunden entfernen?';

  @override
  String get friendsRemoving => 'Wird entfernt...';

  @override
  String get friendsReport => 'Melden';

  @override
  String get friendsRequestAccepted => 'Freundschaftsanfrage angenommen!';

  @override
  String get friendsRequestAlreadyExists =>
      'Du hast schon eine Freundschaftsanfrage gesendet';

  @override
  String get friendsRequestCancelled => 'Freundschaftsanfrage zurückgezogen';

  @override
  String get friendsRequestPendingInfo =>
      'Deine Freundschaftsanfrage ist noch offen';

  @override
  String get friendsRequestReceivedInfo =>
      'Diese Person hat dir eine Freundschaftsanfrage geschickt';

  @override
  String get friendsRequestRejected => 'Freundschaftsanfrage abgelehnt';

  @override
  String get friendsRequestSent => 'Freundschaftsanfrage gesendet!';

  @override
  String get friendsRequestsButton => 'Anfragen';

  @override
  String get friendsRequestsEmptySubtitle =>
      'Wenn dir jemand eine Freundschaftsanfrage schickt,\nsiehst du sie hier';

  @override
  String get friendsRequestsEmptyTitle => 'Keine Freundschaftsanfragen';

  @override
  String get friendsRequestsReceivedTab => 'Erhalten';

  @override
  String get friendsRequestsSentTab => 'Gesendet';

  @override
  String get friendsRequestsTitle => 'Freundschaftsanfragen';

  @override
  String get friendsSearchHint => 'Freunde durchsuchen';

  @override
  String get friendsSearchPeopleHint => 'Name oder @Nutzername';

  @override
  String get friendsSendCapsule => 'Kapsel senden';

  @override
  String get friendsSendRequestLabel => 'Freundschaftsanfrage senden';

  @override
  String get friendsSentEmptySubtitle =>
      'Hier siehst du die Freundschaftsanfragen,\ndie du sendest';

  @override
  String get friendsSentEmptyTitle => 'Keine gesendeten Anfragen';

  @override
  String get friendsShareProfile => 'Profil teilen';

  @override
  String get friendsShareProfileTo => 'Profil teilen ...';

  @override
  String get friendsSuggestionRemoved => 'Vorschlag aus der Liste entfernt!';

  @override
  String get friendsThisIsYou => 'Das ist dein Konto';

  @override
  String get friendsUnfollowed => 'Du folgst dieser Person nicht mehr';

  @override
  String get friendsViewProfile => 'Profil ansehen';

  @override
  String get historyAddToFavorites => 'Zu Favoriten hinzufügen';

  @override
  String get historyCapsuleOpened => 'Kapsel ist geöffnet!';

  @override
  String get historyColorBlue => 'Blau';

  @override
  String get historyColorGreen => 'Grün';

  @override
  String get historyColorOrange => 'Orange';

  @override
  String get historyColorPurple => 'Lila';

  @override
  String get historyColorRed => 'Rot';

  @override
  String get historyColorYellow => 'Gelb';

  @override
  String historyCountdown(int days, int hours, int minutes, int seconds) {
    return '${days}T ${hours}h ${minutes}m ${seconds}s';
  }

  @override
  String historyCountdownYears(int years, int days, int hours, int minutes) {
    return '${years}J ${days}T ${hours}h ${minutes}m';
  }

  @override
  String get historyCreateFirst => 'Kapsel erstellen';

  @override
  String historyDeleteConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kapseln löschen?',
      one: '$count Kapsel löschen?',
    );
    return '$_temp0';
  }

  @override
  String historyDeleteSelected(int count) {
    return 'Löschen ($count)';
  }

  @override
  String historyDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kapseln gelöscht',
      one: '$count Kapsel gelöscht',
    );
    return '$_temp0';
  }

  @override
  String historyDistanceFromYou(String distance) {
    return '$distance km von dir';
  }

  @override
  String historyDistanceFromYouMiles(String distance) {
    return '$distance Meilen von dir';
  }

  @override
  String get historyDistanceUnknown => 'Entfernung unbekannt';

  @override
  String get historyEmpty => 'Noch keine Kapseln';

  @override
  String get historyEmptySubtitle =>
      'Mach ein Foto, lass es an einem Ort und wähle, wann es sich öffnet.';

  @override
  String get historyErrorDelete => 'Kapseln konnten nicht gelöscht werden';

  @override
  String get historyErrorFavorites =>
      'Favoriten konnten nicht aktualisiert werden';

  @override
  String historyFavoriteAdded(String title) {
    return '„$title“ zu Favoriten hinzugefügt';
  }

  @override
  String historyFavoriteRemoved(String title) {
    return '„$title“ aus Favoriten entfernt';
  }

  @override
  String get historyFilterAny => 'Alle';

  @override
  String get historyFilterBy => 'Filtern';

  @override
  String get historyFilterCapsule => 'Kapseln';

  @override
  String get historyFilterColor => 'Farbe';

  @override
  String get historyFilterFavorite => 'Favoriten';

  @override
  String get historyFilterVisibility => 'Sichtbarkeit';

  @override
  String get historyLoadError => 'Deine Kapseln konnten nicht geladen werden';

  @override
  String get historyNoMatches => 'Keine Kapsel passt zu deiner Suche';

  @override
  String get historyNoMatchesSubtitle =>
      'Versuche ein anderes Wort oder setze die Filter zurück.';

  @override
  String get historyOnThisDay => 'An diesem Tag';

  @override
  String get historyPrivacyFriends => 'Freunde';

  @override
  String get historyPrivacyPrivate => 'Privat';

  @override
  String get historyPrivacyPublic => 'Öffentlich';

  @override
  String get historyRemoveFromFavorites => 'Aus Favoriten entfernen';

  @override
  String get historyReset => 'Zurücksetzen';

  @override
  String get historySearchHint => 'Kapseln suchen...';

  @override
  String historySelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ausgewählt',
      one: '$count ausgewählt',
    );
    return '$_temp0';
  }

  @override
  String get historySortBy => 'Sortieren';

  @override
  String get historySortClosest => 'Nächste zuerst';

  @override
  String get historySortDistance => 'Entfernung';

  @override
  String get historySortFarthest => 'Fernste zuerst';

  @override
  String get historySortNewest => 'Neueste zuerst';

  @override
  String get historySortOldest => 'Älteste zuerst';

  @override
  String get historySortRelevance => 'Relevanz';

  @override
  String get historyTitle => 'Meine Kapseln';

  @override
  String get historyVisibilityFriends => 'Für Freunde';

  @override
  String get historyVisibilityPrivate => 'Privat';

  @override
  String get historyVisibilityPublic => 'Öffentlich';

  @override
  String get historyWaitingUpload => 'Wartet auf Verbindung';

  @override
  String historyYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vor $count Jahren',
      one: 'Vor einem Jahr',
    );
    return '$_temp0';
  }

  @override
  String get mapCapsuleLocked => 'Gesperrt';

  @override
  String get mapCapsuleNoDescription => 'Diese Kapsel hat keine Beschreibung.';

  @override
  String get mapCapsuleOpen => 'Öffnen';

  @override
  String mapCapsuleOpensIn(String time) {
    return 'Öffnet sich in $time';
  }

  @override
  String get mapCapsuleReady => 'Schau, was drin ist!';

  @override
  String get mapCompass => 'Karte nach Norden drehen';

  @override
  String mapDurationDays(int count) {
    return '${count}T';
  }

  @override
  String mapDurationHours(int count) {
    return '${count}h';
  }

  @override
  String mapDurationMinutes(int count) {
    return '${count}min';
  }

  @override
  String mapDurationSeconds(int count) {
    return '${count}s';
  }

  @override
  String get mapFirstCapsuleBody =>
      'Mach hier ein Foto und wähle, wann es sich öffnet.';

  @override
  String get mapFirstCapsuleTitle => 'Hinterlasse deine erste Kapsel';

  @override
  String get mapLocationDenied =>
      'Erlaube den Standortzugriff, um Kapseln in deiner Nähe zu sehen';

  @override
  String get mapLocationServiceOff =>
      'Schalte die Ortung ein, um Kapseln in deiner Nähe zu sehen';

  @override
  String get mapLocationUnknown =>
      'Wir konnten deinen Standort nicht ermitteln';

  @override
  String get mapMyLocation => 'Mein Standort';

  @override
  String get mapZoomIn => 'Vergrößern';

  @override
  String get mapZoomOut => 'Verkleinern';

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
  String get messagesChoosePhoto => 'Aus der Galerie wählen';

  @override
  String get messagesClearConfirm => 'Löschen';

  @override
  String get messagesClearConfirmTitle =>
      'Möchtest du den Chatverlauf wirklich löschen?';

  @override
  String get messagesClearFailed => 'Verlauf konnte nicht gelöscht werden';

  @override
  String get messagesCopied => 'Kopiert';

  @override
  String get messagesCopy => 'Kopieren';

  @override
  String get messagesDeleteConfirmTitle =>
      'Diese Nachricht für euch beide löschen?';

  @override
  String get messagesDeleteFailed =>
      'Die Nachricht konnte nicht gelöscht werden';

  @override
  String get messagesDeleteForEveryone => 'Für alle löschen';

  @override
  String get messagesDeleteForMe => 'Für mich löschen';

  @override
  String messagesEmptySubtitle(String name) {
    return 'Sag $name Hallo!';
  }

  @override
  String get messagesEmptyTitle => 'Noch keine Nachrichten';

  @override
  String get messagesFindChatsHint => 'Chats suchen';

  @override
  String messagesFindPeople(String query) {
    return 'Personen finden: „$query“';
  }

  @override
  String get messagesForward => 'Weiterleiten';

  @override
  String get messagesForwardTo => 'Weiterleiten an';

  @override
  String get messagesForwarded => 'Weitergeleitet';

  @override
  String messagesForwardedTo(String name) {
    return 'Weitergeleitet an $name';
  }

  @override
  String get messagesGroupAddPeople => 'Personen hinzufügen';

  @override
  String get messagesGroupCreate => 'Erstellen';

  @override
  String get messagesGroupFailed =>
      'Bei der Gruppe ist etwas schiefgegangen. Versuch es noch einmal.';

  @override
  String get messagesGroupHello => 'Sag allen Hallo';

  @override
  String get messagesGroupInvited =>
      'Eingeladen. Deine Freunde sind gleich dabei.';

  @override
  String get messagesGroupLeave => 'Gruppe verlassen';

  @override
  String messagesGroupLeaveConfirm(String name) {
    return '„$name“ verlassen? Ihre Nachrichten werden hier nicht mehr angezeigt.';
  }

  @override
  String get messagesGroupLeft => 'Du bist nicht mehr in dieser Gruppe';

  @override
  String messagesGroupMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mitglieder',
      one: '1 Mitglied',
    );
    return '$_temp0';
  }

  @override
  String get messagesGroupMembersTitle => 'Mitglieder';

  @override
  String get messagesGroupName => 'Gruppenname';

  @override
  String get messagesGroupNameTooLong =>
      'Ein Gruppenname hat höchstens 60 Zeichen';

  @override
  String get messagesGroupNeedsName => 'Gib der Gruppe einen Namen';

  @override
  String get messagesGroupNeedsPeople => 'Wähle mindestens einen Freund aus';

  @override
  String get messagesGroupRename => 'Gruppe umbenennen';

  @override
  String get messagesGroupSave => 'Speichern';

  @override
  String get messagesGroupTooMany => 'Eine Gruppe hat höchstens 20 Personen';

  @override
  String get messagesGroupWho => 'Wer ist dabei?';

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
  String get messagesMicPermission =>
      'Erlaube das Mikrofon, um Sprachnachrichten zu senden';

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
  String get messagesNewGroup => 'Neue Gruppe';

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
  String messagesOpenGroup(String name) {
    return 'Gruppe $name öffnen';
  }

  @override
  String get messagesOpenPhoto => 'Foto öffnen';

  @override
  String get messagesPauseVoice => 'Pause';

  @override
  String get messagesPhoto => 'Foto';

  @override
  String get messagesPhotoCaption => 'Bildunterschrift hinzufügen…';

  @override
  String get messagesPhotoUnreadable =>
      'Dieses Bild kann nicht gesendet werden';

  @override
  String get messagesPin => 'Anheften';

  @override
  String messagesPinLimit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Du kannst bis zu $count Chats anheften',
      one: 'Du kannst 1 Chat anheften',
    );
    return '$_temp0';
  }

  @override
  String get messagesPinned => 'Angeheftet';

  @override
  String get messagesPlayVoice => 'Sprachnachricht abspielen';

  @override
  String get messagesQuoteGone =>
      'Diese Nachricht gibt es in diesem Chat nicht mehr';

  @override
  String get messagesReactFailed =>
      'Deine Reaktion konnte nicht gespeichert werden';

  @override
  String get messagesReceiptFailed => 'Nicht gesendet · Tippen zum Wiederholen';

  @override
  String get messagesReceiptRead => 'Gelesen';

  @override
  String get messagesReceiptSending => 'Wird gesendet…';

  @override
  String get messagesReceiptSent => 'Gesendet';

  @override
  String get messagesRecordVoice => 'Sprachnachricht aufnehmen';

  @override
  String get messagesReport => 'Melden';

  @override
  String get messagesReportFailed =>
      'Die Meldung konnte nicht gesendet werden. Versuch es noch einmal.';

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
  String get messagesSendPhoto => 'Foto senden';

  @override
  String get messagesSignedOut => 'Du bist abgemeldet';

  @override
  String messagesStartChatWith(String name) {
    return 'Chat mit $name starten';
  }

  @override
  String get messagesStickers => 'Sticker';

  @override
  String get messagesStickersFaces => 'Gesichter';

  @override
  String get messagesStickersHands => 'Gesten';

  @override
  String get messagesStickersHearts => 'Herzen und Feste';

  @override
  String get messagesStickersNature => 'Natur';

  @override
  String get messagesStickersPlaces => 'Orte und Dinge';

  @override
  String get messagesStickersRecent => 'Zuletzt verwendet';

  @override
  String get messagesTakePhoto => 'Foto aufnehmen';

  @override
  String get messagesTitle => 'Meine Laters';

  @override
  String get messagesToday => 'Heute';

  @override
  String get messagesTooLong => 'Diese Nachricht ist zu lang';

  @override
  String get messagesTyping => 'schreibt';

  @override
  String messagesTypingMany(int count) {
    return '$count Personen schreiben';
  }

  @override
  String messagesTypingName(String name) {
    return '$name schreibt';
  }

  @override
  String get messagesUnmutedToast => 'Stummschaltung aufgehoben';

  @override
  String get messagesUnpin => 'Lösen';

  @override
  String get messagesUnreadDivider => 'Ungelesene Nachrichten';

  @override
  String get messagesVoice => 'Sprachnachricht';

  @override
  String get messagesVoiceCancel => 'Aufnahme abbrechen';

  @override
  String get messagesVoiceFailed =>
      'Diese Sprachnachricht lässt sich nicht abspielen';

  @override
  String get messagesVoiceRecording => 'Aufnahme';

  @override
  String get messagesVoiceSend => 'Sprachnachricht senden';

  @override
  String get messagesVoiceTooShort => 'Zu kurz zum Senden';

  @override
  String get messagesYesterday => 'Gestern';

  @override
  String messagesYouPrefix(String message) {
    return 'Du: $message';
  }

  @override
  String get navMap => 'Karte';

  @override
  String get navMessages => 'Nachrichten';

  @override
  String get navMyCapsules => 'Meine Kapseln';

  @override
  String get navNewCapsule => 'Neue Kapsel';

  @override
  String get navProfile => 'Profil';

  @override
  String notificationsAchievementBody(String name) {
    return '$name: Du hast einen neuen Erfolg freigeschaltet';
  }

  @override
  String notificationsCapsuleBody(String name) {
    return '$name hat eine neue Kapsel erstellt';
  }

  @override
  String get notificationsChannelActivity => 'Aktivität';

  @override
  String get notificationsChannelActivityDescription =>
      'Follower, Freundschaftsanfragen, Reaktionen, Kommentare und neue Kapseln';

  @override
  String get notificationsChannelActivitySilent => 'Aktivität (lautlos)';

  @override
  String get notificationsChannelActivitySilentDescription =>
      'Aktivität ohne Ton und Vibration';

  @override
  String get notificationsChannelMessages => 'Nachrichten';

  @override
  String get notificationsChannelMessagesDescription =>
      'Neue Nachrichten von deinen Freunden';

  @override
  String get notificationsChannelMessagesSilent => 'Nachrichten (lautlos)';

  @override
  String get notificationsChannelMessagesSilentDescription =>
      'Neue Nachrichten ohne Ton und Vibration';

  @override
  String get notificationsChannelOther => 'Andere Benachrichtigungen';

  @override
  String get notificationsChannelOtherDescription =>
      'Andere Benachrichtigungen von Later';

  @override
  String notificationsCoAuthorBody(String name) {
    return '$name hat eine Kapsel mit dir gemacht';
  }

  @override
  String notificationsCommentBody(String name) {
    return '$name hat deine Kapsel kommentiert';
  }

  @override
  String notificationsCommentBodyWithText(String name, String text) {
    return '$name hat kommentiert: $text';
  }

  @override
  String notificationsDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Tagen',
      one: 'vor $count Tag',
    );
    return '$_temp0';
  }

  @override
  String notificationsDeleteConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Benachrichtigungen löschen?',
      one: '$count Benachrichtigung löschen?',
    );
    return '$_temp0';
  }

  @override
  String notificationsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Benachrichtigungen gelöscht',
      one: '$count Benachrichtigung gelöscht',
    );
    return '$_temp0';
  }

  @override
  String get notificationsEmptyAll =>
      'Hier erscheinen deine Benachrichtigungen und Aktivitäten';

  @override
  String get notificationsEmptyComments =>
      'Hier erscheinen Kommentare zu deinen Kapseln';

  @override
  String get notificationsEmptyReplies =>
      'Hier erscheinen Antworten auf deine Nachrichten';

  @override
  String notificationsFollowBody(String name) {
    return '$name folgt dir jetzt';
  }

  @override
  String notificationsFriendAcceptedBody(String name) {
    return '$name hat deine Freundschaftsanfrage angenommen';
  }

  @override
  String notificationsFriendRequestBody(String name) {
    return '$name möchte mit dir befreundet sein';
  }

  @override
  String notificationsHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Stunden',
      one: 'vor $count Stunde',
    );
    return '$_temp0';
  }

  @override
  String get notificationsJustNow => 'Gerade eben';

  @override
  String get notificationsMarkAsRead => 'Als gelesen markieren';

  @override
  String notificationsMarkedRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Benachrichtigungen als gelesen markiert',
      one: '$count Benachrichtigung als gelesen markiert',
    );
    return '$_temp0';
  }

  @override
  String notificationsMessageBody(String name) {
    return '$name hat dir eine Nachricht geschickt';
  }

  @override
  String notificationsMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Minuten',
      one: 'vor $count Minute',
    );
    return '$_temp0';
  }

  @override
  String notificationsReactionBody(String name, String emoji) {
    return '$name hat mit $emoji auf deine Kapsel reagiert';
  }

  @override
  String notificationsReplyBody(String name) {
    return '$name hat dir geantwortet';
  }

  @override
  String notificationsReplyBodyWithText(String name, String text) {
    return '$name hat geantwortet: $text';
  }

  @override
  String notificationsSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ausgewählt',
      one: '$count ausgewählt',
    );
    return '$_temp0';
  }

  @override
  String get notificationsTabAll => 'Alle';

  @override
  String get notificationsTabComments => 'Kommentare';

  @override
  String get notificationsTabReplies => 'Antworten';

  @override
  String get notificationsTitle => 'Benachrichtigungen';

  @override
  String get notificationsTypeAchievement => 'Erfolg';

  @override
  String get notificationsTypeCapsule => 'Neue Kapsel';

  @override
  String get notificationsTypeCoAuthor => 'Gemeinsam';

  @override
  String get notificationsTypeComment => 'Neuer Kommentar';

  @override
  String get notificationsTypeFollow => 'Neuer Follower';

  @override
  String get notificationsTypeFriendAccepted => 'Neuer Freund';

  @override
  String get notificationsTypeFriendRequest => 'Freundschaftsanfrage';

  @override
  String get notificationsTypeMessage => 'Neue Nachricht';

  @override
  String get notificationsTypeOther => 'Benachrichtigung';

  @override
  String get notificationsTypeReaction => 'Neue Reaktion';

  @override
  String get notificationsTypeReply => 'Neue Antwort';

  @override
  String notificationsUnreadBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ungelesene Benachrichtigungen',
      one: '$count ungelesene Benachrichtigung',
    );
    return '$_temp0';
  }

  @override
  String get placeNoLocation => 'Kein Standort';

  @override
  String get placeUnknown => 'Unbekannter Ort';

  @override
  String get profileAboutPrompt => 'Schreib ein paar Worte über dich';

  @override
  String get profileAddFriends => 'Freunde hinzufügen';

  @override
  String get profileBackgroundDelete => 'Hintergrundbild löschen';

  @override
  String get profileBackgroundTitle => 'Hintergrundbild';

  @override
  String get profileBackgroundUpdated => 'Hintergrundbild aktualisiert!';

  @override
  String get profileChoosePinned => 'Freunde anpinnen';

  @override
  String get profileCopyLink => 'Kopieren';

  @override
  String get profileErrorCopyLink => 'Link konnte nicht kopiert werden';

  @override
  String get profileErrorDeleteBackground =>
      'Hintergrundbild konnte nicht gelöscht werden';

  @override
  String get profileErrorDeletePicture =>
      'Profilbild konnte nicht gelöscht werden';

  @override
  String get profileErrorShare => 'Profil konnte nicht geteilt werden';

  @override
  String get profileErrorUploadBackground =>
      'Hintergrundbild konnte nicht hochgeladen werden';

  @override
  String get profileErrorUploadPicture =>
      'Profilbild konnte nicht hochgeladen werden';

  @override
  String profileFollowers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Follower',
      one: '1 Follower',
    );
    return '$_temp0';
  }

  @override
  String profileFollowing(int count) {
    return '$count folgt';
  }

  @override
  String get profileFriendsAll => 'Alle';

  @override
  String get profileFriendsSection => 'Freunde';

  @override
  String get profileImageFromGallery => 'Aus Galerie wählen';

  @override
  String get profileImageTakePhoto => 'Foto aufnehmen';

  @override
  String get profileLinkCopied => 'Link kopiert!';

  @override
  String get profileMyCapsules => 'Meine Kapseln';

  @override
  String get profileMyFriends => 'Meine Freunde';

  @override
  String get profileNewCapsule => 'Neue Kapsel';

  @override
  String get profileNewForEveryone => 'Für alle';

  @override
  String get profileNewForFriends => 'Für Freunde';

  @override
  String get profileNoFriends => 'Du hast noch keine Freunde';

  @override
  String get profileNoFriendsAction => 'Finde Leute, die du kennst';

  @override
  String get profilePictureDelete => 'Profilbild löschen';

  @override
  String get profilePictureTitle => 'Profilbild';

  @override
  String get profilePictureUpdated => 'Profilbild aktualisiert!';

  @override
  String get profilePin => 'Anheften';

  @override
  String profilePinLimit(int count) {
    return 'Höchstens $count angeheftete Freunde';
  }

  @override
  String profilePinned(String name) {
    return '$name angeheftet';
  }

  @override
  String get profilePinnedHint =>
      'Wählst du weniger als 3 aus, zeigen wir zufällige Freunde aus deiner Liste';

  @override
  String get profilePinnedLimit => 'Du kannst höchstens 3 Freunde anpinnen';

  @override
  String get profilePinnedTitle => 'Pinne bis zu 3 Freunde an';

  @override
  String get profilePinnedUpdated => 'Angepinnte Freunde aktualisiert!';

  @override
  String get profileQrError => 'Etwas ist schiefgelaufen...';

  @override
  String get profileQuickCapsule => 'Kapsel senden';

  @override
  String get profileQuickMessage => 'Nachricht';

  @override
  String get profileShare => 'Teilen';

  @override
  String get profileShareHeading => 'Teile dein Profil';

  @override
  String get profileShareHint =>
      'Andere können diesen Code mit ihrer Kamera oder in der App scannen, um dich als Freund hinzuzufügen';

  @override
  String profileShareMessage(String name, String link) {
    return 'Schau dir $name auf Later an!\n$link';
  }

  @override
  String profileShareSubject(String name) {
    return 'Vernetze dich mit $name auf Later';
  }

  @override
  String get profileShareSubtitle =>
      'Lass andere diesen QR-Code scannen, damit sie dich als Freund hinzufügen können';

  @override
  String get profileShareTitle => 'Profil teilen';

  @override
  String profileStatCapsules(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kapseln',
      one: 'Kapsel',
    );
    return '$_temp0';
  }

  @override
  String profileStatPlaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Orte',
      one: 'Ort',
    );
    return '$_temp0';
  }

  @override
  String get profileStatTogether => 'mit Freunden';

  @override
  String get profileUnpin => 'Lösen';

  @override
  String profileUnpinned(String name) {
    return '$name gelöst';
  }

  @override
  String get profileUpdating => 'Aktualisiere...';

  @override
  String get profileVerified => 'Verifiziertes Konto';

  @override
  String get profileViewProfile => 'Profil ansehen';

  @override
  String get settingsAbout => 'Über mich';

  @override
  String get settingsAboutDescription =>
      'Ein paar Worte unter deinem Namen für alle, die dein Profil öffnen.';

  @override
  String get settingsAboutHint => 'Sammle Sonnenuntergänge seit 2019';

  @override
  String get settingsAboutLicenses => 'Open-Source-Lizenzen';

  @override
  String get settingsAboutOpenFailed => 'Die Seite ließ sich nicht öffnen.';

  @override
  String get settingsAboutPrivacy => 'Datenschutzerklärung';

  @override
  String get settingsAboutTerms => 'Nutzungsbedingungen';

  @override
  String settingsAboutTooLong(int count) {
    return 'Höchstens $count Zeichen';
  }

  @override
  String get settingsAboutUpdated => '„Über mich“ aktualisiert';

  @override
  String get settingsAboutVersion => 'Version';

  @override
  String get settingsAboutVersionUnknown => 'unbekannt';

  @override
  String get settingsAppPermissions => 'App-Berechtigungen';

  @override
  String get settingsAppearance => 'Darstellung';

  @override
  String get settingsAppearanceDescription =>
      'Wie Later auf diesem Handy aussieht';

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
  String get settingsDownloadData => 'Meine Daten herunterladen';

  @override
  String get settingsDownloadDataFailed =>
      'Daten konnten nicht vorbereitet werden';

  @override
  String get settingsDownloadDataHint =>
      'Profil, Einstellungen, Kapseln, Freunde und Chats als eine Datei (Fotos als Links).';

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
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsLanguageDescription =>
      'Die Sprache der App und deiner Benachrichtigungen';

  @override
  String get settingsLanguageFooter =>
      'Benachrichtigungen von Later kommen auch in dieser Sprache.';

  @override
  String get settingsLanguageSystem => 'Sprache des Handys';

  @override
  String settingsLanguageSystemHint(String language) {
    return 'Jetzt: $language';
  }

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
  String get settingsNotificationsAchievements => 'Erfolge';

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
  String get settingsNotificationsComments => 'Kommentare';

  @override
  String get settingsNotificationsCommentsHint =>
      'Zu deinen Kapseln und Antworten an dich';

  @override
  String get settingsNotificationsDescription =>
      'Wähle, worüber Later dich informiert';

  @override
  String get settingsNotificationsFollowers => 'Neue Follower';

  @override
  String get settingsNotificationsFriendRequests => 'Freundschaftsanfragen';

  @override
  String get settingsNotificationsFriendRequestsHint =>
      'Erhalten und angenommen';

  @override
  String get settingsNotificationsMessages => 'Nachrichten';

  @override
  String get settingsNotificationsMuteHint =>
      'Einzelne Chats schaltest du über ihr Menü in Nachrichten stumm.';

  @override
  String get settingsNotificationsNews => 'Neuigkeiten von Later';

  @override
  String get settingsNotificationsNewsHint => 'Seltene Ankündigungen vom Team';

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
  String get settingsNotificationsReactions => 'Reaktionen';

  @override
  String get settingsNotificationsSound => 'Ton und Vibration';

  @override
  String get settingsNotificationsStreak => 'Serien-Erinnerung';

  @override
  String get settingsNotificationsStreakHint =>
      'Abends, wenn deine Serie heute enden würde';

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
  String get settingsPhotoQualityHigh => 'Hoch (schärfer, größer)';

  @override
  String get settingsPhotoQualityStandard => 'Standard (schneller gesendet)';

  @override
  String get settingsPrivacy => 'Datenschutz';

  @override
  String get settingsPrivacyAchievements => 'Meine Erfolge zeigen';

  @override
  String get settingsPrivacyAchievementsHint =>
      'Freunde sehen sie in deinem Profil';

  @override
  String get settingsPrivacyApproximate => 'Ungefährer Standort';

  @override
  String get settingsPrivacyApproximateHint =>
      'Setzt neue Kapseln im Umkreis von etwa einem Kilometer statt an die genaue Stelle';

  @override
  String get settingsPrivacyDescription =>
      'Was andere sehen und wie neue Kapseln starten';

  @override
  String get settingsPrivacyFindByContacts => 'Über meine E-Mail auffindbar';

  @override
  String get settingsPrivacyFindByContactsHint =>
      'Wer deine E-Mail in den Kontakten hat, kann dich als Vorschlag sehen. Gespeichert wird nur ein Fingerabdruck einer bestätigten Adresse.';

  @override
  String get settingsPrivacyFindByName => 'Per Name auffindbar';

  @override
  String get settingsPrivacyFindByNameHint =>
      'Man kann nach deinem Namen suchen. Nach dem Benutzernamen immer.';

  @override
  String get settingsPrivacyNewCapsulesFooter =>
      'Beides kannst du beim Erstellen für jede Kapsel ändern.';

  @override
  String get settingsPrivacyReadReceipts => 'Lesebestätigungen';

  @override
  String get settingsPrivacyReadReceiptsHint =>
      'Ausgeschaltet sehen Freunde nicht, wann du ihre Nachrichten gelesen hast, und du siehst es bei ihnen auch nicht';

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
  String get settingsSaveToGallery => 'Kapselfotos in der Galerie speichern';

  @override
  String get settingsSaveToGalleryHint =>
      'In Pictures/Later, sobald die Kapsel erstellt ist.';

  @override
  String get settingsSectionAccount => 'MEIN KONTO';

  @override
  String get settingsSectionCamera => 'KAMERA';

  @override
  String get settingsSectionContact => 'KONTAKT';

  @override
  String get settingsSectionDistances => 'ENTFERNUNGEN';

  @override
  String get settingsSectionHow => 'WIE';

  @override
  String get settingsSectionMap => 'KARTE';

  @override
  String get settingsSectionMoreActivity => 'AKTIVITÄT';

  @override
  String get settingsSectionNewCapsules => 'NEUE KAPSELN';

  @override
  String get settingsSectionNotificationsPrivacy =>
      'BENACHRICHTIGUNGEN & DATENSCHUTZ';

  @override
  String get settingsSectionNotifyAbout => 'BENACHRICHTIGEN BEI';

  @override
  String get settingsSectionPhotos => 'FOTOS';

  @override
  String get settingsSectionQuestions => 'FRAGEN';

  @override
  String get settingsSectionQuietHours => 'RUHEZEITEN';

  @override
  String get settingsSectionSize => 'GRÖSSE';

  @override
  String get settingsSectionSupport => 'SUPPORT';

  @override
  String get settingsSectionTheme => 'DESIGN';

  @override
  String get settingsSectionThisPhone => 'DIESES HANDY';

  @override
  String get settingsSectionVisibility => 'WAS ANDERE SEHEN';

  @override
  String get settingsSignInEmail => 'E-Mail und Passwort';

  @override
  String get settingsSignInMethods => 'Anmeldemethoden';

  @override
  String get settingsSignedInWithGoogle => 'Angemeldet mit Google';

  @override
  String get settingsSizeFooter =>
      'Macht alles auf dem Bildschirm kleiner oder größer, auch den Text.';

  @override
  String get settingsSizeLarge => 'Groß';

  @override
  String get settingsSizeSmall => 'Klein';

  @override
  String get settingsSizeStandard => 'Standard';

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
  String get settingsThemeDark => 'Dunkel';

  @override
  String get settingsThemeLight => 'Hell';

  @override
  String get settingsThemeSystem => 'Wie das Handy';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsUnblock => 'Blockierung aufheben';

  @override
  String get settingsUnblocking => 'Wird aufgehoben...';

  @override
  String get settingsUnitsKilometres => 'Kilometer';

  @override
  String get settingsUnitsMiles => 'Meilen';

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
  String get settingsVisibilityFriends => 'Freunde';

  @override
  String get settingsVisibilityFriendsHint => 'Nur deine Freunde';

  @override
  String get settingsVisibilityPrivate => 'Privat';

  @override
  String get settingsVisibilityPrivateHint => 'Nur du';

  @override
  String get settingsVisibilityPublic => 'Öffentlich';

  @override
  String get settingsVisibilityPublicHint => 'Alle auf der Karte';

  @override
  String get settingsYourPassword => 'Dein Passwort';
}
