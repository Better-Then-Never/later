import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/options/options_section.dart';
import '../device_settings_store.dart';
import '../widgets/settings_scaffold.dart';

/// Map look and the camera the capsule camera starts with.
class DeviceSettingsPage extends StatelessWidget {
  const DeviceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DeviceSettingsStore>();
    return SettingsScaffold(
      title: 'Map and camera',
      description: 'How Later looks and works on this phone',
      children: [
        OptionsSection(
          title: 'MAP',
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
          title: 'CAMERA',
          footer: 'The camera that opens when you create a capsule.',
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
      ],
    );
  }
}
