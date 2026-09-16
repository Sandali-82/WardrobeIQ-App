import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/clothing_item.dart';
import '../models/outfit.dart';
import '../models/worn_log.dart';

/// Central place for all backend calls. Every screen talks to the backend
/// through this class instead of calling http directly, so the base URL,
/// auth header, and error handling live in one place.
class ApiService {
  static const String baseUrl = 'https://10.94.245.102:7161';

  static http.Client _createClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    return IOClient(httpClient);
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ---------- Auth ----------

  static Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    final client = _createClient();
    final response = await client.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      await _saveToken(data['token']);
      return data;
    } else {
      throw Exception(data['message'] ?? 'Registration failed');
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final client = _createClient();
    final response = await client.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      await _saveToken(data['token']);
      return data;
    } else {
      throw Exception(data['message'] ?? 'Login failed');
    }
  }

  static Future<bool> isLoggedIn() async {
    final token = await _getToken();
    return token != null;
  }

  // ---------- Generic authenticated request helpers ----------

  static Future<dynamic> getAuthed(String path) async {
    final client = _createClient();
    final response = await client.get(
      Uri.parse('$baseUrl$path'),
      headers: await _authHeaders(),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> postAuthed(String path, Map<String, dynamic> body) async {
    final client = _createClient();
    final response = await client.post(
      Uri.parse('$baseUrl$path'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> deleteAuthed(String path) async {
    final client = _createClient();
    final response = await client.delete(
      Uri.parse('$baseUrl$path'),
      headers: await _authHeaders(),
    );
    return _handleResponse(response);
  }

  static dynamic _handleResponse(http.Response response) {
    final data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      final message = data is Map ? (data['message'] ?? 'Request failed') : 'Request failed';
      throw Exception(message);
    }
  }

  // ---------- Clothing items ----------

  static Future<List<ClothingItem>> getClothingItems() async {
    final data = await getAuthed('/api/clothingitem');
    return (data as List).map((json) => ClothingItem.fromJson(json)).toList();
  }

  static Future<void> addClothingItem({
    required String name,
    required String imageUrl,
    required String category,
    required String color,
    required String season,
    List<String> tags = const [],
  }) async {
    await postAuthed('/api/clothingitem', {
      'name': name,
      'imageUrl': imageUrl,
      'category': category,
      'color': color,
      'season': season,
      'tags': tags,
    });
  }

  static Future<void> deleteClothingItem(String id) async {
    await deleteAuthed('/api/clothingitem/$id');
  }

  // ---------- Outfits ----------

  static Future<List<Outfit>> getOutfits() async {
    final data = await getAuthed('/api/outfit');
    return (data as List).map((json) => Outfit.fromJson(json)).toList();
  }

  static Future<void> createOutfit({
    required String name,
    required List<String> itemIds,
  }) async {
    await postAuthed('/api/outfit', {
      'name': name,
      'itemIds': itemIds,
    });
  }

  static Future<void> deleteOutfit(String id) async {
    await deleteAuthed('/api/outfit/$id');
  }

  // ---------- Worn logs (calendar) ----------

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<List<WornLog>> getWornLogs({required DateTime from, required DateTime to}) async {
    final data = await getAuthed('/api/wornlog?from=${_dateOnly(from)}&to=${_dateOnly(to)}');
    return (data as List).map((json) => WornLog.fromJson(json)).toList();
  }

  static Future<void> logWornOutfit({required String outfitId, required DateTime dateWorn}) async {
    await postAuthed('/api/wornlog', {
      'outfitId': outfitId,
      'dateWorn': _dateOnly(dateWorn),
    });
  }

  static Future<void> deleteWornLog(String id) async {
    await deleteAuthed('/api/wornlog/$id');
  }

  // ---------- AI Suggestions ----------

  static Future<List<String>> getOccasionTypes() async {
    final data = await getAuthed('/api/suggestion/occasion-types');
    return List<String>.from(data);
  }

  static Future<({List<String> itemIds, String explanation})> getSuggestion({
    required String occasion,
    String? notes,
  }) async {
    final data = await postAuthed('/api/suggestion/occasion', {
      'occasion': occasion,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return (
      itemIds: List<String>.from(data['suggestedItemIds']),
      explanation: data['explanation'] as String,
    );
  }

  // ---------- Profile: face shape / body shape ----------

  static Future<({String shape, String explanation})> calculateFaceShape({
    required double foreheadWidth,
    required double cheekboneWidth,
    required double jawlineWidth,
    required double faceLength,
  }) async {
    final data = await postAuthed('/api/profile/face-shape', {
      'foreheadWidth': foreheadWidth,
      'cheekboneWidth': cheekboneWidth,
      'jawlineWidth': jawlineWidth,
      'faceLength': faceLength,
    });
    return (shape: data['faceShape'] as String, explanation: data['explanation'] as String);
  }

  static Future<({String shape, String explanation})> calculateBodyShape({
    required double shoulderWidth,
    required double bustWidth,
    required double waistWidth,
    required double hipWidth,
  }) async {
    final data = await postAuthed('/api/profile/body-shape', {
      'shoulderWidth': shoulderWidth,
      'bustWidth': bustWidth,
      'waistWidth': waistWidth,
      'hipWidth': hipWidth,
    });
    return (shape: data['bodyShape'] as String, explanation: data['explanation'] as String);
  }

  static Future<String?> getSavedFaceShape() async {
    try {
      final data = await getAuthed('/api/profile/face-shape');
      return data['faceShape'] as String?;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getSavedBodyShape() async {
    try {
      final data = await getAuthed('/api/profile/body-shape');
      return data['bodyShape'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ---------- Styling guide ----------

  static Future<({
    String necklines,
    String hairstyles,
    String sleeves,
    String silhouettes,
    String colors,
    String avoid,
  })> getStylingGuide() async {
    final data = await getAuthed('/api/profile/styling-guide');
    return (
      necklines: data['necklines'] as String,
      hairstyles: data['hairstyles'] as String,
      sleeves: data['sleeves'] as String,
      silhouettes: data['silhouettes'] as String,
      colors: data['colors'] as String,
      avoid: data['avoid'] as String,
    );
  }
}
