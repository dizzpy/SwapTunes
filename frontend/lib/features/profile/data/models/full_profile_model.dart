/// Rich profile model returned by GET /users/:username.
///
/// Distinct from [UserModel] (compact auth state) — this is the
/// display model used exclusively by profile screens.
class FullProfileModel {
  final String id;
  final String fullName;
  final String username;
  final String? bio;
  final String? avatarUrl;
  final String? coverUrl;
  final String userType; // 'listener' | 'creator'
  final bool isVerified;
  final bool spotifyConnected;
  final DateTime createdAt;
  final DateTime? usernameChangedAt;
  final List<String> genres;
  final ProfileStats stats;
  final bool? isFollowing; // null when viewing own profile
  final CreatorProfile? creatorProfile; // null for listeners

  const FullProfileModel({
    required this.id,
    required this.fullName,
    required this.username,
    this.bio,
    this.avatarUrl,
    this.coverUrl,
    required this.userType,
    required this.isVerified,
    required this.spotifyConnected,
    required this.createdAt,
    this.usernameChangedAt,
    required this.genres,
    required this.stats,
    this.isFollowing,
    this.creatorProfile,
  });

  bool get isCreator => userType == 'creator';

  /// Days until username can be changed again. 0 = can change now.
  int get usernameChangeCooldownDays {
    if (usernameChangedAt == null) return 0;
    final daysSince = DateTime.now().difference(usernameChangedAt!).inDays;
    return daysSince >= 7 ? 0 : (7 - daysSince);
  }

  factory FullProfileModel.fromJson(Map<String, dynamic> json) {
    // creator_profiles is a list from Supabase join — take first element
    final creatorList = json['creator_profiles'] as List?;
    CreatorProfile? creatorProfile;
    if (creatorList != null && creatorList.isNotEmpty) {
      creatorProfile = CreatorProfile.fromJson(
        creatorList.first as Map<String, dynamic>,
      );
    }

    return FullProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      username: json['username'] as String,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      coverUrl: json['cover_url'] as String?,
      userType: (json['user_type'] as String?) ?? 'listener',
      isVerified: (json['is_verified'] as bool?) ?? false,
      spotifyConnected: (json['spotify_connected'] as bool?) ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      usernameChangedAt: json['username_changed_at'] != null
          ? DateTime.parse(json['username_changed_at'] as String)
          : null,
      genres: (json['genres'] as List?)?.cast<String>() ?? [],
      stats: ProfileStats.fromJson(
        (json['stats'] as Map<String, dynamic>?) ?? {},
      ),
      isFollowing: json['is_following'] as bool?,
      creatorProfile: creatorProfile,
    );
  }

  FullProfileModel copyWith({
    String? id,
    String? fullName,
    String? username,
    String? bio,
    Object? avatarUrl = _sentinel,
    Object? coverUrl = _sentinel,
    String? userType,
    bool? isVerified,
    bool? spotifyConnected,
    DateTime? createdAt,
    DateTime? usernameChangedAt,
    List<String>? genres,
    ProfileStats? stats,
    bool? isFollowing,
    CreatorProfile? creatorProfile,
  }) {
    return FullProfileModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl == _sentinel ? this.avatarUrl : avatarUrl as String?,
      coverUrl: coverUrl == _sentinel ? this.coverUrl : coverUrl as String?,
      userType: userType ?? this.userType,
      isVerified: isVerified ?? this.isVerified,
      spotifyConnected: spotifyConnected ?? this.spotifyConnected,
      createdAt: createdAt ?? this.createdAt,
      usernameChangedAt: usernameChangedAt ?? this.usernameChangedAt,
      genres: genres ?? this.genres,
      stats: stats ?? this.stats,
      isFollowing: isFollowing ?? this.isFollowing,
      creatorProfile: creatorProfile ?? this.creatorProfile,
    );
  }
}

// Sentinel for nullable copyWith fields
const Object _sentinel = Object();

class ProfileStats {
  final int followers;
  final int following;
  final int posts;
  final int playlists;
  final int collabs;

  const ProfileStats({
    required this.followers,
    required this.following,
    required this.posts,
    required this.playlists,
    required this.collabs,
  });

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    return ProfileStats(
      followers: (json['followers'] as num?)?.toInt() ?? 0,
      following: (json['following'] as num?)?.toInt() ?? 0,
      posts: (json['posts'] as num?)?.toInt() ?? 0,
      playlists: (json['playlists'] as num?)?.toInt() ?? 0,
      collabs: (json['collabs'] as num?)?.toInt() ?? 0,
    );
  }

  ProfileStats copyWith({
    int? followers,
    int? following,
    int? posts,
    int? playlists,
    int? collabs,
  }) {
    return ProfileStats(
      followers: followers ?? this.followers,
      following: following ?? this.following,
      posts: posts ?? this.posts,
      playlists: playlists ?? this.playlists,
      collabs: collabs ?? this.collabs,
    );
  }
}

class CreatorProfile {
  final String? roleTitle;
  final String? location;
  final List<String> specializations;
  final String? soundcloudUrl;
  final String? youtubeUrl;
  final String? spotifyArtistUrl;
  final String? appleMusicUrl;
  final String? portfolioUrl;

  const CreatorProfile({
    this.roleTitle,
    this.location,
    required this.specializations,
    this.soundcloudUrl,
    this.youtubeUrl,
    this.spotifyArtistUrl,
    this.appleMusicUrl,
    this.portfolioUrl,
  });

  factory CreatorProfile.fromJson(Map<String, dynamic> json) {
    return CreatorProfile(
      roleTitle: json['role_title'] as String?,
      location: json['location'] as String?,
      specializations: (json['specializations'] as List?)?.cast<String>() ?? [],
      soundcloudUrl: json['soundcloud_url'] as String?,
      youtubeUrl: json['youtube_url'] as String?,
      spotifyArtistUrl: json['spotify_artist_url'] as String?,
      appleMusicUrl: json['apple_music_url'] as String?,
      portfolioUrl: json['portfolio_url'] as String?,
    );
  }
}
