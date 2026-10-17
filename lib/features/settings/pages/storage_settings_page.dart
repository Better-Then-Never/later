import 'package:flutter/material.dart';

import '../../../data/services/cache_service.dart';
import '../../../shared/widgets/default_text.dart';
import '../../../shared/widgets/options/options_section.dart';
import '../../../shared/widgets/options/options_settings_row.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../widgets/settings_scaffold.dart';

/// How much space the cache takes, and a way to free it.
class StorageSettingsPage extends StatefulWidget {
  const StorageSettingsPage({super.key, this.cache});

  /// For tests; the device's cache otherwise.
  final CacheService? cache;

  @override
  State<StorageSettingsPage> createState() => _StorageSettingsPageState();
}

class _StorageSettingsPageState extends State<StorageSettingsPage> {
  late final CacheService _cache = widget.cache ?? CacheService();
  int? _size;
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    _measure();
  }

  Future<void> _measure() async {
    final size = await _cache.size();
    if (mounted) setState(() => _size = size);
  }

  void _confirmClear() {
    if (_clearing) return;
    ConfirmDialog.show(
      context: context,
      title: 'Clear the cache? Pictures load again when you need them.',
      confirmText: 'Clear',
      onConfirm: _clear,
    );
  }

  Future<void> _clear() async {
    setState(() => _clearing = true);
    await _cache.clear();
    await _measure();
    if (!mounted) return;
    setState(() => _clearing = false);
    PopupNotificationService.showSuccess(
      context: context,
      message: 'Cache cleared',
      position: NotificationPosition.bottom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = _size;
    return SettingsScaffold(
      title: 'Data and storage',
      description: 'Space Later uses on this phone',
      children: [
        OptionsSection(
          footer:
              'Photos taken or picked for capsules and pictures loaded '
              'from the internet. Your capsules, chats and account stay.',
          children: [
            OptionsSettingsRow(
              title: 'Cache',
              trailing: DefaultText(
                size == null ? '...' : CacheService.format(size),
              ),
              withDivider: false,
            ),
          ],
        ),
        OptionsSection(
          children: [
            OptionsSettingsRow(
              title: _clearing ? 'Clearing...' : 'Clear cache',
              withDivider: false,
              onTap: _confirmClear,
            ),
          ],
        ),
      ],
    );
  }
}
