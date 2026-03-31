import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';

/// Raw HTTP layer for creator-related API calls.
class CreatorRemoteDatasource {
  final ApiClient _client;

  const CreatorRemoteDatasource(this._client);

  /// POST /creator/setup — first-time setup or re-activation.
  Future<Map<String, dynamic>> setupCreatorProfile(
    Map<String, dynamic> data,
  ) async {
    final result = await _client.post(ApiConstants.creatorSetup, body: data);
    return result as Map<String, dynamic>;
  }

  /// PATCH /creator/profile — update existing creator profile.
  Future<Map<String, dynamic>> updateCreatorProfile(
    Map<String, dynamic> data,
  ) async {
    final result = await _client.patch(ApiConstants.creatorProfile, body: data);
    return result as Map<String, dynamic>;
  }

  /// POST /creator/deactivate — switch back to listener.
  Future<void> deactivateCreator() async {
    await _client.post(ApiConstants.creatorDeactivate, body: {});
  }
}
