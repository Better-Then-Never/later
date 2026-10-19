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

/// What the map keeps on this phone: its pins, and where its sync stands
/// (docs/map/COLD_START.md, "Delta sync").
class StoredMap {
  const StoredMap({
    this.pins = const [],
    this.syncedTo,
    this.friendIds = const [],
    this.bandLatitude,
  });

  static const none = StoredMap();

  final List<StoredPin> pins;

  /// The newest change among the friends' and public pins (a capsule's
  /// createdAt, a deletion's deletedAt, both server times): the sync asks
  /// for what is newer. Null: the map reads everything.
  final DateTime? syncedTo;

  /// The friends whose friends-only capsules the pins hold: a friend added
  /// since has their older ones read in full.
  final List<String> friendIds;

  /// The middle of the latitude band the public pins came from.
  final double? bandLatitude;
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
  Future<StoredMap>? _loading;
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

  /// What the map kept when [uid] last used it on this phone; nothing when
  /// it has not (a first start, another account).
  Future<StoredMap> read(String uid) => uid == _uid
      ? _loading ?? Future.value(StoredMap.none)
      : Future.value(StoredMap.none);

  /// Keeps [map] as [uid]'s (after the previous write, never two at once).
  Future<void> save(String uid, StoredMap map) {
    if (uid != _uid) return Future.value();
    final bytes = encode(map);
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

  Future<StoredMap> _read(String uid) async {
    try {
      final file = await _file(uid);
      if (!await file.exists()) return StoredMap.none;
      return decode(await file.readAsBytes(), uid: uid);
    } on Object catch (e) {
      AppLogger.warning('Map pins not read', error: e);
      return StoredMap.none;
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

  /// "LMP" and the format's version (an older one reads as nothing kept:
  /// the map then reads everything once).
  static const _magic = 0x4C4D5002;

  /// The map as bytes: a header (magic, pin count, synced-to time in ms or
  /// 0, the band's latitude or NaN, the friends), the owners once each, then
  /// per pin its id, owner (index), latitude and longitude (64-bit), colour,
  /// privacy and source (a byte each) and opening time (ms since the epoch,
  /// 0 for none). About 55 bytes a pin; read without parsing text (5,000
  /// pins in a few milliseconds).
  static Uint8List encode(StoredMap map) {
    final list = [
      for (final p in map.pins)
        if (p.capsule.location != null) p,
    ];
    final owners = <String, int>{};
    for (final p in list) {
      owners.putIfAbsent(p.capsule.ownerId, () => owners.length);
    }
    final out = BytesBuilder(copy: false);
    void bytes(ByteData data) => out.add(data.buffer.asUint8List());
    void text(String value) {
      final encoded = utf8.encode(value);
      bytes(ByteData(2)..setUint16(0, encoded.length));
      out.add(encoded);
    }

    bytes(
      ByteData(24)
        ..setUint32(0, _magic)
        ..setUint32(4, list.length)
        ..setInt64(8, map.syncedTo?.millisecondsSinceEpoch ?? 0)
        ..setFloat64(16, map.bandLatitude ?? double.nan),
    );
    bytes(ByteData(4)..setUint32(0, map.friendIds.length));
    map.friendIds.forEach(text);
    bytes(ByteData(4)..setUint32(0, owners.length));
    owners.keys.forEach(text);
    for (final p in list) {
      final c = p.capsule;
      text(c.id);
      final at = c.location!;
      bytes(
        ByteData(31)
          ..setUint32(0, owners[c.ownerId]!)
          ..setFloat64(4, at.latitude)
          ..setFloat64(12, at.longitude)
          ..setUint8(20, c.color.index)
          ..setUint8(21, c.privacy.index)
          ..setUint8(22, p.source.index)
          ..setInt64(23, c.openAt?.millisecondsSinceEpoch ?? 0),
      );
    }
    return out.takeBytes();
  }

  /// [encode]'s map back, its pins as capsules with only those fields (a
  /// co-authored one lists [uid] as its co-author); nothing kept when the
  /// bytes are not a store of this version (never half of one).
  static StoredMap decode(Uint8List bytes, {required String uid}) {
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
      if (bytes.length < 24 || data.getUint32(0) != _magic) {
        return StoredMap.none;
      }
      final count = data.getUint32(4);
      final synced = data.getInt64(8);
      final band = data.getFloat64(16);
      at = 24;
      final friends = <String>[];
      final friendCount = data.getUint32(at);
      at += 4;
      for (var i = 0; i < friendCount; i++) {
        friends.add(text());
      }
      final ownerCount = data.getUint32(at);
      at += 4;
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
      return StoredMap(
        pins: pins,
        syncedTo: synced == 0
            ? null
            : DateTime.fromMillisecondsSinceEpoch(synced),
        friendIds: friends,
        bandLatitude: band.isNaN ? null : band,
      );
    } on Object {
      // Cut short or from another version: as if nothing were kept.
      return StoredMap.none;
    }
  }
}
