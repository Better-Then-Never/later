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
}
