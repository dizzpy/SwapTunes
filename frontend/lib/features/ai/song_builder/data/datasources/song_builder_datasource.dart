import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/network/api_client.dart';
import '../models/song_builder_model.dart';

/// Remote datasource for the AI Song Builder feature.
class SongBuilderDatasource {
  final ApiClient _client;

  SongBuilderDatasource(this._client);

  Future<SongBuilderResult> buildSong({
    required String idea,
    required String genre,
    String? lyrics,
    required String type,
  }) async {
    final data = await _client.post(
      ApiConstants.songBuilder,
      body: {
        'idea': idea,
        'genre': genre,
        if (lyrics != null && lyrics.isNotEmpty) 'lyrics': lyrics,
        'type': type,
      },
    );
    return SongBuilderResult.fromJson(data as Map<String, dynamic>);
  }

  Future<void> savePlan(SongBuilderResult result) async {
    await _client.post(
      ApiConstants.songBuilderSave,
      body: {
        'title': result.title,
        'data': {
          'title': result.title,
          'vibe': result.vibe,
          'bpm': result.bpm,
          'key': result.key,
          'genre': result.genre,
          'type': result.type,
          'sampleHook': result.sampleHook,
          'hasUserLyrics': result.hasUserLyrics,
          'instruments': result.instruments,
          'sections': result.sections.map((s) => {
            'name': s.name,
            'timestamp': s.timestamp,
            'direction': s.direction,
            'userLyrics': s.userLyrics,
            'isUserLyrics': s.isUserLyrics,
            'isDrop': s.isDrop,
          }).toList(),
        },
      },
    );
  }
}
