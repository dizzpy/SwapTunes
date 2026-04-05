class NotificationModel {
  final String id;
  final String type; // 'like' | 'comment' | 'follow' | 'message' | 'collab'
  final bool isRead;
  final DateTime createdAt;
  final String? referenceId;
  final String actorId;
  final String actorName;
  final String actorUsername;
  final String? actorAvatarUrl;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.referenceId,
    required this.actorId,
    required this.actorName,
    required this.actorUsername,
    this.actorAvatarUrl,
  });

  /// Constructs from the backend GET /notifications response.
  ///
  /// Shape: { id, type, is_read, created_at, reference_id,
  ///          actor: { id, username, full_name, avatar_url } }
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final actor = json['actor'] as Map<String, dynamic>? ?? {};
    return NotificationModel(
      id: json['id'] as String,
      type: json['type'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
      referenceId: json['reference_id'] as String?,
      actorId: actor['id'] as String? ?? '',
      actorName: actor['full_name'] as String? ?? '',
      actorUsername: actor['username'] as String? ?? '',
      actorAvatarUrl: actor['avatar_url'] as String?,
    );
  }

  /// Returns a copy with [isRead] set to true.
  NotificationModel markRead() => NotificationModel(
        id: id,
        type: type,
        isRead: true,
        createdAt: createdAt,
        referenceId: referenceId,
        actorId: actorId,
        actorName: actorName,
        actorUsername: actorUsername,
        actorAvatarUrl: actorAvatarUrl,
      );

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}';
  }
}
