import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../shared/widgets/wavy_prograss_indicator.dart';
import '../../data/models/full_profile_model.dart';
import '../../data/repositories/profile_repository.dart';

/// Edit profile screen — reached by tapping "Edit Profile" button.
///
/// Allows editing name, bio, username (7-day cooldown), genres,
/// avatar and cover images.
/// Optimistic save: updates parent viewmodel immediately, patches API in background.
class EditProfileScreen extends StatefulWidget {
  final FullProfileModel profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _usernameCtrl;

  String? _pendingAvatarUrl;
  bool _isUploadingAvatar = false;
  bool _isSaving = false;
  String? _errorMessage;
  late List<String> _genres;

  static const _commonGenres = [
    'Pop',
    'Rock',
    'Hip-Hop',
    'R&B',
    'Jazz',
    'Classical',
    'Electronic',
    'Indie',
    'Dubstep',
    'House',
    'Techno',
    'Soul',
    'Blues',
    'Country',
    'Reggae',
    'Metal',
    'Folk',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.fullName);
    _bioCtrl = TextEditingController(text: widget.profile.bio ?? '');
    _usernameCtrl = TextEditingController(text: widget.profile.username);
    _genres = List<String>.from(widget.profile.genres);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  String get _effectiveAvatarUrl =>
      _pendingAvatarUrl ?? widget.profile.avatarUrl ?? '';

  bool get _isBusy => _isSaving || _isUploadingAvatar;

  int get _usernameCooldownDays => widget.profile.usernameChangeCooldownDays;

  Future<void> _onAvatarTap() async {
    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.cardFront,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            if (_effectiveAvatarUrl.isNotEmpty)
              ListTile(
                leading: const Icon(
                  Icons.image_outlined,
                  color: AppColors.textWhite,
                ),
                title: Text('View photo', style: AppTextStyles.bodyPrimary),
                onTap: () {
                  Navigator.pop(ctx);
                  _showFullImage();
                },
              ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.primary,
              ),
              title: Text(
                'Choose from library',
                style: AppTextStyles.bodyPrimary.copyWith(
                  color: AppColors.primary,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUpload(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.primary,
              ),
              title: Text(
                'Take a photo',
                style: AppTextStyles.bodyPrimary.copyWith(
                  color: AppColors.primary,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUpload(ImageSource.camera);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showFullImage() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: _effectiveAvatarUrl.isNotEmpty
                ? InteractiveViewer(child: Image.network(_effectiveAvatarUrl))
                : const Icon(
                    Icons.person,
                    color: AppColors.textSecondary,
                    size: 80,
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 90);
    if (file == null || !mounted) return;

    setState(() {
      _isUploadingAvatar = true;
      _errorMessage = null;
    });
    try {
      final url = await context.read<ProfileRepository>().uploadImage(file);
      if (mounted) setState(() => _pendingAvatarUrl = url);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Upload failed. Try again.');
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  void _toggleGenre(String genre) {
    setState(() {
      if (_genres.contains(genre)) {
        _genres.remove(genre);
      } else {
        _genres.add(genre);
      }
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Name cannot be empty.');
      return;
    }

    final newUsername = _usernameCtrl.text.trim();
    final usernameChanged =
        newUsername != widget.profile.username && newUsername.isNotEmpty;

    if (usernameChanged && _usernameCooldownDays > 0) {
      setState(
        () => _errorMessage =
            'Username can be changed in $_usernameCooldownDays day${_usernameCooldownDays == 1 ? '' : 's'}.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await context.read<ProfileRepository>().updateProfile(
        fullName: name != widget.profile.fullName ? name : null,
        bio: _bioCtrl.text.trim() != (widget.profile.bio ?? '')
            ? _bioCtrl.text.trim()
            : null,
        avatarUrl: _pendingAvatarUrl,
        username: usernameChanged ? newUsername : null,
        genres: _genres != widget.profile.genres ? _genres : null,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        final msg = e is Map
            ? (e['message'] ?? 'Save failed.')
            : 'Save failed. Try again.';
        setState(() => _errorMessage = msg.toString());
        AppSnackbar.error(msg.toString());
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Profile', style: AppTextStyles.bodyPrimary),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isBusy ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: WavyCircularIndicator(
                      color: AppColors.primary,
                      size: 18,
                    ),
                  )
                : Text(
                    'Save',
                    style: AppTextStyles.bodyPrimary.copyWith(
                      color: _isBusy
                          ? AppColors.textSecondary
                          : AppColors.primary,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            GestureDetector(
              onTap: _isUploadingAvatar ? null : _onAvatarTap,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.cardFront,
                      border: Border.all(color: AppColors.outline, width: 2),
                      image: _effectiveAvatarUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(_effectiveAvatarUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _isUploadingAvatar
                        ? const WavyCircularIndicator(
                            color: AppColors.primary,
                            size: 40,
                          )
                        : _effectiveAvatarUrl.isEmpty
                        ? const Icon(
                            Icons.person,
                            color: AppColors.textSecondary,
                            size: 48,
                          )
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to change photo',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // Error
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _errorMessage!,
                  style: AppTextStyles.bodySecondary70.copyWith(
                    color: AppColors.danger,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Name
            _buildField(
              label: 'Name',
              controller: _nameCtrl,
              hint: 'Your full name',
            ),
            const SizedBox(height: 16),

            // Username
            _buildField(
              label: 'Username',
              controller: _usernameCtrl,
              hint: 'your_username',
              enabled: _usernameCooldownDays == 0,
              suffixText: _usernameCooldownDays > 0
                  ? 'Available in $_usernameCooldownDays day${_usernameCooldownDays == 1 ? '' : 's'}'
                  : null,
            ),
            const SizedBox(height: 16),

            // Bio
            _buildField(
              label: 'Bio',
              controller: _bioCtrl,
              hint: 'Tell people about yourself',
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // Genre Tags
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Genres',
                style: AppTextStyles.bodySecondary70.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonGenres.map((genre) {
                final selected = _genres.contains(genre);
                return GestureDetector(
                  onTap: () => _toggleGenre(genre),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.cardFront,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.outline,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      '#$genre',
                      style: AppTextStyles.bodySecondary70.copyWith(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    bool enabled = true,
    String? suffixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySecondary70.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          enabled: enabled,
          style: AppTextStyles.bodyPrimary.copyWith(
            color: enabled ? AppColors.textWhite : AppColors.textSecondary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodySecondary70,
            suffixText: suffixText,
            suffixStyle: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: enabled ? AppColors.cardFront : AppColors.outline,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.outline),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
