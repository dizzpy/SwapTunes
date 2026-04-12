import '../../../creator/data/models/song_builder_model.dart';

/// A saved song plan entry from the `saved_song_plans` table.
class SavedSongPlanModel {
  final String id;
  final String title;
  final SongBuilderResult data;
  final DateTime createdAt;

  SavedSongPlanModel({
    required this.id,
    required this.title,
    required this.data,
    required this.createdAt,
  });

  factory SavedSongPlanModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final dataMap = rawData is Map<String, dynamic>
        ? rawData
        : <String, dynamic>{};

    return SavedSongPlanModel(
      id: json['id'] as String,
      title: json['title'] as String,
      data: SongBuilderResult.fromJson(dataMap),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
