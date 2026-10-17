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
  String get friendsAccept => 'Принять';

  @override
  String get friendsAcceptRequestLabel => 'Принять заявку в друзья';

  @override
  String get friendsAdd => 'Добавить';

  @override
  String get friendsAddTitle => 'Добавить друзей';

  @override
  String get friendsBlock => 'Заблокировать';

  @override
  String get friendsBlockConfirm => 'Точно заблокировать этого пользователя?';

  @override
  String get friendsCapsulesSettings => 'Настройки капсул';

  @override
  String get friendsChatSettings => 'Настройки чата';

  @override
  String get friendsEmpty => 'Вы пока не добавили друзей';

  @override
  String get friendsErrorAcceptRequest => 'Не удалось принять заявку';

  @override
  String get friendsErrorBlock => 'Не удалось заблокировать пользователя';

  @override
  String get friendsErrorCancelRequest => 'Не удалось отменить заявку';

  @override
  String get friendsErrorFollow => 'Не удалось подписаться';

  @override
  String get friendsErrorLoadUsers => 'Не удалось загрузить пользователей';

  @override
  String get friendsErrorRejectRequest => 'Не удалось отклонить заявку';

  @override
  String get friendsErrorRemoveFriend => 'Не удалось удалить из друзей';

  @override
  String get friendsErrorSendRequest => 'Не удалось отправить заявку в друзья';

  @override
  String get friendsErrorUnblock => 'Не удалось разблокировать пользователя';

  @override
  String get friendsErrorUnfollow => 'Не удалось отписаться';

  @override
  String get friendsFollow => 'Подписаться';

  @override
  String get friendsFollowed =>
      'Вы подписались! Будем сообщать о новых капсулах';

  @override
  String get friendsFollowing => 'Вы подписаны';

  @override
  String get friendsFriendCapsulesEmpty => 'Здесь появятся капсулы друга';

  @override
  String get friendsFriendCapsulesTitle => 'Капсулы друга';

  @override
  String get friendsHideSuggestionLabel => 'Скрыть рекомендацию';

  @override
  String get friendsMakeFriends => 'Найдите друзей';

  @override
  String get friendsManageFriendship => 'Настройки дружбы';

  @override
  String get friendsMyFriendsTitle => 'Мои друзья';

  @override
  String get friendsMyProfile => 'Мой профиль';

  @override
  String get friendsNoMatches => 'Среди друзей никого не нашлось';

  @override
  String get friendsNoSuggestions => 'Больше рекомендаций нет';

  @override
  String get friendsOpenChat => 'Открыть чат';

  @override
  String get friendsPending => 'Заявка отправлена';

  @override
  String get friendsQrHint => 'Наведите камеру на QR-код, чтобы добавить друга';

  @override
  String get friendsQrInvalid =>
      'Неверный QR-код. Отсканируйте QR-код профиля Later.';

  @override
  String get friendsQrTitle => 'Сканировать QR-код';

  @override
  String get friendsReject => 'Отклонить';

  @override
  String get friendsRemove => 'Удалить из друзей';

  @override
  String get friendsRemoveAction => 'Удалить';

  @override
  String get friendsRemoveConfirm => 'Точно удалить пользователя из друзей?';

  @override
  String get friendsRemoving => 'Удаляем...';

  @override
  String get friendsReport => 'Пожаловаться';

  @override
  String get friendsRequestAccepted => 'Заявка в друзья принята!';

  @override
  String get friendsRequestAlreadyExists => 'Заявка в друзья уже отправлена';

  @override
  String get friendsRequestCancelled => 'Заявка в друзья отменена';

  @override
  String get friendsRequestPendingInfo => 'Заявка в друзья ждёт ответа';

  @override
  String get friendsRequestReceivedInfo =>
      'Этот пользователь отправил вам заявку в друзья';

  @override
  String get friendsRequestRejected => 'Заявка в друзья отклонена';

  @override
  String get friendsRequestSent => 'Заявка в друзья отправлена!';

  @override
  String get friendsRequestsButton => 'Заявки';

  @override
  String get friendsRequestsEmptySubtitle =>
      'Когда кто-то отправит вам заявку в друзья,\nона появится здесь';

  @override
  String get friendsRequestsEmptyTitle => 'Нет заявок в друзья';

  @override
  String get friendsRequestsReceivedTab => 'Входящие';

  @override
  String get friendsRequestsSentTab => 'Отправленные';

  @override
  String get friendsRequestsTitle => 'Заявки в друзья';

  @override
  String get friendsSearchByTagHint => 'Поиск по нику';

  @override
  String get friendsSearchHint => 'Поиск среди друзей';

  @override
  String get friendsSendCapsule => 'Отправить капсулу';

  @override
  String get friendsSendRequestLabel => 'Отправить заявку в друзья';

  @override
  String get friendsSentEmptySubtitle =>
      'Здесь появятся заявки в друзья,\nкоторые вы отправите';

  @override
  String get friendsSentEmptyTitle => 'Нет отправленных заявок';

  @override
  String get friendsShareProfile => 'Поделиться профилем';

  @override
  String get friendsShareProfileTo => 'Поделиться профилем ...';

  @override
  String get friendsSuggestionRemoved => 'Рекомендация убрана из списка!';

  @override
  String get friendsThisIsYou => 'Это ваш аккаунт';

  @override
  String get friendsUnfollowed => 'Вы отписались';

  @override
  String get friendsViewProfile => 'Открыть профиль';

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

  @override
  String get profileAddFriends => 'Добавить друзей';

  @override
  String get profileAddToMapEveryone => 'На карту | Для всех';

  @override
  String get profileAddToMapFriends => 'На карту | Для друзей';

  @override
  String get profileBackgroundDelete => 'Удалить фон';

  @override
  String get profileBackgroundTitle => 'Фон профиля';

  @override
  String get profileBackgroundUpdated => 'Фон профиля обновлён!';

  @override
  String get profileChoosePinned => 'Закрепить друзей';

  @override
  String get profileCopyLink => 'Копировать';

  @override
  String get profileErrorCopyLink => 'Не удалось скопировать ссылку';

  @override
  String get profileErrorDeleteBackground => 'Не удалось удалить фон профиля';

  @override
  String get profileErrorDeletePicture => 'Не удалось удалить фото профиля';

  @override
  String get profileErrorShare => 'Не удалось поделиться профилем';

  @override
  String get profileErrorUploadBackground => 'Не удалось загрузить фон профиля';

  @override
  String get profileErrorUploadPicture => 'Не удалось загрузить фото профиля';

  @override
  String get profileImageFromGallery => 'Выбрать из галереи';

  @override
  String get profileImageTakePhoto => 'Сделать фото';

  @override
  String get profileLinkCopied => 'Ссылка скопирована!';

  @override
  String get profileMyCapsules => 'Мои капсулы';

  @override
  String get profileMyFriends => 'Мои друзья';

  @override
  String get profileNoFriends => 'У вас пока нет друзей';

  @override
  String get profilePictureDelete => 'Удалить фото профиля';

  @override
  String get profilePictureTitle => 'Фото профиля';

  @override
  String get profilePictureUpdated => 'Фото профиля обновлено!';

  @override
  String get profilePinnedHint =>
      'Если выберете меньше трёх, покажем случайных друзей из вашего списка';

  @override
  String get profilePinnedLimit => 'Закрепить можно не больше 3 друзей';

  @override
  String get profilePinnedTitle => 'Закрепите до 3 друзей';

  @override
  String get profilePinnedUpdated => 'Закреплённые друзья обновлены!';

  @override
  String get profileQrError => 'Что-то пошло не так...';

  @override
  String get profileShare => 'Поделиться';

  @override
  String get profileShareHeading => 'Поделитесь профилем';

  @override
  String get profileShareHint =>
      'Друзья могут отсканировать этот код камерой телефона или в приложении, чтобы добавить вас';

  @override
  String profileShareMessage(String name, String link) {
    return '$name в Later — загляните!\n$link';
  }

  @override
  String profileShareSubject(String name) {
    return '$name ждёт вас в Later';
  }

  @override
  String get profileShareSubtitle =>
      'Покажите этот QR-код, чтобы вас добавили в друзья';

  @override
  String get profileShareTitle => 'Поделиться профилем';

  @override
  String get profileUpdating => 'Секунду...';

  @override
  String get profileViewProfile => 'Открыть профиль';

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
