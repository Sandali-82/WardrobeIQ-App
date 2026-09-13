/// Mirrors the backend's ClothingItemResponse DTO. Keeping this as a
/// dedicated model (instead of passing raw Maps around) means every screen
/// gets compile-time safety and one place to update if the backend shape
/// changes.
class ClothingItem {
  final String id;
  final String name;
  final String imageUrl;
  final String category;
  final String color;
  final String season;
  final List<String> tags;

  ClothingItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.color,
    required this.season,
    required this.tags,
  });

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    return ClothingItem(
      id: json['id'],
      name: json['name'],
      imageUrl: json['imageUrl'],
      category: json['category'],
      color: json['color'],
      season: json['season'],
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}
