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
  String get placeNoLocation => 'Sin ubicación';

  @override
  String get placeUnknown => 'Lugar desconocido';

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
  String get settingsNotificationsDescription => 'Elige de qué te avisa Later';

  @override
  String get settingsNotificationsFollowers => 'Nuevos seguidores';

  @override
  String get settingsNotificationsMessages => 'Mensajes';

  @override
  String get settingsNotificationsMuteHint =>
      'Silencia un chat concreto desde su menú en Mensajes.';

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
  String get settingsNotificationsSound => 'Sonido y vibración';

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
  String get settingsPermissionContacts => 'Contactos';

  @override
  String get settingsPermissionContactsDescription =>
      'Invita a amigos y encuentra a gente que conoces';

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
  String get settingsPermissionMicrophone => 'Micrófono';

  @override
  String get settingsPermissionMicrophoneDescription =>
      'Grabar audio para cápsulas del tiempo';

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
  String get settingsSectionNotificationsPrivacy =>
      'NOTIFICACIONES Y PRIVACIDAD';

  @override
  String get settingsSectionNotifyAbout => 'AVÍSAME DE';

  @override
  String get settingsSectionQuestions => 'PREGUNTAS';

  @override
  String get settingsSectionQuietHours => 'HORAS DE SILENCIO';

  @override
  String get settingsSectionSupport => 'SOPORTE';

  @override
  String get settingsSectionThisPhone => 'ESTE TELÉFONO';

  @override
  String get settingsSignedInWithGoogle => 'Sesión iniciada con Google';

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
  String get settingsYourPassword => 'Tu contraseña';
}
