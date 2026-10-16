import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../repositories/repositories.dart';
import '../services/image_processor.dart';

/// Profile and background pictures under `userdata/{uid}/assets/images/`.
class FirebaseImageStorageRepository implements ImageStorageRepository {
  FirebaseImageStorageRepository({
    FirebaseStorage? storage,
    ImageProcessor processor = const ImageProcessor(),
  }) : _storage = storage ?? FirebaseStorage.instance,
       _processor = processor;

  final FirebaseStorage _storage;
  final ImageProcessor _processor;

  static final _jpeg = SettableMetadata(contentType: 'image/jpeg');

  Reference _ref(String uid, String name) =>
      _storage.ref('userdata/$uid/assets/images/$name');

  static const _profile = 'profile_image';
  static const _profileSmall = 'profile_image_small';
  static const _background = 'background_image';

  Future<String?> _url(Reference ref) async {
    try {
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return null;
      rethrow;
    }
  }

  @override
  Future<String?> imageUrl(
    String uid,
    ProfileImageKind kind, {
    bool small = false,
  }) async {
    switch (kind) {
      case ProfileImageKind.background:
        return _url(_ref(uid, _background));
      case ProfileImageKind.profile:
        if (small) {
          final url = await _url(_ref(uid, _profileSmall));
          if (url != null) return url;
        }
        return _url(_ref(uid, _profile));
    }
  }

  @override
  Future<void> uploadProfileImage(String uid, Uint8List bytes) async {
    final full = await _processor.squareJpeg(bytes, size: 1024);
    final small = await _processor.squareJpeg(bytes, size: 256);
    await _ref(uid, _profile).putData(full, _jpeg);
    await _ref(uid, _profileSmall).putData(small, _jpeg);
  }

  @override
  Future<void> uploadBackgroundImage(String uid, Uint8List bytes) async {
    final data = await _processor.backgroundJpeg(bytes);
    await _ref(uid, _background).putData(data, _jpeg);
  }

  Future<void> _deleteIfExists(Reference ref) async {
    try {
      await ref.delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }

  @override
  Future<void> deleteImage(String uid, ProfileImageKind kind) async {
    switch (kind) {
      case ProfileImageKind.background:
        await _deleteIfExists(_ref(uid, _background));
      case ProfileImageKind.profile:
        await _deleteIfExists(_ref(uid, _profile));
        await _deleteIfExists(_ref(uid, _profileSmall));
    }
  }
}
