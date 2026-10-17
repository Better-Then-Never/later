import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../data/services/cache_service.dart';
import '../../../shared/widgets/default_text.dart';
import '../../../shared/widgets/options/options_section.dart';
import '../../../shared/widgets/options/options_settings_row.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../widgets/settings_scaffold.dart';
import '../data_export.dart';

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
      title: context.l10n.settingsStorageClearConfirm,
      confirmText: context.l10n.settingsStorageClear,
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
      message: context.l10n.settingsStorageCleared,
      position: NotificationPosition.bottom,
    );
  }

  bool _exporting = false;

  Future<void> _export() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    final failure = await DataExport.share(context);
    if (!mounted) return;
    setState(() => _exporting = false);
    if (failure != null) {
      PopupNotificationService.showError(
        context: context,
        message: failure.message,
        position: NotificationPosition.bottom,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = _size;
    final l10n = context.l10n;
    return SettingsScaffold(
      title: l10n.settingsDataAndStorage,
      description: l10n.settingsStorageDescription,
      children: [
        OptionsSection(
          footer: l10n.settingsStorageFooter,
          children: [
            OptionsSettingsRow(
              title: l10n.settingsStorageCache,
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
              title: _clearing
                  ? l10n.settingsStorageClearing
                  : l10n.settingsStorageClearCache,
              withDivider: false,
              onTap: _confirmClear,
            ),
          ],
        ),
        OptionsSection(
          footer: l10n.settingsDownloadDataHint,
          children: [
            OptionsSettingsRow(
              title: _exporting
                  ? l10n.commonLoading
                  : l10n.settingsDownloadData,
              withDivider: false,
              onTap: _export,
            ),
          ],
        ),
      ],
    );
  }
}
