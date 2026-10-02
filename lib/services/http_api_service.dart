import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/clothing_item.dart';
import '../models/outfit.dart';
import '../models/worn_log.dart';
import 'api_service.dart';

/// Real implementation of [ApiService] that talks to the backend over HTTP.
/// The HTTP client is created through [clientFactory], so tests can inject
/// a `MockClient` and exercise all the parsing / error-handling logic here
/// without any network.
class HttpApiService implements ApiService {
  HttpApiService({http.Client Function()? clientFactory})
      : _clientFactory = clientFactory ?? (() => http.Client());

  static const String baseUrl = 'https://wardrobeiq-api.onrender.com';

  final http.Client Function() _clientFactory;

  // ---------- Local session storage ----------

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Cached locally alongside the token so screens (e.g. Settings) can
  // pre-fill fields without an extra round trip.
  Future<void> _saveUserInfo(String name, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    await prefs.setString('userEmail', email);
  }

  @override
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
  }

  @override
  Future<UserInfo> getSavedUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return (name: prefs.getString('userName'), email: prefs.getString('userEmail'));
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await _getToken();
    return token != null;
  }

  // Called by DeepLinkService once the confirm-email browser page hands off
  // to the app via wardrobeiq://login-success?token=...&name=...&email=...
  @override
  Future<void> saveSessionFromDeepLink({
    required String token,
    required String name,
    required String email,
  }) async {
    await _saveToken(token);
    await _saveUserInfo(name, email);
  }

  // ---------- Request plumbing ----------

  Future<Map<String, String>> _authHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Creates a client per request and always closes it afterwards.
  Future<http.Response> _send(
      Future<http.Response> Function(http.Client client) request) async {
    final client = _clientFactory();
    try {
      return await request(client);
    } finally {
      client.close();
    }
  }

  Future<T> _runSafely<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on TimeoutException {
      throw Exception('The server took too long to respond. Please try again.');
    } on SocketException {
      throw Exception('Couldn\'t connect to the server. Check your connection and try again.');
    } on HttpException {
      throw Exception('Couldn\'t connect to the server. Check your connection and try again.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Something went wrong. Please try again.');
    }
  }

  dynamic _handleResponse(http.Response response) {
    dynamic data;
    try {
      data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (_) {
      throw Exception('Something went wrong. Please try again.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      final message = data is Map ? (data['message'] ?? 'Request failed') : 'Request failed';
      throw Exception(message);
    }
  }

  Future<dynamic> _get(String path) => _runSafely(() async {
        final headers = await _authHeaders();
        final response = await _send((c) => c.get(Uri.parse('$baseUrl$path'), headers: headers));
        return _handleResponse(response);
      });

  Future<dynamic> _post(String path, Map<String, dynamic> body) => _runSafely(() async {
        final headers = await _authHeaders();
        final response = await _send(
            (c) => c.post(Uri.parse('$baseUrl$path'), headers: headers, body: jsonEncode(body)));
        return _handleResponse(response);
      });

  Future<dynamic> _patch(String path, Map<String, dynamic> body) => _runSafely(() async {
        final headers = await _authHeaders();
        final response = await _send(
            (c) => c.patch(Uri.parse('$baseUrl$path'), headers: headers, body: jsonEncode(body)));
        return _handleResponse(response);
      });

  Future<dynamic> _put(String path, Map<String, dynamic> body) => _runSafely(() async {
        final headers = await _authHeaders();
        final response = await _send(
            (c) => c.put(Uri.parse('$baseUrl$path'), headers: headers, body: jsonEncode(body)));
        return _handleResponse(response);
      });

  Future<dynamic> _delete(String path) => _runSafely(() async {
        final headers = await _authHeaders();
        final response = await _send((c) => c.delete(Uri.parse('$baseUrl$path'), headers: headers));
        return _handleResponse(response);
      });

  // ---------- Auth ----------

  @override
  Future<Map<String, dynamic>> register(String name, String email, String password) {
    return _runSafely(() async {
      final response = await _send((c) => c.post(
            Uri.parse('$baseUrl/api/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'name': name, 'email': email, 'password': password}),
          ));
      // Register returns no token - the account exists but is unconfirmed,
      // so there's no session to save yet.
      return _handleResponse(response) as Map<String, dynamic>;
    });
  }

  @override
  Future<Map<String, dynamic>> login(String email, String password) {
    return _runSafely(() async {
      final response = await _send((c) => c.post(
            Uri.parse('$baseUrl/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          ));
      final data = _handleResponse(response);
      await _saveToken(data['token']);
      await _saveUserInfo(data['name'], data['email']);
      return data as Map<String, dynamic>;
    });
  }

  // ---------- Clothing items ----------

  @override
  Future<List<ClothingItem>> getClothingItems() async {
    final data = await _get('/api/clothingitem');
    return (data as List).map((json) => ClothingItem.fromJson(json)).toList();
  }

  @override
  Future<void> addClothingItem({
    required String name,
    required String imageUrl,
    required String category,
    required String color,
    required String season,
    List<String> tags = const [],
  }) async {
    await _post('/api/clothingitem', {
      'name': name,
      'imageUrl': imageUrl,
      'category': category,
      'color': color,
      'season': season,
      'tags': tags,
    });
  }

  @override
  Future<void> deleteClothingItem(String id) async {
    await _delete('/api/clothingitem/$id');
  }

  // ---------- Outfits ----------

  @override
  Future<List<Outfit>> getOutfits() async {
    final data = await _get('/api/outfit');
    return (data as List).map((json) => Outfit.fromJson(json)).toList();
  }

  @override
  Future<void> createOutfit({required String name, required List<String> itemIds}) async {
    await _post('/api/outfit', {'name': name, 'itemIds': itemIds});
  }

  @override
  Future<void> deleteOutfit(String id) async {
    await _delete('/api/outfit/$id');
  }

  // ---------- Worn logs (calendar) ----------

  String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Future<List<WornLog>> getWornLogs({required DateTime from, required DateTime to}) async {
    final data = await _get('/api/wornlog?from=${_dateOnly(from)}&to=${_dateOnly(to)}');
    return (data as List).map((json) => WornLog.fromJson(json)).toList();
  }

  @override
  Future<void> logWornOutfit({required String outfitId, required DateTime dateWorn}) async {
    await _post('/api/wornlog', {'outfitId': outfitId, 'dateWorn': _dateOnly(dateWorn)});
  }

  @override
  Future<void> deleteWornLog(String id) async {
    await _delete('/api/wornlog/$id');
  }

  // ---------- AI suggestions ----------

  @override
  Future<List<String>> getOccasionTypes() async {
    final data = await _get('/api/suggestion/occasion-types');
    return List<String>.from(data);
  }

  @override
  Future<SuggestionResult> getSuggestion({required String occasion, String? notes}) async {
    final data = await _post('/api/suggestion/occasion', {
      'occasion': occasion,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return (
      itemIds: List<String>.from(data['suggestedItemIds']),
      explanation: data['explanation'] as String,
    );
  }

  // ---------- Profile: face shape / body shape ----------

  @override
  Future<ShapeResult> calculateFaceShape({
    required double foreheadWidth,
    required double cheekboneWidth,
    required double jawlineWidth,
    required double faceLength,
  }) async {
    final data = await _post('/api/profile/face-shape', {
      'foreheadWidth': foreheadWidth,
      'cheekboneWidth': cheekboneWidth,
      'jawlineWidth': jawlineWidth,
      'faceLength': faceLength,
    });
    return (shape: data['faceShape'] as String, explanation: data['explanation'] as String);
  }

  @override
  Future<ShapeResult> calculateBodyShape({
    required double shoulderWidth,
    required double bustWidth,
    required double waistWidth,
    required double hipWidth,
  }) async {
    final data = await _post('/api/profile/body-shape', {
      'shoulderWidth': shoulderWidth,
      'bustWidth': bustWidth,
      'waistWidth': waistWidth,
      'hipWidth': hipWidth,
    });
    return (shape: data['bodyShape'] as String, explanation: data['explanation'] as String);
  }

  @override
  Future<String?> getSavedFaceShape() async {
    try {
      final data = await _get('/api/profile/face-shape');
      return data['faceShape'] as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> getSavedBodyShape() async {
    try {
      final data = await _get('/api/profile/body-shape');
      return data['bodyShape'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ---------- Skin undertone ----------

  @override
  Future<UndertoneResult> analyzeUndertone({
    required String imageBase64,
    required String mimeType,
  }) async {
    final data = await _post('/api/profile/undertone', {
      'imageBase64': imageBase64,
      'mimeType': mimeType,
    });
    return (undertone: data['undertone'] as String, explanation: data['explanation'] as String);
  }

  @override
  Future<String?> getSavedUndertone() async {
    try {
      final data = await _get('/api/profile/undertone');
      return data['skinUndertone'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ---------- Styling guide ----------

  @override
  Future<StylingGuide> getStylingGuide() async {
    final data = await _get('/api/profile/styling-guide');
    return (
      necklines: data['necklines'] as String,
      hairstyles: data['hairstyles'] as String,
      sleeves: data['sleeves'] as String,
      silhouettes: data['silhouettes'] as String,
      colors: data['colors'] as String,
      avoid: data['avoid'] as String,
    );
  }

  // ---------- Settings (name/email + password) ----------

  @override
  Future<ProfileUpdateResult> updateProfile({String? name, String? email}) async {
    final body = <String, dynamic>{};
    if (name != null && name.isNotEmpty) body['name'] = name;
    if (email != null && email.isNotEmpty) body['email'] = email;

    final data = await _patch('/api/auth/profile', body);
    await _saveUserInfo(data['name'], data['email']);
    return (name: data['name'] as String, email: data['email'] as String);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _put('/api/auth/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}