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
