class Tutorial {
  final String id;
  final String title;
  final String category;
  final String description;
  final String? thumbnailUrl;
  final String authorName;
  final String? authorAvatar;
  final int stepsCount;
  final int likesCount;
  final int commentsCount;
  final String? difficultyLevel;
  final DateTime createdAt;

  Tutorial({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    this.thumbnailUrl,
    required this.authorName,
    this.authorAvatar,
    required this.stepsCount,
    required this.likesCount,
    required this.commentsCount,
    this.difficultyLevel,
    required this.createdAt,
  });

  factory Tutorial.fromJson(Map<String, dynamic> json) {
    return Tutorial(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      description: json['description'],
      thumbnailUrl: json['thumbnail_url'],
      authorName: json['author']?['full_name'] ?? 'Unknown',
      authorAvatar: json['author']?['avatar_url'],
      stepsCount: json['steps']?.length ?? 0,
      likesCount: json['favorites']?.length ?? 0,
      commentsCount: json['comments']?.length ?? 0,
      difficultyLevel: json['difficulty_level'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}