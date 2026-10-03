import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../services/storage_service.dart';
import '../../utils/errors.dart';
import '../../utils/video_duration.dart';
import '../../widgets/responsive_page.dart';
import '../../widgets/user_avatar.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _imageBytes;
  String? _imageName;

  Uint8List? _videoBytes;
  String? _videoName;

  bool _publishing = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  bool get _hasMedia => _imageBytes != null || _videoBytes != null;

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _imageName = picked.name;
        _videoBytes = null;
        _videoName = null;
      });
    } catch (_) {
      if (mounted) _showMessage('تعذّر اختيار الصورة');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final picked = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 1),
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final withinLimit = await isVideoWithinLimit(picked.path, bytes: bytes);
      if (!withinLimit) {
        if (mounted) _showMessage('الفيديو يجب ألا يتجاوز دقيقة واحدة');
        return;
      }
      if (!mounted) return;
      setState(() {
        _videoBytes = bytes;
        _videoName = picked.name;
        _imageBytes = null;
        _imageName = null;
      });
    } catch (_) {
      if (mounted) _showMessage('تعذّر اختيار الفيديو');
    }
  }

  Future<void> _publish() async {
    final content = _contentController.text.trim();
    if (content.isEmpty && !_hasMedia) {
      _showMessage('اكتب محتوى أو أضف صورة أو فيديو أولاً');
      return;
    }

    setState(() => _publishing = true);
    try {
      final storage = context.read<StorageService>();
      final posts = context.read<PostService>();

      String? imageUrl;
      String? videoUrl;
      if (_imageBytes != null) {
        imageUrl = await storage.uploadPostImage(
          bytes: _imageBytes!,
          fileName: _imageName ?? 'post_image.jpg',
        );
      } else if (_videoBytes != null) {
        videoUrl = await storage.uploadPostVideo(
          bytes: _videoBytes!,
          fileName: _videoName ?? 'post_video.mp4',
        );
      }

      await posts.createPost(
        content: content,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم نشر المنشور بنجاح')),
        );
      }
    } catch (error) {
      if (mounted) _showMessage(translateSupabaseError(error));
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final auth = context.watch<AuthService>();
    final canPublish = !_publishing &&
        (_contentController.text.trim().isNotEmpty || _hasMedia);

    return Scaffold(
      appBar: AppBar(
        title: const Text('منشور جديد'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextButton(
              onPressed: canPublish ? _publish : null,
              child: _publishing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text(
                      'نشر',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: ResponsivePage(
        maxWidth: 720,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    UserAvatar(profile: auth.profile, radius: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.profile?.displayName ?? 'كشاف',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'منشور جديد · متاح للجميع',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _contentController,
                      maxLines: 6,
                      minLines: 3,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'مشاركة خبر، فكرة، أو تجربة مع الفرقة...',
                        border: InputBorder.none,
                        filled: false,
                      ),
                    ),
                    if (_imageBytes != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            Image.memory(
                              _imageBytes!,
                              width: double.infinity,
                              height: 240,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton.filledTonal(
                                onPressed: () => setState(() {
                                  _imageBytes = null;
                                  _imageName = null;
                                }),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_videoBytes != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        height: 90,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.videocam_rounded,
                                color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'فيديو جديد: $_videoName',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: IconButton.filledTonal(
                                onPressed: () => setState(() {
                                  _videoBytes = null;
                                  _videoName = null;
                                }),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        TextButton.icon(
                          onPressed: _publishing ? null : _pickImage,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: Text(
                              _imageBytes == null ? 'إضافة صورة' : 'تغيير الصورة'),
                        ),
                        TextButton.icon(
                          onPressed: _publishing ? null : _pickVideo,
                          icon: const Icon(Icons.video_library_outlined),
                          label: Text(
                              _videoBytes == null ? 'إضافة فيديو (دقيقة)' : 'تغيير الفيديو'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: canPublish ? _publish : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.send_rounded),
              label: const Text(
                'نشر المنشور',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}