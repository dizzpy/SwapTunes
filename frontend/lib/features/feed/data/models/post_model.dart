/// Data model for a feed post.
///
/// Maps the JSON returned by `GET /posts/feed` and `POST /posts`.
/// [isUploading] is true only for optimistic placeholder posts while
/// the create-post request is in flight.
class PostModel {
  final String id;
  final String userId;
  final String content;
  final String? imageUrl;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final DateTime createdAt;
  final String authorUsername;
  final String authorFullName;
  final String? authorAvatarUrl;
  final bool authorIsVerified;
  final bool isUploading;

  const PostModel({
    required this.id,
    required this.userId,
    required this.content,
    this.imageUrl,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    required this.createdAt,
    required this.authorUsername,
    required this.authorFullName,
    this.authorAvatarUrl,
    required this.authorIsVerified,
    this.isUploading = false,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return PostModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      imageUrl: json['image_url'] as String?,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
      isLiked: (json['is_liked'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      authorUsername: user['username'] as String? ?? '',
      authorFullName: user['full_name'] as String? ?? '',
      authorAvatarUrl: user['avatar_url'] as String?,
      authorIsVerified: (user['is_verified'] as bool?) ?? false,
    );
  }

  PostModel copyWith({
    String? content,
    bool? isLiked,
    int? likesCount,
    int? commentsCount,
    bool? isUploading,
    String? imageUrl,
  }) {
    return PostModel(
      id: id,
      userId: userId,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt,
      authorUsername: authorUsername,
      authorFullName: authorFullName,
      authorAvatarUrl: authorAvatarUrl,
      authorIsVerified: authorIsVerified,
      isUploading: isUploading ?? this.isUploading,
    );
  }

  String get formattedLikes => '${_formatCount(likesCount)} Likes';
  String get formattedComments => '${_formatCount(commentsCount)} Comment';

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays >= 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  static String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
