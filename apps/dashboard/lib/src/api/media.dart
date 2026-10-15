/// Uma mídia da biblioteca (na fase 6, só sites).
class Media {
  const Media({
    required this.id,
    required this.kind,
    required this.name,
    required this.createdAt,
    this.url,
  });

  factory Media.fromJson(Map<String, Object?> json) => Media(
        id: json['id']! as String,
        kind: json['kind']! as String,
        name: json['name']! as String,
        url: json['url'] as String?,
        createdAt: DateTime.parse(json['createdAt']! as String),
      );

  final String id;

  /// Um dos `MediaKinds`.
  final String kind;
  final String name;
  final String? url;
  final DateTime createdAt;
}
