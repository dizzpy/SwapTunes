import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_interceptor.dart';
import '../../../../core/network/network_exceptions.dart';
import '../models/comment_model.dart';
import '../models/liker_model.dart';
import '../models/post_model.dart';

/// Remote datasource for all feed-related API calls.
///
/// Handles post CRUD, like/unlike, hide, report, comments,
/// and image upload via the backend UploadThing proxy endpoint.
/// Default number of posts per page.
const int kFeedPageSize = 20;

/// Default number of comments per page.
const int kCommentsPageSize = 30;

/// Max dimension (width/height) for compressed post images.
const int _kCompressMaxDimension = 1920;

/// JPEG quality for compressed post images (0-100).
const int _kCompressQuality = 85;

class FeedRemoteDatasource {
  final ApiClient _client;
  final ApiInterceptor _interceptor;

  FeedRemoteDatasource(this._client, this._interceptor);

  // ── Feed ───────────────────────────────────────────────

  Future<List<PostModel>> getFeed({
    int page = 1,
    int limit = kFeedPageSize,
  }) async {
    final data =
        await _client.get(
              ApiConstants.postsFeed,
              queryParams: {'page': '$page', 'limit': '$limit'},
            )
            as List;
    return data
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Create ─────────────────────────────────────────────

  Future<PostModel> createPost(String content, {String? imageUrl}) async {
    final body = <String, dynamic>{'content': content};
    if (imageUrl != null) body['image_url'] = imageUrl;

    final data = await _client.post(ApiConstants.postsCreate, body: body);
    return PostModel.fromJson(data as Map<String, dynamic>);
  }

  // ── Image Upload ───────────────────────────────────────

  /// Compresses [image] and uploads it to the backend UploadThing proxy.
  ///
  /// Compression settings: max 1920px on longest side, 85% JPEG quality.
  /// Falls back to raw bytes if compression is unavailable (e.g. iOS Simulator).
  /// Returns the UploadThing CDN URL on success.
  Future<String> uploadImage(XFile image) async {
    Uint8List imageBytes;
    try {
      final compressed = await FlutterImageCompress.compressWithFile(
        image.path,
        minWidth: _kCompressMaxDimension,
        minHeight: _kCompressMaxDimension,
        quality: _kCompressQuality,
        keepExif: false,
      );
      imageBytes = compressed ?? await image.readAsBytes();
    } catch (_) {
      // Compression unavailable on this platform — upload original
      imageBytes = await image.readAsBytes();
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.uploadImage}');
    final request = http.MultipartRequest('POST', uri);

    // Attach auth token
    final headers = _interceptor.getHeaders();
    final authHeader = headers['Authorization'];
    if (authHeader != null) request.headers['Authorization'] = authHeader;

    final ext = image.path.split('.').last.toLowerCase();
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: 'post_${DateTime.now().millisecondsSinceEpoch}.$ext',
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

  // ── Like / Unlike ──────────────────────────────────────

  Future<void> likePost(String postId) async {
    await _client.post(ApiConstants.postLike(postId));
  }

  Future<void> unlikePost(String postId) async {
    await _client.delete(ApiConstants.postLike(postId));
  }

  // ── Moderation ─────────────────────────────────────────

  Future<PostModel> updatePost(
    String postId, {
    String? content,
    String? imageUrl,
  }) async {
    final body = <String, dynamic>{};
    if (content != null) body['content'] = content;
    if (imageUrl != null) body['image_url'] = imageUrl;
    final data = await _client.patch(
      ApiConstants.postUpdate(postId),
      body: body,
    );
    return PostModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deletePost(String postId) async {
    await _client.delete(ApiConstants.postDelete(postId));
  }

  Future<void> hidePost(String postId) async {
    await _client.post(ApiConstants.postHide(postId));
  }

  Future<void> reportPost(String postId, String reason) async {
    await _client.post(
      ApiConstants.postReport(postId),
      body: {'reason': reason},
    );
  }

  // ── Comments ───────────────────────────────────────────

  Future<List<CommentModel>> getComments(
    String postId, {
    int page = 1,
    int limit = kCommentsPageSize,
  }) async {
    final data =
        await _client.get(
              ApiConstants.postComments(postId),
              queryParams: {'page': '$page', 'limit': '$limit'},
            )
            as List;
    return data
        .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CommentModel> addComment(String postId, String content) async {
    final data = await _client.post(
      ApiConstants.postComments(postId),
      body: {'content': content},
    );
    return CommentModel.fromJson(data as Map<String, dynamic>);
  }

  Future<CommentModel> updateComment(
    String postId,
    String commentId,
    String content,
  ) async {
    final data = await _client.patch(
      ApiConstants.postCommentUpdate(postId, commentId),
      body: {'content': content},
    );
    return CommentModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _client.delete(ApiConstants.postCommentDelete(postId, commentId));
  }

  Future<List<LikerModel>> getLikers(String postId) async {
    final data = await _client.get(ApiConstants.postLikers(postId)) as List;
    return data
        .map((e) => LikerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
