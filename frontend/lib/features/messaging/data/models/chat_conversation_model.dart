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

  /// Constructs from the backend GET /conversations response.
  ///
  /// The backend returns [user_one] and [user_two] as objects. We pick
  /// whichever is NOT [currentUserId] as the conversation participant.
  factory ChatConversationModel.fromApiJson(
    Map<String, dynamic> json,
    String currentUserId,
  ) {
    final userOne = json['user_one'] as Map<String, dynamic>? ?? {};
    final userTwo = json['user_two'] as Map<String, dynamic>? ?? {};

    final participant =
        (userOne['id'] as String?) == currentUserId ? userTwo : userOne;

    return ChatConversationModel(
      id: json['id'] as String,
      participantId: participant['id'] as String? ?? '',
      participantName: participant['full_name'] as String? ?? '',
      participantAvatarUrl: participant['avatar_url'] as String?,
      isOnline: false, // no presence system yet
      lastMessage: json['last_message'] as String? ?? '',
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
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
    if (lastMessage.isEmpty || lastMessageAt.millisecondsSinceEpoch == 0) return '';
    final diff = DateTime.now().difference(lastMessageAt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${lastMessageAt.day}/${lastMessageAt.month}';
  }
}
