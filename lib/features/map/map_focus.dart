import 'package:flutter/foundation.dart';

import '../../data/models/capsule.dart';

/// A request to show a capsule on the map (from the history list or a
/// notification). The map consumes it once its camera is ready.
class MapFocus extends ChangeNotifier {
  Capsule? _pending;

  Capsule? get pending => _pending;

  void focus(Capsule capsule) {
    _pending = capsule;
    notifyListeners();
  }

  /// Returns the pending capsule and clears it.
  Capsule? take() {
    final capsule = _pending;
    _pending = null;
    return capsule;
  }
}
