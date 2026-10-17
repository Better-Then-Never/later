import '../../core/l10n/l10n.dart';
import '../../data/models/capsule.dart';

/// Colour names in the app's language (the model's `label` stays English).
extension CapsuleColorL10n on CapsuleColor {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    CapsuleColor.red => l10n.historyColorRed,
    CapsuleColor.blue => l10n.historyColorBlue,
    CapsuleColor.green => l10n.historyColorGreen,
    CapsuleColor.yellow => l10n.historyColorYellow,
    CapsuleColor.orange => l10n.historyColorOrange,
    CapsuleColor.purple => l10n.historyColorPurple,
  };
}

/// Visibility names in the app's language (the model's `label` stays
/// English).
extension CapsulePrivacyL10n on CapsulePrivacy {
  /// "Public", "Private", "Friends": the filter menu and button.
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    CapsulePrivacy.public => l10n.historyPrivacyPublic,
    CapsulePrivacy.private => l10n.historyPrivacyPrivate,
    CapsulePrivacy.friends => l10n.historyPrivacyFriends,
  };

  /// "Public visibility" etc.: the info row of a capsule in the list.
  String visibilityLabel(AppLocalizations l10n) => switch (this) {
    CapsulePrivacy.public => l10n.historyVisibilityPublic,
    CapsulePrivacy.private => l10n.historyVisibilityPrivate,
    CapsulePrivacy.friends => l10n.historyVisibilityFriends,
  };
}
