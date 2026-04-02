import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../../../shared/widgets/input_box.dart';
import '../../data/models/collab_model.dart';
import '../viewmodels/collab_viewmodel.dart';
import '../widgets/tag_chip.dart';

/// Screen for creating or editing a collaboration post.
///
/// Pass [existingCollab] to enter edit mode with pre-filled values.
class NewCollaborationScreen extends StatefulWidget {
  final CollabModel? existingCollab;

  const NewCollaborationScreen({super.key, this.existingCollab});

  @override
  State<NewCollaborationScreen> createState() => _NewCollaborationScreenState();
}

class _NewCollaborationScreenState extends State<NewCollaborationScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  String? _titleError;
  String? _descriptionError;

  bool get _isEditMode => widget.existingCollab != null;

  static const List<String> _lookingForOptions = [
    'Vocalist',
    'Producer',
    'Mixing',
    'Mastering',
    'Songwriter',
    'Instrumentalist',
  ];

  static const List<String> _genreOptions = [
    'Pop',
    'Rock',
    'Hip-Hop',
    'R&B',
    'Jazz',
    'Electronic',
    'Classical',
    'Country',
  ];

  static const List<({String label, String desc, String value})> _projectTypes =
      [
        (label: 'Paid Project', desc: 'Direct payment for work', value: 'paid'),
        (
          label: 'Revenue Share',
          desc: 'Share profits from the project',
          value: 'revenue_share',
        ),
        (
          label: 'For Fun/Experience',
          desc: 'Non-commercial collaboration',
          value: 'free',
        ),
      ];

  late final List<String> _selectedLookingFor;
  late final List<String> _selectedGenres;
  late String _paymentType;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingCollab;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    _selectedLookingFor = existing != null
        ? List.from(existing.lookingFor)
        : [];
    _selectedGenres = existing != null ? List.from(existing.genreStyle) : [];
    _paymentType = existing?.paymentType ?? 'revenue_share';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CollabViewmodel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: AppIconButton(
            icon: AppAssets.icon.arrowLeft,
            variant: AppIconButtonVariant.empty,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
        title: Text(
          _isEditMode
              ? AppStrings.collab.editCollabTitle
              : AppStrings.collab.newCollabTitle,
          style: AppTextStyles.heading3,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InputBox(
              title: AppStrings.collab.titleFieldLabel,
              hintText: AppStrings.collab.titleFieldHint,
              controller: _titleController,
              errorMessage: _titleError,
            ),
            const SizedBox(height: 24),
            InputBox(
              title: AppStrings.collab.descriptionFieldLabel,
              hintText: AppStrings.collab.descriptionFieldHint,
              isMultiLine: true,
              controller: _descriptionController,
              errorMessage: _descriptionError,
            ),
            const SizedBox(height: 28),
            _SectionHeader(
              title: AppStrings.collab.lookingForSectionTitle,
              subtitle: AppStrings.collab.lookingForSectionSubtitle,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _lookingForOptions.map((opt) {
                final isSelected = _selectedLookingFor.contains(opt);
                return TagChip(
                  label: opt,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedLookingFor.remove(opt);
                      } else {
                        _selectedLookingFor.add(opt);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            _SectionHeader(
              title: AppStrings.collab.genreSectionTitle,
              subtitle: AppStrings.collab.genreSectionSubtitle,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _genreOptions.map((opt) {
                final isSelected = _selectedGenres.contains(opt);
                final canSelect = _selectedGenres.length < 3 || isSelected;
                return TagChip(
                  label: opt,
                  isSelected: isSelected,
                  onTap: canSelect
                      ? () {
                          setState(() {
                            if (isSelected) {
                              _selectedGenres.remove(opt);
                            } else {
                              _selectedGenres.add(opt);
                            }
                          });
                        }
                      : null,
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            _SectionHeader(
              title: AppStrings.collab.projectTypeSectionTitle,
              subtitle: AppStrings.collab.projectTypeSectionSubtitle,
            ),
            const SizedBox(height: 12),
            ..._projectTypes.map(
              (pt) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ProjectTypeOption(
                  label: pt.label,
                  description: pt.desc,
                  value: pt.value,
                  isSelected: _paymentType == pt.value,
                  onTap: () => setState(() => _paymentType = pt.value),
                ),
              ),
            ),
            const SizedBox(height: 36),
            Opacity(
              opacity: vm.isCreating ? 0.6 : 1.0,
              child: IgnorePointer(
                ignoring: vm.isCreating,
                child: GreenButton(
                  text: vm.isCreating
                      ? ''
                      : (_isEditMode
                            ? AppStrings.collab.editButton
                            : AppStrings.collab.postButton),
                  height: 56,
                  icon: vm.isCreating
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                  onPressed: _submit,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    var valid = true;
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.length < 5) {
      setState(() => _titleError = AppStrings.collab.titleRequired);
      valid = false;
    } else {
      setState(() => _titleError = null);
    }

    if (description.length < 10) {
      setState(() => _descriptionError = AppStrings.collab.descriptionRequired);
      valid = false;
    } else {
      setState(() => _descriptionError = null);
    }

    if (!valid) return;

    if (_selectedLookingFor.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.collab.lookingForRequired),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final vm = context.read<CollabViewmodel>();

    bool success;
    if (_isEditMode) {
      success = await vm.updateCollab(
        id: widget.existingCollab!.id,
        title: title,
        description: description,
        lookingFor: List.from(_selectedLookingFor),
        genreStyle: List.from(_selectedGenres),
        paymentType: _paymentType,
      );
    } else {
      success = await vm.createCollab(
        title: title,
        description: description,
        lookingFor: List.from(_selectedLookingFor),
        genreStyle: List.from(_selectedGenres),
        paymentType: _paymentType,
      );
    }

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? AppStrings.collab.editSuccess
                : AppStrings.collab.postSuccess,
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            vm.createError ??
                (_isEditMode
                    ? AppStrings.collab.editError
                    : AppStrings.collab.postError),
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.bodyPrimary.copyWith(fontSize: 17)),
        const SizedBox(height: 4),
        Text(subtitle, style: AppTextStyles.bodySecondary),
      ],
    );
  }
}

class _ProjectTypeOption extends StatelessWidget {
  final String label;
  final String description;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProjectTypeOption({
    required this.label,
    required this.description,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  IconData get _icon {
    switch (value) {
      case 'paid':
        return Icons.attach_money_rounded;
      case 'revenue_share':
        return Icons.trending_up_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardFront,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.bodyPrimary),
                  const SizedBox(height: 2),
                  Text(description, style: AppTextStyles.bodySecondary),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.outline,
                  width: 2,
                ),
                color: isSelected ? AppColors.primary : AppColors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: AppColors.textWhite,
                      size: 14,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
