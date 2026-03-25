class ChatConversationModel {
  final String id;
  final String participantId;
  final String participantName;
  final String? participantAvatarUrl;
  final bool isOnline;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;

  const ChatConversationModel({
    required this.id,
    required this.participantId,
    required this.participantName,
    this.participantAvatarUrl,
    required this.isOnline,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    final participant = json['participant'] as Map<String, dynamic>? ?? {};
    return ChatConversationModel(
      id: json['id'] as String,
      participantId: json['participant_id'] as String? ?? participant['id'] as String? ?? '',
      participantName: participant['full_name'] as String? ?? '',
      participantAvatarUrl: participant['avatar_url'] as String?,
      isOnline: (json['is_online'] as bool?) ?? false,
      lastMessage: json['last_message'] as String? ?? '',
      lastMessageAt: DateTime.parse(json['last_message_at'] as String),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'participant_id': participantId,
    'last_message': lastMessage,
    'last_message_at': lastMessageAt.toIso8601String(),
    'unread_count': unreadCount,
  };

  String get timeAgo {
    final diff = DateTime.now().difference(lastMessageAt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${lastMessageAt.day}/${lastMessageAt.month}';
  }
}
