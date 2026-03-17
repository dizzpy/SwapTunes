import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  bool _canPost = false;

  @override
  void initState() {
    super.initState();
    _captionController.addListener(_updateCanPost);
  }

  void _updateCanPost() {
    setState(() {
      _canPost =
          _captionController.text.trim().isNotEmpty ||
          _selectedImages.isNotEmpty;
    });
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
          _updateCanPost();
        });
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _updateCanPost();
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: HugeIcon(
            icon: AppAssets.icon.close,
            color: AppColors.textWhite,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          AppStrings.feed.createPostTitle,
          style: AppTextStyles.heading3,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            child: TextButton(
              onPressed: _canPost
                  ? () {
                      // TODO: Implement publishing
                      Navigator.pop(context);
                    }
                  : null,
              style: TextButton.styleFrom(
                backgroundColor: _canPost
                    ? AppColors.primary
                    : AppColors.cardFront,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: Text(
                AppStrings.feed.publishBtn,
                style: AppTextStyles.bodyPrimary.copyWith(
                  color: _canPost
                      ? AppColors.background
                      : AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Hero(
                        tag: 'post_creator_avatar',
                        child: const CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(
                            'https://i.pinimg.com/736x/d0/f7/85/d0f78534886dae30e4abad239214b999.jpg',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dizzpy Sanchez',
                            style: AppTextStyles.bodyPrimary.copyWith(
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Public',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _captionController,
                    maxLines: null,
                    style: AppTextStyles.bodyPrimary.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: InputDecoration(
                      hintText: AppStrings.feed.postHint,
                      hintStyle: AppTextStyles.bodySecondary.copyWith(
                        fontSize: 18,
                      ),
                      border: InputBorder.none,
                    ),
                    autofocus: true,
                  ),
                  if (_selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                width: 160,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  image: DecorationImage(
                                    image: FileImage(
                                      File(_selectedImages[index].path),
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Attachment Bar
          Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 10,
              top: 10,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: AppColors.cardFront,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _AttachmentIcon(
                      icon: AppAssets.icon.gallery,
                      label: 'Gallery',
                      onTap: _pickImages,
                    ),
                    const Spacer(),
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedMagicWand01,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentIcon extends StatelessWidget {
  final dynamic icon;
  final String label;
  final VoidCallback onTap;

  const _AttachmentIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 20),
        child: HugeIcon(icon: icon, color: AppColors.textWhite, size: 24),
      ),
    );
  }
}
