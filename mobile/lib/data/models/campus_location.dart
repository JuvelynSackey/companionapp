/// Matches GET /api/locations exactly — the backend has no percentage-based
/// map coordinates (the old app's mapX/mapY), only real latitude/longitude.
/// That's a prerequisite gap for the custom-drawn campus map (Phase 2
/// roadmap item), not something to paper over with a fake field here.
class CampusLocation {
  CampusLocation({
    required this.locationId,
    required this.name,
    required this.category,
    required this.description,
    required this.latitude,
    required this.longitude,
  });

  factory CampusLocation.fromJson(Map<String, dynamic> json) => CampusLocation(
        locationId: json['locationId'] as int,
        name: json['name'] as String,
        category: json['category'] as String,
        description: json['description'] as String? ?? '',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );

  final int locationId;
  final String name;
  final String category;
  final String description;
  final double latitude;
  final double longitude;
}
