import '../datasources/collab_match_datasource.dart';
import '../models/collab_match_result.dart';

/// Repository for the AI Collab Match feature.
class CollabMatchRepository {
  final CollabMatchDatasource _datasource;

  CollabMatchRepository(this._datasource);

  Future<List<CollabMatchResult>> getCollabMatches(String collabId) =>
      _datasource.getCollabMatches(collabId);
}
