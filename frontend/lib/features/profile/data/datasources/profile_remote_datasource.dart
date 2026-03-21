import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_interceptor.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../feed/data/models/post_model.dart';
import '../models/full_profile_model.dart';
import '../models/follow_user_model.dart';

/// Raw HTTP layer for all profile-related API calls.
///
/// Mirrors the pattern used by [FeedRemoteDatasource]:
/// parse typed models here, repository only delegates.
class ProfileRemoteDatasource {
  final ApiClient _client;
  final ApiInterceptor _interceptor;

  ProfileRemoteDatasource(this._client, this._interceptor);

  /// GET /users/:username — works for both own and other users' profiles.
  Future<FullProfileModel> getUserProfile(String username) async {
    final data = await _client.get(ApiConstants.userProfile(username));
    return FullProfileModel.fromJson(data as Map<String, dynamic>);
  }

  /// POST /users/:userId/follow
  Future<void> followUser(String userId) async {
    await _client.post(ApiConstants.follow(userId));
  }

  /// DELETE /users/:userId/unfollow
  Future<void> unfollowUser(String userId) async {
    await _client.delete(ApiConstants.unfollow(userId));
  }

  /// GET /users/:userId/followers (paginated)
  Future<List<FollowUserModel>> getFollowers(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    final data =
        await _client.get(
              ApiConstants.followers(userId),
              queryParams: {'page': '$page', 'limit': '$limit'},
            )
            as List;
    return data
        .map((e) => FollowUserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /users/:userId/following (paginated)
  Future<List<FollowUserModel>> getFollowing(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    final data =
        await _client.get(
              ApiConstants.following(userId),
              queryParams: {'page': '$page', 'limit': '$limit'},
            )
            as List;
    return data
        .map((e) => FollowUserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /users/:userId/posts (paginated)
  Future<List<PostModel>> getUserPosts(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    final data =
        await _client.get(
              ApiConstants.userPosts(userId),
              queryParams: {'page': '$page', 'limit': '$limit'},
            )
            as List;
    return data
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Upload an image to the backend UploadThing proxy.
  ///
  /// Compresses before upload (max 1920px, 85% JPEG quality).
  /// Returns the CDN URL on success.
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
        filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.$ext',
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
