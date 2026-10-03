import 'package:mocktail/mocktail.dart';
import 'package:wardrobe_app/repositories/auth_repository.dart';
import 'package:wardrobe_app/repositories/clothing_repository.dart';
import 'package:wardrobe_app/repositories/outfit_repository.dart';
import 'package:wardrobe_app/repositories/profile_repository.dart';
import 'package:wardrobe_app/repositories/suggestion_repository.dart';
import 'package:wardrobe_app/repositories/worn_log_repository.dart';
import 'mock_auth_repository.dart';
import 'mock_clothing_repository.dart';

class MockOutfitRepository extends Mock implements OutfitRepository {}

class MockWornLogRepository extends Mock implements WornLogRepository {}

class MockSuggestionRepository extends Mock implements SuggestionRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

/// Installs mocks for every repository that the five home tabs use and stubs
/// them with empty data, so [HomeScreen] can be built in a widget test.
/// Tests can re-stub individual methods afterwards.
class HomeTestHarness {
  final auth = MockAuthRepository();
  final clothing = MockClothingRepository();
  final outfits = MockOutfitRepository();
  final wornLogs = MockWornLogRepository();
  final suggestions = MockSuggestionRepository();
  final profile = MockProfileRepository();

  void install() {
    registerFallbackValue(DateTime(2026, 1, 1));

    AuthRepository.instance = auth;
    ClothingRepository.instance = clothing;
    OutfitRepository.instance = outfits;
    WornLogRepository.instance = wornLogs;
    SuggestionRepository.instance = suggestions;
    ProfileRepository.instance = profile;

    when(() => auth.isLoggedIn()).thenAnswer((_) async => true);
    when(() => auth.logout()).thenAnswer((_) async {});

    when(() => clothing.getAll()).thenAnswer((_) async => []);
    when(() => outfits.getAll()).thenAnswer((_) async => []);
    when(() => wornLogs.getRange(
            from: any(named: 'from'), to: any(named: 'to')))
        .thenAnswer((_) async => []);
    when(() => suggestions.getOccasionTypes())
        .thenAnswer((_) async => ['Casual']);
    when(() => profile.getSavedFaceShape()).thenAnswer((_) async => null);
    when(() => profile.getSavedBodyShape()).thenAnswer((_) async => null);
    when(() => profile.getSavedUndertone()).thenAnswer((_) async => null);
  }
}