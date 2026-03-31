import '../datasources/creator_remote_datasource.dart';

/// Repository for creator profile operations.
///
/// Delegates directly to the remote datasource — no local caching
/// is needed since role changes must always reflect the latest server state.
class CreatorRepository {
  final CreatorRemoteDatasource _datasource;

  const CreatorRepository(this._datasource);

  /// Upgrade to creator (first-time) or re-activate (returning creator).
  Future<Map<String, dynamic>> setupCreator({
    required String roleTitle,
    required List<String> specializations,
    String? location,
    String? soundcloudUrl,
    String? youtubeUrl,
    String? spotifyArtistUrl,
    String? appleMusicUrl,
    String? portfolioUrl,
  }) async {
    final data = {
      'role_title': roleTitle,
      'specializations': specializations,
      if (location != null && location.isNotEmpty) 'location': location,
      if (soundcloudUrl != null && soundcloudUrl.isNotEmpty) 'soundcloud_url': soundcloudUrl,
      if (youtubeUrl != null && youtubeUrl.isNotEmpty) 'youtube_url': youtubeUrl,
      if (spotifyArtistUrl != null && spotifyArtistUrl.isNotEmpty) 'spotify_artist_url': spotifyArtistUrl,
      if (appleMusicUrl != null && appleMusicUrl.isNotEmpty) 'apple_music_url': appleMusicUrl,
      if (portfolioUrl != null && portfolioUrl.isNotEmpty) 'portfolio_url': portfolioUrl,
    };
    return _datasource.setupCreatorProfile(data);
  }

  /// Update an existing creator profile.
  Future<Map<String, dynamic>> updateCreator(Map<String, dynamic> data) {
    return _datasource.updateCreatorProfile(data);
  }

  /// Switch back to listener mode.
  Future<void> deactivateCreator() {
    return _datasource.deactivateCreator();
  }
}
