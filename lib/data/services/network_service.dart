import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// What kind of network the phone is on, through the app's own channel
/// (MainActivity.kt, "later.app/network"). Android only; elsewhere every
/// network counts as unmetered.
class NetworkService {
  NetworkService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('later.app/network');

  final MethodChannel _channel;

  /// Whether the current network costs money (mobile data).
  Future<bool> isMetered() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    return await _channel.invokeMethod<bool>('isMetered') ?? false;
  }
}
