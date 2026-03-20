import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../datasources/feed_remote_datasource.dart';
import '../models/comment_model.dart';
import '../models/liker_model.dart';
import '../models/post_model.dart';

/// Repository for all feed-related operations.
///
/// Acts as the single point of access for the presentation layer,
/// delegating to [FeedRemoteDatasource] for network operations.
class FeedRepository {
  final FeedRemoteDatasource _datasource;

  FeedRepository(this._datasource);

  Future<List<PostModel>> getFeed({int page = 1, int limit = 20}) =>
      _datasource.getFeed(page: page, limit: limit);

  Future<PostModel> createPost(String content, {String? imageUrl}) =>
      _datasource.createPost(content, imageUrl: imageUrl);

  Future<String> uploadImage(XFile image) =>
      _datasource.uploadImage(image);

  Future<void> likePost(String postId) => _datasource.likePost(postId);

  Future<void> unlikePost(String postId) => _datasource.unlikePost(postId);

  Future<PostModel> updatePost(String postId, {String? content, String? imageUrl}) =>
      _datasource.updatePost(postId, content: content, imageUrl: imageUrl);

  Future<void> deletePost(String postId) => _datasource.deletePost(postId);

  Future<void> hidePost(String postId) => _datasource.hidePost(postId);

  Future<void> reportPost(String postId, String reason) =>
      _datasource.reportPost(postId, reason);

  Future<List<CommentModel>> getComments(String postId,
          {int page = 1, int limit = 30}) =>
      _datasource.getComments(postId, page: page, limit: limit);

  Future<CommentModel> addComment(String postId, String content) =>
      _datasource.addComment(postId, content);

  Future<CommentModel> updateComment(String postId, String commentId, String content) =>
      _datasource.updateComment(postId, commentId, content);

  Future<void> deleteComment(String postId, String commentId) =>
      _datasource.deleteComment(postId, commentId);

  Future<List<LikerModel>> getLikers(String postId) =>
      _datasource.getLikers(postId);
}
