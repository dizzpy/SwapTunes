class CollabMatchResult {
  final String userId;
  final int matchScore;
  final String reason;
  final MatchedCreatorProfile profile;

  CollabMatchResult.fromJson(Map<String, dynamic> json)
      : userId = json['userId'] as String,
        matchScore = json['matchScore'] as int,
        reason = json['reason'] as String,
        profile = MatchedCreatorProfile.fromJson(
          json['profile'] as Map<String, dynamic>,
        );
}

class MatchedCreatorProfile {
  final String username;
  final String? avatarUrl;
  final String roleTitle;
  final List<String> specializations;

  MatchedCreatorProfile.fromJson(Map<String, dynamic> json)
      : username =
            (json['users'] as Map<String, dynamic>)['username'] as String,
        avatarUrl =
            (json['users'] as Map<String, dynamic>)['avatar_url'] as String?,
        roleTitle = json['role_title'] as String,
        specializations = List<String>.from(json['specializations'] ?? []);
}
