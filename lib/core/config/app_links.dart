/// Addresses shown in Settings > Help and support and Settings > About.
///
/// One place for every external link. A null value hides its row: there is
/// no support mailbox, privacy policy or terms page yet
/// (docs/polish/BLOCKERS.md). Fill them in here and the rows appear.
abstract final class AppLinks {
  /// Where "Contact support" and "Report a problem" write to.
  static const String? supportEmail = null;

  static const String? privacyPolicy = null;
  static const String? termsOfService = null;
}
