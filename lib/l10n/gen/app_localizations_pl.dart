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
  String get placeNoLocation => 'Brak lokalizacji';

  @override
  String get placeUnknown => 'Nieznane miejsce';

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
  String get settingsNotificationsDescription =>
      'Wybierz, o czym Later ma ci mówić';

  @override
  String get settingsNotificationsFollowers => 'Nowi obserwujący';

  @override
  String get settingsNotificationsMessages => 'Wiadomości';

  @override
  String get settingsNotificationsMuteHint =>
      'Pojedynczy czat wyciszysz w jego menu w Wiadomościach.';

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
  String get settingsNotificationsSound => 'Dźwięk i wibracje';

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
  String get settingsSectionNotificationsPrivacy =>
      'POWIADOMIENIA I PRYWATNOŚĆ';

  @override
  String get settingsSectionNotifyAbout => 'O CZYM POWIADAMIAĆ';

  @override
  String get settingsSectionQuestions => 'PYTANIA';

  @override
  String get settingsSectionQuietHours => 'GODZINY CISZY';

  @override
  String get settingsSectionSupport => 'WSPARCIE';

  @override
  String get settingsSectionThisPhone => 'TEN TELEFON';

  @override
  String get settingsSignedInWithGoogle => 'Logowanie przez Google';

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
  String get settingsYourPassword => 'Twoje hasło';
}
