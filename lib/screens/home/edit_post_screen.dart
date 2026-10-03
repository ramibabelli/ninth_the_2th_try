import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/post.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../services/storage_service.dart';
import '../../utils/errors.dart';
import '../../utils/video_duration.dart';
import '../../widgets/responsive_page.dart';
import '../../widgets/user_avatar.dart';

class EditPostScreen extends StatefulWidget {
  final Post post;

  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _contentController = TextEditingController(text: '');
  final _picker = ImagePicker();

  String? _imageUrl;
  String? _videoUrl;
  String? _pickedKind;
  Uint8List? _pickedBytes;
  String? _pickedName;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _contentController.text = widget.post.content;
    _imageUrl = widget.post.imageUrl;
    _videoUrl = widget.post.videoUrl;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  bool get _hasMedia =>
      (_imageUrl?.isNotEmpty ?? false) ||
      (_videoUrl?.isNotEmpty ?? false) ||
      _pickedBytes != null;

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
        _pickedKind = 'image';
        _pickedBytes = bytes;
        _pickedName = picked.name;
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
        _pickedKind = 'video';
        _pickedBytes = bytes;
        _pickedName = picked.name;
      });
    } catch (_) {
      if (mounted) _showMessage('تعذّر اختيار الفيديو');
    }
  }

  void _removeMedia() {
    setState(() {
      _imageUrl = null;
      _videoUrl = null;
      _pickedKind = null;
      _pickedBytes = null;
      _pickedName = null;
    });
  }

  Future<void> _save() async {
    final content = _contentController.text.trim();
    if (content.isEmpty && !_hasMedia) {
      _showMessage('اكتب محتوى أو أضف وسائط أولاً');
      return;
    }

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final storage = context.read<StorageService>();
      final posts = context.read<PostService>();

      String? finalImage = _imageUrl;
      String? finalVideo = _videoUrl;

      if (_pickedKind == 'image' && _pickedBytes != null) {
        finalImage = await storage.uploadPostImage(
            bytes: _pickedBytes!, fileName: _pickedName ?? 'post_image.jpg');
        finalVideo = null;
        await storage.deleteByPublicUrl(widget.post.imageUrl ?? '');
        await storage.deleteByPublicUrl(widget.post.videoUrl ?? '');
      } else if (_pickedKind == 'video' && _pickedBytes != null) {
        finalVideo = await storage.uploadPostVideo(
            bytes: _pickedBytes!, fileName: _pickedName ?? 'post_video.mp4');
        finalImage = null;
        await storage.deleteByPublicUrl(widget.post.imageUrl ?? '');
        await storage.deleteByPublicUrl(widget.post.videoUrl ?? '');
      } else if (_pickedKind == null) {
        await storage.deleteByPublicUrl(
            finalImage == null ? (widget.post.imageUrl ?? '') : '');
        await storage.deleteByPublicUrl(
            finalVideo == null ? (widget.post.videoUrl ?? '') : '');
      }

      await posts.updatePost(
        id: widget.post.id,
        content: content,
        imageUrl: finalImage,
        videoUrl: finalVideo,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('تم تعديل المنشور بنجاح')));
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(translateSupabaseError(error))));
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _mediaPreview() {
    final colorScheme = Theme.of(context).colorScheme;

    if (_pickedKind == 'image' && _pickedBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
          _pickedBytes!,
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    if (_pickedKind == 'video' && _pickedBytes != null) {
      return Container(
        height: 90,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_rounded, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text('فيديو جديد: $_pickedName'),
          ],
        ),
      );
    }

    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          _imageUrl!,
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            height: 220,
            color: colorScheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: Icon(Icons.broken_image_outlined,
                color: colorScheme.outline, size: 40),
          ),
        ),
      );
    }

    if (_videoUrl != null && _videoUrl!.isNotEmpty) {
      return Container(
        height: 90,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_rounded, color: colorScheme.primary),
            const SizedBox(width: 8),
            const Text('فيديو محفوظ في المنشور'),
          ],
        ),
      );
    }

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(
        'لا وسائط مرفقة حاليًا',
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final auth = context.watch<AuthService>();
    final canSave = !_saving &&
        (_contentController.text.trim().isNotEmpty || _hasMedia);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل المنشور'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextButton(
              onPressed: canSave ? _save : null,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text(
                      'حفظ',
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
                            'تعديل المنشور · يظهر لصاحب الحساب',
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
                    const SizedBox(height: 12),
                    _mediaPreview(),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      alignment: WrapAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: _saving ? null : _pickImage,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('صورة'),
                        ),
                        TextButton.icon(
                          onPressed: _saving ? null : _pickVideo,
                          icon: const Icon(Icons.videocam_outlined),
                          label: const Text('فيديو'),
                        ),
                        if (_hasMedia)
                          TextButton.icon(
                            onPressed: _saving ? null : _removeMedia,
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.error,
                            ),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('إزالة الوسائط'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}