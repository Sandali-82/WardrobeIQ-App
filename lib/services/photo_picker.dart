import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

enum PhotoSource { camera, gallery }

class PickedPhoto {
  final Uint8List bytes;
  final String mimeType;

  /// The file path of the picked image. Only needed by code that has to hand
  /// a real file to another API (for example the Cloudinary upload).
  final String path;

  const PickedPhoto({
    required this.bytes,
    required this.mimeType,
    this.path = '',
  });
}

abstract class PhotoPicker {
  static PhotoPicker instance = _PhotoPickerImpl();

  /// Returns null when the user cancels. Pass `maxWidth: null` to keep the
  /// original image size.
  Future<PickedPhoto?> pick(
    PhotoSource source, {
    int? maxWidth = 1024,
    int imageQuality = 85,
  });
}

class _PhotoPickerImpl implements PhotoPicker {
  final _picker = ImagePicker();

  @override
  Future<PickedPhoto?> pick(
    PhotoSource source, {
    int? maxWidth = 1024,
    int imageQuality = 85,
  }) async {
    final picked = await _picker.pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: maxWidth?.toDouble(), // downscale before encoding - keeps requests small
      imageQuality: imageQuality,
    );
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    final mimeType = picked.path.toLowerCase().endsWith('.png')
        ? 'image/png'
        : 'image/jpeg';
    return PickedPhoto(bytes: bytes, mimeType: mimeType, path: picked.path);
  }
}