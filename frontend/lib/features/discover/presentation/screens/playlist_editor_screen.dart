import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../data/models/source_platform.dart';
import '../../data/repositories/discover_repository.dart';
import '../viewmodels/playlist_editor_viewmodel.dart';

class PlaylistEditorScreen extends StatelessWidget {
  /// Non-null = edit mode with pre-populated fields.
  final String? playlistId;

  /// Pre-selected platform (set when coming from Spotify import).
  final SourcePlatform? initialPlatform;

  /// Pre-filled primary URL (set when coming from Spotify import).
  final String? initialPrimaryUrl;

  /// Suggested genre tags from Spotify API (shown as tap-to-add chips).
  final List<String> suggestedGenres;

  /// Suggested artists from Spotify playlist tracks.
  final List<String> suggestedArtists;

  const PlaylistEditorScreen({
    super.key,
    this.playlistId,
    this.initialPlatform,
    this.initialPrimaryUrl,
    this.suggestedGenres = const [],
    this.suggestedArtists = const [],
  });

  bool get _isEditMode => playlistId != null;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => PlaylistEditorViewModel(
        repository: ctx.read<DiscoverRepository>(),
        playlistId: playlistId,
        initialPlatform: initialPlatform,
        initialPrimaryUrl: initialPrimaryUrl,
        suggestedGenres: suggestedGenres,
        suggestedArtists: suggestedArtists,
      ),
      child: _PlaylistEditorContent(isEditMode: _isEditMode),
    );
  }
}

class _PlaylistEditorContent extends StatefulWidget {
  final bool isEditMode;

  const _PlaylistEditorContent({required this.isEditMode});

  @override
  State<_PlaylistEditorContent> createState() => _PlaylistEditorContentState();
}

class _PlaylistEditorContentState extends State<_PlaylistEditorContent> {
  final _genreController = TextEditingController();
  final _artistController = TextEditingController();

  @override
  void dispose() {
    _genreController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PlaylistEditorViewModel>();
    final title = widget.isEditMode
        ? AppStrings.discover.editPlaylistTitle
        : AppStrings.discover.createPlaylistTitle;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, title),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1 — Cover image picker
            _buildCoverImagePicker(viewModel),
            const SizedBox(height: 28),

            // 2 — Basic info
            _buildSectionLabel(AppStrings.discover.playlistNameLabel),
            const SizedBox(height: 10),
            _buildTextField(
              hint: AppStrings.discover.playlistNameHint,
              onChanged: viewModel.setName,
              errorText: viewModel.nameError,
            ),
            const SizedBox(height: 16),
            _buildSectionLabel(AppStrings.discover.descriptionLabel),
            const SizedBox(height: 10),
            _buildTextField(
              hint: AppStrings.discover.descriptionHint,
              maxLines: 3,
              onChanged: viewModel.setDescription,
            ),
            const SizedBox(height: 28),

            // 3 — Platform selector
            _buildSectionLabel(AppStrings.discover.sourcePlatformLabel),
            const SizedBox(height: 10),
            _buildPlatformSelector(viewModel),
            if (viewModel.platformError != null) ...[
              const SizedBox(height: 6),
              Text(
                viewModel.platformError!,
                style: AppTextStyles.caption.copyWith(color: AppColors.danger),
              ),
            ],
            const SizedBox(height: 28),

            // 4 — Primary link input (shown only after platform is selected)
            _buildSectionLabel(AppStrings.discover.primaryLinkLabel),
            const SizedBox(height: 10),
            _buildPrimaryLinkInput(viewModel),
            const SizedBox(height: 28),

            // 5 — Categorization
            _buildSectionLabel(AppStrings.discover.categorizationLabel),
            const SizedBox(height: 16),

            _buildSubSectionLabel(AppStrings.discover.genreTagsLabel),
            const SizedBox(height: 10),
            _buildChipInput(
              controller: _genreController,
              hint: AppStrings.discover.addGenreHint,
              tags: viewModel.genreTags,
              suggestions: viewModel.suggestedGenres,
              onAdd: (tag) {
                viewModel.addGenreTag(tag);
                _genreController.clear();
              },
              onRemove: viewModel.removeGenreTag,
            ),
            const SizedBox(height: 16),

            _buildSubSectionLabel(AppStrings.discover.featuredArtistsLabel),
            const SizedBox(height: 10),
            _buildChipInput(
              controller: _artistController,
              hint: AppStrings.discover.addArtistHint,
              tags: viewModel.artists,
              suggestions: viewModel.suggestedArtists,
              onAdd: (name) {
                viewModel.addArtist(name);
                _artistController.clear();
              },
              onRemove: viewModel.removeArtist,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                _buildSubSectionLabel(AppStrings.discover.moodLabel),
                const SizedBox(width: 8),
                Text(
                  AppStrings.discover.moodSubtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildSelectableChipGrid(
              options: kMoodTags,
              selected: viewModel.moodTags,
              onToggle: viewModel.toggleMoodTag,
              maxSelect: 3,
            ),
            const SizedBox(height: 16),

            _buildSubSectionLabel(AppStrings.discover.eraLabel),
            const SizedBox(height: 10),
            _buildDropdown(
              value: viewModel.era,
              options: kEraOptions,
              onChanged: viewModel.setEra,
            ),
            const SizedBox(height: 16),

            _buildSubSectionLabel(AppStrings.discover.energyLabel),
            const SizedBox(height: 10),
            _buildSegmentedSelector(
              options: kEnergyOptions,
              selected: viewModel.energyLevel,
              onSelect: viewModel.setEnergyLevel,
            ),
            const SizedBox(height: 16),

            _buildSubSectionLabel(AppStrings.discover.occasionLabel),
            const SizedBox(height: 10),
            _buildSelectableChipGrid(
              options: kOccasionTags,
              selected: viewModel.occasionTags,
              onToggle: viewModel.toggleOccasionTag,
            ),
            const SizedBox(height: 16),

            _buildSubSectionLabel(AppStrings.discover.vocalStyleLabel),
            const SizedBox(height: 10),
            _buildSegmentedSelector(
              options: kVocalStyleOptions,
              selected: viewModel.vocalStyle,
              onSelect: viewModel.setVocalStyle,
            ),
            const SizedBox(height: 16),

            _buildSubSectionLabel(AppStrings.discover.languageLabel),
            const SizedBox(height: 10),
            _buildDropdown(
              value: viewModel.language,
              options: kLanguageOptions,
              onChanged: viewModel.setLanguage,
            ),
            const SizedBox(height: 28),

            // 6 — Visibility
            _buildSectionLabel(AppStrings.discover.visibilityLabel),
            const SizedBox(height: 10),
            _buildVisibilityToggle(viewModel),
            const SizedBox(height: 32),

            _buildSubmitButton(context, viewModel),
          ],
        ),
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────

  AppBar _buildAppBar(BuildContext context, String title) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.cardFront,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outline),
          ),
          child: const Center(
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: AppColors.textWhite,
              size: 20,
            ),
          ),
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.heading3.copyWith(color: AppColors.textWhite),
      ),
    );
  }

  // ── Cover image ───────────────────────────────────────────────────────────

  Widget _buildCoverImagePicker(PlaylistEditorViewModel viewModel) {
    return Center(
      child: GestureDetector(
        onTap: () {
          AppHaptics.buttonTap();
          _showCoverImageSheet(context, viewModel);
        },
        child: Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            color: AppColors.cardFront,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.outline, width: 1.5),
          ),
          child: viewModel.isUploadingImage
              ? const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primary,
                    ),
                  ),
                )
              : viewModel.coverImageUrl != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(19),
                      child: Image.network(
                        viewModel.coverImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildCoverPlaceholder(),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () {
                          AppHaptics.buttonTap();
                          viewModel.removeCoverImage();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.background.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const HugeIcon(
                            icon: HugeIcons.strokeRoundedCancel01,
                            color: AppColors.textWhite,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : _buildCoverPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildCoverPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const HugeIcon(
          icon: HugeIcons.strokeRoundedImage02,
          color: AppColors.textSecondary,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.discover.coverImageLabel,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  void _showCoverImageSheet(
    BuildContext context,
    PlaylistEditorViewModel viewModel,
  ) {
    AppHaptics.sheetOpen();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.cardFront,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Cover Image',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.textWhite,
                ),
              ),
              const SizedBox(height: 20),
              _CoverImageOption(
                icon: HugeIcons.strokeRoundedImage01,
                label: 'Choose from Gallery',
                onTap: () {
                  Navigator.pop(context);
                  _pickCoverImage(viewModel, ImageSource.gallery);
                },
              ),
              const SizedBox(height: 10),
              _CoverImageOption(
                icon: HugeIcons.strokeRoundedCamera01,
                label: 'Take a Photo',
                onTap: () {
                  Navigator.pop(context);
                  _pickCoverImage(viewModel, ImageSource.camera);
                },
              ),
              if (viewModel.coverImageUrl != null) ...[
                const SizedBox(height: 10),
                _CoverImageOption(
                  icon: HugeIcons.strokeRoundedDelete01,
                  label: 'Remove Image',
                  isDanger: true,
                  onTap: () {
                    Navigator.pop(context);
                    viewModel.removeCoverImage();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickCoverImage(
    PlaylistEditorViewModel viewModel,
    ImageSource source,
  ) async {
    final success = await viewModel.pickCoverImage(source);
    if (!success && mounted) {
      AppSnackbar.error('Failed to upload cover image');
    }
  }

  // ── Platform selector ─────────────────────────────────────────────────────

  Widget _buildPlatformSelector(PlaylistEditorViewModel viewModel) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: SourcePlatform.values.map((platform) {
        final isSelected = viewModel.sourcePlatform == platform;
        return GestureDetector(
          onTap: () {
            AppHaptics.buttonTap();
            viewModel.setSourcePlatform(platform);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? platform.color.withValues(alpha: 0.15)
                  : AppColors.cardFront,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? platform.color : AppColors.outline,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: platform.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  platform.displayName,
                  style: AppTextStyles.bodySecondaryWhite.copyWith(
                    color: isSelected
                        ? platform.color
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Primary link input ────────────────────────────────────────────────────

  Widget _buildPrimaryLinkInput(PlaylistEditorViewModel viewModel) {
    if (viewModel.sourcePlatform == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardFront,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedLink01,
              color: AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 12),
            Text(
              AppStrings.discover.noPlatformSelected,
              style: AppTextStyles.bodySecondaryWhite.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final platform = viewModel.sourcePlatform!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary link field
        TextField(
          onChanged: viewModel.setPrimaryUrl,
          controller: TextEditingController.fromValue(
            TextEditingValue(
              text: viewModel.primaryUrl,
              selection: TextSelection.collapsed(
                offset: viewModel.primaryUrl.length,
              ),
            ),
          ),
          style: AppTextStyles.bodySecondaryWhite.copyWith(
            color: AppColors.textWhite,
          ),
          decoration: InputDecoration(
            hintText: viewModel.primaryUrlHint,
            hintStyle: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: platform.color,
                shape: BoxShape.circle,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 36),
            filled: true,
            fillColor: AppColors.cardFront,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color:
                    (viewModel.primaryUrlError ?? viewModel.linkError) != null
                    ? AppColors.danger
                    : AppColors.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color:
                    (viewModel.primaryUrlError ?? viewModel.linkError) != null
                    ? AppColors.danger
                    : platform.color,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),

        // Inline validation error
        if (viewModel.primaryUrlError != null ||
            viewModel.linkError != null) ...[
          const SizedBox(height: 6),
          Text(
            viewModel.primaryUrlError ?? viewModel.linkError!,
            style: AppTextStyles.caption.copyWith(color: AppColors.danger),
          ),
        ],
      ],
    );
  }

  // ── Chip input with suggestions ───────────────────────────────────────────

  Widget _buildChipInput({
    required TextEditingController controller,
    required String hint,
    required List<String> tags,
    required List<String> suggestions,
    required ValueChanged<String> onAdd,
    required ValueChanged<String> onRemove,
  }) {
    // Suggestions that haven't been added yet
    final pendingSuggestions = suggestions
        .where((s) => !tags.contains(s))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Suggested chips row
        if (pendingSuggestions.isNotEmpty) ...[
          Row(
            children: [
              Text(
                AppStrings.discover.suggested,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: pendingSuggestions.map((s) {
                    return GestureDetector(
                      onTap: () {
                        AppHaptics.buttonTap();
                        onAdd(s);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedAdd01,
                              color: AppColors.primary,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              s,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],

        // Manual input row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: AppTextStyles.bodySecondaryWhite.copyWith(
                  color: AppColors.textWhite,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppColors.cardFront,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) onAdd(value);
                },
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                if (controller.text.trim().isNotEmpty) {
                  AppHaptics.buttonTap();
                  onAdd(controller.text);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedAdd01,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),

        // Added chips
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags
                .map(
                  (tag) => _buildRemovableChip(
                    label: tag,
                    onRemove: () => onRemove(tag),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildRemovableChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedCancel01,
              color: AppColors.primary,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ── Selectable chip grid ──────────────────────────────────────────────────

  Widget _buildSelectableChipGrid({
    required List<String> options,
    required List<String> selected,
    required ValueChanged<String> onToggle,
    int? maxSelect,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        final isDisabled =
            maxSelect != null && !isSelected && selected.length >= maxSelect;

        return GestureDetector(
          onTap: isDisabled
              ? null
              : () {
                  AppHaptics.buttonTap();
                  onToggle(option);
                },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.cardFront,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : isDisabled
                    ? AppColors.outline.withValues(alpha: 0.4)
                    : AppColors.outline,
              ),
            ),
            child: Text(
              option,
              style: AppTextStyles.caption.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : isDisabled
                    ? AppColors.textSecondary.withValues(alpha: 0.5)
                    : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Segmented selector ────────────────────────────────────────────────────

  Widget _buildSegmentedSelector({
    required List<String> options,
    required String? selected,
    required ValueChanged<String?> onSelect,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardFront,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: options.map((option) {
          final isSelected = selected == option;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                AppHaptics.buttonTap();
                onSelect(isSelected ? null : option);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    option,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected
                          ? AppColors.background
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Dropdown ──────────────────────────────────────────────────────────────

  Widget _buildDropdown({
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardFront,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      child: DropdownButton<String>(
        value: value,
        hint: Text(
          'Select...',
          style: AppTextStyles.bodySecondaryWhite.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        dropdownColor: AppColors.cardFront,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedArrowDown01,
          color: AppColors.textSecondary,
          size: 18,
        ),
        style: AppTextStyles.bodySecondaryWhite.copyWith(
          color: AppColors.textWhite,
        ),
        items: options
            .map(
              (option) => DropdownMenuItem(value: option, child: Text(option)),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  // ── Visibility toggle ─────────────────────────────────────────────────────

  Widget _buildVisibilityToggle(PlaylistEditorViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardFront,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          _VisibilityOption(
            label: AppStrings.discover.publicLabel,
            icon: HugeIcons.strokeRoundedGlobe02,
            isSelected: viewModel.isPublic,
            onTap: () {
              AppHaptics.buttonTap();
              viewModel.setPublic(true);
            },
          ),
          _VisibilityOption(
            label: AppStrings.discover.privateLabel,
            icon: HugeIcons.strokeRoundedLockKey,
            isSelected: !viewModel.isPublic,
            onTap: () {
              AppHaptics.buttonTap();
              viewModel.setPublic(false);
            },
          ),
        ],
      ),
    );
  }

  // ── Submit button ─────────────────────────────────────────────────────────

  Widget _buildSubmitButton(
    BuildContext context,
    PlaylistEditorViewModel viewModel,
  ) {
    final label = widget.isEditMode
        ? AppStrings.discover.saveChangesBtn
        : AppStrings.discover.publishBtn;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: viewModel.isSaving
            ? null
            : () async {
                AppHaptics.buttonTap();
                final success = await viewModel.savePlaylist();
                if (!context.mounted) return;
                if (success) {
                  AppHaptics.success();
                  AppSnackbar.success(
                    widget.isEditMode
                        ? 'Playlist updated'
                        : 'Playlist published',
                  );
                  Navigator.pop(context, true);
                } else if (viewModel.error != null) {
                  // API / network error
                  AppSnackbar.error(AppStrings.discover.saveError);
                } else {
                  // Validation error — show first field error
                  final msg =
                      viewModel.nameError ??
                      viewModel.platformError ??
                      viewModel.linkError ??
                      AppStrings.discover.saveError;
                  AppSnackbar.error(msg);
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: viewModel.isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.background,
                ),
              )
            : Text(
                label,
                style: AppTextStyles.bodyPrimary.copyWith(
                  color: AppColors.background,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildTextField({
    required String hint,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
    String? errorText,
  }) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: onChanged,
          maxLines: maxLines,
          style: AppTextStyles.bodySecondaryWhite.copyWith(
            color: AppColors.textWhite,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodySecondaryWhite.copyWith(
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: AppColors.cardFront,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: hasError ? AppColors.danger : AppColors.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: hasError ? AppColors.danger : AppColors.primary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            errorText,
            style: AppTextStyles.caption.copyWith(color: AppColors.danger),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.bodyPrimary.copyWith(
        color: AppColors.textWhite,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSubSectionLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.bodySecondaryWhite.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ── Visibility option widget ──────────────────────────────────────────────────

class _VisibilityOption extends StatelessWidget {
  final String label;
  final dynamic icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _VisibilityOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                icon: icon,
                color: isSelected
                    ? AppColors.background
                    : AppColors.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.bodySecondaryWhite.copyWith(
                  color: isSelected
                      ? AppColors.background
                      : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverImageOption extends StatelessWidget {
  final dynamic icon;
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  const _CoverImageOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? AppColors.danger : AppColors.primary;
    return GestureDetector(
      onTap: () {
        AppHaptics.buttonTap();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            HugeIcon(icon: icon, color: color, size: 20),
            const SizedBox(width: 14),
            Text(
              label,
              style: AppTextStyles.bodyPrimary.copyWith(
                color: isDanger ? AppColors.danger : AppColors.textWhite,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
