import '../../../profile/data/models/full_profile_model.dart';

/// Holds pre-fill data passed to [CreatorSetup] for re-activation.
///
/// Built from [CreatorProfile] (already on the FullProfileModel)
/// so no extra API call is needed.
class CreatorProfileForm {
  final String? roleTitle;
  final String? location;
  final List<String> specializations;
  final String? soundcloudUrl;
  final String? youtubeUrl;
  final String? spotifyArtistUrl;
  final String? appleMusicUrl;
  final String? portfolioUrl;

  const CreatorProfileForm({
    this.roleTitle,
    this.location,
    required this.specializations,
    this.soundcloudUrl,
    this.youtubeUrl,
    this.spotifyArtistUrl,
    this.appleMusicUrl,
    this.portfolioUrl,
  });

  factory CreatorProfileForm.fromCreatorProfile(CreatorProfile profile) {
    return CreatorProfileForm(
      roleTitle: profile.roleTitle,
      location: profile.location,
      specializations: profile.specializations,
      soundcloudUrl: profile.soundcloudUrl,
      youtubeUrl: profile.youtubeUrl,
      spotifyArtistUrl: profile.spotifyArtistUrl,
      appleMusicUrl: profile.appleMusicUrl,
      portfolioUrl: profile.portfolioUrl,
    );
  }
}
