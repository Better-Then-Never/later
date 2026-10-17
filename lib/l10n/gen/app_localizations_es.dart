// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

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
  String get authPermissionContactsText =>
      '¡Encuentra a tus amigos en tus contactos e invítalos!';

  @override
  String get authPermissionContactsTitle => 'Acceso a los contactos';

  @override
  String get authPermissionEnable => 'Permitir';

  @override
  String get authPermissionGranted => 'Permitido';

  @override
  String get authPermissionLocationText =>
      '¡Y podrás encontrar cápsulas cerca de ti!';

  @override
  String get authPermissionLocationTitle =>
      'Comparte tu ubicación con nosotros';

  @override
  String get authPermissionMicrophoneText => 'Sin él, la cámara no funcionará';

  @override
  String get authPermissionMicrophoneTitle =>
      'Dale a Later acceso al micrófono';

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
  String get commonBack => 'Atrás';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonDone => 'Listo';

  @override
  String get commonErrorGeneric => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get commonLoading => 'Cargando...';

  @override
  String get commonNoConnection => 'Sin conexión. Inténtalo de nuevo.';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonSearchHint => 'Buscar...';

  @override
  String get commonUnknownUser => 'Usuario desconocido';

  @override
  String get commonUnknownUsername => 'desconocido';

  @override
  String get failureNotFound => 'Este elemento ya no existe.';

  @override
  String get failurePermission => 'No tienes permiso para hacer eso.';

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
  String get messagesClearConfirm => 'Borrar';

  @override
  String get messagesClearConfirmTitle =>
      '¿Seguro que quieres borrar el historial del chat?';

  @override
  String get messagesClearFailed => 'No se pudo borrar el historial';

  @override
  String messagesEmptySubtitle(String name) {
    return '¡Saluda a $name!';
  }

  @override
  String get messagesEmptyTitle => 'Aún no hay mensajes';

  @override
  String get messagesFindChatsHint => 'Buscar chats';

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
  String get messagesReceiptFailed => 'No enviado · Toca para reintentar';

  @override
  String get messagesReceiptRead => 'Leído';

  @override
  String get messagesReceiptSending => 'Enviando…';

  @override
  String get messagesReceiptSent => 'Enviado';

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
  String get messagesSignedOut => 'Has cerrado sesión';

  @override
  String messagesStartChatWith(String name) {
    return 'Empezar un chat con $name';
  }

  @override
  String get messagesTitle => 'Mis Laters';

  @override
  String get messagesToday => 'Hoy';

  @override
  String get messagesTooLong => 'Este mensaje es demasiado largo';

  @override
  String get messagesUnmutedToast => 'Sonido del chat activado';

  @override
  String get messagesYesterday => 'Ayer';

  @override
  String messagesYouPrefix(String message) {
    return 'Tú: $message';
  }

  @override
  String get placeNoLocation => 'Sin ubicación';

  @override
  String get placeUnknown => 'Lugar desconocido';
}
