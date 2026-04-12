import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/network/api_client.dart';
import '../models/collab_match_result.dart';

/// Remote datasource for the AI Collab Match feature.
class CollabMatchDatasource {
  final ApiClient _client;

  CollabMatchDatasource(this._client);

  /// Fetches AI-matched creators for a collab listing.
  Future<List<CollabMatchResult>> getCollabMatches(String collabId) async {
    final data = await _client.post(ApiConstants.collabMatch(collabId)) as List;
    return data
        .map((e) => CollabMatchResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
