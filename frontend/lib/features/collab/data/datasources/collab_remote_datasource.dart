import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/collab_match_result.dart';
import '../models/collab_model.dart';

/// Number of collaboration posts fetched per page.
const int kCollabPageSize = 20;

/// Remote datasource for all collaboration-related API calls.
class CollabRemoteDatasource {
  final ApiClient _client;

  CollabRemoteDatasource(this._client);

  /// Fetches open collaborations, optionally filtered by [role].
  Future<List<CollabModel>> getCollabs({
    int page = 1,
    int limit = kCollabPageSize,
    String? role,
  }) async {
    final params = <String, String>{'page': '$page', 'limit': '$limit'};
    if (role != null) params['role'] = role;

    final data =
        await _client.get(ApiConstants.collabs, queryParams: params) as List;
    return data
        .map((e) => CollabModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches the authenticated creator's own collaboration posts.
  Future<List<CollabModel>> getMyCollabs({
    int page = 1,
    int limit = kCollabPageSize,
  }) async {
    final data =
        await _client.get(
              ApiConstants.myCollabs,
              queryParams: {'page': '$page', 'limit': '$limit'},
            )
            as List;
    return data
        .map((e) => CollabModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches a single collaboration post by [id].
  Future<CollabModel> getCollabById(String id) async {
    final data = await _client.get(ApiConstants.collabById(id));
    return CollabModel.fromJson(data as Map<String, dynamic>);
  }

  /// Creates a new collaboration post.
  Future<CollabModel> createCollab({
    required String title,
    required String description,
    required List<String> lookingFor,
    required List<String> genreStyle,
    required String paymentType,
  }) async {
    final data = await _client.post(
      ApiConstants.collabs,
      body: {
        'title': title,
        'description': description,
        'looking_for': lookingFor,
        'genre_style': genreStyle,
        'payment_type': paymentType,
      },
    );
    return CollabModel.fromJson(data as Map<String, dynamic>);
  }

  /// Updates an existing collaboration post.
  Future<CollabModel> updateCollab(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final data = await _client.patch(
      ApiConstants.collabById(id),
      body: updates,
    );
    return CollabModel.fromJson(data as Map<String, dynamic>);
  }

  /// Deletes a collaboration post.
  Future<void> deleteCollab(String id) async {
    await _client.delete(ApiConstants.collabById(id));
  }

  /// Fetches AI-matched creators for a collab listing.
  Future<List<CollabMatchResult>> getCollabMatches(String collabId) async {
    final data = await _client.post(ApiConstants.collabMatch(collabId)) as List;
    return data
        .map((e) => CollabMatchResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
