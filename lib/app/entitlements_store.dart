import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../core/config/limits.dart';
import '../core/logging/app_logger.dart';
import '../core/session/session_scoped.dart';
import '../data/repositories/repositories.dart';

/// The signed-in account's [Limits] (B7): read once per sign-in from
/// `entitlements/limits`; the defaults until then, or when it cannot be
/// read. One document read per session.
class EntitlementsStore extends ChangeNotifier implements SessionScoped {
  EntitlementsStore(this._config);

  final ConfigRepository _config;
  Limits _limits = Limits.standard;
  String? _uid;

  Limits get limits => _limits;

  /// The limits where [context] has the store, the defaults elsewhere
  /// (tests and pages built without it).
  static Limits of(BuildContext context) {
    try {
      return context.read<EntitlementsStore>().limits;
    } on ProviderNotFoundException {
      return Limits.standard;
    }
  }

  @override
  void attach(String uid) {
    _uid = uid;
    _config
        .limits()
        .then((data) {
          if (_uid != uid) return;
          final next = Limits.fromMap(data);
          if (next == _limits) return;
          _limits = next;
          notifyListeners();
        })
        .catchError((Object e) {
          AppLogger.warning('Limits not read, defaults kept', error: e);
        });
  }

  @override
  void detach() {
    _uid = null;
    if (_limits == Limits.standard) return;
    _limits = Limits.standard;
    notifyListeners();
  }

  @override
  Future<void> beforeSignOut(String uid) async {}
}
