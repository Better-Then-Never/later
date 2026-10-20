import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'map_projection.dart';

/// A camera the map reported, with the padding it is relative to (its target
/// is the middle of the padded area).
typedef MapView = ({CameraPosition camera, EdgeInsets padding});

/// What the map shows, as the native map last reported it (M-02: the
/// selected pin's overlay follows it).
///
/// Android keeps the map still when its padding changes: the camera's target
/// moves instead, and the map says so only with its next camera move, which
/// can come much later or never. So each camera is read with the padding in
/// force when the map reported it. A padding Flutter [asked] for counts from
/// the first camera after the map [confirmed] it (it handles messages in
/// order). A camera arriving before that gets whichever padding keeps the
/// map still since the last one: a padding change jumps the target by half
/// the change, far more than the map moves between two reports.
class MapViewport extends ValueNotifier<MapView?> {
  MapViewport() : super(null);

  /// Paddings asked for and not yet seen in a camera, oldest first, and
  /// whether the map has confirmed each.
  final _asked = <(EdgeInsets, bool)>[];

  /// The map starts with [camera] and [padding].
  void start(CameraPosition camera, EdgeInsets padding) {
    value ??= (camera: camera, padding: padding);
  }

  void asked(EdgeInsets padding) => _asked.add((padding, false));

  /// The map has the oldest padding asked for and not confirmed yet.
  void confirmed() {
    final i = _asked.indexWhere((a) => !a.$2);
    if (i >= 0) _asked[i] = (_asked[i].$1, true);
  }

  void moved(CameraPosition camera) {
    final last = value;
    if (last == null) return;
    final candidates = [last.padding, for (final a in _asked) a.$1];
    // Confirmed ones are in force, and those before them are gone.
    final from = _asked.lastIndexWhere((a) => a.$2) + 1;
    var best = from;
    var bestJump = double.infinity;
    for (var i = from; i < candidates.length; i++) {
      final jump = _jump(last, camera, candidates[i]);
      if (jump < bestJump) {
        best = i;
        bestJump = jump;
      }
    }
    if (best > 0) _asked.removeRange(0, best);
    value = (camera: camera, padding: candidates[best]);
  }

  /// How far the last target moved on screen if [camera] is relative to
  /// [padding] (the map's size cancels out).
  static double _jump(MapView last, CameraPosition camera, EdgeInsets padding) {
    final before = MapProjection.toScreen(
      last.camera.target,
      last.camera,
      Size.zero,
      last.padding,
    );
    final now = MapProjection.toScreen(
      last.camera.target,
      camera,
      Size.zero,
      padding,
    );
    return (now - before).distance;
  }
}
