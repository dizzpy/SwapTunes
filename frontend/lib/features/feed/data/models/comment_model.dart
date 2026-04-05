/// Data model for a post comment.
///
/// Maps the JSON returned by `GET /posts/:id/comments` and `POST /posts/:id/comments`.
class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String authorUsername;
  final String authorFullName;
  final String? authorAvatarUrl;

  const CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.authorUsername,
    required this.authorFullName,
    this.authorAvatarUrl,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return CommentModel(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      authorUsername: user['username'] as String? ?? '',
      authorFullName: user['full_name'] as String? ?? '',
      authorAvatarUrl: user['avatar_url'] as String?,
    );
  }

  CommentModel copyWith({String? content}) {
    return CommentModel(
      id: id,
      postId: postId,
      userId: userId,
      content: content ?? this.content,
      createdAt: createdAt,
      authorUsername: authorUsername,
      authorFullName: authorFullName,
      authorAvatarUrl: authorAvatarUrl,
    );
  }

  /// Returns a human-readable relative time string (e.g. "2h", "3d").
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays >= 7) return '${(diff.inDays / 7).floor()}w';
    if (diff.inDays >= 1) return '${diff.inDays}d';
    if (diff.inHours >= 1) return '${diff.inHours}h';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
    return 'now';
  }
}
