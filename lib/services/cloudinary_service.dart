import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Uploads images directly from the device to Cloudinary using an
/// unsigned upload preset - no backend involvement, no API secret on the
/// client. Returns the hosted image's URL to save as a ClothingItem's
/// imageUrl.
class CloudinaryService {
  static const String _cloudName = 'avb2kr31';
  static const String _uploadPreset = 'wardrobe_items';

  static Future<String> uploadImage(File imageFile) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Image upload failed. Please try again.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['secure_url'] as String;
  }
}