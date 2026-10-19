import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/logging/app_logger.dart';
import '../../core/session/session_scoped.dart';
import '../../data/models/capsule.dart';
import '../../data/models/geo_position.dart';

/// Which of the map's queries a pin came from ([MapController]'s sources):
/// a source that answers replaces the stored pins it had.
enum PinSource { own, co, friends, public }

/// A pin as the map last showed it: only what the marker, the filter and the
/// visibility rule need (id, owner, place, colour, privacy, opening time)
/// and the source it came from. Never a title, a photo or a text.
class StoredPin {
  const StoredPin(this.capsule, this.source);

  final Capsule capsule;
  final PinSource source;
}

/// The map's pins on this phone (M-06, docs/map/COLD_START.md): written
/// whenever the map has every source's answer, read when the account signs
/// in, so a cold start draws every pin with the streets instead of waiting
/// for Firestore (whose first answer took 1.2 s and more). The map replaces
/// a source's pins as soon as that source answers, so a capsule deleted,
/// hidden or no longer visible goes with the first answer
/// ([MapController]).
///
/// One file per account in the app's private storage (`map_pins/<uid>.bin`),
/// holding only pins the server returned to that account. Deleted when the
/// account signs out or its session ends, and when another account signs in
/// on this phone (docs/ux/PRIVACY.md).
class MapPinStore extends SessionScoped {
  MapPinStore({Future<Directory> Function()? directory})
    : _directory = directory ?? _defaultDirectory;

  final Future<Directory> Function() _directory;
  String? _uid;
  Future<List<StoredPin>>? _loading;
  Future<void> _writing = Future.value();
  Future<void> _cleaning = Future.value();

  /// Every read, write and deletion begun so far has finished.
  @visibleForTesting
  Future<void> get settled async {
    await _loading;
    await _writing;
    await _cleaning;
  }

  static Future<Directory> _defaultDirectory() async =>
      Directory('${(await getApplicationSupportDirectory()).path}/map_pins');

  @override
  void attach(String uid) {
    _uid = uid;
    _loading = _read(uid);
    _cleaning = _removeOthers(uid);
  }

  @override
  void detach() {
    final uid = _uid;
    _uid = null;
    _loading = null;
    if (uid != null) _cleaning = _delete(uid);
  }

  /// The pins the map showed when [uid] last used it on this phone; empty
  /// when there are none (a first start, another account).
  Future<List<StoredPin>> pins(String uid) =>
      uid == _uid ? _loading ?? Future.value(const []) : Future.value(const []);

  /// Keeps [pins] as [uid]'s (after the previous write, never two at once).
  Future<void> save(String uid, Iterable<StoredPin> pins) {
    if (uid != _uid) return Future.value();
    final bytes = encode(pins);
    return _writing = _writing.then((_) async {
      if (uid != _uid) return;
      try {
        final file = await _file(uid);
        await file.parent.create(recursive: true);
        // Whole or not at all: a start never reads half a file.
        final part = File('${file.path}.part');
        await part.writeAsBytes(bytes, flush: true);
        await part.rename(file.path);
      } on Object catch (e) {
        AppLogger.warning('Map pins not saved', error: e);
      }
    });
  }

  Future<File> _file(String uid) async =>
      File('${(await _directory()).path}/$uid.bin');

  Future<List<StoredPin>> _read(String uid) async {
    try {
      final file = await _file(uid);
      if (!await file.exists()) return const [];
      return decode(await file.readAsBytes(), uid: uid);
    } on Object catch (e) {
      AppLogger.warning('Map pins not read', error: e);
      return const [];
    }
  }

  Future<void> _delete(String uid) async {
    await _writing;
    try {
      final file = await _file(uid);
      if (await file.exists()) await file.delete();
    } on Object catch (e) {
      AppLogger.warning('Map pins not deleted', error: e);
    }
  }

  /// Another account's pins never stay on the phone with this one.
  Future<void> _removeOthers(String uid) async {
    try {
      final dir = await _directory();
      if (!await dir.exists()) return;
      await for (final entry in dir.list()) {
        final name = entry.uri.pathSegments.last;
        // This account's file and its write in progress stay.
        if (entry is File && !name.startsWith('$uid.')) await entry.delete();
      }
    } on Object catch (e) {
      AppLogger.warning('Map pins of another account not deleted', error: e);
    }
  }

  // ---------------------------------------------------------------- format

  /// "LMP" and the format's version.
  static const _magic = 0x4C4D5001;

  /// The pins as bytes: a header (magic, count), the owners once each, then
  /// per pin its id, owner (index), latitude and longitude (64-bit),
  /// colour, privacy and source (a byte each) and opening time (ms since
  /// the epoch, 0 for none). About 55 bytes a pin; read without parsing
  /// text (5,000 pins in a few milliseconds).
  static Uint8List encode(Iterable<StoredPin> pins) {
    final list = [
      for (final p in pins)
        if (p.capsule.location != null) p,
    ];
    final owners = <String, int>{};
    for (final p in list) {
      owners.putIfAbsent(p.capsule.ownerId, () => owners.length);
    }
    final out = BytesBuilder(copy: false);
    final head = ByteData(8)
      ..setUint32(0, _magic)
      ..setUint32(4, list.length);
    out.add(head.buffer.asUint8List());
    void text(String value) {
      final bytes = utf8.encode(value);
      out
        ..add((ByteData(2)..setUint16(0, bytes.length)).buffer.asUint8List())
        ..add(bytes);
    }

    out.add((ByteData(4)..setUint32(0, owners.length)).buffer.asUint8List());
    owners.keys.forEach(text);
    for (final p in list) {
      final c = p.capsule;
      text(c.id);
      final at = c.location!;
      final body = ByteData(31)
        ..setUint32(0, owners[c.ownerId]!)
        ..setFloat64(4, at.latitude)
        ..setFloat64(12, at.longitude)
        ..setUint8(20, c.color.index)
        ..setUint8(21, c.privacy.index)
        ..setUint8(22, p.source.index)
        ..setInt64(23, c.openAt?.millisecondsSinceEpoch ?? 0);
      out.add(body.buffer.asUint8List());
    }
    return out.takeBytes();
  }

  /// [encode]'s pins back, as capsules with only those fields (a
  /// co-authored one lists [uid] as its co-author); empty when the bytes are
  /// not a store of this version (never half of one).
  static List<StoredPin> decode(Uint8List bytes, {required String uid}) {
    final data = ByteData.sublistView(bytes);
    var at = 0;
    String text() {
      final length = data.getUint16(at);
      final value = utf8.decode(
        Uint8List.sublistView(bytes, at + 2, at + 2 + length),
      );
      at += 2 + length;
      return value;
    }

    try {
      if (bytes.length < 12 || data.getUint32(0) != _magic) return const [];
      final count = data.getUint32(4);
      final ownerCount = data.getUint32(8);
      at = 12;
      final owners = [for (var i = 0; i < ownerCount; i++) text()];
      final pins = <StoredPin>[];
      for (var i = 0; i < count; i++) {
        final id = text();
        final source = PinSource.values[data.getUint8(at + 22)];
        final openAt = data.getInt64(at + 23);
        pins.add(
          StoredPin(
            Capsule(
              id: id,
              ownerId: owners[data.getUint32(at)],
              title: '',
              location: GeoPosition(
                data.getFloat64(at + 4),
                data.getFloat64(at + 12),
              ),
              color: CapsuleColor.values[data.getUint8(at + 20)],
              privacy: CapsulePrivacy.values[data.getUint8(at + 21)],
              openAt: openAt == 0
                  ? null
                  : DateTime.fromMillisecondsSinceEpoch(openAt),
              coAuthors: source == PinSource.co ? [uid] : const [],
            ),
            source,
          ),
        );
        at += 31;
      }
      return pins;
    } on Object {
      // Cut short or from another version: as if there were none.
      return const [];
    }
  }
}
