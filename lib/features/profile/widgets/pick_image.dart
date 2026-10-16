import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../../../core/logging/app_logger.dart';

/// Picks a photo and returns its bytes, or null when cancelled or denied.
/// The picker already scales it down, so huge camera photos are never
/// loaded into memory in full.
Future<Uint8List?> pickImageBytes(ImageSource source) async {
  try {
    final image = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    return image?.readAsBytes();
  } catch (e) {
    AppLogger.warning('Picking an image failed', error: e);
    return null;
  }
}
