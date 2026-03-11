/// User model representing the authenticated user's profile.
///
/// Maps directly to the JSON returned by `/auth/me` and `/auth/profile/setup`.
class UserModel {
  final String id;
  final String fullName;
  final String username;
  final String? bio;
  final String? avatarUrl;
  final String userType;
  final bool spotifyConnected;
  final bool isVerified;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.username,
    this.bio,
    this.avatarUrl,
    required this.userType,
    required this.spotifyConnected,
    required this.isVerified,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      username: json['username'] as String,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      userType: (json['user_type'] as String?) ?? 'listener',
      spotifyConnected: (json['spotify_connected'] as bool?) ?? false,
      isVerified: (json['is_verified'] as bool?) ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'username': username,
      'bio': bio,
      'avatar_url': avatarUrl,
      'user_type': userType,
      'spotify_connected': spotifyConnected,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
