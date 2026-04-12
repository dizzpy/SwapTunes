import '../datasources/song_builder_datasource.dart';
import '../models/song_builder_model.dart';

/// Repository for the AI Song Builder feature.
class SongBuilderRepository {
  final SongBuilderDatasource _datasource;

  SongBuilderRepository(this._datasource);

  Future<SongBuilderResult> buildSong({
    required String idea,
    required String genre,
    String? lyrics,
    required String type,
  }) => _datasource.buildSong(idea: idea, genre: genre, lyrics: lyrics, type: type);

  Future<void> savePlan(SongBuilderResult result) => _datasource.savePlan(result);
}
