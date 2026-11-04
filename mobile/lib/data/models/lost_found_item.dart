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
}

enum LostFoundKind {
  lost('Lost', 'lost'),
  found('Found', 'found');

  const LostFoundKind(this.label, this.apiValue);
  final String label;
  final String apiValue;
}
