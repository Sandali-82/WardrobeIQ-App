import '../models/clothing_item.dart';
import '../services/api_service.dart';

abstract class ClothingRepository {
  static ClothingRepository instance = _ClothingRepositoryImpl();

  Future<List<ClothingItem>> getAll();
  Future<void> add({
    required String name,
    required String imageUrl,
    required String category,
    required String color,
    required String season,
    List<String> tags = const [],
  });
  Future<void> delete(String id);
}

class _ClothingRepositoryImpl implements ClothingRepository {
  ApiService get _api => ApiService.instance;

  @override
  Future<List<ClothingItem>> getAll() => _api.getClothingItems();

  @override
  Future<void> add({
    required String name,
    required String imageUrl,
    required String category,
    required String color,
    required String season,
    List<String> tags = const [],
  }) =>
      _api.addClothingItem(
        name: name,
        imageUrl: imageUrl,
        category: category,
        color: color,
        season: season,
        tags: tags,
      );

  @override
  Future<void> delete(String id) => _api.deleteClothingItem(id);
}