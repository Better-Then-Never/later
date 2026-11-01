// Push texts in the recipient's language (users/{uid}/settings/app.language),
// English when unknown. Terms follow docs/ux/GLOSSARY.md.
'use strict';

const LANGUAGES = ['en', 'ru', 'pl', 'de', 'es'];

const MESSAGES = {
  en: {
    followTitle: 'New follower',
    followBody: '{name} started following you',
    capsuleTitle: 'New capsule',
    capsuleBody: '{name} created a new capsule',
    coAuthorTitle: 'Made together',
    coAuthorBody: '{name} made a capsule with you',
    messageNoPreview: 'New message',
    messageCapsule: 'Sent you a capsule',
    messageCapsuleTitled: 'Sent you a capsule: {title}',
    messagePhoto: 'Sent you a photo',
    messageVoice: 'Voice message',
    messageReaction: 'Reacted {emoji} to your message',
    messageReactionText: '{emoji} to your message: {text}',
    requestTitle: 'Friend request',
    requestBody: '{name} wants to be your friend',
    acceptedTitle: 'New friend',
    acceptedBody: '{name} accepted your friend request',
    reactionTitle: 'New reaction',
    reactionBody: '{name} reacted {emoji} to your capsule',
    commentTitle: 'New comment',
    commentBody: '{name}: {text}',
    replyTitle: 'New reply',
    achievementTitle: 'Achievement unlocked',
    achievementBody: '{title}',
    streakTitle: 'Keep your streak',
    streakBody: 'Your {days}-day streak ends tonight. Make a capsule!',
    openTitle: '{title} is open',
    openBodyOwn: 'Your capsule from {date}. Tap to open it.',
    openBodyFrom: "{name}'s capsule from {date}. Tap to open it.",
    readyTitle: '{title} is ready',
    readyBody: "{elapsed}. It's waiting for you in {place}.",
    readyBodyNoPlace: "{elapsed}. It's waiting for you where it was left.",
    someone: 'Someone',
  },
  ru: {
    followTitle: 'Новый подписчик',
    followBody: '{name} — ваш новый подписчик',
    capsuleTitle: 'Новая капсула',
    capsuleBody: 'Новая капсула от {name}',
    coAuthorTitle: 'Вместе',
    coAuthorBody: 'Совместная капсула от {name}',
    messageNoPreview: 'Новое сообщение',
    messageCapsule: 'Капсула для вас',
    messageCapsuleTitled: 'Капсула для вас: {title}',
    messagePhoto: 'Фото для вас',
    messageVoice: 'Голосовое сообщение',
    messageReaction: '{emoji} на ваше сообщение',
    messageReactionText: '{emoji} на ваше сообщение: {text}',
    requestTitle: 'Заявка в друзья',
    requestBody: '{name} хочет добавить вас в друзья',
    acceptedTitle: 'Новый друг',
    acceptedBody: '{name} теперь у вас в друзьях',
    reactionTitle: 'Новая реакция',
    reactionBody: '{emoji} от {name} на вашу капсулу',
    commentTitle: 'Новый комментарий',
    commentBody: '{name}: {text}',
    replyTitle: 'Новый ответ',
    achievementTitle: 'Новое достижение',
    achievementBody: '{title}',
    streakTitle: 'Сохраните серию',
    streakBody: 'Ваша серия из {days} дн. прервётся сегодня ночью. Создайте капсулу!',
    openTitle: '«{title}» открыта',
    openBodyOwn: 'Ваша капсула, оставленная {date}. Нажмите, чтобы открыть.',
    openBodyFrom: 'Капсула {name}, оставленная {date}. Нажмите, чтобы открыть.',
    readyTitle: '«{title}» готова',
    readyBody: '{elapsed}. Она ждёт вас: {place}.',
    readyBodyNoPlace: '{elapsed}. Она ждёт там, где её оставили.',
    someone: 'Кто-то',
  },
  pl: {
    followTitle: 'Nowy obserwujący',
    followBody: '{name} zaczyna cię obserwować',
    capsuleTitle: 'Nowa kapsuła',
    capsuleBody: '{name} tworzy nową kapsułę',
    coAuthorTitle: 'Razem',
    coAuthorBody: '{name} tworzy kapsułę razem z tobą',
    messageNoPreview: 'Nowa wiadomość',
    messageCapsule: 'Wysyła ci kapsułę',
    messageCapsuleTitled: 'Wysyła ci kapsułę: {title}',
    messagePhoto: 'Wysyła ci zdjęcie',
    messageVoice: 'Wiadomość głosowa',
    messageReaction: 'Reaguje {emoji} na twoją wiadomość',
    messageReactionText: '{emoji} na twoją wiadomość: {text}',
    requestTitle: 'Zaproszenie do znajomych',
    requestBody: '{name} chce dodać cię do znajomych',
    acceptedTitle: 'Nowy znajomy',
    acceptedBody: '{name} przyjmuje twoje zaproszenie',
    reactionTitle: 'Nowa reakcja',
    reactionBody: '{name} reaguje {emoji} na twoją kapsułę',
    commentTitle: 'Nowy komentarz',
    commentBody: '{name}: {text}',
    replyTitle: 'Nowa odpowiedź',
    achievementTitle: 'Nowe osiągnięcie',
    achievementBody: '{title}',
    streakTitle: 'Nie przerywaj serii',
    streakBody: 'Twoja seria ({days} dni) skończy się dziś w nocy. Stwórz kapsułę!',
    openTitle: '„{title}” jest otwarta',
    openBodyOwn: 'Twoja kapsuła z {date}. Dotknij, by ją otworzyć.',
    openBodyFrom: 'Kapsuła od {name} z {date}. Dotknij, by ją otworzyć.',
    readyTitle: '„{title}” jest gotowa',
    readyBody: '{elapsed}. Czeka na Ciebie: {place}.',
    readyBodyNoPlace: '{elapsed}. Czeka tam, gdzie ją zostawiono.',
    someone: 'Ktoś',
  },
  de: {
    followTitle: 'Neuer Follower',
    followBody: '{name} folgt dir jetzt',
    capsuleTitle: 'Neue Kapsel',
    capsuleBody: '{name} hat eine neue Kapsel erstellt',
    coAuthorTitle: 'Gemeinsam',
    coAuthorBody: '{name} hat eine Kapsel mit dir gemacht',
    messageNoPreview: 'Neue Nachricht',
    messageCapsule: 'Hat dir eine Kapsel geschickt',
    messageCapsuleTitled: 'Hat dir eine Kapsel geschickt: {title}',
    messagePhoto: 'Hat dir ein Foto geschickt',
    messageVoice: 'Sprachnachricht',
    messageReaction: 'Hat mit {emoji} auf deine Nachricht reagiert',
    messageReactionText: '{emoji} auf deine Nachricht: {text}',
    requestTitle: 'Freundschaftsanfrage',
    requestBody: '{name} möchte mit dir befreundet sein',
    acceptedTitle: 'Neuer Freund',
    acceptedBody: '{name} hat deine Freundschaftsanfrage angenommen',
    reactionTitle: 'Neue Reaktion',
    reactionBody: '{name} hat mit {emoji} auf deine Kapsel reagiert',
    commentTitle: 'Neuer Kommentar',
    commentBody: '{name}: {text}',
    replyTitle: 'Neue Antwort',
    achievementTitle: 'Erfolg freigeschaltet',
    achievementBody: '{title}',
    streakTitle: 'Halte deine Serie',
    streakBody: 'Deine Serie von {days} Tagen endet heute Nacht. Erstelle eine Kapsel!',
    openTitle: '„{title}“ ist offen',
    openBodyOwn: 'Deine Kapsel vom {date}. Tippe, um sie zu öffnen.',
    openBodyFrom: 'Kapsel von {name} vom {date}. Tippe, um sie zu öffnen.',
    readyTitle: '„{title}“ ist bereit',
    readyBody: '{elapsed}. Sie wartet in {place} auf dich.',
    readyBodyNoPlace: '{elapsed}. Sie wartet dort auf dich, wo sie hinterlassen wurde.',
    someone: 'Jemand',
  },
  es: {
    followTitle: 'Nuevo seguidor',
    followBody: '{name} empezó a seguirte',
    capsuleTitle: 'Nueva cápsula',
    capsuleBody: '{name} creó una nueva cápsula',
    coAuthorTitle: 'Juntos',
    coAuthorBody: '{name} hizo una cápsula contigo',
    messageNoPreview: 'Nuevo mensaje',
    messageCapsule: 'Te envió una cápsula',
    messageCapsuleTitled: 'Te envió una cápsula: {title}',
    messagePhoto: 'Te envió una foto',
    messageVoice: 'Mensaje de voz',
    messageReaction: 'Reaccionó {emoji} a tu mensaje',
    messageReactionText: '{emoji} a tu mensaje: {text}',
    requestTitle: 'Solicitud de amistad',
    requestBody: '{name} quiere ser tu amigo',
    acceptedTitle: 'Nuevo amigo',
    acceptedBody: '{name} aceptó tu solicitud de amistad',
    reactionTitle: 'Nueva reacción',
    reactionBody: '{name} reaccionó {emoji} a tu cápsula',
    commentTitle: 'Nuevo comentario',
    commentBody: '{name}: {text}',
    replyTitle: 'Nueva respuesta',
    achievementTitle: 'Logro desbloqueado',
    achievementBody: '{title}',
    streakTitle: 'Mantén tu racha',
    streakBody: 'Tu racha de {days} días termina esta noche. ¡Crea una cápsula!',
    openTitle: '«{title}» está abierta',
    openBodyOwn: 'Tu cápsula del {date}. Tócala para abrirla.',
    openBodyFrom: 'La cápsula de {name} del {date}. Tócala para abrirla.',
    readyTitle: '«{title}» está lista',
    readyBody: '{elapsed}. Te espera en {place}.',
    readyBodyNoPlace: '{elapsed}. Te espera donde la dejaron.',
    someone: 'Alguien',
  },
};

/**
 * How long a capsule waited ("A year has passed", "Прошло 3 года"):
 * whole years, else months, else days, by each language's plural rules.
 */
const ELAPSED = {
  en: {
    year: { 1: 'A year has passed', other: '{n} years have passed' },
    month: { 1: 'A month has passed', other: '{n} months have passed' },
    day: { 1: 'A day has passed', other: '{n} days have passed' },
  },
  de: {
    year: { 1: 'Ein Jahr ist vergangen', other: '{n} Jahre sind vergangen' },
    month: { 1: 'Ein Monat ist vergangen', other: '{n} Monate sind vergangen' },
    day: { 1: 'Ein Tag ist vergangen', other: '{n} Tage sind vergangen' },
  },
  es: {
    year: { 1: 'Ha pasado un año', other: 'Han pasado {n} años' },
    month: { 1: 'Ha pasado un mes', other: 'Han pasado {n} meses' },
    day: { 1: 'Ha pasado un día', other: 'Han pasado {n} días' },
  },
  pl: {
    year: { 1: 'Minął rok', few: 'Minęły {n} lata', many: 'Minęło {n} lat', other: 'Minęło {n} roku' },
    month: { 1: 'Minął miesiąc', few: 'Minęły {n} miesiące', many: 'Minęło {n} miesięcy', other: 'Minęło {n} miesiąca' },
    day: { 1: 'Minął dzień', few: 'Minęły {n} dni', many: 'Minęło {n} dni', other: 'Minęło {n} dnia' },
  },
  ru: {
    year: { 1: 'Прошёл год', one: 'Прошёл {n} год', few: 'Прошло {n} года', many: 'Прошло {n} лет', other: 'Прошло {n} года' },
    month: { 1: 'Прошёл месяц', one: 'Прошёл {n} месяц', few: 'Прошло {n} месяца', many: 'Прошло {n} месяцев', other: 'Прошло {n} месяца' },
    day: { 1: 'Прошёл день', one: 'Прошёл {n} день', few: 'Прошло {n} дня', many: 'Прошло {n} дней', other: 'Прошло {n} дня' },
  },
};

function elapsed(lang, from, to) {
  const forms = ELAPSED[LANGUAGES.includes(lang) ? lang : 'en'];
  const days = Math.max(1, Math.floor((to.getTime() - from.getTime()) / 86400000));
  const [unit, n] =
    days >= 365 ? ['year', Math.floor(days / 365)] :
    days >= 30 ? ['month', Math.floor(days / 30)] :
    ['day', days];
  const table = forms[unit];
  const form = n === 1 ? table[1] : table[new Intl.PluralRules(lang).select(n)] || table.other;
  return form.replace('{n}', String(n));
}

/** [date] as the app writes it ("6 Oct 2025") in [lang]. */
function day(lang, date) {
  const locale = lang === 'en' || !LANGUAGES.includes(lang) ? 'en-GB' : lang;
  return new Intl.DateTimeFormat(locale, {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
    timeZone: 'UTC',
  })
    .format(date)
    // Russian adds "г."; the sentence brings its own full stop.
    .replace(/\s*г\.$/, '');
}

function languageOf(settings) {
  const lang = settings && settings.language;
  return LANGUAGES.includes(lang) ? lang : 'en';
}

/** The message [key] in [lang] with {placeholders} filled in. */
function t(lang, key, values = {}) {
  const table = MESSAGES[LANGUAGES.includes(lang) ? lang : 'en'];
  const text = table[key] !== undefined ? table[key] : MESSAGES.en[key];
  if (text === undefined) throw new Error(`unknown message ${key}`);
  return text.replace(/\{(\w+)\}/g, (_, name) =>
    values[name] !== undefined ? String(values[name]) : `{${name}}`,
  );
}

module.exports = { LANGUAGES, MESSAGES, languageOf, t, elapsed, day };
