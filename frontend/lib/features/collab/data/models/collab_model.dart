/// Data model for a collaboration post.
///
/// Maps to the `collaborations` table joined with the creator's user record.
class CollabModel {
  final String id;
  final String creatorId;
  final String title;
  final String description;
  final List<String> lookingFor;
  final List<String> genreStyle;
  final String paymentType; // 'paid' | 'revenue_share' | 'free'
  final String status; // 'open' | 'closed'
  final DateTime createdAt;

  // Creator fields (joined from users table)
  final String creatorUsername;
  final String creatorFullName;
  final String? creatorAvatarUrl;
  final bool creatorIsVerified;

  const CollabModel({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.lookingFor,
    required this.genreStyle,
    required this.paymentType,
    required this.status,
    required this.createdAt,
    required this.creatorUsername,
    required this.creatorFullName,
    this.creatorAvatarUrl,
    required this.creatorIsVerified,
  });

  factory CollabModel.fromJson(Map<String, dynamic> json) {
    final creator = json['creator'] as Map<String, dynamic>? ?? {};
    return CollabModel(
      id: json['id'] as String,
      creatorId: json['creator_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      lookingFor: List<String>.from(json['looking_for'] as List? ?? []),
      genreStyle: List<String>.from(json['genre_style'] as List? ?? []),
      paymentType: json['payment_type'] as String,
      status: json['status'] as String? ?? 'open',
      createdAt: DateTime.parse(json['created_at'] as String),
      creatorUsername: creator['username'] as String? ?? '',
      creatorFullName: creator['full_name'] as String? ?? '',
      creatorAvatarUrl: creator['avatar_url'] as String?,
      creatorIsVerified: (creator['is_verified'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'looking_for': lookingFor,
    'genre_style': genreStyle,
    'payment_type': paymentType,
  };

  CollabModel copyWith({
    String? title,
    String? description,
    List<String>? lookingFor,
    List<String>? genreStyle,
    String? paymentType,
    String? status,
  }) {
    return CollabModel(
      id: id,
      creatorId: creatorId,
      title: title ?? this.title,
      description: description ?? this.description,
      lookingFor: lookingFor ?? this.lookingFor,
      genreStyle: genreStyle ?? this.genreStyle,
      paymentType: paymentType ?? this.paymentType,
      status: status ?? this.status,
      createdAt: createdAt,
      creatorUsername: creatorUsername,
      creatorFullName: creatorFullName,
      creatorAvatarUrl: creatorAvatarUrl,
      creatorIsVerified: creatorIsVerified,
    );
  }

  /// Human-readable label for the payment type.
  String get paymentTypeLabel {
    switch (paymentType) {
      case 'paid':
        return 'Paid Project';
      case 'revenue_share':
        return 'Revenue Share';
      case 'free':
        return 'For Fun/Experience';
      default:
        return paymentType;
    }
  }

  /// Relative time string (e.g. "2h ago", "3d ago").
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays >= 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}
