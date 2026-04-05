/// Lightweight user model for follower / following list items.
///
/// Returned by GET /users/:userId/followers and GET /users/:userId/following.
class FollowUserModel {
  final String id;
  final String fullName;
  final String username;
  final String? avatarUrl;

  const FollowUserModel({
    required this.id,
    required this.fullName,
    required this.username,
    this.avatarUrl,
  });

  factory FollowUserModel.fromJson(Map<String, dynamic> json) {
    return FollowUserModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}
