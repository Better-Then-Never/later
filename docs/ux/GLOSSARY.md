# GLOSSARY.md: product terms and their approved translations

Every translation uses these terms. Tone: short, warm, playful, like a friend talking. Address the user
informally in Polish (ty), German (du) and Spanish (tú); Russian uses «вы» (lower case) as most Russian apps do.
"Later" is the brand: never translated, never inflected in a way that changes its spelling.

| English | Русский | Polski | Deutsch | Español |
|---|---|---|---|---|
| Later (app name) | Later | Later | Later | Later |
| capsule / capsules | капсула / капсулы | kapsuła / kapsuły | Kapsel / Kapseln | cápsula / cápsulas |
| time capsule | капсула времени | kapsuła czasu | Zeitkapsel | cápsula del tiempo |
| loop capsule | капсула-луп | kapsuła loop | Loop-Kapsel | cápsula loop |
| My Laters (messages tab title) | Мои Laters | Moje Laters | Meine Laters | Mis Laters |
| map | карта | mapa | Karte | mapa |
| place / location | место / геопозиция | miejsce / lokalizacja | Ort / Standort | lugar / ubicación |
| friend / friends | друг / друзья | znajomy / znajomi | Freund / Freunde | amigo / amigos |
| friend request | заявка в друзья | zaproszenie do znajomych | Freundschaftsanfrage | solicitud de amistad |
| follower / followers | подписчик / подписчики | obserwujący | Follower | seguidor / seguidores |
| following | подписки | obserwowani | Gefolgt | siguiendo |
| follow / unfollow | подписаться / отписаться | obserwuj / przestań obserwować | folgen / entfolgen | seguir / dejar de seguir |
| message / messages, chat | сообщение / сообщения, чат | wiadomość / wiadomości, czat | Nachricht / Nachrichten, Chat | mensaje / mensajes, chat |
| notification(s) | уведомление / уведомления | powiadomienie / powiadomienia | Benachrichtigung(en) | notificación / notificaciones |
| profile | профиль | profil | Profil | perfil |
| settings | Настройки | Ustawienia | Einstellungen | Ajustes |
| username | имя пользователя | nazwa użytkownika | Benutzername | nombre de usuario |
| block / unblock | заблокировать / разблокировать | zablokuj / odblokuj | blockieren / Blockierung aufheben | bloquear / desbloquear |
| mute / unmute | отключить уведомления / включить уведомления | wycisz / wyłącz wyciszenie | stummschalten / Stummschaltung aufheben | silenciar / activar sonido |
| Public / Friends / Private (visibility) | Публичная / Для друзей / Личная | Publiczna / Dla znajomych / Prywatna | Öffentlich / Freunde / Privat | Pública / Amigos / Privada |
| opens on (date) | откроется | otworzy się | öffnet sich am | se abre el |
| streak | серия | seria | Serie | racha |
| achievement(s) | достижение / достижения | osiągnięcie / osiągnięcia | Erfolg / Erfolge | logro / logros |
| reaction(s) | реакция / реакции | reakcja / reakcje | Reaktion / Reaktionen | reacción / reacciones |
| comment(s) | комментарий / комментарии | komentarz / komentarze | Kommentar / Kommentare | comentario / comentarios |
| co-author | соавтор | współautor | Mitautor | coautor |
| explore | исследовать | odkrywaj | entdecken | explorar |
| verified | подтверждённый аккаунт | zweryfikowane konto | verifiziert | verificado |
| Log Out | Выйти | Wyloguj się | Abmelden | Cerrar sesión |
| Delete account | Удалить аккаунт | Usuń konto | Konto löschen | Eliminar cuenta |

Rules:
- Plurals use ICU plural forms: Russian needs `one`, `few`, `many`, `other`; Polish `one`, `few`, `many`,
  `other`; German and Spanish `one`, `other`. Always give `=0` where English has a zero phrase.
- Dates and times are formatted with the current locale (`DateFormat(..., locale)`), never hard-coded patterns.
- Keep emoji and the app name exactly as in English. Keep button labels short (German grows ~30 %).
