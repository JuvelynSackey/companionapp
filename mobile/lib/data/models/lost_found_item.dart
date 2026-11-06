/// One post on the shared Lost & Found board (GET /api/lost-found).
/// [postedBy] and [contact] are null for guests: the server only sends who
/// posted an item, and how to reach them, to signed-in users.
class LostFoundItem {
  const LostFoundItem({
    required this.itemId,
    required this.kind,
    required this.title,
    this.description,
    this.location,
    required this.isReturned,
    required this.createdAt,
    this.postedBy,
    this.contact,
    required this.isMine,
    required this.canManage,
    this.possibleMatches = const [],
    this.hasPhoto = false,
  });

  factory LostFoundItem.fromJson(Map<String, dynamic> json) => LostFoundItem(
        itemId: json['itemId'] as int,
        kind: json['kind'] == 'found' ? LostFoundKind.found : LostFoundKind.lost,
        title: json['title'] as String,
        description: json['description'] as String?,
        location: json['location'] as String?,
        isReturned: json['status'] == 'returned',
        createdAt: DateTime.parse(json['createdAt'] as String),
        postedBy: json['postedBy'] as String?,
        contact: json['contact'] as String?,
        isMine: json['isMine'] as bool? ?? false,
        canManage: json['canManage'] as bool? ?? false,
        hasPhoto: json['hasPhoto'] as bool? ?? false,
        possibleMatches: [
          for (final m in (json['possibleMatches'] as List? ?? const []))
            LostFoundMatch(itemId: (m as Map<String, dynamic>)['itemId'] as int, title: m['title'] as String),
        ],
      );

  final int itemId;
  final LostFoundKind kind;
  final String title;
  final String? description;
  final String? location;
  final bool isReturned;
  final DateTime createdAt;
  final String? postedBy;
  final String? contact;

  /// The signed-in user posted it.
  final bool isMine;

  /// The signed-in user may mark it returned or remove it (its poster, or an admin).
  final bool canManage;

  /// Open posts of the other kind that may be the same item, best first.
  /// The server suggests them from shared words in the title and place.
  final List<LostFoundMatch> possibleMatches;

  /// The post has a photo, served at GET /api/lost-found/{itemId}/photo.
  final bool hasPhoto;
}

/// A post the server thinks may be the same item as another.
class LostFoundMatch {
  const LostFoundMatch({required this.itemId, required this.title});
  final int itemId;
  final String title;
}

enum LostFoundKind {
  lost('Lost', 'lost'),
  found('Found', 'found');

  const LostFoundKind(this.label, this.apiValue);
  final String label;
  final String apiValue;
}
