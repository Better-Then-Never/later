import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/logging/app_logger.dart';

/// The app's version and the phone it runs on, for the About page and
/// support messages; opening links and emails.
class AppInfo {
  const AppInfo({required this.version, required this.build});

  final String version;
  final String build;

  /// "0.0.31 (31)".
  String get label => build.isEmpty ? version : '$version ($build)';

  static Future<AppInfo>? _loaded;

  /// Read once per app run.
  static Future<AppInfo> load() => _loaded ??= _load();

  static Future<AppInfo> _load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return AppInfo(version: info.version, build: info.buildNumber);
    } catch (e) {
      AppLogger.warning('Could not read the app version', error: e);
      return const AppInfo(version: 'unknown', build: '');
    }
  }

  /// What support needs to look into a problem. No email, no tokens.
  String supportText({String? uid}) => [
    'App: Later $label',
    'Phone: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
    if (uid != null) 'User id: $uid',
  ].join('\n');

  /// Opens [url] in the browser; false when nothing could open it.
  static Future<bool> openUrl(String url) =>
      _launch(Uri.parse(url), LaunchMode.externalApplication);

  /// Opens the email app with a new message; false when there is none.
  static Future<bool> openEmail(
    String to, {
    required String subject,
    String body = '',
  }) => _launch(
    Uri(
      scheme: 'mailto',
      path: to,
      // Uri's queryParameters encode spaces as "+", which mail apps show.
      query:
          'subject=${Uri.encodeComponent(subject)}'
          '&body=${Uri.encodeComponent(body)}',
    ),
    LaunchMode.externalApplication,
  );

  static Future<bool> _launch(Uri uri, LaunchMode mode) async {
    try {
      return await launchUrl(uri, mode: mode);
    } catch (e) {
      AppLogger.warning('Could not open $uri', error: e);
      return false;
    }
  }
}
