// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get achievementAnimator => 'Animador';

  @override
  String achievementAnimatorGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Haz $count cápsulas animadas',
      one: 'Haz 1 cápsula animada',
    );
    return '$_temp0';
  }

  @override
  String get achievementChatterbox => 'Charlatán';

  @override
  String achievementChatterboxGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Escribe $count comentarios',
      one: 'Escribe 1 comentario',
    );
    return '$_temp0';
  }

  @override
  String get achievementCollector => 'Coleccionista';

  @override
  String achievementCollectorGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Crea $count cápsulas',
      one: 'Crea 1 cápsula',
    );
    return '$_temp0';
  }

  @override
  String get achievementCrowdPleaser => 'Favorito del público';

  @override
  String achievementCrowdPleaserGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Recibe $count reacciones',
      one: 'Recibe 1 reacción',
    );
    return '$_temp0';
  }

  @override
  String get achievementEarlyBird => 'Madrugador';

  @override
  String achievementEarlyBirdGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Crea $count cápsulas entre las 5 y las 8',
      one: 'Crea una cápsula entre las 5 y las 8',
    );
    return '$_temp0';
  }

  @override
  String get achievementExplorer => 'Explorador';

  @override
  String achievementExplorerGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deja cápsulas en $count lugares distintos',
      one: 'Deja una cápsula en 1 lugar',
    );
    return '$_temp0';
  }

  @override
  String get achievementFirstCapsule => 'Primera cápsula';

  @override
  String get achievementFirstCapsuleGoal => 'Crea tu primera cápsula';

  @override
  String get achievementFriendly => 'Sociable';

  @override
  String achievementFriendlyGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Haz $count amigos',
      one: 'Haz 1 amigo',
    );
    return '$_temp0';
  }

  @override
  String get achievementNightOwl => 'Ave nocturna';

  @override
  String achievementNightOwlGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Crea $count cápsulas entre la medianoche y las 5',
      one: 'Crea una cápsula entre la medianoche y las 5',
    );
    return '$_temp0';
  }

  @override
  String get achievementOpenBook => 'Libro abierto';

  @override
  String achievementOpenBookGoal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Comparte $count cápsulas públicas',
      one: 'Comparte 1 cápsula pública',
    );
    return '$_temp0';
  }

  @override
  String get achievementStreak => 'En racha';

  @override
  String achievementStreakGoal(int count) {
    return 'Mantén una racha de $count días';
  }

  @override
  String get achievementTraveler => 'Viajero';

  @override
  String achievementTravelerGoal(String km) {
    return 'Recorre $km km entre tus cápsulas';
  }

  @override
  String get achievementsDescription =>
      'Se desbloquean usando Later, nunca pagando';

  @override
  String get achievementsLocked => 'Bloqueado';

  @override
  String get achievementsNoneYet =>
      'El primero está a una cápsula de distancia.';

  @override
  String get achievementsSeeAll => 'Ver todos';

  @override
  String achievementsStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Racha de $count días',
      one: 'Racha de 1 día',
    );
    return '$_temp0';
  }

  @override
  String get achievementsStreakKeep => 'Crea una cápsula hoy para no perderla';

  @override
  String get achievementsStreakTodayDone => 'Hoy ya cuenta';

  @override
  String achievementsTier(int tier, int tiers) {
    return 'Nivel $tier de $tiers';
  }

  @override
  String get achievementsTitle => 'Logros';

  @override
  String get appName => 'Later';

  @override
  String get authContinueWithGoogle => 'Continuar con Google';

  @override
  String get authEmailHint => 'Correo electrónico';

  @override
  String get authEnterEmail => 'Escribe tu correo electrónico';

  @override
  String get authErrorEmailInUse => 'Ya existe una cuenta con este correo.';

  @override
  String get authErrorEmailTaken => 'Otra cuenta ya usa este correo.';

  @override
  String get authErrorInvalidCredential => 'Correo o contraseña incorrectos.';

  @override
  String get authErrorInvalidEmail => 'El correo electrónico no es válido.';

  @override
  String get authErrorMethodDisabled =>
      'Este método de inicio de sesión no está activado.';

  @override
  String get authErrorPickGoogleAccount =>
      'Elige la cuenta de Google con la que inicias sesión.';

  @override
  String get authErrorRecentLogin =>
      'Confirma que eres tú e inténtalo de nuevo.';

  @override
  String get authErrorTooManyRequests =>
      'Demasiados intentos. Inténtalo más tarde.';

  @override
  String get authErrorUserDisabled => 'Esta cuenta está desactivada.';

  @override
  String get authErrorUserNotFound =>
      'No se encontró ningún usuario con este correo.';

  @override
  String get authErrorWeakPassword => 'La contraseña es demasiado débil.';

  @override
  String authErrorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get authErrorWrongPassword => 'Contraseña incorrecta.';

  @override
  String get authErrorWrongPasswordProvided => 'La contraseña es incorrecta.';

  @override
  String get authFacebookSoon => 'Facebook (próximamente)';

  @override
  String get authFillAllFields => 'Completa todos los campos';

  @override
  String get authForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get authGetStarted => 'Empezar';

  @override
  String get authGoToLogIn => 'Inicia sesión';

  @override
  String get authGoToSignUp => 'Regístrate';

  @override
  String get authGoogleFailed =>
      'No se pudo iniciar sesión con Google. Inténtalo de nuevo.';

  @override
  String get authHaveAccount => '¿Ya tienes cuenta?';

  @override
  String get authHidePassword => 'Ocultar contraseña';

  @override
  String authLegalNotice(String terms, String privacy) {
    return 'Al registrarte, aceptas los $terms y la $privacy';
  }

  @override
  String get authLinkOpenFailed => 'No se pudo abrir la página.';

  @override
  String get authLogInButton => 'Entrar';

  @override
  String get authLoginSubtitle =>
      'Entra en tu cuenta para seguir usando la app';

  @override
  String get authLoginTitle => 'Inicia sesión';

  @override
  String get authNameHint => 'Nombre';

  @override
  String get authNoAccount => '¿No tienes cuenta?';

  @override
  String get authNoFreeUsername =>
      'No pudimos elegir un nombre de usuario. Regístrate, por favor.';

  @override
  String get authOrConnectWith => 'O continúa con';

  @override
  String get authPasswordHint => 'Contraseña';

  @override
  String get authPermissionCameraText => '¡Y podrás crear cápsulas del tiempo!';

  @override
  String get authPermissionCameraTitle => 'Dale a Later acceso a la cámara';

  @override
  String get authPermissionEnable => 'Permitir';

  @override
  String get authPermissionLocationText =>
      '¡Y podrás encontrar cápsulas cerca de ti!';

  @override
  String get authPermissionLocationTitle =>
      'Comparte tu ubicación con nosotros';

  @override
  String get authPermissionNotNow => 'Ahora no';

  @override
  String get authPermissionNotificationsText =>
      '¡Entérate de nuevos seguidores y cápsulas!';

  @override
  String get authPermissionNotificationsTitle => 'Activa las notificaciones';

  @override
  String get authPrivacyPolicy => 'Política de privacidad';

  @override
  String get authResetDescription =>
      'Escribe tu correo y te enviaremos un enlace para restablecer la contraseña';

  @override
  String get authResetInvalidEmail => 'Correo electrónico no válido';

  @override
  String get authResetSend => 'Enviar enlace';

  @override
  String get authResetSent =>
      '¡Te enviamos un correo para restablecer la contraseña! Revisa tu bandeja de entrada.';

  @override
  String get authResetTitle => 'Restablecer contraseña';

  @override
  String get authResetUserNotFound => 'No hay ninguna cuenta con este correo';

  @override
  String get authShowPassword => 'Mostrar contraseña';

  @override
  String get authSignInAgain => 'Vuelve a iniciar sesión.';

  @override
  String get authSignUpButton => 'Registrarse';

  @override
  String get authSignupSubtitle => 'Completa tus datos para registrarte';

  @override
  String get authSignupTitle => 'Crea tu cuenta';

  @override
  String get authTermsOfUse => 'Términos de uso';

  @override
  String get authUsernameHint => 'Nombre de usuario';

  @override
  String get authWelcomeSubtitle =>
      'Crea una cuenta para ver tus cápsulas\ny las de tus amigos';

  @override
  String get authWelcomeTo => 'Te damos la bienvenida a';

  @override
  String get capsulesCameraAccessDenied =>
      'Permite el acceso a la cámara en Ajustes para hacer una foto';

  @override
  String get capsulesCameraExposure => 'Brillo';

  @override
  String get capsulesCameraFlashAuto => 'Flash automático';

  @override
  String get capsulesCameraFlashAutoBadge => 'A';

  @override
  String get capsulesCameraFlashOff => 'Flash desactivado';

  @override
  String get capsulesCameraFlashOn => 'Flash activado';

  @override
  String get capsulesCameraFlashTorch => 'Linterna encendida';

  @override
  String get capsulesCameraFlashTorchBadge => 'L';

  @override
  String get capsulesCameraHoldForLoop => 'Mantén para un bucle';

  @override
  String get capsulesCameraStartFailed => 'No se pudo iniciar la cámara';

  @override
  String get capsulesCameraSwitch => 'Cambiar de cámara';

  @override
  String get capsulesCameraTakePhoto => 'Hacer foto';

  @override
  String get capsulesCameraTakePhotoOrLoop =>
      'Hacer foto. Mantén para grabar un bucle';

  @override
  String get capsulesCameraUnavailable => 'No hay ninguna cámara disponible';

  @override
  String capsulesCameraZoomTo(String zoom) {
    return 'Zoom $zoom×';
  }

  @override
  String get capsulesColorBlue => 'Azul';

  @override
  String get capsulesColorGreen => 'Verde';

  @override
  String get capsulesColorOrange => 'Naranja';

  @override
  String get capsulesColorPurple => 'Morado';

  @override
  String get capsulesColorRed => 'Rojo';

  @override
  String get capsulesColorYellow => 'Amarillo';

  @override
  String get capsulesCommentDelete => 'Eliminar comentario';

  @override
  String get capsulesCommentDeleteConfirm => '¿Eliminar este comentario?';

  @override
  String get capsulesCommentDeleteFailed => 'No se pudo eliminar el comentario';

  @override
  String get capsulesCommentFailed => 'No se pudo publicar tu comentario';

  @override
  String get capsulesCommentHint => 'Escribe un comentario...';

  @override
  String get capsulesCommentTooLong =>
      'Los comentarios pueden tener hasta 500 caracteres';

  @override
  String get capsulesComments => 'Comentarios';

  @override
  String capsulesCommentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comentarios',
      one: '1 comentario',
      zero: 'Comentar',
    );
    return '$_temp0';
  }

  @override
  String get capsulesCommentsEarlier => 'Ver comentarios anteriores';

  @override
  String get capsulesCommentsEmpty => 'Aún no hay comentarios';

  @override
  String get capsulesCommentsEmptyHint => 'Sé el primero en decir algo.';

  @override
  String get capsulesCreationAllowComments => 'Permitir comentarios';

  @override
  String get capsulesCreationAllowReactions => 'Permitir reacciones';

  @override
  String get capsulesCreationApproximate => 'Ubicación aproximada';

  @override
  String get capsulesCreationApproximateHint =>
      'A un kilómetro aproximado, no en el punto exacto';

  @override
  String get capsulesCreationColor => 'Color';

  @override
  String get capsulesCreationDescriptionHint => 'Añade una descripción...';

  @override
  String get capsulesCreationOpenAt => 'Se abre el';

  @override
  String get capsulesCreationPreview => 'Vista previa de la cápsula';

  @override
  String get capsulesCreationPrivacy => 'Visibilidad';

  @override
  String get capsulesCreationSelectDate => 'Elige una fecha';

  @override
  String get capsulesCreationSettings => 'Ajustes de la cápsula';

  @override
  String get capsulesCreationSubmit => 'Crear cápsula';

  @override
  String get capsulesCreationTitle => 'Crear cápsula';

  @override
  String get capsulesCreationTitleHint => 'Título...';

  @override
  String get capsulesDefaultTitle => 'Cápsula';

  @override
  String get capsulesErrorNoLocation => 'No hemos podido detectar tu ubicación';

  @override
  String get capsulesErrorSaveFailed => 'No se pudo guardar la cápsula';

  @override
  String get capsulesErrorSavedNotSent =>
      'La cápsula se ha guardado, pero no se ha enviado. Vuelve a tocar el botón para intentarlo de nuevo.';

  @override
  String get capsulesOpenInMonth => 'En un mes';

  @override
  String get capsulesOpenInWeek => 'En una semana';

  @override
  String get capsulesOpenInYear => 'En un año';

  @override
  String get capsulesOpenNow => 'Abrir ya';

  @override
  String get capsulesOpenPickDate => 'Elegir fecha…';

  @override
  String get capsulesOpenTomorrow => 'Mañana';

  @override
  String get capsulesPrivacyFriends => 'Amigos';

  @override
  String get capsulesPrivacyPrivate => 'Privada';

  @override
  String get capsulesPrivacyPublic => 'Pública';

  @override
  String get capsulesQueued =>
      'Guardada en tu teléfono. Se subirá cuando vuelvas a tener conexión.';

  @override
  String capsulesReactWith(String emoji) {
    return 'Reaccionar con $emoji';
  }

  @override
  String get capsulesReactionFailed => 'No se pudo guardar tu reacción';

  @override
  String get capsulesReply => 'Responder';

  @override
  String capsulesReplyHint(String name) {
    return 'Responder a $name...';
  }

  @override
  String get capsulesReport => 'Denunciar';

  @override
  String get capsulesReportAbuse => 'Acoso u odio';

  @override
  String get capsulesReportCapsule => 'Denunciar cápsula';

  @override
  String get capsulesReportNudity => 'Desnudos';

  @override
  String get capsulesReportOther => 'Otra cosa';

  @override
  String get capsulesReportPrivacy => 'Información privada';

  @override
  String get capsulesReportSent =>
      'Gracias por avisarnos. El equipo de Later lo revisará.';

  @override
  String get capsulesReportSpam => 'Spam';

  @override
  String get capsulesReportTitle => '¿Qué tiene de malo?';

  @override
  String get capsulesReportViolence => 'Violencia';

  @override
  String get capsulesYou => 'Tú';

  @override
  String get commonBack => 'Atrás';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonErrorGeneric => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get commonLoading => 'Cargando...';

  @override
  String commonNewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nuevos',
      one: '$count nuevo',
    );
    return '$_temp0';
  }

  @override
  String get commonNoConnection => 'Sin conexión. Inténtalo de nuevo.';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonSearchHint => 'Buscar...';

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
  String get commonUnknownUser => 'Usuario desconocido';

  @override
  String get commonUnknownUsername => 'desconocido';

  @override
  String get commonUntitled => 'Sin título';

  @override
  String get commonUsernameRequired => 'Escribe un nombre de usuario';

  @override
  String get commonUsernameRules =>
      'Usa de 3 a 30 letras (a-z), números, puntos, guiones o guiones bajos';

  @override
  String get commonUsernameTaken => 'Ese nombre de usuario ya está en uso';

  @override
  String get failureNotFound => 'Este elemento ya no existe.';

  @override
  String get failurePermission => 'No tienes permiso para hacer eso.';

  @override
  String get friendsAccept => 'Aceptar';

  @override
  String get friendsAcceptRequestLabel => 'Aceptar solicitud de amistad';

  @override
  String get friendsAdd => 'Añadir';

  @override
  String get friendsAddTitle => 'Añadir amigos';

  @override
  String get friendsBlock => 'Bloquear';

  @override
  String get friendsBlockConfirm =>
      '¿Seguro que quieres bloquear a este usuario?';

  @override
  String get friendsEmpty => 'Aún no has añadido amigos';

  @override
  String get friendsErrorAcceptRequest => 'No se pudo aceptar la solicitud';

  @override
  String get friendsErrorBlock => 'No se pudo bloquear al usuario';

  @override
  String get friendsErrorCancelRequest => 'No se pudo cancelar la solicitud';

  @override
  String get friendsErrorFollow => 'No se pudo seguir a este usuario';

  @override
  String get friendsErrorLoadUsers => 'No se pudieron cargar los usuarios';

  @override
  String get friendsErrorRejectRequest => 'No se pudo rechazar la solicitud';

  @override
  String get friendsErrorRemoveFriend => 'No se pudo eliminar de tus amigos';

  @override
  String get friendsErrorSendRequest =>
      'No se pudo enviar la solicitud de amistad';

  @override
  String get friendsErrorUnblock => 'No se pudo desbloquear al usuario';

  @override
  String get friendsErrorUnfollow =>
      'No se pudo dejar de seguir a este usuario';

  @override
  String get friendsFindByUsernameHint =>
      'Busca por @usuario o escanea el código QR de un amigo. Aquí aparecerán personas que conocen tus amigos.';

  @override
  String get friendsFollow => 'Seguir';

  @override
  String get friendsFollowed =>
      '¡Siguiendo! Recibirás notificaciones de sus cápsulas';

  @override
  String get friendsFollowing => 'Siguiendo';

  @override
  String get friendsFriendCapsulesEmpty =>
      'Aquí aparecerán las cápsulas de tu amigo';

  @override
  String get friendsFriendCapsulesTitle => 'Cápsulas de tu amigo';

  @override
  String get friendsHideSuggestionLabel => 'Ocultar sugerencia';

  @override
  String get friendsMakeFriends => 'Haz amigos';

  @override
  String get friendsManageFriendship => 'Gestionar amistad';

  @override
  String friendsMutualCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count amigos en común',
      one: '1 amigo en común',
    );
    return '$_temp0';
  }

  @override
  String get friendsMyFriendsTitle => 'Mis amigos';

  @override
  String get friendsMyProfile => 'Mi perfil';

  @override
  String get friendsNoMatches => 'Ningún amigo coincide con tu búsqueda';

  @override
  String get friendsNoSuggestions => 'No hay más sugerencias';

  @override
  String get friendsOpenChat => 'Abrir chat';

  @override
  String get friendsPending => 'Pendiente';

  @override
  String get friendsQrHint =>
      'Apunta la cámara al código QR para añadir a un amigo';

  @override
  String get friendsQrInvalid =>
      'Código QR no válido. Escanea el código QR de un perfil de Later.';

  @override
  String get friendsQrTitle => 'Escanear código QR';

  @override
  String get friendsReject => 'Rechazar';

  @override
  String get friendsRemove => 'Eliminar de amigos';

  @override
  String get friendsRemoveAction => 'Eliminar';

  @override
  String get friendsRemoveConfirm =>
      '¿Seguro que quieres eliminar a este usuario de tus amigos?';

  @override
  String get friendsRemoving => 'Eliminando...';

  @override
  String get friendsReport => 'Denunciar';

  @override
  String get friendsRequestAccepted => '¡Solicitud de amistad aceptada!';

  @override
  String get friendsRequestAlreadyExists =>
      'Ya enviaste una solicitud de amistad';

  @override
  String get friendsRequestCancelled => 'Solicitud de amistad cancelada';

  @override
  String get friendsRequestPendingInfo =>
      'La solicitud de amistad está pendiente';

  @override
  String get friendsRequestReceivedInfo =>
      'Este usuario te envió una solicitud de amistad';

  @override
  String get friendsRequestRejected => 'Solicitud de amistad rechazada';

  @override
  String get friendsRequestSent => '¡Solicitud de amistad enviada!';

  @override
  String get friendsRequestsButton => 'Solicitudes';

  @override
  String get friendsRequestsEmptySubtitle =>
      'Cuando alguien te envíe una solicitud de amistad,\naparecerá aquí';

  @override
  String get friendsRequestsEmptyTitle => 'No hay solicitudes de amistad';

  @override
  String get friendsRequestsReceivedTab => 'Recibidas';

  @override
  String get friendsRequestsSentTab => 'Enviadas';

  @override
  String get friendsRequestsTitle => 'Solicitudes de amistad';

  @override
  String get friendsSearchByTagHint => 'Buscar por usuario';

  @override
  String get friendsSearchHint => 'Buscar entre tus amigos';

  @override
  String get friendsSendCapsule => 'Enviar cápsula';

  @override
  String get friendsSendRequestLabel => 'Enviar solicitud de amistad';

  @override
  String get friendsSentEmptySubtitle =>
      'Aquí aparecerán las solicitudes\nque envíes';

  @override
  String get friendsSentEmptyTitle => 'No hay solicitudes enviadas';

  @override
  String get friendsShareProfile => 'Compartir perfil';

  @override
  String get friendsShareProfileTo => 'Compartir perfil ...';

  @override
  String get friendsSuggestionRemoved => '¡Sugerencia eliminada de la lista!';

  @override
  String get friendsThisIsYou => 'Esta es tu cuenta';

  @override
  String get friendsUnfollowed => 'Ya no sigues a este usuario';

  @override
  String get friendsViewProfile => 'Ver perfil';

  @override
  String get historyAddToFavorites => 'Añadir a favoritos';

  @override
  String get historyCapsuleOpened => '¡Cápsula abierta!';

  @override
  String get historyColorBlue => 'Azul';

  @override
  String get historyColorGreen => 'Verde';

  @override
  String get historyColorOrange => 'Naranja';

  @override
  String get historyColorPurple => 'Morado';

  @override
  String get historyColorRed => 'Rojo';

  @override
  String get historyColorYellow => 'Amarillo';

  @override
  String historyCountdown(int days, int hours, int minutes, int seconds) {
    return '${days}d ${hours}h ${minutes}m ${seconds}s';
  }

  @override
  String historyCountdownYears(int years, int days, int hours, int minutes) {
    return '${years}a ${days}d ${hours}h ${minutes}m';
  }

  @override
  String get historyCreateFirst => 'Crear una cápsula';

  @override
  String historyDeleteConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Eliminar $count cápsulas?',
      one: '¿Eliminar $count cápsula?',
    );
    return '$_temp0';
  }

  @override
  String historyDeleteSelected(int count) {
    return 'Eliminar ($count)';
  }

  @override
  String historyDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cápsulas eliminadas',
      one: '$count cápsula eliminada',
    );
    return '$_temp0';
  }

  @override
  String historyDistanceFromYou(String distance) {
    return 'A $distance km de ti';
  }

  @override
  String get historyDistanceUnknown => 'Distancia desconocida';

  @override
  String get historyEmpty => 'Aún no tienes cápsulas';

  @override
  String get historyEmptySubtitle =>
      'Haz una foto, déjala en un lugar y elige cuándo se abre.';

  @override
  String get historyErrorDelete => 'No se pudieron eliminar las cápsulas';

  @override
  String get historyErrorFavorites => 'No se pudieron actualizar los favoritos';

  @override
  String historyFavoriteAdded(String title) {
    return '«$title» se añadió a favoritos';
  }

  @override
  String historyFavoriteRemoved(String title) {
    return '«$title» se quitó de favoritos';
  }

  @override
  String get historyFilterAny => 'Todas';

  @override
  String get historyFilterBy => 'Filtrar';

  @override
  String get historyFilterCapsule => 'Cápsulas';

  @override
  String get historyFilterColor => 'Color';

  @override
  String get historyFilterFavorite => 'Favoritas';

  @override
  String get historyFilterVisibility => 'Visibilidad';

  @override
  String get historyLoadError => 'No se pudieron cargar tus cápsulas';

  @override
  String get historyNoMatches => 'Ninguna cápsula coincide con tu búsqueda';

  @override
  String get historyNoMatchesSubtitle =>
      'Prueba otra palabra o restablece los filtros.';

  @override
  String get historyOnThisDay => 'Un día como hoy';

  @override
  String get historyPrivacyFriends => 'Amigos';

  @override
  String get historyPrivacyPrivate => 'Privada';

  @override
  String get historyPrivacyPublic => 'Pública';

  @override
  String get historyRemoveFromFavorites => 'Quitar de favoritos';

  @override
  String get historyReset => 'Restablecer';

  @override
  String get historySearchHint => 'Buscar cápsulas...';

  @override
  String historySelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seleccionadas',
      one: '$count seleccionada',
    );
    return '$_temp0';
  }

  @override
  String get historySortBy => 'Ordenar';

  @override
  String get historySortClosest => 'Más cercanas';

  @override
  String get historySortDistance => 'Distancia';

  @override
  String get historySortFarthest => 'Más lejanas';

  @override
  String get historySortNewest => 'Más recientes';

  @override
  String get historySortOldest => 'Más antiguas';

  @override
  String get historySortRelevance => 'Relevancia';

  @override
  String get historyTitle => 'Mis cápsulas';

  @override
  String get historyVisibilityFriends => 'Para amigos';

  @override
  String get historyVisibilityPrivate => 'Privada';

  @override
  String get historyVisibilityPublic => 'Pública';

  @override
  String get historyWaitingUpload => 'Esperando conexión';

  @override
  String historyYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hace $count años',
      one: 'Hace 1 año',
    );
    return '$_temp0';
  }

  @override
  String get mapCapsuleLocked => 'Bloqueada';

  @override
  String get mapCapsuleNoDescription => 'Esta cápsula no tiene descripción.';

  @override
  String get mapCapsuleOpen => 'Abrir';

  @override
  String mapCapsuleOpensIn(String time) {
    return 'Se abre en $time';
  }

  @override
  String get mapCapsuleReady => '¡Descubre lo que hay dentro!';

  @override
  String get mapCompass => 'Orientar el mapa al norte';

  @override
  String mapDurationDays(int count) {
    return '${count}d';
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
  String get mapFirstCapsuleBody => 'Haz una foto aquí y elige cuándo se abre.';

  @override
  String get mapFirstCapsuleTitle => 'Deja tu primera cápsula';

  @override
  String get mapLocationDenied =>
      'Permite el acceso a tu ubicación para ver cápsulas cerca de ti';

  @override
  String get mapLocationServiceOff =>
      'Activa la ubicación para ver cápsulas cerca de ti';

  @override
  String get mapLocationUnknown => 'No hemos podido detectar tu ubicación';

  @override
  String get mapMyLocation => 'Mi ubicación';

  @override
  String get mapZoomIn => 'Acercar';

  @override
  String get mapZoomOut => 'Alejar';

  @override
  String get messagesBlockedByYou => 'Has bloqueado a este usuario';

  @override
  String get messagesCantSend => 'No puedes enviar mensajes a este usuario';

  @override
  String get messagesCapsuleLabel => 'Cápsula';

  @override
  String get messagesCapsuleUnavailable => 'Esta cápsula ya no está disponible';

  @override
  String get messagesChatFallbackTitle => 'Chat';

  @override
  String get messagesChatOptions => 'Opciones del chat';

  @override
  String get messagesChatsLoadError => 'No se pudieron cargar tus chats';

  @override
  String get messagesCheckConnection =>
      'Revisa tu conexión e inténtalo de nuevo';

  @override
  String get messagesChoosePhoto => 'Elegir de la galería';

  @override
  String get messagesClearConfirm => 'Borrar';

  @override
  String get messagesClearConfirmTitle =>
      '¿Seguro que quieres borrar el historial del chat?';

  @override
  String get messagesClearFailed => 'No se pudo borrar el historial';

  @override
  String get messagesCopied => 'Copiado';

  @override
  String get messagesCopy => 'Copiar';

  @override
  String get messagesDeleteConfirmTitle =>
      '¿Eliminar este mensaje para los dos?';

  @override
  String get messagesDeleteFailed => 'No se pudo eliminar el mensaje';

  @override
  String get messagesDeleteForEveryone => 'Eliminar para todos';

  @override
  String get messagesDeleteForMe => 'Eliminar para mí';

  @override
  String messagesEmptySubtitle(String name) {
    return '¡Saluda a $name!';
  }

  @override
  String get messagesEmptyTitle => 'Aún no hay mensajes';

  @override
  String get messagesFindChatsHint => 'Buscar chats';

  @override
  String get messagesForward => 'Reenviar';

  @override
  String get messagesForwardTo => 'Reenviar a';

  @override
  String get messagesForwarded => 'Reenviado';

  @override
  String messagesForwardedTo(String name) {
    return 'Reenviado a $name';
  }

  @override
  String get messagesGroupAddPeople => 'Añadir personas';

  @override
  String get messagesGroupCreate => 'Crear';

  @override
  String get messagesGroupFailed =>
      'Algo salió mal con el grupo. Inténtalo de nuevo.';

  @override
  String get messagesGroupHello => 'Saluda a todos';

  @override
  String get messagesGroupInvited =>
      'Invitados. Tus amigos se unirán en un momento.';

  @override
  String get messagesGroupLeave => 'Salir del grupo';

  @override
  String messagesGroupLeaveConfirm(String name) {
    return '¿Salir de «$name»? Sus mensajes ya no se verán aquí.';
  }

  @override
  String get messagesGroupLeft => 'Ya no estás en este grupo';

  @override
  String messagesGroupMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count miembros',
      one: '1 miembro',
    );
    return '$_temp0';
  }

  @override
  String get messagesGroupMembersTitle => 'Miembros';

  @override
  String get messagesGroupName => 'Nombre del grupo';

  @override
  String get messagesGroupNameTooLong =>
      'El nombre del grupo puede tener 60 caracteres como máximo';

  @override
  String get messagesGroupNeedsName => 'Ponle un nombre al grupo';

  @override
  String get messagesGroupNeedsPeople => 'Elige al menos un amigo';

  @override
  String get messagesGroupRename => 'Cambiar el nombre del grupo';

  @override
  String get messagesGroupSave => 'Guardar';

  @override
  String get messagesGroupTooMany => 'Un grupo tiene como máximo 20 personas';

  @override
  String get messagesGroupWho => '¿Quién está?';

  @override
  String get messagesInputHint => 'Escribe un mensaje...';

  @override
  String get messagesLoadError => 'No se pudieron cargar los mensajes';

  @override
  String get messagesMenuBlock => 'Bloquear usuario';

  @override
  String get messagesMenuClearHistory => 'Borrar historial';

  @override
  String get messagesMenuMute => 'Silenciar chat';

  @override
  String get messagesMenuSearch => 'Buscar';

  @override
  String get messagesMenuUnblock => 'Desbloquear usuario';

  @override
  String get messagesMenuUnmute => 'Activar sonido';

  @override
  String get messagesMicPermission =>
      'Permite el micrófono para enviar mensajes de voz';

  @override
  String get messagesMutedToast => 'Chat silenciado';

  @override
  String get messagesNewChatFindFriends => 'Encontrar amigos';

  @override
  String get messagesNewChatNoFriends => 'Aún no tienes amigos';

  @override
  String get messagesNewChatNoFriendsSubtitle =>
      '¡Añade amigos para empezar a chatear!';

  @override
  String get messagesNewChatNoMatch => 'No se encontraron amigos';

  @override
  String get messagesNewChatSearchHint => 'Buscar amigos';

  @override
  String get messagesNewChatTitle => 'Nuevo chat';

  @override
  String get messagesNewGroup => 'Nuevo grupo';

  @override
  String get messagesNoChatsFound => 'No se encontraron chats';

  @override
  String get messagesNoChatsSubtitle =>
      '¡Toca el botón de nuevo mensaje para empezar a chatear con tus amigos!';

  @override
  String get messagesNoChatsTitle => 'Aún no tienes conversaciones';

  @override
  String get messagesNoMatchTitle => 'No se encontraron mensajes';

  @override
  String messagesNothingMatches(String query) {
    return 'Nada coincide con «$query»';
  }

  @override
  String get messagesNotificationsMuted => 'Chat silenciado';

  @override
  String messagesOpenCapsule(String title) {
    return 'Abrir la cápsula «$title»';
  }

  @override
  String messagesOpenGroup(String name) {
    return 'Abrir el grupo $name';
  }

  @override
  String get messagesOpenPhoto => 'Abrir foto';

  @override
  String get messagesPauseVoice => 'Pausa';

  @override
  String get messagesPhoto => 'Foto';

  @override
  String get messagesPhotoCaption => 'Añade un texto…';

  @override
  String get messagesPhotoUnreadable => 'No se puede enviar esta imagen';

  @override
  String get messagesPin => 'Fijar arriba';

  @override
  String messagesPinLimit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Puedes fijar hasta $count chats',
      one: 'Puedes fijar 1 chat',
    );
    return '$_temp0';
  }

  @override
  String get messagesPinned => 'Fijado';

  @override
  String get messagesPlayVoice => 'Reproducir mensaje de voz';

  @override
  String get messagesQuoteGone => 'Ese mensaje ya no está en este chat';

  @override
  String get messagesReactFailed => 'No se pudo guardar tu reacción';

  @override
  String get messagesReceiptFailed => 'No enviado · Toca para reintentar';

  @override
  String get messagesReceiptRead => 'Leído';

  @override
  String get messagesReceiptSending => 'Enviando…';

  @override
  String get messagesReceiptSent => 'Enviado';

  @override
  String get messagesRecordVoice => 'Grabar un mensaje de voz';

  @override
  String get messagesReport => 'Denunciar';

  @override
  String get messagesReportFailed =>
      'No se pudo enviar la denuncia. Inténtalo de nuevo.';

  @override
  String get messagesScrollToLatest => 'Ir al último mensaje';

  @override
  String get messagesSearchHint => 'Buscar mensajes';

  @override
  String get messagesSend => 'Enviar';

  @override
  String get messagesSendCapsule => 'Enviar una cápsula';

  @override
  String get messagesSendFailed => 'No se pudo enviar el mensaje';

  @override
  String get messagesSendPhoto => 'Enviar una foto';

  @override
  String get messagesSignedOut => 'Has cerrado sesión';

  @override
  String messagesStartChatWith(String name) {
    return 'Empezar un chat con $name';
  }

  @override
  String get messagesStickers => 'Stickers';

  @override
  String get messagesStickersFaces => 'Caras';

  @override
  String get messagesStickersHands => 'Gestos';

  @override
  String get messagesStickersHearts => 'Corazones y fiestas';

  @override
  String get messagesStickersNature => 'Naturaleza';

  @override
  String get messagesStickersPlaces => 'Lugares y cosas';

  @override
  String get messagesStickersRecent => 'Usados recientemente';

  @override
  String get messagesTakePhoto => 'Hacer una foto';

  @override
  String get messagesTitle => 'Mis Laters';

  @override
  String get messagesToday => 'Hoy';

  @override
  String get messagesTooLong => 'Este mensaje es demasiado largo';

  @override
  String get messagesTyping => 'escribiendo';

  @override
  String messagesTypingMany(int count) {
    return '$count personas están escribiendo';
  }

  @override
  String messagesTypingName(String name) {
    return '$name está escribiendo';
  }

  @override
  String get messagesUnmutedToast => 'Sonido del chat activado';

  @override
  String get messagesUnpin => 'Desfijar';

  @override
  String get messagesUnreadDivider => 'Mensajes sin leer';

  @override
  String get messagesVoice => 'Mensaje de voz';

  @override
  String get messagesVoiceCancel => 'Cancelar la grabación';

  @override
  String get messagesVoiceFailed =>
      'No se puede reproducir este mensaje de voz';

  @override
  String get messagesVoiceRecording => 'Grabando';

  @override
  String get messagesVoiceSend => 'Enviar mensaje de voz';

  @override
  String get messagesVoiceTooShort => 'Demasiado corto para enviar';

  @override
  String get messagesYesterday => 'Ayer';

  @override
  String messagesYouPrefix(String message) {
    return 'Tú: $message';
  }

  @override
  String get navMap => 'Mapa';

  @override
  String get navMessages => 'Mensajes';

  @override
  String get navMyCapsules => 'Mis cápsulas';

  @override
  String get navNewCapsule => 'Nueva cápsula';

  @override
  String get navProfile => 'Perfil';

  @override
  String notificationsAchievementBody(String name) {
    return '$name: desbloqueaste un logro nuevo';
  }

  @override
  String notificationsCapsuleBody(String name) {
    return '$name creó una nueva cápsula';
  }

  @override
  String get notificationsChannelActivity => 'Actividad';

  @override
  String get notificationsChannelActivityDescription =>
      'Seguidores, solicitudes de amistad, reacciones, comentarios y cápsulas nuevas';

  @override
  String get notificationsChannelActivitySilent => 'Actividad (en silencio)';

  @override
  String get notificationsChannelActivitySilentDescription =>
      'Actividad sin sonido ni vibración';

  @override
  String get notificationsChannelMessages => 'Mensajes';

  @override
  String get notificationsChannelMessagesDescription =>
      'Mensajes nuevos de tus amigos';

  @override
  String get notificationsChannelMessagesSilent => 'Mensajes (en silencio)';

  @override
  String get notificationsChannelMessagesSilentDescription =>
      'Mensajes nuevos sin sonido ni vibración';

  @override
  String get notificationsChannelOther => 'Otras notificaciones';

  @override
  String get notificationsChannelOtherDescription =>
      'Otras notificaciones de Later';

  @override
  String notificationsCommentBody(String name) {
    return '$name comentó tu cápsula';
  }

  @override
  String notificationsCommentBodyWithText(String name, String text) {
    return '$name comentó: $text';
  }

  @override
  String notificationsDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count días',
      one: 'hace $count día',
    );
    return '$_temp0';
  }

  @override
  String notificationsDeleteConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Eliminar $count notificaciones?',
      one: '¿Eliminar $count notificación?',
    );
    return '$_temp0';
  }

  @override
  String notificationsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notificaciones eliminadas',
      one: '$count notificación eliminada',
    );
    return '$_temp0';
  }

  @override
  String get notificationsEmptyAll =>
      'Aquí aparecerán tus notificaciones y tu actividad';

  @override
  String get notificationsEmptyComments =>
      'Aquí aparecerán los comentarios en tus cápsulas';

  @override
  String get notificationsEmptyReplies =>
      'Aquí aparecerán las respuestas a tus mensajes';

  @override
  String notificationsFollowBody(String name) {
    return '$name empezó a seguirte';
  }

  @override
  String notificationsFriendAcceptedBody(String name) {
    return '$name aceptó tu solicitud de amistad';
  }

  @override
  String notificationsFriendRequestBody(String name) {
    return '$name quiere ser tu amigo';
  }

  @override
  String notificationsHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count horas',
      one: 'hace $count hora',
    );
    return '$_temp0';
  }

  @override
  String get notificationsJustNow => 'Ahora mismo';

  @override
  String get notificationsMarkAsRead => 'Marcar como leídas';

  @override
  String notificationsMarkedRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notificaciones marcadas como leídas',
      one: '$count notificación marcada como leída',
    );
    return '$_temp0';
  }

  @override
  String notificationsMessageBody(String name) {
    return '$name te envió un mensaje';
  }

  @override
  String notificationsMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count minutos',
      one: 'hace $count minuto',
    );
    return '$_temp0';
  }

  @override
  String notificationsReactionBody(String name, String emoji) {
    return '$name reaccionó con $emoji a tu cápsula';
  }

  @override
  String notificationsReplyBody(String name) {
    return '$name te respondió';
  }

  @override
  String notificationsReplyBodyWithText(String name, String text) {
    return '$name respondió: $text';
  }

  @override
  String notificationsSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seleccionadas',
      one: '$count seleccionada',
    );
    return '$_temp0';
  }

  @override
  String get notificationsTabAll => 'Todas';

  @override
  String get notificationsTabComments => 'Comentarios';

  @override
  String get notificationsTabReplies => 'Respuestas';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get notificationsTypeAchievement => 'Logro';

  @override
  String get notificationsTypeCapsule => 'Nueva cápsula';

  @override
  String get notificationsTypeComment => 'Nuevo comentario';

  @override
  String get notificationsTypeFollow => 'Nuevo seguidor';

  @override
  String get notificationsTypeFriendAccepted => 'Nuevo amigo';

  @override
  String get notificationsTypeFriendRequest => 'Solicitud de amistad';

  @override
  String get notificationsTypeMessage => 'Nuevo mensaje';

  @override
  String get notificationsTypeOther => 'Notificación';

  @override
  String get notificationsTypeReaction => 'Nueva reacción';

  @override
  String get notificationsTypeReply => 'Nueva respuesta';

  @override
  String notificationsUnreadBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notificaciones sin leer',
      one: '$count notificación sin leer',
    );
    return '$_temp0';
  }

  @override
  String get placeNoLocation => 'Sin ubicación';

  @override
  String get placeUnknown => 'Lugar desconocido';

  @override
  String get profileAddFriends => 'Añadir amigos';

  @override
  String get profileAddToMapEveryone => 'Al mapa | Para todos';

  @override
  String get profileAddToMapFriends => 'Al mapa | Solo para amigos';

  @override
  String get profileBackgroundDelete => 'Eliminar imagen de fondo';

  @override
  String get profileBackgroundTitle => 'Imagen de fondo';

  @override
  String get profileBackgroundUpdated => '¡Imagen de fondo actualizada!';

  @override
  String get profileChoosePinned => 'Fijar amigos';

  @override
  String get profileCopyLink => 'Copiar enlace';

  @override
  String get profileErrorCopyLink => 'No se pudo copiar el enlace';

  @override
  String get profileErrorDeleteBackground =>
      'No se pudo eliminar la imagen de fondo';

  @override
  String get profileErrorDeletePicture =>
      'No se pudo eliminar la foto de perfil';

  @override
  String get profileErrorShare => 'No se pudo compartir el perfil';

  @override
  String get profileErrorUploadBackground =>
      'No se pudo subir la imagen de fondo';

  @override
  String get profileErrorUploadPicture => 'No se pudo subir la foto de perfil';

  @override
  String profileFollowers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seguidores',
      one: '1 seguidor',
    );
    return '$_temp0';
  }

  @override
  String profileFollowing(int count) {
    return '$count seguidos';
  }

  @override
  String get profileFriendsSection => 'Amigos';

  @override
  String get profileImageFromGallery => 'Elegir de la galería';

  @override
  String get profileImageTakePhoto => 'Hacer una foto';

  @override
  String get profileLinkCopied => '¡Enlace copiado!';

  @override
  String get profileMyCapsules => 'Mis cápsulas';

  @override
  String get profileMyFriends => 'Mis amigos';

  @override
  String get profileNoFriends => 'Aún no tienes amigos';

  @override
  String get profileNoFriendsAction => 'Encuentra a gente que conoces';

  @override
  String get profilePictureDelete => 'Eliminar foto de perfil';

  @override
  String get profilePictureTitle => 'Foto de perfil';

  @override
  String get profilePictureUpdated => '¡Foto de perfil actualizada!';

  @override
  String get profilePinnedHint =>
      'Si eliges menos de 3, mostraremos amigos al azar de tu lista';

  @override
  String get profilePinnedLimit => 'Solo puedes fijar hasta 3 amigos';

  @override
  String get profilePinnedTitle => 'Fija hasta 3 amigos';

  @override
  String get profilePinnedUpdated => '¡Amigos fijados actualizados!';

  @override
  String get profileQrError => 'Algo salió mal...';

  @override
  String get profileShare => 'Compartir';

  @override
  String get profileShareHeading => 'Comparte tu perfil';

  @override
  String get profileShareHint =>
      'Otros pueden escanear este código con la cámara o desde la app para añadirte como amigo';

  @override
  String profileShareMessage(String name, String link) {
    return '¡Mira el perfil de $name en Later!\n$link';
  }

  @override
  String profileShareSubject(String name) {
    return 'Conecta con $name en Later';
  }

  @override
  String get profileShareSubtitle =>
      'Deja que otros escaneen este código QR para añadirte como amigo';

  @override
  String get profileShareTitle => 'Compartir perfil';

  @override
  String get profileUpdating => 'Actualizando...';

  @override
  String get profileVerified => 'Cuenta verificada';

  @override
  String get profileViewProfile => 'Ver perfil';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get settingsAboutLicenses => 'Licencias de código abierto';

  @override
  String get settingsAboutOpenFailed => 'No se pudo abrir la página.';

  @override
  String get settingsAboutPrivacy => 'Política de privacidad';

  @override
  String get settingsAboutTerms => 'Términos de uso';

  @override
  String get settingsAboutVersion => 'Versión';

  @override
  String get settingsAboutVersionUnknown => 'desconocida';

  @override
  String get settingsAppPermissions => 'Permisos de la app';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsAppearanceDescription =>
      'Cómo se ve Later en este teléfono';

  @override
  String settingsBlockedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bloqueados',
      one: '$count bloqueado',
    );
    return '$_temp0';
  }

  @override
  String get settingsBlockedDescription =>
      'No pueden escribirte ni enviarte solicitudes de amistad';

  @override
  String get settingsBlockedEmpty => 'No has bloqueado a nadie';

  @override
  String get settingsBlockedEmptyHint =>
      'Bloquea a alguien desde su perfil\no desde un chat';

  @override
  String get settingsBlockedNobody => 'Nadie';

  @override
  String get settingsBlockedUsers => 'Usuarios bloqueados';

  @override
  String get settingsCameraBack => 'Cámara trasera';

  @override
  String get settingsCameraFooter =>
      'La cámara que se abre cuando creas una cápsula.';

  @override
  String get settingsCameraFront => 'Cámara frontal';

  @override
  String get settingsCompleteProfileDescription =>
      'Elige cómo te verán tus amigos';

  @override
  String settingsCompleteProfileNoProfile(String email) {
    return 'Tu cuenta $email aún no tiene perfil.';
  }

  @override
  String get settingsCompleteProfileTitle => 'Ya casi está';

  @override
  String get settingsCustomizeDescription => 'Toca una imagen para cambiarla';

  @override
  String get settingsCustomizeProfile => 'Personalizar perfil';

  @override
  String get settingsDataAndStorage => 'Datos y almacenamiento';

  @override
  String get settingsDeleteAccount => 'Eliminar cuenta';

  @override
  String get settingsDeleteButton => 'Eliminar mi cuenta';

  @override
  String get settingsDeleteConfirm =>
      '¿Eliminar tu cuenta? No se puede deshacer.';

  @override
  String get settingsDeleteDescription =>
      'Elimina tu cuenta y todo lo que contiene';

  @override
  String get settingsDeleteNote =>
      'Al eliminar tu cuenta se borran tu perfil, fotos, cápsulas, chats, amigos y seguidores. Tus amigos ya no te verán a ti ni tus mensajes. No se puede deshacer.';

  @override
  String get settingsDeletedAccount => 'Cuenta eliminada';

  @override
  String get settingsDeviceDescription =>
      'Cómo se ve y funciona Later en este teléfono';

  @override
  String get settingsEmail => 'Correo electrónico';

  @override
  String settingsEmailDescription(String email) {
    return 'Inicias sesión en Later con $email';
  }

  @override
  String settingsEmailGoogleDescription(String email) {
    return 'Inicias sesión con Google como $email';
  }

  @override
  String get settingsEmailGoogleNote =>
      'Tu correo viene de tu cuenta de Google. Para usar otro, cámbialo en tu cuenta de Google.';

  @override
  String settingsEmailLinkSent(String newEmail, String currentEmail) {
    return 'Te enviamos un enlace a $newEmail. Ábrelo para confirmar: entonces cambiará tu correo. Hasta entonces, sigue iniciando sesión con $currentEmail.';
  }

  @override
  String get settingsEmailNewHint => 'Nuevo correo';

  @override
  String get settingsEmailSendLink => 'Enviar enlace';

  @override
  String get settingsErrorChatUpdateFailed => 'No se pudo actualizar el chat.';

  @override
  String get settingsErrorCouldNotSave =>
      'No se pudo guardar. Inténtalo de nuevo.';

  @override
  String get settingsErrorCurrentPassword => 'Escribe tu contraseña actual.';

  @override
  String get settingsErrorEnterName => 'Escribe tu nombre.';

  @override
  String get settingsErrorEnterNewName => '¡Escribe un nombre nuevo!';

  @override
  String get settingsErrorEnterNewUsername =>
      '¡Escribe un nombre de usuario nuevo!';

  @override
  String get settingsErrorEnterPassword => 'Escribe tu contraseña.';

  @override
  String get settingsErrorInvalidEmail =>
      'Escribe un correo electrónico válido.';

  @override
  String get settingsErrorNameFailed => '¡No se pudo actualizar el nombre!';

  @override
  String get settingsErrorPasswordSame =>
      'La nueva contraseña es igual a la actual.';

  @override
  String settingsErrorPasswordTooShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'La nueva contraseña necesita al menos $count caracteres.',
      one: 'La nueva contraseña necesita al menos $count carácter.',
    );
    return '$_temp0';
  }

  @override
  String get settingsErrorPasswordsMismatch =>
      'Las nuevas contraseñas no coinciden.';

  @override
  String get settingsErrorSameEmail => 'Este ya es tu correo.';

  @override
  String get settingsErrorSaveFailed => 'No se pudieron guardar los ajustes.';

  @override
  String get settingsErrorSignInAgain => 'Vuelve a iniciar sesión.';

  @override
  String get settingsErrorUsernameFailed =>
      '¡No se pudo actualizar el nombre de usuario!';

  @override
  String get settingsFaqBlockAnswer =>
      'Bloquéalo desde su perfil o desde el menú del chat. Puedes desbloquearlo en Ajustes > Usuarios bloqueados.';

  @override
  String get settingsFaqBlockQuestion => '¿Cómo evito que alguien me contacte?';

  @override
  String get settingsFaqCapsuleAnswer =>
      'Una foto con un título y una nota, fijada en el mapa donde la hiciste. Puedes elegir una fecha: hasta entonces, la cápsula sigue cerrada.';

  @override
  String get settingsFaqCapsuleQuestion => '¿Qué es una cápsula?';

  @override
  String get settingsFaqDeleteAnswer =>
      'Ajustes > Eliminar cuenta. Todo lo que creaste se borra y no se puede recuperar.';

  @override
  String get settingsFaqDeleteQuestion => '¿Cómo elimino mi cuenta?';

  @override
  String get settingsFaqFriendsAnswer =>
      'Busca su nombre de usuario en Amigos, escanea su código QR o comparte el enlace de tu perfil.';

  @override
  String get settingsFaqFriendsQuestion => '¿Cómo añado amigos?';

  @override
  String get settingsFaqNotificationsAnswer =>
      'Revisa Ajustes > Notificaciones: el teléfono debe permitir que Later te avise y las notificaciones push deben estar activadas. Las horas de silencio y los chats silenciados también bloquean los avisos.';

  @override
  String get settingsFaqNotificationsQuestion => 'No me llegan notificaciones';

  @override
  String get settingsFaqVisibilityAnswer =>
      'Lo eliges al crearla: solo tú (Privada), tus amigos (Amigos) o todo el mundo (Pública).';

  @override
  String get settingsFaqVisibilityQuestion => '¿Quién puede ver mis cápsulas?';

  @override
  String get settingsGoogleConfirmsNote =>
      'Google confirmará que eres tú: elige tu cuenta cuando te lo pida.';

  @override
  String get settingsHelp => 'Ayuda';

  @override
  String settingsHelpContactFooter(String email) {
    return 'Los correos enviados desde la app incluyen la versión de la app y datos de tu teléfono. También puedes escribirnos a $email.';
  }

  @override
  String get settingsHelpContactSupport => 'Contactar con soporte';

  @override
  String get settingsHelpCopied =>
      'Copiado. Pégalo en tu mensaje para nosotros.';

  @override
  String get settingsHelpCopyInfo => 'Copiar información de la app';

  @override
  String get settingsHelpDescription => 'Respuestas y formas de contactarnos';

  @override
  String settingsHelpNoEmailApp(String email) {
    return 'No hay ninguna app de correo. Escríbenos a $email';
  }

  @override
  String get settingsHelpReportProblem => 'Informar de un problema';

  @override
  String get settingsHelpSubjectProblem => 'Later: informe de un problema';

  @override
  String get settingsHelpSubjectQuestion => 'Later: pregunta';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageDescription =>
      'El idioma de la app y de tus notificaciones';

  @override
  String get settingsLanguageFooter =>
      'Las notificaciones de Later también llegarán en este idioma.';

  @override
  String get settingsLanguageSystem => 'Idioma del teléfono';

  @override
  String settingsLanguageSystemHint(String language) {
    return 'Ahora: $language';
  }

  @override
  String get settingsLogOut => 'Cerrar sesión';

  @override
  String get settingsLogOutConfirm => '¿Seguro que quieres cerrar sesión?';

  @override
  String get settingsMapAndCamera => 'Mapa y cámara';

  @override
  String get settingsMapLookHybrid => 'Satélite con etiquetas';

  @override
  String get settingsMapLookSatellite => 'Satélite';

  @override
  String get settingsMapLookStandard => 'Estándar';

  @override
  String get settingsName => 'Nombre';

  @override
  String get settingsNameDescription =>
      'Así te verán en Later. Elige un nombre con el que tus amigos te reconozcan';

  @override
  String get settingsNameHint => 'Nuevo nombre';

  @override
  String get settingsNameUpdated => '¡Nombre actualizado!';

  @override
  String get settingsNotifications => 'Notificaciones';

  @override
  String get settingsNotificationsAchievements => 'Logros';

  @override
  String get settingsNotificationsAllow => 'Permitir notificaciones';

  @override
  String get settingsNotificationsBlockedFooter =>
      'Tu teléfono no permite que Later muestre notificaciones, así que no te llegará ninguna, elijas lo que elijas abajo.';

  @override
  String get settingsNotificationsCapsules => 'Nuevas cápsulas';

  @override
  String get settingsNotificationsCapsulesHint =>
      'De personas que sigues con las notificaciones activadas';

  @override
  String get settingsNotificationsComments => 'Comentarios';

  @override
  String get settingsNotificationsCommentsHint =>
      'En tus cápsulas y respuestas para ti';

  @override
  String get settingsNotificationsDescription => 'Elige de qué te avisa Later';

  @override
  String get settingsNotificationsFollowers => 'Nuevos seguidores';

  @override
  String get settingsNotificationsFriendRequests => 'Solicitudes de amistad';

  @override
  String get settingsNotificationsFriendRequestsHint => 'Recibidas y aceptadas';

  @override
  String get settingsNotificationsMessages => 'Mensajes';

  @override
  String get settingsNotificationsMuteHint =>
      'Silencia un chat concreto desde su menú en Mensajes.';

  @override
  String get settingsNotificationsNews => 'Novedades de Later';

  @override
  String get settingsNotificationsNewsHint => 'Anuncios ocasionales del equipo';

  @override
  String get settingsNotificationsOff => 'Desactivadas';

  @override
  String get settingsNotificationsOffInPhone =>
      'Desactivadas en los ajustes del teléfono';

  @override
  String get settingsNotificationsOn => 'Activadas';

  @override
  String get settingsNotificationsPreview => 'Mostrar el texto del mensaje';

  @override
  String get settingsNotificationsPreviewOff =>
      'Los avisos solo dicen «Nuevo mensaje»';

  @override
  String get settingsNotificationsPush => 'Notificaciones push';

  @override
  String get settingsNotificationsPushOff =>
      'No recibes notificaciones push de Later';

  @override
  String get settingsNotificationsReactions => 'Reacciones';

  @override
  String get settingsNotificationsSound => 'Sonido y vibración';

  @override
  String get settingsNotificationsStreak => 'Recordatorio de racha';

  @override
  String get settingsNotificationsStreakHint =>
      'Por la tarde, si tu racha terminaría hoy';

  @override
  String get settingsPassword => 'Contraseña';

  @override
  String get settingsPasswordChanged => 'Contraseña cambiada';

  @override
  String get settingsPasswordConfirmsNote =>
      'Tu contraseña confirma que eres tú.';

  @override
  String get settingsPasswordCurrent => 'Contraseña actual';

  @override
  String get settingsPasswordDescription =>
      'Elige una contraseña que no uses en ningún otro sitio';

  @override
  String get settingsPasswordForgot => '¿Olvidaste tu contraseña?';

  @override
  String get settingsPasswordGoogleDescription => 'Inicias sesión con Google';

  @override
  String get settingsPasswordGoogleNote =>
      'Tu cuenta no tiene contraseña de Later: Google confirma que eres tú. Cambia tu contraseña en tu cuenta de Google.';

  @override
  String settingsPasswordNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nueva contraseña (mín. $count caracteres)',
      one: 'Nueva contraseña (mín. $count carácter)',
    );
    return '$_temp0';
  }

  @override
  String get settingsPasswordRepeat => 'Repite la nueva contraseña';

  @override
  String get settingsPasswordResetFailed =>
      'No se pudo enviar el enlace. Inténtalo de nuevo.';

  @override
  String settingsPasswordResetSent(String email) {
    return 'Te enviamos un enlace para restablecerla a $email';
  }

  @override
  String get settingsPermissionCamera => 'Cámara';

  @override
  String get settingsPermissionCameraDescription =>
      'Acceso a la cámara para crear cápsulas del tiempo';

  @override
  String get settingsPermissionDenied => 'Denegado';

  @override
  String get settingsPermissionGranted => 'Concedido';

  @override
  String get settingsPermissionLimited => 'Limitado';

  @override
  String get settingsPermissionLocation => 'Ubicación';

  @override
  String get settingsPermissionLocationDescription =>
      'Cápsulas cercanas y funciones basadas en la ubicación';

  @override
  String get settingsPermissionNotificationsDescription =>
      'Novedades sobre seguidores y cápsulas';

  @override
  String get settingsPermissionOpenSettings => 'Abrir ajustes';

  @override
  String get settingsPermissionPermanentlyDenied => 'Denegado para siempre';

  @override
  String get settingsPermissionProvisional => 'Provisional';

  @override
  String get settingsPermissionRequiredBody =>
      'Este permiso se ha denegado para siempre. Actívalo en los ajustes de tu dispositivo.';

  @override
  String get settingsPermissionRequiredTitle => 'Permiso necesario';

  @override
  String get settingsPermissionRestricted => 'Restringido';

  @override
  String get settingsPermissionRevokeBody =>
      'Para revocar este permiso, ve a los ajustes de tu dispositivo. Las funciones relacionadas de la app dejarán de funcionar.';

  @override
  String get settingsPermissionRevokeTitle => 'Revocar permiso';

  @override
  String get settingsPermissionsDescription =>
      'Qué puede usar Later en este teléfono';

  @override
  String get settingsPrivacy => 'Privacidad';

  @override
  String get settingsPrivacyAchievements => 'Mostrar mis logros';

  @override
  String get settingsPrivacyAchievementsHint =>
      'Tus amigos los ven en tu perfil';

  @override
  String get settingsPrivacyApproximate => 'Ubicación aproximada';

  @override
  String get settingsPrivacyApproximateHint =>
      'Coloca las cápsulas nuevas a un kilómetro aproximado, no en el punto exacto';

  @override
  String get settingsPrivacyDescription =>
      'Qué ven los demás y cómo empiezan las cápsulas nuevas';

  @override
  String get settingsPrivacyNewCapsulesFooter =>
      'Puedes cambiar ambas opciones en cada cápsula al crearla.';

  @override
  String get settingsPrivacyReadReceipts => 'Confirmaciones de lectura';

  @override
  String get settingsPrivacyReadReceiptsHint =>
      'Si las desactivas, tus amigos no verán cuándo leíste sus mensajes y tú tampoco verás los suyos';

  @override
  String get settingsQuietFrom => 'Silencio desde';

  @override
  String get settingsQuietHours => 'Horas de silencio';

  @override
  String get settingsQuietHoursFooter =>
      'Sin notificaciones push durante estas horas. Los mensajes siguen llegando a la app.';

  @override
  String get settingsQuietHoursFrom => 'Desde';

  @override
  String get settingsQuietHoursUntil => 'Hasta';

  @override
  String get settingsQuietUntil => 'Silencio hasta';

  @override
  String get settingsSectionAccount => 'MI CUENTA';

  @override
  String get settingsSectionCamera => 'CÁMARA';

  @override
  String get settingsSectionContact => 'CONTACTO';

  @override
  String get settingsSectionHow => 'CÓMO';

  @override
  String get settingsSectionMap => 'MAPA';

  @override
  String get settingsSectionMoreActivity => 'ACTIVIDAD';

  @override
  String get settingsSectionNewCapsules => 'CÁPSULAS NUEVAS';

  @override
  String get settingsSectionNotificationsPrivacy =>
      'NOTIFICACIONES Y PRIVACIDAD';

  @override
  String get settingsSectionNotifyAbout => 'AVÍSAME DE';

  @override
  String get settingsSectionQuestions => 'PREGUNTAS';

  @override
  String get settingsSectionQuietHours => 'HORAS DE SILENCIO';

  @override
  String get settingsSectionSize => 'TAMAÑO';

  @override
  String get settingsSectionSupport => 'SOPORTE';

  @override
  String get settingsSectionTheme => 'TEMA';

  @override
  String get settingsSectionThisPhone => 'ESTE TELÉFONO';

  @override
  String get settingsSectionVisibility => 'QUÉ VEN LOS DEMÁS';

  @override
  String get settingsSignedInWithGoogle => 'Sesión iniciada con Google';

  @override
  String get settingsSizeFooter =>
      'Hace todo lo que hay en pantalla más pequeño o más grande, también el texto.';

  @override
  String get settingsSizeLarge => 'Grande';

  @override
  String get settingsSizeSmall => 'Pequeño';

  @override
  String get settingsSizeStandard => 'Estándar';

  @override
  String get settingsStorageCache => 'Caché';

  @override
  String get settingsStorageClear => 'Borrar';

  @override
  String get settingsStorageClearCache => 'Borrar caché';

  @override
  String get settingsStorageClearConfirm =>
      '¿Borrar la caché? Las imágenes se volverán a cargar cuando las necesites.';

  @override
  String get settingsStorageCleared => 'Caché borrada';

  @override
  String get settingsStorageClearing => 'Borrando...';

  @override
  String get settingsStorageDescription =>
      'Espacio que ocupa Later en este teléfono';

  @override
  String get settingsStorageFooter =>
      'Fotos hechas o elegidas para cápsulas e imágenes cargadas desde internet. Tus cápsulas, chats y cuenta se quedan.';

  @override
  String settingsSupportInfoApp(String version) {
    return 'App: Later $version';
  }

  @override
  String settingsSupportInfoPhone(String system) {
    return 'Teléfono: $system';
  }

  @override
  String settingsSupportInfoUserId(String uid) {
    return 'ID de usuario: $uid';
  }

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeSystem => 'Igual que el teléfono';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsUnblock => 'Desbloquear';

  @override
  String get settingsUnblocking => 'Desbloqueando...';

  @override
  String get settingsUsername => 'Nombre de usuario';

  @override
  String get settingsUsernameDescription =>
      'Así te encuentran y te añaden tus amigos en Later';

  @override
  String get settingsUsernameHint => 'Nuevo nombre de usuario';

  @override
  String get settingsUsernameUpdated => '¡Nombre de usuario actualizado!';

  @override
  String get settingsVisibilityFriends => 'Amigos';

  @override
  String get settingsVisibilityFriendsHint => 'Solo tus amigos';

  @override
  String get settingsVisibilityPrivate => 'Privada';

  @override
  String get settingsVisibilityPrivateHint => 'Solo tú';

  @override
  String get settingsVisibilityPublic => 'Pública';

  @override
  String get settingsVisibilityPublicHint => 'Todos en el mapa';

  @override
  String get settingsYourPassword => 'Tu contraseña';
}
