import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../data/services/gallery_service.dart';
import '../../../shared/widgets/options/options_section.dart';
import '../device_settings_store.dart';
import '../widgets/settings_scaffold.dart';

/// Map look, the camera the capsule camera starts with, photo size, the
/// gallery copy and distance units: how this phone behaves.
class DeviceSettingsPage extends StatelessWidget {
  const DeviceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DeviceSettingsStore>();
    final l10n = context.l10n;
    return SettingsScaffold(
      title: l10n.settingsMapAndCamera,
      description: l10n.settingsDeviceDescription,
      children: [
        OptionsSection(
          title: l10n.settingsSectionMap,
          children: [
            for (final look in MapLook.values)
              SettingsChoiceRow(
                title: look.label,
                selected: store.mapLook == look,
                withDivider: look != MapLook.values.last,
                onTap: () => store.setMapLook(look),
              ),
          ],
        ),
        OptionsSection(
          title: l10n.settingsSectionCamera,
          footer: l10n.settingsCameraFooter,
          children: [
            for (final camera in StartCamera.values)
              SettingsChoiceRow(
                title: camera.label,
                selected: store.startCamera == camera,
                withDivider: camera != StartCamera.values.last,
                onTap: () => store.setStartCamera(camera),
              ),
          ],
        ),
        OptionsSection(
          title: l10n.settingsSectionPhotos,
          children: [
            for (final quality in PhotoQuality.values)
              SettingsChoiceRow(
                title: quality.label,
                selected: store.photoQuality == quality,
                withDivider:
                    quality != PhotoQuality.values.last ||
                    GalleryService.isSupported,
                onTap: () => store.setPhotoQuality(quality),
              ),
            if (GalleryService.isSupported)
              OptionsSwitchRow(
                title: l10n.settingsSaveToGallery,
                subtitle: l10n.settingsSaveToGalleryHint,
                value: store.saveToGallery,
                withDivider: false,
                onChanged: store.setSaveToGallery,
              ),
          ],
        ),
        OptionsSection(
          title: l10n.settingsSectionDistances,
          children: [
            for (final unit in DistanceUnit.values)
              SettingsChoiceRow(
                title: unit.label,
                selected: store.distanceUnit == unit,
                withDivider: unit != DistanceUnit.values.last,
                onTap: () => store.setDistanceUnit(unit),
              ),
          ],
        ),
      ],
    );
  }
}
