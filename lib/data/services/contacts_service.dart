import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// The phone's contacts, as hashes of their email addresses only: the
/// address book is read and hashed in native code
/// (android/.../ContactsChannel.kt), so no name, number or address reaches
/// Dart or the server. Android only for now.
class ContactsService {
  ContactsService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('later.app/contacts');

  final MethodChannel _channel;

  /// Whether this phone can look for friends in its contacts.
  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  /// Asks for access to the contacts; true when granted.
  Future<bool> requestAccess() async =>
      (await Permission.contacts.request()).isGranted;

  /// At most [limit] distinct hashes (empty without access).
  Future<List<String>> emailHashes({int limit = 1000}) async {
    final list = await _channel.invokeListMethod<String>('emailHashes', {
      'limit': limit,
    });
    return list ?? const [];
  }
}
