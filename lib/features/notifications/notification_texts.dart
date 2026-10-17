import '../../core/l10n/l10n.dart';
import '../../data/models/app_notification.dart';
import '../../core/l10n/app_dates.dart';

/// Titles in the app's language (the model's `title` stays English).
extension NotificationTypeL10n on NotificationType {
  String localizedTitle(AppLocalizations l10n) => switch (this) {
    NotificationType.follow => l10n.notificationsTypeFollow,
    NotificationType.capsule => l10n.notificationsTypeCapsule,
    NotificationType.message => l10n.notificationsTypeMessage,
    NotificationType.reply => l10n.notificationsTypeReply,
    NotificationType.comment => l10n.notificationsTypeComment,
    NotificationType.reaction => l10n.notificationsTypeReaction,
    NotificationType.friendRequest => l10n.notificationsTypeFriendRequest,
    NotificationType.friendAccepted => l10n.notificationsTypeFriendAccepted,
    NotificationType.achievement => l10n.notificationsTypeAchievement,
    NotificationType.other => l10n.notificationsTypeOther,
  };
}

/// A notification sentence split around the sender's name, which the list
/// shows in bold wherever the language puts it.
typedef NotificationSentence = ({String before, String after});

/// Texts of the in-app notifications, in the app's language. Widgets pass
/// `context.l10n`; without it [AppL10n.current] is used.
abstract final class NotificationTexts {
  /// Stands in for the name while the sentence is built (a private-use
  /// character, never part of a translation or a user's text).
  static const _name = '\u{E000}';

  /// The sentence of [n]. Known types are written from the type and the
  /// sender's name ("{name} started following you"), not from the English
  /// `message` stored with the notification; comments and replies keep
  /// their stored text (what the person wrote). Unknown types show the
  /// stored message after the name, as before.
  static NotificationSentence sentence(
    AppNotification n, {
    AppLocalizations? l10n,
  }) {
    final strings = l10n ?? AppL10n.current;
    final text = n.message.trim();
    final template = switch (n.type) {
      NotificationType.follow => strings.notificationsFollowBody(_name),
      NotificationType.capsule => strings.notificationsCapsuleBody(_name),
      NotificationType.message => strings.notificationsMessageBody(_name),
      NotificationType.comment =>
        text.isEmpty
            ? strings.notificationsCommentBody(_name)
            : strings.notificationsCommentBodyWithText(_name, text),
      NotificationType.reply =>
        text.isEmpty
            ? strings.notificationsReplyBody(_name)
            : strings.notificationsReplyBodyWithText(_name, text),
      NotificationType.reaction => strings.notificationsReactionBody(
        _name,
        n.reaction ?? '',
      ),
      NotificationType.friendRequest => strings.notificationsFriendRequestBody(
        _name,
      ),
      NotificationType.friendAccepted =>
        strings.notificationsFriendAcceptedBody(_name),
      NotificationType.achievement => strings.notificationsAchievementBody(
        _name,
      ),
      NotificationType.other => null,
    };
    if (template == null) return (before: '', after: ' ${n.message}');
    final at = template.indexOf(_name);
    if (at < 0) return (before: '', after: ' $template');
    return (
      before: template.substring(0, at),
      after: template.substring(at + _name.length),
    );
  }

  /// Time of a notification: "Just now", minutes, hours and days ago, then
  /// the date ("16/10/2026").
  static String time(
    DateTime timestamp,
    DateTime now, {
    AppLocalizations? l10n,
  }) {
    final strings = l10n ?? AppL10n.current;
    final difference = now.difference(timestamp);
    if (difference.inMinutes < 1) return strings.notificationsJustNow;
    if (difference.inHours < 1) {
      return strings.notificationsMinutesAgo(difference.inMinutes);
    }
    if (difference.inDays < 1) {
      return strings.notificationsHoursAgo(difference.inHours);
    }
    if (difference.inDays < 7) {
      return strings.notificationsDaysAgo(difference.inDays);
    }
    return AppDates.short(timestamp, strings.localeName);
  }
}
