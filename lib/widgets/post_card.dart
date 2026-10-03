import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/post.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../utils/errors.dart';
import '../utils/formatters.dart';
import '../utils/media_saver.dart';
import '../screens/home/edit_post_screen.dart';
import '../screens/home/media_viewer_screen.dart';
import 'post_video_viewer.dart';
import 'user_avatar.dart';

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  bool _isOwner(BuildContext context) {
    final currentUserId = context.read<AuthService>().userId;
    return currentUserId != null && currentUserId == post.authorId;
  }

  void _openMedia(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MediaViewerScreen(
          imageUrl: post.imageUrl,
          videoUrl: post.videoUrl,
        ),
      ),
    );
  }

  Future<void> _downloadMedia(BuildContext context) async {
    final isVideo = post.videoUrl != null && post.videoUrl!.isNotEmpty;
    final url = isVideo ? post.videoUrl! : post.imageUrl;
    if (url == null) return;
    final message = await saveMediaToDevice(url: url, isVideo: isVideo);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editPost(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditPostScreen(post: post)),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف المنشور'),
        content: const Text('هل أنت متأكد من حذف هذا المنشور؟ لا يمكن التراجع.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<PostService>().deletePost(post.id);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('تم حذف المنشور')));
    } catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(translateSupabaseError(error))));
    }
  }

  Widget _mediaSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasImage = post.imageUrl != null && post.imageUrl!.isNotEmpty;
    final hasVideo = post.videoUrl != null && post.videoUrl!.isNotEmpty;

    if (!hasImage && !hasVideo) return const SizedBox.shrink();

    final Widget media = hasVideo
        ? PostVideoViewer(url: post.videoUrl!)
        : GestureDetector(
            onTap: () => _openMedia(context),
            child: Image.network(
              post.imageUrl!,
              height: 260,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: 260,
                  color: colorScheme.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                );
              },
              errorBuilder: (_, _, _) => Container(
                height: 260,
                color: colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: colorScheme.outline,
                  size: 40,
                ),
              ),
            ),
          );

    return Stack(
      children: [
        media,
        Align(
          alignment: AlignmentDirectional.bottomEnd,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: IconButton.filledTonal(
              onPressed: () => _downloadMedia(context),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black45,
                foregroundColor: Colors.white,
                minimumSize: const Size(38, 38),
              ),
              tooltip: 'تحميل',
              icon: const Icon(Icons.download_rounded, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasContent = post.content.trim().isNotEmpty;
    final isOwner = _isOwner(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
            child: Row(
              children: [
                UserAvatar(profile: post.author, radius: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author?.displayName ?? 'كشاف',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        timeAgo(post.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOwner)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editPost(context);
                        case 'delete':
                          _confirmDelete(context);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined),
                            SizedBox(width: 8),
                            Text('تعديل'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text('حذف'),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (hasContent)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Text(
                post.content,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
              ),
            ),
          _mediaSection(context),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}