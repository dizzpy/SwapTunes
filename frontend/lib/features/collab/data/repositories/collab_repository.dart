import '../datasources/collab_remote_datasource.dart';
import '../models/collab_model.dart';

/// Repository for collaboration data.
///
/// Thin pass-through over [CollabRemoteDatasource] for v1.
/// Isar caching can be layered in here later without touching the ViewModel.
class CollabRepository {
  final CollabRemoteDatasource _datasource;

  CollabRepository(this._datasource);

  Future<List<CollabModel>> getCollabs({
    int page = 1,
    int limit = kCollabPageSize,
    String? role,
  }) => _datasource.getCollabs(page: page, limit: limit, role: role);

  Future<List<CollabModel>> getMyCollabs({
    int page = 1,
    int limit = kCollabPageSize,
  }) => _datasource.getMyCollabs(page: page, limit: limit);

  Future<CollabModel> getCollabById(String id) => _datasource.getCollabById(id);

  Future<CollabModel> createCollab({
    required String title,
    required String description,
    required List<String> lookingFor,
    required List<String> genreStyle,
    required String paymentType,
  }) => _datasource.createCollab(
    title: title,
    description: description,
    lookingFor: lookingFor,
    genreStyle: genreStyle,
    paymentType: paymentType,
  );

  Future<CollabModel> updateCollab(String id, Map<String, dynamic> updates) =>
      _datasource.updateCollab(id, updates);

  Future<void> deleteCollab(String id) => _datasource.deleteCollab(id);
}
