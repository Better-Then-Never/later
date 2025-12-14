import 'package:flutter/foundation.dart';


class CapsuleJumpService extends ChangeNotifier {
  Map<String, dynamic>? _capsule;

  Map<String, dynamic>? get capsule => _capsule;

  void jumpTo(Map<String, dynamic> capsule) {
    _capsule = capsule;
    notifyListeners();
  }

  void clear() {
    _capsule = null;
  }
}
