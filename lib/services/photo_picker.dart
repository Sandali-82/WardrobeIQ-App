import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

enum PhotoSource { camera, gallery }

class PickedPhoto {
  final Uint8List bytes;
  final String mimeType;
  const PickedPhoto({required this.bytes, required this.mimeType});
}

abstract class PhotoPicker {
  static PhotoPicker instance = _PhotoPickerImpl();

  /// Returns null when the user cancels.
  Future<PickedPhoto?> pick(PhotoSource source);
}

class _PhotoPickerImpl implements PhotoPicker {
  final _picker = ImagePicker();

  @override
  Future<PickedPhoto?> pick(PhotoSource source) async {
    final picked = await _picker.pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 1024, // downscale before base64-encoding - keeps the request small
      imageQuality: 85,
    );
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    final mimeType = picked.path.toLowerCase().endsWith('.png')
        ? 'image/png'
        : 'image/jpeg';
    return PickedPhoto(bytes: bytes, mimeType: mimeType);
  }
}