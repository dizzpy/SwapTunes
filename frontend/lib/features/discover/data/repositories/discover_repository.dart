import 'package:image_picker/image_picker.dart';

import '../datasources/discover_remote_datasource.dart';
import '../models/playlist_model.dart';
import '../models/spotify_playlist_model.dart';
import '../models/suggested_user_model.dart';

class DiscoverRepository {
  final DiscoverRemoteDatasource _datasource;

  DiscoverRepository(this._datasource);

  // ── Suggested users ────────────────────────────────────

  Future<List<SuggestedUserModel>> getSuggestedUsers({int limit = 20}) =>
      _datasource.getSuggestedUsers(limit: limit);

  // ── Genres ─────────────────────────────────────────────

  Future<List<String>> getGenres() => _datasource.getGenres();

  // ── Discover feed ──────────────────────────────────────

  Future<List<PlaylistModel>> getDiscoverPlaylists({
    String? genre,
    int page = 1,
    int limit = kDiscoverPageSize,
  }) =>
      _datasource.getDiscoverPlaylists(genre: genre, page: page, limit: limit);

  // ── Playlist CRUD ──────────────────────────────────────

  Future<PlaylistModel> getPlaylist(String id) => _datasource.getPlaylist(id);

  Future<PlaylistModel> createPlaylist(Map<String, dynamic> body) =>
      _datasource.createPlaylist(body);

  Future<PlaylistModel> updatePlaylist(String id, Map<String, dynamic> body) =>
      _datasource.updatePlaylist(id, body);

  Future<void> deletePlaylist(String id) => _datasource.deletePlaylist(id);

  // ── Likes ──────────────────────────────────────────────

  Future<void> likePlaylist(String id) => _datasource.likePlaylist(id);

  Future<void> unlikePlaylist(String id) => _datasource.unlikePlaylist(id);

  // ── Spotify ────────────────────────────────────────────

  Future<List<SpotifyPlaylistModel>> getAvailableSpotifyPlaylists() =>
      _datasource.getAvailableSpotifyPlaylists();

  Future<PlaylistModel> importSpotifyPlaylist(String playlistId) =>
      _datasource.importSpotifyPlaylist(playlistId);

  // ── Trending genres ────────────────────────────────────

  Future<List<String>> getTrendingGenres({int limit = 10}) =>
      _datasource.getTrendingGenres(limit: limit);

  // ── Search ─────────────────────────────────────────────

  Future<Map<String, dynamic>> search(
    String query, {
    String type = 'all',
    int page = 1,
    int limit = 20,
  }) => _datasource.search(query, type: type, page: page, limit: limit);

  // ── Image upload ────────────────────────────────────────

  Future<String> uploadImage(XFile image) => _datasource.uploadImage(image);
}
