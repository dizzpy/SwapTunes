import 'package:flutter/material.dart';
import '../../data/models/playlist_model.dart';
import '../../data/models/source_platform.dart';
import '../../data/repositories/discover_repository.dart';

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

  // Single primary link — maps the stored primary_url to the correct platform slot
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

  factory PlaylistDetailData.fromModel(
    PlaylistModel model,
    String? currentUserId,
  ) {
    return PlaylistDetailData(
      id: model.id,
      name: model.name,
      description: model.description,
      coverImageUrl: model.coverImageUrl,
      trackCount: model.trackCount,
      sourcePlatform: model.sourcePlatform,
      isPublic: model.isPublic,
      genreTags: model.genreTags,
      ownerUsername: model.ownerUsername,
      ownerFullName: model.ownerFullName,
      ownerAvatarUrl: model.ownerAvatarUrl,
      isOwner: currentUserId != null && currentUserId == model.userId,
      createdAt: model.createdAt,
      spotifyUrl: model.sourcePlatform == SourcePlatform.spotify
          ? model.primaryUrl
          : null,
      youtubeMusicUrl: model.sourcePlatform == SourcePlatform.youtubeMusic
          ? model.primaryUrl
          : null,
      appleMusicUrl: model.sourcePlatform == SourcePlatform.appleMusic
          ? model.primaryUrl
          : null,
      soundcloudUrl: model.sourcePlatform == SourcePlatform.soundcloud
          ? model.primaryUrl
          : null,
    );
  }

  /// Returns only platforms that have a URL configured.
  List<MapEntry<SourcePlatform, String>> get activeLinks {
    final links = <MapEntry<SourcePlatform, String>>[];
    if (spotifyUrl != null)
      links.add(MapEntry(SourcePlatform.spotify, spotifyUrl!));
    if (youtubeMusicUrl != null)
      links.add(MapEntry(SourcePlatform.youtubeMusic, youtubeMusicUrl!));
    if (appleMusicUrl != null)
      links.add(MapEntry(SourcePlatform.appleMusic, appleMusicUrl!));
    if (soundcloudUrl != null)
      links.add(MapEntry(SourcePlatform.soundcloud, soundcloudUrl!));
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
  final DiscoverRepository _repository;
  final String playlistId;
  final String? currentUserId;

  bool _isLoading = true;
  bool _isDeleting = false;
  String? _error;
  PlaylistDetailData? _playlist;
  final List<TrackItem> _trackList = [];

  bool _isLiked = false;
  int _likeCount = 0;
  bool _isTogglingLike = false;

  bool get isLoading => _isLoading;
  bool get isDeleting => _isDeleting;
  String? get error => _error;
  PlaylistDetailData? get playlist => _playlist;
  List<TrackItem> get trackList => _trackList;
  bool get isLiked => _isLiked;
  int get likeCount => _likeCount;

  PlaylistDetailViewModel({
    required this.playlistId,
    required DiscoverRepository repository,
    this.currentUserId,
  }) : _repository = repository {
    _loadPlaylist();
  }

  Future<void> _loadPlaylist() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final model = await _repository.getPlaylist(playlistId);
      _playlist = PlaylistDetailData.fromModel(model, currentUserId);
      _isLiked = model.isLiked;
      _likeCount = model.likesCount;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> retry() => _loadPlaylist();

  Future<void> toggleLike() async {
    if (_isTogglingLike) return;
    _isTogglingLike = true;

    // Optimistic update
    final wasLiked = _isLiked;
    _isLiked = !_isLiked;
    _likeCount += _isLiked ? 1 : -1;
    notifyListeners();

    try {
      if (_isLiked) {
        await _repository.likePlaylist(playlistId);
      } else {
        await _repository.unlikePlaylist(playlistId);
      }
    } catch (_) {
      // Revert on failure
      _isLiked = wasLiked;
      _likeCount += wasLiked ? 1 : -1;
      notifyListeners();
    }

    _isTogglingLike = false;
  }

  Future<bool> deletePlaylist() async {
    if (_isDeleting) return false;
    _isDeleting = true;
    notifyListeners();

    try {
      await _repository.deletePlaylist(playlistId);
      _isDeleting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isDeleting = false;
      notifyListeners();
      return false;
    }
  }
}
