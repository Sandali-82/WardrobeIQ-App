/// Mirrors the backend's WornLogResponse DTO.
class WornLog {
  final String id;
  final String outfitId;
  final String outfitName;
  final DateTime dateWorn;

  WornLog({
    required this.id,
    required this.outfitId,
    required this.outfitName,
    required this.dateWorn,
  });

  factory WornLog.fromJson(Map<String, dynamic> json) {
    return WornLog(
      id: json['id'],
      outfitId: json['outfitId'],
      outfitName: json['outfitName'],
      // Backend returns UTC ("...Z"); convert to local before use so the
      // calendar's date-key comparisons (year/month/day) line up with the
      // locally-selected day instead of being off by a day near midnight.
      dateWorn: DateTime.parse(json['dateWorn']).toLocal(),
    );
  }
}