import '../models/outfit.dart';
import '../services/api_service.dart';

abstract class OutfitRepository {
  static OutfitRepository instance = _OutfitRepositoryImpl();

  Future<List<Outfit>> getAll();
  Future<void> create({required String name, required List<String> itemIds});
  Future<void> delete(String id);
}

class _OutfitRepositoryImpl implements OutfitRepository {
  ApiService get _api => ApiService.instance;

  @override
  Future<List<Outfit>> getAll() => _api.getOutfits();

  @override
  Future<void> create({required String name, required List<String> itemIds}) =>
      _api.createOutfit(name: name, itemIds: itemIds);

  @override
  Future<void> delete(String id) => _api.deleteOutfit(id);
}