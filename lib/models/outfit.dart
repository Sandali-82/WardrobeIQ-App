/// Mirrors the backend's OutfitResponse DTO.
class Outfit {
  final String id;
  final String name;
  final List<String> itemIds;
  final DateTime createdAt;

  Outfit({
    required this.id,
    required this.name,
    required this.itemIds,
    required this.createdAt,
  });

  factory Outfit.fromJson(Map<String, dynamic> json) {
    return Outfit(
      id: json['id'],
      name: json['name'],
      itemIds: List<String>.from(json['itemIds'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}