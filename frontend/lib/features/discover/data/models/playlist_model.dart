import 'source_platform.dart';

class PlaylistModel {
  final String id;
  final String userId;
  final String? spotifyPlaylistId;
  final String name;
  final String? description;
  final String? coverImageUrl;
  final int trackCount;
  final bool isPublic;
  final SourcePlatform sourcePlatform;
  final String? primaryUrl;
  final List<String> genreTags;
  final List<String> artists;
  final List<String> moodTags;
  final String? era;
  final String? energyLevel;
  final List<String> occasionTags;
  final String? vocalStyle;
  final String? language;
  final int likesCount;
  final bool isLiked;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String ownerUsername;
  final String ownerFullName;
  final String? ownerAvatarUrl;

  const PlaylistModel({
    required this.id,
    required this.userId,
    this.spotifyPlaylistId,
    required this.name,
    this.description,
    this.coverImageUrl,
    required this.trackCount,
    required this.isPublic,
    required this.sourcePlatform,
    this.primaryUrl,
    required this.genreTags,
    required this.artists,
    required this.moodTags,
    this.era,
    this.energyLevel,
    required this.occasionTags,
    this.vocalStyle,
    this.language,
    required this.likesCount,
    required this.isLiked,
    required this.createdAt,
    this.updatedAt,
    required this.ownerUsername,
    required this.ownerFullName,
    this.ownerAvatarUrl,
  });

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return PlaylistModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      spotifyPlaylistId: json['spotify_playlist_id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      trackCount: (json['track_count'] as num?)?.toInt() ?? 0,
      isPublic: (json['is_public'] as bool?) ?? true,
      sourcePlatform: SourcePlatform.fromValue(
        json['source_platform'] as String? ?? 'other',
      ),
      primaryUrl: json['primary_url'] as String?,
      genreTags: _toStringList(json['genre_tags']),
      artists: _toStringList(json['artists']),
      moodTags: _toStringList(json['mood_tags']),
      era: json['era'] as String?,
      energyLevel: json['energy_level'] as String?,
      occasionTags: _toStringList(json['occasion_tags']),
      vocalStyle: json['vocal_style'] as String?,
      language: json['language'] as String?,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      isLiked: (json['is_liked'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      ownerUsername: user['username'] as String? ?? '',
      ownerFullName: user['full_name'] as String? ?? '',
      ownerAvatarUrl: user['avatar_url'] as String?,
    );
  }

  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'cover_image_url': coverImageUrl,
    'is_public': isPublic,
    'source_platform': sourcePlatform.value,
    'primary_url': primaryUrl,
    'genre_tags': genreTags,
    'artists': artists,
    'mood_tags': moodTags,
    'era': era,
    'energy_level': energyLevel,
    'occasion_tags': occasionTags,
    'vocal_style': vocalStyle,
    'language': language,
    'track_count': trackCount,
  };

  PlaylistModel copyWith({bool? isLiked, int? likesCount}) {
    return PlaylistModel(
      id: id,
      userId: userId,
      spotifyPlaylistId: spotifyPlaylistId,
      name: name,
      description: description,
      coverImageUrl: coverImageUrl,
      trackCount: trackCount,
      isPublic: isPublic,
      sourcePlatform: sourcePlatform,
      primaryUrl: primaryUrl,
      genreTags: genreTags,
      artists: artists,
      moodTags: moodTags,
      era: era,
      energyLevel: energyLevel,
      occasionTags: occasionTags,
      vocalStyle: vocalStyle,
      language: language,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt,
      updatedAt: updatedAt,
      ownerUsername: ownerUsername,
      ownerFullName: ownerFullName,
      ownerAvatarUrl: ownerAvatarUrl,
    );
  }
}
