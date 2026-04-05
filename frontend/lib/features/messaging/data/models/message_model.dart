/// Transient delivery state for outgoing messages.
/// Not persisted — server messages always have [status] == null (treated as sent).
enum MessageStatus { sending, sent, failed }

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String text; // mapped from backend 'content' field
  final bool isRead;
  final bool isDeleted;
  final DateTime createdAt;

  /// Null for all messages loaded from server / cache.
  /// Only set on optimistic placeholders created during send.
  final MessageStatus? status;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.isRead,
    required this.isDeleted,
    required this.createdAt,
    this.status,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      text: json['content'] as String,
      isRead: (json['is_read'] as bool?) ?? false,
      isDeleted: (json['is_deleted'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversation_id': conversationId,
    'sender_id': senderId,
    'content': text,
    'is_read': isRead,
    'is_deleted': isDeleted,
    'created_at': createdAt.toIso8601String(),
  };

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? text,
    bool? isRead,
    bool? isDeleted,
    DateTime? createdAt,
    MessageStatus? status,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      isRead: isRead ?? this.isRead,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}
