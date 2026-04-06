class Artwork {
  final String id;
  final String title;
  final String? description;
  final String imageUrl;
  final String authorName;
  final String? authorAvatar;
  final int likesCount;
  final int commentsCount;
  final bool isPublic;
  final DateTime createdAt;

  Artwork({
    required this.id,
    required this.title,
    this.description,
    required this.imageUrl,
    required this.authorName,
    this.authorAvatar,
    required this.likesCount,
    required this.commentsCount,
    required this.isPublic,
    required this.createdAt,
  });

  factory Artwork.fromJson(Map<String, dynamic> json) {
    return Artwork(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['image_url'],
      authorName: json['author']?['full_name'] ?? 'Unknown',
      authorAvatar: json['author']?['avatar_url'],
      likesCount: json['likes']?.length ?? 0,
      commentsCount: json['comments']?.length ?? 0,
      isPublic: json['is_public'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}