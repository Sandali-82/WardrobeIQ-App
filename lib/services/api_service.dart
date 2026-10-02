import '../models/clothing_item.dart';
import '../models/outfit.dart';
import '../models/worn_log.dart';
import 'http_api_service.dart';

// Record typedefs keep the interface readable. Records are structurally
// typed, so these are interchangeable with the inline record types the
// screens were already using.
typedef UserInfo = ({String? name, String? email});
typedef ShapeResult = ({String shape, String explanation});
typedef UndertoneResult = ({String undertone, String explanation});
typedef SuggestionResult = ({List<String> itemIds, String explanation});
typedef ProfileUpdateResult = ({String name, String email});
typedef StylingGuide = ({
  String necklines,
  String hairstyles,
  String sleeves,
  String silhouettes,
  String colors,
  String avoid,
});

/// The contract every screen depends on. Screens call
/// `ApiService.instance.someMethod()`; production uses [HttpApiService],
/// while tests swap in a mock: `ApiService.instance = MockApiService();`
abstract class ApiService {
  static ApiService instance = HttpApiService();

  // ---------- Auth ----------
  Future<Map<String, dynamic>> register(String name, String email, String password);
  Future<Map<String, dynamic>> login(String email, String password);
  Future<void> saveSessionFromDeepLink({
    required String token,
    required String name,
    required String email,
  });
  Future<bool> isLoggedIn();
  Future<void> clearToken();
  Future<UserInfo> getSavedUserInfo();

  // ---------- Clothing items ----------
  Future<List<ClothingItem>> getClothingItems();
  Future<void> addClothingItem({
    required String name,
    required String imageUrl,
    required String category,
    required String color,
    required String season,
    List<String> tags = const [],
  });
  Future<void> deleteClothingItem(String id);

  // ---------- Outfits ----------
  Future<List<Outfit>> getOutfits();
  Future<void> createOutfit({required String name, required List<String> itemIds});
  Future<void> deleteOutfit(String id);

  // ---------- Worn logs (calendar) ----------
  Future<List<WornLog>> getWornLogs({required DateTime from, required DateTime to});
  Future<void> logWornOutfit({required String outfitId, required DateTime dateWorn});
  Future<void> deleteWornLog(String id);

  // ---------- AI suggestions ----------
  Future<List<String>> getOccasionTypes();
  Future<SuggestionResult> getSuggestion({required String occasion, String? notes});

  // ---------- Profile ----------
  Future<ShapeResult> calculateFaceShape({
    required double foreheadWidth,
    required double cheekboneWidth,
    required double jawlineWidth,
    required double faceLength,
  });
  Future<ShapeResult> calculateBodyShape({
    required double shoulderWidth,
    required double bustWidth,
    required double waistWidth,
    required double hipWidth,
  });
  Future<String?> getSavedFaceShape();
  Future<String?> getSavedBodyShape();
  Future<UndertoneResult> analyzeUndertone({
    required String imageBase64,
    required String mimeType,
  });
  Future<String?> getSavedUndertone();
  Future<StylingGuide> getStylingGuide();
  Future<ProfileUpdateResult> updateProfile({String? name, String? email});
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}