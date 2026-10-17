// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get achievementAnimator => 'Аниматор';

  @override
  String achievementAnimatorGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Сделайте $count живые капсулы',
      many: 'Сделайте $count живых капсул',
      few: 'Сделайте $count живые капсулы',
      one: 'Сделайте $count живую капсулу',
    );
    return '$_temp0';
  }

  @override
  String get achievementChatterbox => 'Душа компании';

  @override
  String achievementChatterboxGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Напишите $count комментария',
      many: 'Напишите $count комментариев',
      few: 'Напишите $count комментария',
      one: 'Напишите $count комментарий',
    );
    return '$_temp0';
  }

  @override
  String get achievementCollector => 'Коллекционер';

  @override
  String achievementCollectorGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Создайте $count капсулы',
      many: 'Создайте $count капсул',
      few: 'Создайте $count капсулы',
      one: 'Создайте $count капсулу',
    );
    return '$_temp0';
  }

  @override
  String get achievementCrowdPleaser => 'Любимец публики';

  @override
  String achievementCrowdPleaserGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Получите $count реакции',
      many: 'Получите $count реакций',
      few: 'Получите $count реакции',
      one: 'Получите $count реакцию',
    );
    return '$_temp0';
  }

  @override
  String get achievementEarlyBird => 'Жаворонок';

  @override
  String achievementEarlyBirdGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Создайте $count капсулы с 5 до 8 утра',
      many: 'Создайте $count капсул с 5 до 8 утра',
      few: 'Создайте $count капсулы с 5 до 8 утра',
      one: 'Создайте $count капсулу с 5 до 8 утра',
    );
    return '$_temp0';
  }

  @override
  String get achievementExplorer => 'Исследователь';

  @override
  String achievementExplorerGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Оставьте капсулы в $count разных местах',
      many: 'Оставьте капсулы в $count разных местах',
      few: 'Оставьте капсулы в $count разных местах',
      one: 'Оставьте капсулы в $count месте',
    );
    return '$_temp0';
  }

  @override
  String get achievementFirstCapsule => 'Первая капсула';

  @override
  String get achievementFirstCapsuleGoal => 'Создайте первую капсулу';

  @override
  String get achievementFriendly => 'Дружелюбный';

  @override
  String achievementFriendlyGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Заведите $count друга',
      many: 'Заведите $count друзей',
      few: 'Заведите $count друзей',
      one: 'Заведите $count друга',
    );
    return '$_temp0';
  }

  @override
  String get achievementNightOwl => 'Сова';

  @override
  String achievementNightOwlGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Создайте $count капсулы с полуночи до 5 утра',
      many: 'Создайте $count капсул с полуночи до 5 утра',
      few: 'Создайте $count капсулы с полуночи до 5 утра',
      one: 'Создайте $count капсулу с полуночи до 5 утра',
    );
    return '$_temp0';
  }

  @override
  String get achievementOpenBook => 'Открытая книга';

  @override
  String achievementOpenBookGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Поделитесь $count публичными капсулами',
      many: 'Поделитесь $count публичными капсулами',
      few: 'Поделитесь $count публичными капсулами',
      one: 'Поделитесь $count публичной капсулой',
    );
    return '$_temp0';
  }

  @override
  String get achievementStreak => 'В ударе';

  @override
  String achievementStreakGoal(int count) {
    return 'Держите серию $count дн.';
  }

  @override
  String get achievementTraveler => 'Путешественник';

  @override
  String achievementTravelerGoal(String km) {
    return 'Преодолейте $km км между своими капсулами';
  }

  @override
  String get achievementsDescription =>
      'Открываются, когда вы пользуетесь Later, а не за деньги';

  @override
  String get achievementsLocked => 'Закрыто';

  @override
  String get achievementsNoneYet => 'До первого — всего одна капсула.';

  @override
  String achievementsProgress(String value, String goal) {
    return '$value из $goal';
  }

  @override
  String get achievementsSeeAll => 'Все';

  @override
  String achievementsStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Серия: $count дня',
      many: 'Серия: $count дней',
      few: 'Серия: $count дня',
      one: 'Серия: $count день',
    );
    return '$_temp0';
  }

  @override
  String get achievementsStreakKeep =>
      'Создайте капсулу сегодня, чтобы не прервать серию';

  @override
  String get achievementsStreakTodayDone => 'Сегодня уже засчитано';

  @override
  String achievementsTier(int tier, int tiers) {
    return 'Уровень $tier из $tiers';
  }

  @override
  String get achievementsTitle => 'Достижения';

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
  String get authPermissionEnable => 'Разрешить';

  @override
  String get authPermissionLocationText =>
      'И вы сможете находить капсулы рядом с собой!';

  @override
  String get authPermissionLocationTitle => 'Поделитесь с нами геопозицией';

  @override
  String get authPermissionNotNow => 'Не сейчас';

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
  String get capsulesCameraAccessDenied =>
      'Разрешите доступ к камере в настройках, чтобы сделать фото';

  @override
  String get capsulesCameraFlashOff => 'Вспышка выключена';

  @override
  String get capsulesCameraFlashOn => 'Вспышка включена';

  @override
  String get capsulesCameraStartFailed => 'Не удалось запустить камеру';

  @override
  String get capsulesCameraSwitch => 'Сменить камеру';

  @override
  String get capsulesCameraTakePhoto => 'Сделать фото';

  @override
  String get capsulesCameraUnavailable => 'Камера недоступна';

  @override
  String get capsulesColorBlue => 'Синий';

  @override
  String get capsulesColorGreen => 'Зелёный';

  @override
  String get capsulesColorOrange => 'Оранжевый';

  @override
  String get capsulesColorPurple => 'Фиолетовый';

  @override
  String get capsulesColorRed => 'Красный';

  @override
  String get capsulesColorYellow => 'Жёлтый';

  @override
  String get capsulesCommentDelete => 'Удалить комментарий';

  @override
  String get capsulesCommentDeleteConfirm => 'Удалить этот комментарий?';

  @override
  String get capsulesCommentDeleteFailed => 'Не удалось удалить комментарий';

  @override
  String get capsulesCommentFailed => 'Не удалось отправить комментарий';

  @override
  String get capsulesCommentHint => 'Напишите комментарий...';

  @override
  String get capsulesCommentTooLong =>
      'Комментарий может быть не длиннее 500 символов';

  @override
  String get capsulesComments => 'Комментарии';

  @override
  String capsulesCommentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count комментария',
      many: '$count комментариев',
      few: '$count комментария',
      one: '$count комментарий',
      zero: 'Комментировать',
    );
    return '$_temp0';
  }

  @override
  String get capsulesCommentsEmpty => 'Комментариев пока нет';

  @override
  String get capsulesCommentsEmptyHint => 'Напишите первым.';

  @override
  String get capsulesCreationAllowComments => 'Разрешить комментарии';

  @override
  String get capsulesCreationAllowReactions => 'Разрешить реакции';

  @override
  String get capsulesCreationApproximate => 'Примерное место';

  @override
  String get capsulesCreationApproximateHint =>
      'Примерно в километре, а не точно';

  @override
  String get capsulesCreationColor => 'Цвет';

  @override
  String get capsulesCreationDescriptionHint => 'Добавьте описание...';

  @override
  String get capsulesCreationOpenAt => 'Откроется';

  @override
  String get capsulesCreationPreview => 'Предпросмотр капсулы';

  @override
  String get capsulesCreationPrivacy => 'Видимость';

  @override
  String get capsulesCreationSelectDate => 'Выберите дату';

  @override
  String get capsulesCreationSettings => 'Настройки капсулы';

  @override
  String get capsulesCreationSubmit => 'Создать капсулу';

  @override
  String get capsulesCreationTitle => 'Создать капсулу';

  @override
  String get capsulesCreationTitleHint => 'Название...';

  @override
  String get capsulesDefaultTitle => 'Капсула';

  @override
  String get capsulesErrorNoLocation => 'Не удалось определить вашу геопозицию';

  @override
  String get capsulesErrorSaveFailed => 'Не удалось сохранить капсулу';

  @override
  String get capsulesErrorSavedNotSent =>
      'Капсула сохранена, но не отправлена. Нажмите кнопку ещё раз, чтобы повторить.';

  @override
  String get capsulesPrivacyFriends => 'Для друзей';

  @override
  String get capsulesPrivacyPrivate => 'Личная';

  @override
  String get capsulesPrivacyPublic => 'Публичная';

  @override
  String capsulesReactWith(String emoji) {
    return 'Реакция $emoji';
  }

  @override
  String get capsulesReactionFailed => 'Не удалось сохранить реакцию';

  @override
  String get capsulesReply => 'Ответить';

  @override
  String capsulesReplyHint(String name) {
    return 'Ответ для $name...';
  }

  @override
  String get capsulesReport => 'Пожаловаться';

  @override
  String get capsulesReportAbuse => 'Оскорбления или ненависть';

  @override
  String get capsulesReportCapsule => 'Пожаловаться на капсулу';

  @override
  String get capsulesReportNudity => 'Обнажённость';

  @override
  String get capsulesReportOther => 'Другое';

  @override
  String get capsulesReportPrivacy => 'Личная информация';

  @override
  String get capsulesReportSent =>
      'Спасибо, что сообщили. Команда Later посмотрит.';

  @override
  String get capsulesReportSpam => 'Спам';

  @override
  String get capsulesReportTitle => 'Что не так?';

  @override
  String get capsulesReportViolence => 'Насилие';

  @override
  String get capsulesYou => 'Вы';

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
  String commonSizeBytes(String size) {
    return '$size Б';
  }

  @override
  String commonSizeGigabytes(String size) {
    return '$size ГБ';
  }

  @override
  String commonSizeKilobytes(String size) {
    return '$size КБ';
  }

  @override
  String commonSizeMegabytes(String size) {
    return '$size МБ';
  }

  @override
  String get commonUnknownUser => 'Неизвестный пользователь';

  @override
  String get commonUnknownUsername => 'неизвестно';

  @override
  String get commonUntitled => 'Без названия';

  @override
  String get commonUsernameRequired => 'Введите имя пользователя';

  @override
  String get commonUsernameRules =>
      'Используйте от 3 до 30 латинских букв, цифр, точек, дефисов или подчёркиваний';

  @override
  String get commonUsernameTaken => 'Это имя пользователя уже занято';

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
  String get friendsFindByUsernameHint =>
      'Найдите человека по @нику или отсканируйте QR-код друга. Здесь появятся знакомые ваших друзей.';

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
  String friendsMutualCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count общих друга',
      many: '$count общих друзей',
      few: '$count общих друга',
      one: '$count общий друг',
    );
    return '$_temp0';
  }

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
  String get historyAddToFavorites => 'Добавить в избранное';

  @override
  String get historyCapsuleOpened => 'Капсула открыта!';

  @override
  String get historyColorBlue => 'Синий';

  @override
  String get historyColorGreen => 'Зелёный';

  @override
  String get historyColorOrange => 'Оранжевый';

  @override
  String get historyColorPurple => 'Фиолетовый';

  @override
  String get historyColorRed => 'Красный';

  @override
  String get historyColorYellow => 'Жёлтый';

  @override
  String historyCountdown(int days, int hours, int minutes, int seconds) {
    return '$daysд $hoursч $minutesм $secondsс';
  }

  @override
  String historyCountdownYears(int years, int days, int hours, int minutes) {
    return '$yearsг $daysд $hoursч $minutesм';
  }

  @override
  String historyDeleteConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Удалить $count капсулы?',
      many: 'Удалить $count капсул?',
      few: 'Удалить $count капсулы?',
      one: 'Удалить $count капсулу?',
    );
    return '$_temp0';
  }

  @override
  String historyDeleteSelected(int count) {
    return 'Удалить ($count)';
  }

  @override
  String historyDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count капсулы удалено',
      many: '$count капсул удалено',
      few: '$count капсулы удалены',
      one: '$count капсула удалена',
    );
    return '$_temp0';
  }

  @override
  String historyDistanceFromYou(String distance) {
    return '$distance км от вас';
  }

  @override
  String get historyDistanceUnknown => 'Расстояние неизвестно';

  @override
  String get historyEmpty => 'Пока нет капсул';

  @override
  String get historyErrorDelete => 'Не удалось удалить капсулы';

  @override
  String get historyErrorFavorites => 'Не удалось обновить избранное';

  @override
  String historyFavoriteAdded(String title) {
    return 'Капсула «$title» добавлена в избранное';
  }

  @override
  String historyFavoriteRemoved(String title) {
    return 'Капсула «$title» убрана из избранного';
  }

  @override
  String get historyFilterAny => 'Все';

  @override
  String get historyFilterBy => 'Фильтр';

  @override
  String get historyFilterCapsule => 'Капсулы';

  @override
  String get historyFilterColor => 'Цвет';

  @override
  String get historyFilterFavorite => 'Избранные';

  @override
  String get historyFilterVisibility => 'Видимость';

  @override
  String get historyNoMatches => 'По вашему запросу капсул нет';

  @override
  String get historyPrivacyFriends => 'Для друзей';

  @override
  String get historyPrivacyPrivate => 'Личная';

  @override
  String get historyPrivacyPublic => 'Публичная';

  @override
  String get historyRemoveFromFavorites => 'Убрать из избранного';

  @override
  String get historyReset => 'Сбросить';

  @override
  String get historySearchHint => 'Найти капсулы...';

  @override
  String historySelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Выбрано: $count',
      many: 'Выбрано: $count',
      few: 'Выбрано: $count',
      one: 'Выбрано: $count',
    );
    return '$_temp0';
  }

  @override
  String get historySortBy => 'Порядок';

  @override
  String get historySortClosest => 'Сначала ближние';

  @override
  String get historySortDistance => 'Расстояние';

  @override
  String get historySortFarthest => 'Сначала дальние';

  @override
  String get historySortNewest => 'Сначала новые';

  @override
  String get historySortOldest => 'Сначала старые';

  @override
  String get historySortRelevance => 'Актуальность';

  @override
  String get historyTitle => 'Мои капсулы';

  @override
  String get historyVisibilityFriends => 'Для друзей';

  @override
  String get historyVisibilityPrivate => 'Личная';

  @override
  String get historyVisibilityPublic => 'Публичная';

  @override
  String get mapCapsuleLocked => 'Закрыта';

  @override
  String get mapCapsuleNoDescription => 'У этой капсулы нет описания.';

  @override
  String get mapCapsuleOpen => 'Открыть';

  @override
  String mapCapsuleOpensIn(String time) {
    return 'Откроется через $time';
  }

  @override
  String get mapCapsuleReady => 'Посмотрите, что внутри!';

  @override
  String mapDurationDays(int count) {
    return '$countд';
  }

  @override
  String mapDurationHours(int count) {
    return '$countч';
  }

  @override
  String mapDurationMinutes(int count) {
    return '$countмин';
  }

  @override
  String mapDurationSeconds(int count) {
    return '$countс';
  }

  @override
  String get mapLocationDenied =>
      'Разрешите доступ к геопозиции, чтобы видеть капсулы рядом с вами';

  @override
  String get mapLocationServiceOff =>
      'Включите геолокацию, чтобы видеть капсулы рядом с вами';

  @override
  String get mapLocationUnknown => 'Не удалось определить вашу геопозицию';

  @override
  String get mapMyLocation => 'Моё местоположение';

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
  String get navMap => 'Карта';

  @override
  String get navMessages => 'Сообщения';

  @override
  String get navMyCapsules => 'Мои капсулы';

  @override
  String get navNewCapsule => 'Новая капсула';

  @override
  String get navProfile => 'Профиль';

  @override
  String notificationsAchievementBody(String name) {
    return '$name: у вас новое достижение';
  }

  @override
  String notificationsCapsuleBody(String name) {
    return '$name делится новой капсулой';
  }

  @override
  String get notificationsChannelActivity => 'Активность';

  @override
  String get notificationsChannelActivityDescription =>
      'Подписчики, заявки в друзья, реакции, комментарии и новые капсулы';

  @override
  String get notificationsChannelActivitySilent => 'Активность (без звука)';

  @override
  String get notificationsChannelActivitySilentDescription =>
      'Активность без звука и вибрации';

  @override
  String get notificationsChannelMessages => 'Сообщения';

  @override
  String get notificationsChannelMessagesDescription =>
      'Новые сообщения от друзей';

  @override
  String get notificationsChannelMessagesSilent => 'Сообщения (без звука)';

  @override
  String get notificationsChannelMessagesSilentDescription =>
      'Новые сообщения без звука и вибрации';

  @override
  String get notificationsChannelOther => 'Другие уведомления';

  @override
  String get notificationsChannelOtherDescription =>
      'Другие уведомления от Later';

  @override
  String notificationsCommentBody(String name) {
    return '$name комментирует вашу капсулу';
  }

  @override
  String notificationsCommentBodyWithText(String name, String text) {
    return '$name комментирует: $text';
  }

  @override
  String notificationsDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня назад',
      many: '$count дней назад',
      few: '$count дня назад',
      one: '$count день назад',
    );
    return '$_temp0';
  }

  @override
  String notificationsDeleteConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Удалить $count уведомления?',
      many: 'Удалить $count уведомлений?',
      few: 'Удалить $count уведомления?',
      one: 'Удалить $count уведомление?',
    );
    return '$_temp0';
  }

  @override
  String notificationsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count уведомления удалено',
      many: '$count уведомлений удалено',
      few: '$count уведомления удалены',
      one: '$count уведомление удалено',
    );
    return '$_temp0';
  }

  @override
  String get notificationsEmptyAll =>
      'Здесь появятся ваши уведомления и активность';

  @override
  String get notificationsEmptyComments =>
      'Здесь появятся комментарии к вашим капсулам';

  @override
  String get notificationsEmptyReplies =>
      'Здесь появятся ответы на ваши сообщения';

  @override
  String notificationsFollowBody(String name) {
    return '$name — ваш новый подписчик';
  }

  @override
  String notificationsFriendAcceptedBody(String name) {
    return '$name принимает вашу заявку в друзья';
  }

  @override
  String notificationsFriendRequestBody(String name) {
    return '$name хочет добавить вас в друзья';
  }

  @override
  String notificationsHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count часа назад',
      many: '$count часов назад',
      few: '$count часа назад',
      one: '$count час назад',
    );
    return '$_temp0';
  }

  @override
  String get notificationsJustNow => 'Только что';

  @override
  String get notificationsMarkAsRead => 'Отметить как прочитанные';

  @override
  String notificationsMarkedRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count уведомления прочитано',
      many: '$count уведомлений прочитано',
      few: '$count уведомления прочитаны',
      one: '$count уведомление прочитано',
    );
    return '$_temp0';
  }

  @override
  String notificationsMessageBody(String name) {
    return '$name пишет вам';
  }

  @override
  String notificationsMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count минуты назад',
      many: '$count минут назад',
      few: '$count минуты назад',
      one: '$count минуту назад',
    );
    return '$_temp0';
  }

  @override
  String notificationsReactionBody(String name, String emoji) {
    return '$name реагирует $emoji на вашу капсулу';
  }

  @override
  String notificationsReplyBody(String name) {
    return '$name отвечает вам';
  }

  @override
  String notificationsReplyBodyWithText(String name, String text) {
    return '$name отвечает: $text';
  }

  @override
  String notificationsSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count выбрано',
      many: '$count выбрано',
      few: '$count выбрано',
      one: '$count выбрано',
    );
    return '$_temp0';
  }

  @override
  String get notificationsTabAll => 'Все';

  @override
  String get notificationsTabComments => 'Комментарии';

  @override
  String get notificationsTabReplies => 'Ответы';

  @override
  String get notificationsTitle => 'Уведомления';

  @override
  String get notificationsTypeAchievement => 'Достижение';

  @override
  String get notificationsTypeCapsule => 'Новая капсула';

  @override
  String get notificationsTypeComment => 'Новый комментарий';

  @override
  String get notificationsTypeFollow => 'Новый подписчик';

  @override
  String get notificationsTypeFriendAccepted => 'Новый друг';

  @override
  String get notificationsTypeFriendRequest => 'Заявка в друзья';

  @override
  String get notificationsTypeMessage => 'Новое сообщение';

  @override
  String get notificationsTypeOther => 'Уведомление';

  @override
  String get notificationsTypeReaction => 'Новая реакция';

  @override
  String get notificationsTypeReply => 'Новый ответ';

  @override
  String notificationsUnreadBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count непрочитанного уведомления',
      many: '$count непрочитанных уведомлений',
      few: '$count непрочитанных уведомления',
      one: '$count непрочитанное уведомление',
    );
    return '$_temp0';
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
  String profileFollowers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count подписчика',
      many: '$count подписчиков',
      few: '$count подписчика',
      one: '$count подписчик',
    );
    return '$_temp0';
  }

  @override
  String profileFollowing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count подписки',
      many: '$count подписок',
      few: '$count подписки',
      one: '$count подписка',
    );
    return '$_temp0';
  }

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
  String get profileVerified => 'Подтверждённый аккаунт';

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
  String get settingsAppearance => 'Оформление';

  @override
  String get settingsAppearanceDescription =>
      'Как Later выглядит на этом телефоне';

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
  String get settingsLanguage => 'Язык';

  @override
  String get settingsLanguageDescription =>
      'Язык приложения и ваших уведомлений';

  @override
  String get settingsLanguageFooter =>
      'Уведомления от Later тоже будут приходить на этом языке.';

  @override
  String get settingsLanguageSystem => 'Язык телефона';

  @override
  String settingsLanguageSystemHint(String language) {
    return 'Сейчас: $language';
  }

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
  String get settingsNotificationsAchievements => 'Достижения';

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
  String get settingsNotificationsComments => 'Комментарии';

  @override
  String get settingsNotificationsCommentsHint =>
      'К вашим капсулам и ответы вам';

  @override
  String get settingsNotificationsDescription =>
      'Выберите, о чём Later будет вам сообщать';

  @override
  String get settingsNotificationsFollowers => 'Новые подписчики';

  @override
  String get settingsNotificationsFriendRequests => 'Заявки в друзья';

  @override
  String get settingsNotificationsFriendRequestsHint => 'Новые и принятые';

  @override
  String get settingsNotificationsMessages => 'Сообщения';

  @override
  String get settingsNotificationsMuteHint =>
      'Отключить уведомления отдельного чата можно в его меню в разделе «Сообщения».';

  @override
  String get settingsNotificationsNews => 'Новости Later';

  @override
  String get settingsNotificationsNewsHint => 'Редкие объявления от команды';

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
  String get settingsNotificationsReactions => 'Реакции';

  @override
  String get settingsNotificationsSound => 'Звук и вибрация';

  @override
  String get settingsNotificationsStreak => 'Напоминание о серии';

  @override
  String get settingsNotificationsStreakHint =>
      'Вечером, если серия сегодня прервётся';

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
  String get settingsPrivacy => 'Приватность';

  @override
  String get settingsPrivacyAchievements => 'Показывать мои достижения';

  @override
  String get settingsPrivacyAchievementsHint =>
      'Друзья видят их в вашем профиле';

  @override
  String get settingsPrivacyApproximate => 'Примерное местоположение';

  @override
  String get settingsPrivacyApproximateHint =>
      'Новые капсулы ставятся в радиусе около километра, а не в точном месте';

  @override
  String get settingsPrivacyDescription =>
      'Что видят другие и какими будут новые капсулы';

  @override
  String get settingsPrivacyNewCapsulesFooter =>
      'Оба параметра можно изменить для каждой капсулы при создании.';

  @override
  String get settingsPrivacyReadReceipts => 'Отчёты о прочтении';

  @override
  String get settingsPrivacyReadReceiptsHint =>
      'Если выключить, друзья не увидят, что вы прочитали их сообщения, а вы не увидите этого у них';

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
  String get settingsSectionMoreActivity => 'АКТИВНОСТЬ';

  @override
  String get settingsSectionNewCapsules => 'НОВЫЕ КАПСУЛЫ';

  @override
  String get settingsSectionNotificationsPrivacy => 'УВЕДОМЛЕНИЯ И ПРИВАТНОСТЬ';

  @override
  String get settingsSectionNotifyAbout => 'О ЧЁМ УВЕДОМЛЯТЬ';

  @override
  String get settingsSectionQuestions => 'ВОПРОСЫ';

  @override
  String get settingsSectionQuietHours => 'ТИХИЕ ЧАСЫ';

  @override
  String get settingsSectionSize => 'РАЗМЕР';

  @override
  String get settingsSectionSupport => 'ПОДДЕРЖКА';

  @override
  String get settingsSectionTheme => 'ТЕМА';

  @override
  String get settingsSectionThisPhone => 'ЭТОТ ТЕЛЕФОН';

  @override
  String get settingsSectionVisibility => 'ЧТО ВИДЯТ ДРУГИЕ';

  @override
  String get settingsSignedInWithGoogle => 'Вход через Google';

  @override
  String get settingsSizeFooter =>
      'Делает всё на экране мельче или крупнее, включая текст.';

  @override
  String get settingsSizeLarge => 'Крупный';

  @override
  String get settingsSizeSmall => 'Мелкий';

  @override
  String get settingsSizeStandard => 'Обычный';

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
  String get settingsThemeDark => 'Тёмная';

  @override
  String get settingsThemeLight => 'Светлая';

  @override
  String get settingsThemeSystem => 'Как на телефоне';

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
  String get settingsVisibilityFriends => 'Для друзей';

  @override
  String get settingsVisibilityFriendsHint => 'Только ваши друзья';

  @override
  String get settingsVisibilityPrivate => 'Личная';

  @override
  String get settingsVisibilityPrivateHint => 'Только вы';

  @override
  String get settingsVisibilityPublic => 'Публичная';

  @override
  String get settingsVisibilityPublicHint => 'Все на карте';

  @override
  String get settingsYourPassword => 'Ваш пароль';
}
