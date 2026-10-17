// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Later';

  @override
  String get commonBack => 'Назад';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonClose => 'Закрыть';

  @override
  String get commonConfirm => 'Подтвердить';

  @override
  String get commonContinue => 'Продолжить';

  @override
  String get commonDelete => 'Удалить';

  @override
  String get commonDone => 'Готово';

  @override
  String get commonErrorGeneric => 'Что-то пошло не так. Попробуйте ещё раз.';

  @override
  String get commonLoading => 'Загрузка...';

  @override
  String get commonNoConnection => 'Нет соединения. Попробуйте ещё раз.';

  @override
  String get commonRetry => 'Повторить';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get commonSearchHint => 'Поиск...';

  @override
  String get commonUnknownUser => 'Неизвестный пользователь';

  @override
  String get commonUnknownUsername => 'неизвестно';

  @override
  String get failureNotFound => 'Этот объект больше не существует.';

  @override
  String get failurePermission => 'У вас нет прав на это действие.';

  @override
  String get placeNoLocation => 'Нет геопозиции';

  @override
  String get placeUnknown => 'Неизвестное место';

  @override
  String get settingsAbout => 'О приложении';

  @override
  String get settingsAboutLicenses => 'Лицензии открытого ПО';

  @override
  String get settingsAboutOpenFailed => 'Не удалось открыть страницу.';

  @override
  String get settingsAboutPrivacy => 'Политика конфиденциальности';

  @override
  String get settingsAboutTerms => 'Условия использования';

  @override
  String get settingsAboutVersion => 'Версия';

  @override
  String get settingsAboutVersionUnknown => 'неизвестна';

  @override
  String get settingsAppPermissions => 'Разрешения приложения';

  @override
  String settingsBlockedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count пользователя',
      many: '$count пользователей',
      few: '$count пользователя',
      one: '$count пользователь',
    );
    return '$_temp0';
  }

  @override
  String get settingsBlockedDescription =>
      'Они не смогут писать вам и отправлять заявки в друзья';

  @override
  String get settingsBlockedEmpty => 'Вы никого не заблокировали';

  @override
  String get settingsBlockedEmptyHint =>
      'Заблокировать человека можно\nв его профиле или в чате';

  @override
  String get settingsBlockedNobody => 'Никого';

  @override
  String get settingsBlockedUsers => 'Заблокированные';

  @override
  String get settingsCameraBack => 'Основная камера';

  @override
  String get settingsCameraFooter =>
      'Камера, которая открывается, когда вы создаёте капсулу.';

  @override
  String get settingsCameraFront => 'Фронтальная камера';

  @override
  String get settingsCompleteProfileDescription =>
      'Выберите, как вас будут видеть друзья';

  @override
  String settingsCompleteProfileNoProfile(String email) {
    return 'У аккаунта $email ещё нет профиля.';
  }

  @override
  String get settingsCompleteProfileTitle => 'Почти готово';

  @override
  String get settingsCustomizeDescription =>
      'Нажмите на фото, чтобы изменить его';

  @override
  String get settingsCustomizeProfile => 'Настроить профиль';

  @override
  String get settingsDataAndStorage => 'Данные и память';

  @override
  String get settingsDeleteAccount => 'Удалить аккаунт';

  @override
  String get settingsDeleteButton => 'Удалить мой аккаунт';

  @override
  String get settingsDeleteConfirm =>
      'Удалить аккаунт? Это действие нельзя отменить.';

  @override
  String get settingsDeleteDescription =>
      'Аккаунт удалится вместе со всем, что в нём есть';

  @override
  String get settingsDeleteNote =>
      'Вместе с аккаунтом удалятся ваш профиль, фото, капсулы, чаты, друзья и подписчики. Друзья больше не увидят ни вас, ни ваших сообщений. Это действие нельзя отменить.';

  @override
  String get settingsDeletedAccount => 'Удалённый аккаунт';

  @override
  String get settingsDeviceDescription =>
      'Как Later выглядит и работает на этом телефоне';

  @override
  String get settingsEmail => 'Электронная почта';

  @override
  String settingsEmailDescription(String email) {
    return 'Вы входите в Later с адресом $email';
  }

  @override
  String settingsEmailGoogleDescription(String email) {
    return 'Вы входите через Google как $email';
  }

  @override
  String get settingsEmailGoogleNote =>
      'Адрес почты берётся из вашего аккаунта Google. Чтобы использовать другой, измените его в аккаунте Google.';

  @override
  String settingsEmailLinkSent(String newEmail, String currentEmail) {
    return 'Мы отправили ссылку на $newEmail. Откройте её, чтобы подтвердить смену адреса. А пока входите с $currentEmail.';
  }

  @override
  String get settingsEmailNewHint => 'Новый адрес почты';

  @override
  String get settingsEmailSendLink => 'Отправить ссылку';

  @override
  String get settingsErrorChatUpdateFailed => 'Не удалось обновить чат.';

  @override
  String get settingsErrorCouldNotSave =>
      'Не удалось сохранить. Попробуйте ещё раз.';

  @override
  String get settingsErrorCurrentPassword => 'Введите текущий пароль.';

  @override
  String get settingsErrorEnterName => 'Введите своё имя.';

  @override
  String get settingsErrorEnterNewName => 'Введите новое имя!';

  @override
  String get settingsErrorEnterNewUsername => 'Введите новое имя пользователя!';

  @override
  String get settingsErrorEnterPassword => 'Введите пароль.';

  @override
  String get settingsErrorInvalidEmail => 'Введите корректный адрес почты.';

  @override
  String get settingsErrorNameFailed => 'Не удалось обновить имя!';

  @override
  String get settingsErrorPasswordSame => 'Новый пароль совпадает с текущим.';

  @override
  String settingsErrorPasswordTooShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Новый пароль должен быть не короче $count символа.',
      many: 'Новый пароль должен быть не короче $count символов.',
      few: 'Новый пароль должен быть не короче $count символов.',
      one: 'Новый пароль должен быть не короче $count символа.',
    );
    return '$_temp0';
  }

  @override
  String get settingsErrorPasswordsMismatch => 'Новые пароли не совпадают.';

  @override
  String get settingsErrorSameEmail => 'Это уже ваш адрес.';

  @override
  String get settingsErrorSaveFailed => 'Не удалось сохранить настройки.';

  @override
  String get settingsErrorSignInAgain => 'Войдите в аккаунт ещё раз.';

  @override
  String get settingsErrorUsernameFailed =>
      'Не удалось обновить имя пользователя!';

  @override
  String get settingsFaqBlockAnswer =>
      'Заблокируйте человека в его профиле или через меню чата. Разблокировать его можно в «Настройки > Заблокированные».';

  @override
  String get settingsFaqBlockQuestion => 'Как запретить кому-то писать мне?';

  @override
  String get settingsFaqCapsuleAnswer =>
      'Это фото с заголовком и заметкой, закреплённое на карте там, где вы его сделали. Можно выбрать дату: до неё капсула останется закрытой.';

  @override
  String get settingsFaqCapsuleQuestion => 'Что такое капсула?';

  @override
  String get settingsFaqDeleteAnswer =>
      '«Настройки > Удалить аккаунт». Всё, что вы создали, удалится, и восстановить это будет нельзя.';

  @override
  String get settingsFaqDeleteQuestion => 'Как удалить аккаунт?';

  @override
  String get settingsFaqFriendsAnswer =>
      'Найдите человека по имени пользователя в разделе «Друзья», отсканируйте его QR-код или поделитесь ссылкой на свой профиль.';

  @override
  String get settingsFaqFriendsQuestion => 'Как добавить друзей?';

  @override
  String get settingsFaqNotificationsAnswer =>
      'Загляните в «Настройки > Уведомления»: телефон должен разрешать Later присылать уведомления, а пуш-уведомления должны быть включены. Ещё пуши не приходят в тихие часы и из чатов с отключёнными уведомлениями.';

  @override
  String get settingsFaqNotificationsQuestion => 'Мне не приходят уведомления';

  @override
  String get settingsFaqVisibilityAnswer =>
      'Вы выбираете это при создании: только вы («Личная»), ваши друзья («Для друзей») или все («Публичная»).';

  @override
  String get settingsFaqVisibilityQuestion => 'Кто видит мои капсулы?';

  @override
  String get settingsGoogleConfirmsNote =>
      'Google подтвердит, что это вы: просто выберите свой аккаунт, когда он попросит.';

  @override
  String get settingsHelp => 'Помощь';

  @override
  String settingsHelpContactFooter(String email) {
    return 'К письмам из приложения добавляются версия приложения и данные телефона. Можно и просто написать на $email.';
  }

  @override
  String get settingsHelpContactSupport => 'Написать в поддержку';

  @override
  String get settingsHelpCopied =>
      'Скопировано. Вставьте это в письмо для нас.';

  @override
  String get settingsHelpCopyInfo => 'Скопировать данные о приложении';

  @override
  String get settingsHelpDescription => 'Ответы на вопросы и связь с нами';

  @override
  String settingsHelpNoEmailApp(String email) {
    return 'Не нашли почтовое приложение. Напишите на $email';
  }

  @override
  String get settingsHelpReportProblem => 'Сообщить о проблеме';

  @override
  String get settingsHelpSubjectProblem => 'Later: сообщение о проблеме';

  @override
  String get settingsHelpSubjectQuestion => 'Later: вопрос';

  @override
  String get settingsLogOut => 'Выйти';

  @override
  String get settingsLogOutConfirm => 'Точно хотите выйти?';

  @override
  String get settingsMapAndCamera => 'Карта и камера';

  @override
  String get settingsMapLookHybrid => 'Спутник с подписями';

  @override
  String get settingsMapLookSatellite => 'Спутник';

  @override
  String get settingsMapLookStandard => 'Обычная';

  @override
  String get settingsName => 'Имя';

  @override
  String get settingsNameDescription =>
      'Так вас будут видеть в Later. Выберите имя, по которому вас узнают друзья';

  @override
  String get settingsNameHint => 'Новое имя';

  @override
  String get settingsNameUpdated => 'Имя обновлено!';

  @override
  String get settingsNotifications => 'Уведомления';

  @override
  String get settingsNotificationsAllow => 'Разрешить уведомления';

  @override
  String get settingsNotificationsBlockedFooter =>
      'Телефон не разрешает Later показывать уведомления, поэтому они не придут, что бы вы ни выбрали ниже.';

  @override
  String get settingsNotificationsCapsules => 'Новые капсулы';

  @override
  String get settingsNotificationsCapsulesHint =>
      'От подписок, для которых включены уведомления';

  @override
  String get settingsNotificationsDescription =>
      'Выберите, о чём Later будет вам сообщать';

  @override
  String get settingsNotificationsFollowers => 'Новые подписчики';

  @override
  String get settingsNotificationsMessages => 'Сообщения';

  @override
  String get settingsNotificationsMuteHint =>
      'Отключить уведомления отдельного чата можно в его меню в разделе «Сообщения».';

  @override
  String get settingsNotificationsOff => 'Выключены';

  @override
  String get settingsNotificationsOffInPhone =>
      'Выключены в настройках телефона';

  @override
  String get settingsNotificationsOn => 'Включены';

  @override
  String get settingsNotificationsPreview => 'Показывать текст сообщений';

  @override
  String get settingsNotificationsPreviewOff =>
      'В пушах будет только «Новое сообщение»';

  @override
  String get settingsNotificationsPush => 'Пуш-уведомления';

  @override
  String get settingsNotificationsPushOff =>
      'Later не будет присылать вам пуши';

  @override
  String get settingsNotificationsSound => 'Звук и вибрация';

  @override
  String get settingsPassword => 'Пароль';

  @override
  String get settingsPasswordChanged => 'Пароль изменён';

  @override
  String get settingsPasswordConfirmsNote => 'Пароль подтверждает, что это вы.';

  @override
  String get settingsPasswordCurrent => 'Текущий пароль';

  @override
  String get settingsPasswordDescription =>
      'Выберите пароль, который вы больше нигде не используете';

  @override
  String get settingsPasswordForgot => 'Забыли пароль?';

  @override
  String get settingsPasswordGoogleDescription => 'Вы входите через Google';

  @override
  String get settingsPasswordGoogleNote =>
      'У вашего аккаунта нет пароля Later: вход подтверждает Google. Сменить пароль можно в аккаунте Google.';

  @override
  String settingsPasswordNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Новый пароль (от $count символа)',
      many: 'Новый пароль (от $count символов)',
      few: 'Новый пароль (от $count символов)',
      one: 'Новый пароль (от $count символа)',
    );
    return '$_temp0';
  }

  @override
  String get settingsPasswordRepeat => 'Повторите новый пароль';

  @override
  String get settingsPasswordResetFailed =>
      'Не удалось отправить ссылку. Попробуйте ещё раз.';

  @override
  String settingsPasswordResetSent(String email) {
    return 'Мы отправили ссылку для сброса пароля на $email';
  }

  @override
  String get settingsPermissionCamera => 'Камера';

  @override
  String get settingsPermissionCameraDescription =>
      'Чтобы снимать капсулы времени';

  @override
  String get settingsPermissionContacts => 'Контакты';

  @override
  String get settingsPermissionContactsDescription =>
      'Чтобы приглашать друзей и находить знакомых';

  @override
  String get settingsPermissionDenied => 'Запрещено';

  @override
  String get settingsPermissionGranted => 'Разрешено';

  @override
  String get settingsPermissionLimited => 'Частично';

  @override
  String get settingsPermissionLocation => 'Геопозиция';

  @override
  String get settingsPermissionLocationDescription =>
      'Капсулы поблизости и функции, связанные с местом';

  @override
  String get settingsPermissionMicrophone => 'Микрофон';

  @override
  String get settingsPermissionMicrophoneDescription =>
      'Чтобы записывать звук для капсул времени';

  @override
  String get settingsPermissionNotificationsDescription =>
      'Новости о подписчиках и капсулах';

  @override
  String get settingsPermissionOpenSettings => 'Открыть настройки';

  @override
  String get settingsPermissionPermanentlyDenied => 'Запрещено навсегда';

  @override
  String get settingsPermissionProvisional => 'Временно';

  @override
  String get settingsPermissionRequiredBody =>
      'Это разрешение запрещено навсегда. Включите его в настройках устройства.';

  @override
  String get settingsPermissionRequiredTitle => 'Нужно разрешение';

  @override
  String get settingsPermissionRestricted => 'Ограничено';

  @override
  String get settingsPermissionRevokeBody =>
      'Чтобы отозвать это разрешение, откройте настройки устройства. Связанные с ним функции приложения перестанут работать.';

  @override
  String get settingsPermissionRevokeTitle => 'Отозвать разрешение';

  @override
  String get settingsPermissionsDescription =>
      'К чему у Later есть доступ на этом телефоне';

  @override
  String get settingsQuietFrom => 'Тишина с';

  @override
  String get settingsQuietHours => 'Тихие часы';

  @override
  String get settingsQuietHoursFooter =>
      'В эти часы пушей не будет. Сообщения всё равно придут в приложение.';

  @override
  String get settingsQuietHoursFrom => 'С';

  @override
  String get settingsQuietHoursUntil => 'До';

  @override
  String get settingsQuietUntil => 'Тишина до';

  @override
  String get settingsSectionAccount => 'МОЙ АККАУНТ';

  @override
  String get settingsSectionCamera => 'КАМЕРА';

  @override
  String get settingsSectionContact => 'СВЯЗЬ С НАМИ';

  @override
  String get settingsSectionHow => 'КАК';

  @override
  String get settingsSectionMap => 'КАРТА';

  @override
  String get settingsSectionNotificationsPrivacy => 'УВЕДОМЛЕНИЯ И ПРИВАТНОСТЬ';

  @override
  String get settingsSectionNotifyAbout => 'О ЧЁМ УВЕДОМЛЯТЬ';

  @override
  String get settingsSectionQuestions => 'ВОПРОСЫ';

  @override
  String get settingsSectionQuietHours => 'ТИХИЕ ЧАСЫ';

  @override
  String get settingsSectionSupport => 'ПОДДЕРЖКА';

  @override
  String get settingsSectionThisPhone => 'ЭТОТ ТЕЛЕФОН';

  @override
  String get settingsSignedInWithGoogle => 'Вход через Google';

  @override
  String get settingsStorageCache => 'Кэш';

  @override
  String get settingsStorageClear => 'Очистить';

  @override
  String get settingsStorageClearCache => 'Очистить кэш';

  @override
  String get settingsStorageClearConfirm =>
      'Очистить кэш? Картинки загрузятся снова, когда понадобятся.';

  @override
  String get settingsStorageCleared => 'Кэш очищен';

  @override
  String get settingsStorageClearing => 'Очищаем...';

  @override
  String get settingsStorageDescription =>
      'Сколько места Later занимает на этом телефоне';

  @override
  String get settingsStorageFooter =>
      'Фото, снятые или выбранные для капсул, и картинки, загруженные из интернета. Ваши капсулы, чаты и аккаунт останутся.';

  @override
  String settingsSupportInfoApp(String version) {
    return 'Приложение: Later $version';
  }

  @override
  String settingsSupportInfoPhone(String system) {
    return 'Телефон: $system';
  }

  @override
  String settingsSupportInfoUserId(String uid) {
    return 'ID пользователя: $uid';
  }

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsUnblock => 'Разблокировать';

  @override
  String get settingsUnblocking => 'Разблокируем...';

  @override
  String get settingsUsername => 'Имя пользователя';

  @override
  String get settingsUsernameDescription =>
      'По нему друзья найдут и добавят вас в Later';

  @override
  String get settingsUsernameHint => 'Новое имя пользователя';

  @override
  String get settingsUsernameUpdated => 'Имя пользователя обновлено!';

  @override
  String get settingsYourPassword => 'Ваш пароль';
}
