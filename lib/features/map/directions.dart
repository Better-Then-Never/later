import 'package:url_launcher/url_launcher.dart';

import '../../core/logging/app_logger.dart';
import '../../data/models/geo_position.dart';

/// Directions to a place capsule ("Go there", B4).
abstract final class Directions {
  /// Walking directions to [to] in the phone's maps app (the browser when
  /// there is none). False when nothing could open them.
  static Future<bool> open(GeoPosition to) async {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${to.latitude},${to.longitude}',
      'travelmode': 'walking',
    });
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      AppLogger.warning('Could not open directions', error: e);
      return false;
    }
  }
}
