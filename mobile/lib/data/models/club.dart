/// A campus club as returned by GET /api/clubs. The backend has no category,
/// leadership or detail endpoint, so this is everything a club is today.
class Club {
  const Club({
    required this.clubId,
    required this.name,
    required this.description,
    required this.memberCount,
    required this.isMember,
  });

  factory Club.fromJson(Map<String, dynamic> json) => Club(
        clubId: json['clubId'] as int,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        memberCount: json['memberCount'] as int,
        // BOOL_OR over a LEFT JOIN with no members comes back null, not false.
        isMember: json['isMember'] as bool? ?? false,
      );

  final int clubId;
  final String name;
  final String description;
  final int memberCount;
  final bool isMember;

  Club copyWith({int? memberCount, bool? isMember}) => Club(
        clubId: clubId,
        name: name,
        description: description,
        memberCount: memberCount ?? this.memberCount,
        isMember: isMember ?? this.isMember,
      );

  /// The club as it will look once the caller joins (or leaves) it. Used for
  /// the optimistic update before the server confirms.
  Club toggledMembership() => copyWith(
        isMember: !isMember,
        memberCount: isMember ? (memberCount - 1).clamp(0, memberCount) : memberCount + 1,
      );
}
