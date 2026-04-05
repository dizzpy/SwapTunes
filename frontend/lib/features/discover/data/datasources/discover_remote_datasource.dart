import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_interceptor.dart';
import '../../../../core/network/network_exceptions.dart';
import '../models/playlist_model.dart';
import '../models/spotify_playlist_model.dart';
import '../models/suggested_user_model.dart';

const int kDiscoverPageSize = 20;

class DiscoverRemoteDatasource {
  final ApiClient _client;
  final ApiInterceptor _interceptor;

  DiscoverRemoteDatasource(this._client, this._interceptor);

  // ── Genres ─────────────────────────────────────────────

  Future<List<String>> getGenres() async {
    final data = await _client.get(ApiConstants.discoverGenres) as List;
    return data.map((e) => e.toString()).toList();
  }

  // ── Suggested users ────────────────────────────────────

  Future<List<SuggestedUserModel>> getSuggestedUsers({int limit = 20}) async {
    final data = await _client.get(
      ApiConstants.discoverUsers,
      queryParams: {'limit': '$limit'},
    ) as List;
    return data
        .map((e) => SuggestedUserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Discover feed ──────────────────────────────────────

  Future<List<PlaylistModel>> getDiscoverPlaylists({
    String? genre,
    int page = 1,
    int limit = kDiscoverPageSize,
  }) async {
    final params = <String, String>{'page': '$page', 'limit': '$limit'};
    if (genre != null) params['genre'] = genre;
    final data =
        await _client.get(ApiConstants.discoverPlaylists, queryParams: params)
            as List;
    return data
        .map((e) => PlaylistModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Playlist CRUD ──────────────────────────────────────

  Future<PlaylistModel> getPlaylist(String id) async {
    final data = await _client.get(ApiConstants.playlistById(id));
    return PlaylistModel.fromJson(data as Map<String, dynamic>);
  }

  Future<PlaylistModel> createPlaylist(Map<String, dynamic> body) async {
    final data = await _client.post(ApiConstants.playlistCreate, body: body);
    return PlaylistModel.fromJson(data as Map<String, dynamic>);
  }

  Future<PlaylistModel> updatePlaylist(
    String id,
    Map<String, dynamic> body,
  ) async {
    final data = await _client.patch(ApiConstants.playlistById(id), body: body);
    return PlaylistModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deletePlaylist(String id) async {
    await _client.delete(ApiConstants.playlistById(id));
  }

  // ── Likes ──────────────────────────────────────────────

  Future<void> likePlaylist(String id) async {
    await _client.post(ApiConstants.playlistLike(id));
  }

  Future<void> unlikePlaylist(String id) async {
    await _client.delete(ApiConstants.playlistLike(id));
  }

  // ── Spotify ────────────────────────────────────────────

  Future<List<SpotifyPlaylistModel>> getAvailableSpotifyPlaylists() async {
    final data = await _client.get(ApiConstants.spotifyAvailable) as List;
    return data
        .map((e) => SpotifyPlaylistModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PlaylistModel> importSpotifyPlaylist(String playlistId) async {
    final data =
        await _client.post(
              ApiConstants.playlistImport,
              body: {
                'playlist_ids': [playlistId],
              },
            )
            as List;
    if (data.isEmpty) {
      throw ApiException(
        code: 'IMPORT_FAILED',
        message: 'No playlist was returned from import',
        statusCode: 400,
      );
    }
    return PlaylistModel.fromJson(data.first as Map<String, dynamic>);
  }

  // ── Trending genres ────────────────────────────────────

  Future<List<String>> getTrendingGenres({int limit = 10}) async {
    final data = await _client.get(
      ApiConstants.discoverTrending,
      queryParams: {'limit': '$limit'},
    ) as List;
    return data.map((e) => e.toString()).toList();
  }

  // ── Search ─────────────────────────────────────────────

  Future<Map<String, dynamic>> search(
    String query, {
    String type = 'all',
    int page = 1,
    int limit = 20,
  }) async {
    final data = await _client.get(
      ApiConstants.discoverSearch,
      queryParams: {'q': query, 'type': type, 'page': '$page', 'limit': '$limit'},
    ) as Map<String, dynamic>;
    return data;
  }

  // ── Image upload ────────────────────────────────────────

  Future<String> uploadImage(XFile image) async {
    Uint8List imageBytes;
    try {
      final compressed = await FlutterImageCompress.compressWithFile(
        image.path,
        minWidth: 1920,
        minHeight: 1920,
        quality: 85,
        keepExif: false,
      );
      imageBytes = compressed ?? await image.readAsBytes();
    } catch (_) {
      imageBytes = await image.readAsBytes();
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.uploadImage}');
    final request = http.MultipartRequest('POST', uri);

    final headers = _interceptor.getHeaders();
    final authHeader = headers['Authorization'];
    if (authHeader != null) request.headers['Authorization'] = authHeader;

    final ext = image.path.split('.').last.toLowerCase();
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: 'playlist_${DateTime.now().millisecondsSinceEpoch}.$ext',
        contentType: MediaType('image', ext == 'jpg' ? 'jpeg' : ext),
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Image upload failed';
      try {
        final json = jsonDecode(response.body);
        message = json['error']?['message'] ?? message;
      } catch (_) {}
      throw ApiException(
        code: 'UPLOAD_FAILED',
        message: message,
        statusCode: response.statusCode,
      );
    }

    final json = jsonDecode(response.body);
    return json['url'] as String;
  }
}
