/// Profile model for the profile setup and update screens.
///
/// Used for building the request body sent to `/auth/profile/setup`
/// and `/users/me`.
class ProfileModel {
  final String fullName;
  final String username;
  final String? bio;
  final String? avatarUrl;
  final List<String> genres;

  const ProfileModel({
    required this.fullName,
    required this.username,
    this.bio,
    this.avatarUrl,
    required this.genres,
  });

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'username': username,
      if (bio != null && bio!.isNotEmpty) 'bio': bio,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'genres': genres,
    };
  }
}
