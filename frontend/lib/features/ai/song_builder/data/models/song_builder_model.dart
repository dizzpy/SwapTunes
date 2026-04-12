/// Represents a single section in a song plan (verse, hook, drop, etc.).
class SongSection {
  final String name;
  final String? timestamp;
  final String direction;
  final String? userLyrics;
  final bool isUserLyrics;
  final bool isDrop;

  SongSection({
    required this.name,
    this.timestamp,
    required this.direction,
    this.userLyrics,
    required this.isUserLyrics,
    required this.isDrop,
  });

  factory SongSection.fromJson(Map<String, dynamic> json) => SongSection(
        name: json['name'] as String,
        timestamp: json['timestamp'] as String?,
        direction: json['direction'] as String,
        userLyrics: json['userLyrics'] as String?,
        isUserLyrics: json['isUserLyrics'] as bool? ?? false,
        isDrop: json['isDrop'] as bool? ?? false,
      );
}

/// Full AI-generated song plan returned by the Song Builder.
class SongBuilderResult {
  final String title;
  final String vibe;
  final String bpm;
  final String key;
  final String genre;
  final String type;
  final String? sampleHook;
  final List<SongSection> sections;
  final List<String> instruments;
  final bool hasUserLyrics;

  SongBuilderResult({
    required this.title,
    required this.vibe,
    required this.bpm,
    required this.key,
    required this.genre,
    required this.type,
    this.sampleHook,
    required this.sections,
    required this.instruments,
    required this.hasUserLyrics,
  });

  factory SongBuilderResult.fromJson(Map<String, dynamic> json) =>
      SongBuilderResult(
        title: json['title'] as String,
        vibe: json['vibe'] as String,
        bpm: json['bpm'] as String,
        key: json['key'] as String,
        genre: json['genre'] as String,
        type: json['type'] as String,
        sampleHook: json['sampleHook'] as String?,
        sections: (json['sections'] as List)
            .map((s) => SongSection.fromJson(s as Map<String, dynamic>))
            .toList(),
        instruments: List<String>.from(json['instruments'] as List),
        hasUserLyrics: json['hasUserLyrics'] as bool? ?? false,
      );
}
