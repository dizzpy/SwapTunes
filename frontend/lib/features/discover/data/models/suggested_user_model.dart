class SuggestedUserModel {
  final String id;
  final String fullName;
  final String username;
  final String? avatarUrl;
  final String? userType;

  const SuggestedUserModel({
    required this.id,
    required this.fullName,
    required this.username,
    this.avatarUrl,
    this.userType,
  });

  factory SuggestedUserModel.fromJson(Map<String, dynamic> json) {
    return SuggestedUserModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      userType: json['user_type'] as String?,
    );
  }
}
