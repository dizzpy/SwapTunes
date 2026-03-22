import 'package:flutter/material.dart';
import '../../data/models/source_platform.dart';

class TrackItem {
  final int index;
  final String title;
  final String artist;

  const TrackItem({
    required this.index,
    required this.title,
    required this.artist,
  });
}

class PlaylistDetailData {
  final String id;
  final String name;
  final String? description;
  final String? coverImageUrl;
  final int trackCount;
  final SourcePlatform sourcePlatform;
  final bool isPublic;
  final List<String> genreTags;
  final String ownerUsername;
  final String ownerFullName;
  final String? ownerAvatarUrl;
  final bool isOwner;
  final DateTime createdAt;

  // External links (null = platform not linked)
  final String? spotifyUrl;
  final String? youtubeMusicUrl;
  final String? appleMusicUrl;
  final String? soundcloudUrl;

  const PlaylistDetailData({
    required this.id,
    required this.name,
    this.description,
    this.coverImageUrl,
    required this.trackCount,
    required this.sourcePlatform,
    required this.isPublic,
    required this.genreTags,
    required this.ownerUsername,
    required this.ownerFullName,
    this.ownerAvatarUrl,
    required this.isOwner,
    required this.createdAt,
    this.spotifyUrl,
    this.youtubeMusicUrl,
    this.appleMusicUrl,
    this.soundcloudUrl,
  });

  /// Returns only platforms that have a URL configured.
  List<MapEntry<SourcePlatform, String>> get activeLinks {
    final links = <MapEntry<SourcePlatform, String>>[];
    if (spotifyUrl != null) {
      links.add(MapEntry(SourcePlatform.spotify, spotifyUrl!));
    }
    if (youtubeMusicUrl != null) {
      links.add(MapEntry(SourcePlatform.youtubeMusic, youtubeMusicUrl!));
    }
    if (appleMusicUrl != null) {
      links.add(MapEntry(SourcePlatform.appleMusic, appleMusicUrl!));
    }
    if (soundcloudUrl != null) {
      links.add(MapEntry(SourcePlatform.soundcloud, soundcloudUrl!));
    }
    return links;
  }

  /// Primary CTA link — source platform's URL first, then first available.
  MapEntry<SourcePlatform, String>? get primaryLink {
    if (activeLinks.isEmpty) return null;
    final sourceFirst = activeLinks.where((e) => e.key == sourcePlatform);
    return sourceFirst.isNotEmpty ? sourceFirst.first : activeLinks.first;
  }

  /// Secondary links excluding the primary one.
  List<MapEntry<SourcePlatform, String>> get secondaryLinks {
    final primary = primaryLink;
    if (primary == null) return [];
    return activeLinks.where((e) => e.key != primary.key).toList();
  }
}

class PlaylistDetailViewModel extends ChangeNotifier {
  final String playlistId;

  bool _isLoading = true;
  bool _isDeleting = false;
  bool _isLoadingTracks = false;
  String? _error;
  PlaylistDetailData? _playlist;
  List<TrackItem> _trackList = [];

  // Like state — will be synced with real API in data layer phase
  bool _isLiked = false;
  int _likeCount = 128;

  bool get isLoading => _isLoading;
  bool get isDeleting => _isDeleting;
  bool get isLoadingTracks => _isLoadingTracks;
  String? get error => _error;
  PlaylistDetailData? get playlist => _playlist;
  List<TrackItem> get trackList => _trackList;
  bool get isLiked => _isLiked;
  int get likeCount => _likeCount;

  PlaylistDetailViewModel({required this.playlistId}) {
    _loadPlaylist();
  }

  void toggleLike() {
    _isLiked = !_isLiked;
    _likeCount += _isLiked ? 1 : -1;
    notifyListeners();
  }

  Future<void> _loadPlaylist() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Simulates network call — will be wired to real API in data layer phase
    await Future.delayed(const Duration(milliseconds: 600));

    _playlist = PlaylistDetailData(
      id: playlistId,
      name: 'Heavy Bass Drops 2026',
      description:
          'The finest dubstep and bass music curated for high energy sessions. '
          'Updated weekly with fresh drops.',
      coverImageUrl: 'https://picsum.photos/seed/$playlistId/400/400',
      trackCount: 45,
      sourcePlatform: SourcePlatform.spotify,
      isPublic: true,
      genreTags: ['Dubstep', 'Bass', 'Electronic'],
      ownerUsername: 'skrillex',
      ownerFullName: 'Skrillex',
      ownerAvatarUrl: 'https://picsum.photos/seed/owner/100/100',
      isOwner: true,
      createdAt: DateTime(2026, 1, 15),
      spotifyUrl: 'https://open.spotify.com/playlist/abc123',
      youtubeMusicUrl: null,
      appleMusicUrl: null,
      soundcloudUrl: null,
    );

    _isLoading = false;
    notifyListeners();

    // Auto-load tracks if Spotify
    if (_playlist!.sourcePlatform == SourcePlatform.spotify) {
      _loadTracks();
    }
  }

  Future<void> _loadTracks() async {
    _isLoadingTracks = true;
    notifyListeners();

    // Simulates Spotify API tracklist call — real API wired in data layer phase
    await Future.delayed(const Duration(milliseconds: 800));

    _trackList = [
      const TrackItem(
        index: 1,
        title: 'Scary Monsters and Nice Sprites',
        artist: 'Skrillex',
      ),
      const TrackItem(
        index: 2,
        title: 'First of the Year (Equinox)',
        artist: 'Skrillex',
      ),
      const TrackItem(index: 3, title: 'Bass Cannon', artist: 'Flux Pavilion'),
      const TrackItem(
        index: 4,
        title: 'I Can\'t Stop',
        artist: 'Flux Pavilion',
      ),
      const TrackItem(index: 5, title: 'X Up', artist: 'Excision'),
      const TrackItem(
        index: 6,
        title: 'Throwin\' Elbows',
        artist: 'Excision & Datsik',
      ),
      const TrackItem(index: 7, title: 'Shambhala', artist: 'Virtual Riot'),
      const TrackItem(index: 8, title: 'Energy Drink', artist: 'Virtual Riot'),
      const TrackItem(index: 9, title: 'Collapse', artist: 'Zeds Dead'),
      const TrackItem(index: 10, title: 'Hadouken', artist: 'Feed Me'),
    ];

    _isLoadingTracks = false;
    notifyListeners();
  }

  Future<bool> deletePlaylist() async {
    _isDeleting = true;
    notifyListeners();

    // Simulates network call — will be wired to real API in data layer phase
    await Future.delayed(const Duration(milliseconds: 600));

    _isDeleting = false;
    notifyListeners();
    return true;
  }
}
