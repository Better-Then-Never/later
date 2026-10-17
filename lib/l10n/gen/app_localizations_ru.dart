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
  String get authContinueWithGoogle => 'Войти через Google';

  @override
  String get authEmailHint => 'Электронная почта';

  @override
  String get authEnterEmail => 'Введите адрес электронной почты';

  @override
  String get authErrorEmailInUse => 'Аккаунт с этим адресом уже существует.';

  @override
  String get authErrorEmailTaken =>
      'Этот адрес уже используется другим аккаунтом.';

  @override
  String get authErrorInvalidCredential => 'Неверная почта или пароль.';

  @override
  String get authErrorInvalidEmail => 'Некорректный адрес электронной почты.';

  @override
  String get authErrorMethodDisabled => 'Этот способ входа недоступен.';

  @override
  String get authErrorPickGoogleAccount =>
      'Выберите аккаунт Google, через который вы входите.';

  @override
  String get authErrorRecentLogin =>
      'Подтвердите, что это вы, и попробуйте ещё раз.';

  @override
  String get authErrorTooManyRequests =>
      'Слишком много попыток. Попробуйте позже.';

  @override
  String get authErrorUserDisabled => 'Этот аккаунт отключён.';

  @override
  String get authErrorUserNotFound => 'Пользователь с этим адресом не найден.';

  @override
  String get authErrorWeakPassword => 'Слишком простой пароль.';

  @override
  String authErrorWithMessage(String message) {
    return 'Ошибка: $message';
  }

  @override
  String get authErrorWrongPassword => 'Неверный пароль.';

  @override
  String get authErrorWrongPasswordProvided => 'Неверный пароль.';

  @override
  String get authFacebookSoon => 'Facebook (скоро)';

  @override
  String get authFillAllFields => 'Заполните все поля';

  @override
  String get authForgotPassword => 'Забыли пароль?';

  @override
  String get authGetStarted => 'Начать';

  @override
  String get authGoToLogIn => 'Войти';

  @override
  String get authGoToSignUp => 'Регистрация';

  @override
  String get authGoogleFailed =>
      'Не удалось войти через Google. Попробуйте ещё раз.';

  @override
  String get authHaveAccount => 'Уже есть аккаунт?';

  @override
  String get authHidePassword => 'Скрыть пароль';

  @override
  String authLegalNotice(String terms, String privacy) {
    return 'Регистрируясь, вы принимаете $terms и $privacy';
  }

  @override
  String get authLinkOpenFailed => 'Не удалось открыть страницу.';

  @override
  String get authLogInButton => 'Войти';

  @override
  String get authLoginSubtitle => 'Войдите в аккаунт, чтобы продолжить';

  @override
  String get authLoginTitle => 'Вход';

  @override
  String get authNameHint => 'Имя';

  @override
  String get authNoAccount => 'Нет аккаунта?';

  @override
  String get authNoFreeUsername =>
      'Не удалось подобрать имя пользователя. Пожалуйста, зарегистрируйтесь.';

  @override
  String get authOrConnectWith => 'Или войдите через';

  @override
  String get authPasswordHint => 'Пароль';

  @override
  String get authPermissionCameraText =>
      'И вы сможете создавать капсулы времени!';

  @override
  String get authPermissionCameraTitle => 'Дайте Later доступ к камере';

  @override
  String get authPermissionContactsText =>
      'Находите друзей из контактов и приглашайте их!';

  @override
  String get authPermissionContactsTitle => 'Доступ к контактам';

  @override
  String get authPermissionEnable => 'Разрешить';

  @override
  String get authPermissionGranted => 'Разрешено';

  @override
  String get authPermissionLocationText =>
      'И вы сможете находить капсулы рядом с собой!';

  @override
  String get authPermissionLocationTitle => 'Поделитесь с нами геопозицией';

  @override
  String get authPermissionMicrophoneText =>
      'Без него камера не будет работать';

  @override
  String get authPermissionMicrophoneTitle => 'Дайте Later доступ к микрофону';

  @override
  String get authPermissionNotificationsText =>
      'Узнавайте о новых подписчиках и капсулах!';

  @override
  String get authPermissionNotificationsTitle => 'Включите уведомления';

  @override
  String get authPrivacyPolicy => 'Политику конфиденциальности';

  @override
  String get authResetDescription =>
      'Введите адрес электронной почты, и мы пришлём ссылку для сброса пароля';

  @override
  String get authResetInvalidEmail => 'Некорректный адрес электронной почты';

  @override
  String get authResetSend => 'Отправить ссылку';

  @override
  String get authResetSent =>
      'Письмо для сброса пароля отправлено! Проверьте почту.';

  @override
  String get authResetTitle => 'Сброс пароля';

  @override
  String get authResetUserNotFound => 'Аккаунт с этим адресом не найден';

  @override
  String get authShowPassword => 'Показать пароль';

  @override
  String get authSignInAgain => 'Войдите в аккаунт ещё раз.';

  @override
  String get authSignUpButton => 'Создать аккаунт';

  @override
  String get authSignupSubtitle => 'Заполните данные, чтобы создать аккаунт';

  @override
  String get authSignupTitle => 'Регистрация';

  @override
  String get authTermsOfUse => 'Условия использования';

  @override
  String get authUsernameHint => 'Имя пользователя';

  @override
  String get authWelcomeSubtitle =>
      'Создайте аккаунт и смотрите\nсвои капсулы и капсулы друзей';

  @override
  String get authWelcomeTo => 'Добро пожаловать в';

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
  String get messagesBlockedByYou => 'Вы заблокировали этого пользователя';

  @override
  String get messagesCantSend => 'Вы не можете писать этому пользователю';

  @override
  String get messagesCapsuleLabel => 'Капсула';

  @override
  String get messagesCapsuleUnavailable => 'Эта капсула больше недоступна';

  @override
  String get messagesChatFallbackTitle => 'Чат';

  @override
  String get messagesChatOptions => 'Меню чата';

  @override
  String get messagesChatsLoadError => 'Не удалось загрузить чаты';

  @override
  String get messagesCheckConnection =>
      'Проверьте подключение и попробуйте ещё раз';

  @override
  String get messagesClearConfirm => 'Очистить';

  @override
  String get messagesClearConfirmTitle =>
      'Вы уверены, что хотите очистить историю чата?';

  @override
  String get messagesClearFailed => 'Не удалось очистить историю';

  @override
  String messagesEmptySubtitle(String name) {
    return '$name ждёт вашего привета!';
  }

  @override
  String get messagesEmptyTitle => 'Пока нет сообщений';

  @override
  String get messagesFindChatsHint => 'Поиск чатов';

  @override
  String get messagesInputHint => 'Напишите сообщение...';

  @override
  String get messagesLoadError => 'Не удалось загрузить сообщения';

  @override
  String get messagesMenuBlock => 'Заблокировать';

  @override
  String get messagesMenuClearHistory => 'Очистить историю';

  @override
  String get messagesMenuMute => 'Отключить уведомления';

  @override
  String get messagesMenuSearch => 'Поиск';

  @override
  String get messagesMenuUnblock => 'Разблокировать';

  @override
  String get messagesMenuUnmute => 'Включить уведомления';

  @override
  String get messagesMutedToast => 'Уведомления чата отключены';

  @override
  String get messagesNewChatFindFriends => 'Найти друзей';

  @override
  String get messagesNewChatNoFriends => 'Пока нет друзей';

  @override
  String get messagesNewChatNoFriendsSubtitle =>
      'Добавьте друзей, чтобы начать общаться!';

  @override
  String get messagesNewChatNoMatch => 'Друзья не найдены';

  @override
  String get messagesNewChatSearchHint => 'Поиск друзей';

  @override
  String get messagesNewChatTitle => 'Новый чат';

  @override
  String get messagesNoChatsFound => 'Чаты не найдены';

  @override
  String get messagesNoChatsSubtitle =>
      'Нажмите кнопку нового сообщения и начните общаться с друзьями!';

  @override
  String get messagesNoChatsTitle => 'Пока нет переписок';

  @override
  String get messagesNoMatchTitle => 'Сообщения не найдены';

  @override
  String messagesNothingMatches(String query) {
    return 'По запросу «$query» ничего не найдено';
  }

  @override
  String get messagesNotificationsMuted => 'Уведомления отключены';

  @override
  String messagesOpenCapsule(String title) {
    return 'Открыть капсулу «$title»';
  }

  @override
  String get messagesReceiptFailed =>
      'Не отправлено · Нажмите, чтобы повторить';

  @override
  String get messagesReceiptRead => 'Прочитано';

  @override
  String get messagesReceiptSending => 'Отправка…';

  @override
  String get messagesReceiptSent => 'Отправлено';

  @override
  String get messagesScrollToLatest => 'К последнему сообщению';

  @override
  String get messagesSearchHint => 'Поиск сообщений';

  @override
  String get messagesSend => 'Отправить';

  @override
  String get messagesSendCapsule => 'Отправить капсулу';

  @override
  String get messagesSendFailed => 'Не удалось отправить сообщение';

  @override
  String get messagesSignedOut => 'Вы вышли из аккаунта';

  @override
  String messagesStartChatWith(String name) {
    return 'Начать чат: $name';
  }

  @override
  String get messagesTitle => 'Мои Laters';

  @override
  String get messagesToday => 'Сегодня';

  @override
  String get messagesTooLong => 'Сообщение слишком длинное';

  @override
  String get messagesUnmutedToast => 'Уведомления чата включены';

  @override
  String get messagesYesterday => 'Вчера';

  @override
  String messagesYouPrefix(String message) {
    return 'Вы: $message';
  }

  @override
  String get placeNoLocation => 'Нет геопозиции';

  @override
  String get placeUnknown => 'Неизвестное место';
}
