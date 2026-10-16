/// Something whose state belongs to one signed-in user. The session attaches
/// it when a user signs in and detaches it when they sign out, so no data can
/// survive from one account into the next.
abstract class SessionScoped {
  void attach(String uid);
  void detach();

  /// Runs while the user is still authenticated, right before sign-out
  /// (e.g. to remove this device's push token).
  Future<void> beforeSignOut(String uid) async {}
}
