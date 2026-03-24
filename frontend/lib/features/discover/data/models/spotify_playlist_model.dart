class SpotifyPlaylistModel {
  final String id;
  final String name;
  final int trackCount;
  final bool isPublic;
  final String? coverImageUrl;
  final bool isImported;

  const SpotifyPlaylistModel({
    required this.id,
    required this.name,
    required this.trackCount,
    required this.isPublic,
    this.coverImageUrl,
    required this.isImported,
  });

  factory SpotifyPlaylistModel.fromJson(Map<String, dynamic> json) {
    return SpotifyPlaylistModel(
      id: json['id'] as String,
      name: json['name'] as String,
      trackCount: (json['track_count'] as num?)?.toInt() ?? 0,
      isPublic: (json['is_public'] as bool?) ?? false,
      coverImageUrl: json['cover_image_url'] as String?,
      isImported: (json['is_imported'] as bool?) ?? false,
    );
  }
}
