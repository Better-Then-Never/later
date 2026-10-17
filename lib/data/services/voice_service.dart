import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Records and plays voice messages through the app's own channel
/// (android/app/src/main/kotlin/com/btn/later/VoiceChannel.kt): AAC files,
/// one recording and one playback at a time. Android only for now (iOS has
/// no recorder yet, see docs/feel/BLOCKERS.md).
class VoiceService {
  VoiceService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('later.app/voice') {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'completed') _completed.add(null);
    });
  }

  final MethodChannel _channel;
  final _completed = StreamController<void>.broadcast();

  /// Recordings downloaded to play, kept on disk a while.
  static final CacheManager cache = CacheManager(
    Config(
      'later_voice',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 200,
    ),
  );

  /// Whether this phone can record and play voice messages.
  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  /// The playback reached its end.
  Stream<void> get completed => _completed.stream;

  Future<void> start(String path) =>
      _channel.invokeMethod<void>('start', {'path': path});

  /// Stops recording and keeps the file: its length in milliseconds, or
  /// null when nothing was recorded.
  Future<int?> stop() => _channel.invokeMethod<int>('stop');

  /// Stops recording and deletes the file.
  Future<void> cancel() => _channel.invokeMethod<void>('cancel');

  /// Loudness since the last call, 0-32767.
  Future<int> amplitude() async =>
      await _channel.invokeMethod<int>('amplitude') ?? 0;

  /// Plays the file at [path]; its length in milliseconds once it started.
  Future<int?> play(String path) => _channel
      .invokeMethod<int>('play', {'path': path})
      .timeout(const Duration(seconds: 15));

  Future<void> pause() => _channel.invokeMethod<void>('pause');

  Future<void> resume() => _channel.invokeMethod<void>('resume');

  Future<void> seek(int ms) => _channel.invokeMethod<void>('seek', {'ms': ms});

  Future<int> position() async =>
      await _channel.invokeMethod<int>('position') ?? 0;

  Future<void> stopPlayback() => _channel.invokeMethod<void>('stopPlayback');

  /// A local copy of the recording at [url] (downloaded once).
  Future<String> fileFor(String url) async =>
      (await cache.getSingleFile(url)).path;
}
