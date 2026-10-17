import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/logging/app_logger.dart';
import '../../data/models/chat.dart';
import '../../data/services/voice_service.dart';

/// Plays the voice messages of one open chat, one at a time: starting
/// another stops the first; leaving the chat stops it.
class VoicePlayer extends ChangeNotifier {
  VoicePlayer(this._voice) {
    _done = _voice.completed.listen((_) => _finish());
  }

  final VoiceService _voice;
  StreamSubscription<void>? _done;
  Timer? _tick;

  String? _id;
  bool _playing = false;
  bool _loading = false;
  int _position = 0;
  int _duration = 0;
  bool _disposed = false;

  bool isPlaying(String id) => _id == id && _playing;
  bool isLoading(String id) => _id == id && _loading;
  int positionOf(String id) => _id == id ? _position : 0;

  /// 0-1 through message [id].
  double progressOf(String id) =>
      _id == id && _duration > 0 ? (_position / _duration).clamp(0.0, 1.0) : 0;

  /// Plays [message] (downloading it once), or pauses / resumes it when it
  /// is the one playing. False when it cannot be played.
  Future<bool> toggle(ChatMessage message) async {
    if (_id == message.id && !_loading) {
      try {
        if (_playing) {
          await _voice.pause();
          _playing = false;
          _tick?.cancel();
        } else {
          await _voice.resume();
          _playing = true;
          _startTick();
        }
        _notify();
        return true;
      } catch (e) {
        AppLogger.warning('Voice pause/resume failed', error: e);
        await stop();
        return false;
      }
    }
    await stop();
    final id = message.id;
    _id = id;
    _loading = true;
    _position = 0;
    _duration = message.durationMs ?? 0;
    _notify();
    try {
      final url = message.audioUrl;
      final path =
          message.localPath ?? (url == null ? null : await _voice.fileFor(url));
      if (path == null) throw StateError('no recording');
      if (_id != id) return true; // another one started meanwhile
      final length = await _voice.play(path);
      if (_id != id) return true;
      _duration = length ?? _duration;
      _loading = false;
      _playing = true;
      _startTick();
      _notify();
      return true;
    } catch (e) {
      AppLogger.warning('Voice message could not be played', error: e);
      if (_id == id) _reset();
      return false;
    }
  }

  /// Jumps to [fraction] (0-1) of message [id] when it is the one playing.
  Future<void> seek(String id, double fraction) async {
    if (_id != id || _loading || _duration <= 0) return;
    final ms = (_duration * fraction.clamp(0.0, 1.0)).round();
    _position = ms;
    _notify();
    try {
      await _voice.seek(ms);
    } catch (e) {
      AppLogger.debug('Voice seek failed: $e');
    }
  }

  Future<void> stop() async {
    if (_id == null) return;
    _reset();
    try {
      await _voice.stopPlayback();
    } catch (e) {
      AppLogger.debug('Voice stop failed: $e');
    }
  }

  void _finish() {
    if (_id == null) return;
    _reset();
  }

  void _reset() {
    _tick?.cancel();
    _id = null;
    _playing = false;
    _loading = false;
    _position = 0;
    _notify();
  }

  void _startTick() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      if (!_playing) return;
      try {
        final position = await _voice.position();
        if (!_playing) return;
        _position = position;
        _notify();
      } catch (_) {
        // The player went away between ticks.
      }
    });
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    unawaited(stop());
    _disposed = true;
    _tick?.cancel();
    unawaited(_done?.cancel());
    super.dispose();
  }
}
