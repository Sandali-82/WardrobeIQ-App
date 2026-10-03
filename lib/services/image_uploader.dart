import 'dart:io';
import 'cloudinary_service.dart';
import 'photo_picker.dart';

abstract class ImageUploader {
  static ImageUploader instance = _CloudinaryImageUploader();

  /// Uploads the photo and returns its hosted URL.
  Future<String> upload(PickedPhoto photo);
}

class _CloudinaryImageUploader implements ImageUploader {
  @override
  Future<String> upload(PickedPhoto photo) =>
      CloudinaryService.uploadImage(File(photo.path));
}