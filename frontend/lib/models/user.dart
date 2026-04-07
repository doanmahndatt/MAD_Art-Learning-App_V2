class User {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String? bio;
  final String role;
  final bool isActive;
  final bool notificationEnabled;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.bio,
    required this.role,
    required this.isActive,
    required this.notificationEnabled,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'] ?? '',
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      role: json['role'] ?? 'user',
      isActive: json['is_active'] ?? true,
      notificationEnabled: json['notification_enabled'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
