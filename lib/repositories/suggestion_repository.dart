import '../services/api_service.dart';

abstract class SuggestionRepository {
  static SuggestionRepository instance = _SuggestionRepositoryImpl();

  Future<List<String>> getOccasionTypes();
  Future<SuggestionResult> getSuggestion({
    required String occasion,
    String? notes,
  });
}

class _SuggestionRepositoryImpl implements SuggestionRepository {
  ApiService get _api => ApiService.instance;

  @override
  Future<List<String>> getOccasionTypes() => _api.getOccasionTypes();

  @override
  Future<SuggestionResult> getSuggestion({
    required String occasion,
    String? notes,
  }) =>
      _api.getSuggestion(occasion: occasion, notes: notes);
}