/// Data model for a user who liked a post.
class LikerModel {
  final String id;
  final String username;
  final String fullName;
  final String? avatarUrl;

  const LikerModel({
    required this.id,
    required this.username,
    required this.fullName,
    this.avatarUrl,
  });

  factory LikerModel.fromJson(Map<String, dynamic> json) {
    return LikerModel(
      id: json['id'] as String,
      username: json['username'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}
