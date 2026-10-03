import 'package:flutter/material.dart';

import '../../utils/media_saver.dart';
import '../../widgets/post_video_viewer.dart';

class MediaViewerScreen extends StatelessWidget {
  final String? imageUrl;
  final String? videoUrl;

  const MediaViewerScreen({
    super.key,
    this.imageUrl,
    this.videoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = videoUrl != null && videoUrl!.isNotEmpty;
    final url = isVideo ? videoUrl! : imageUrl;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(''),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'تحميل',
            onPressed: () async {
              if (url == null) return;
              final messenger = ScaffoldMessenger.of(context);
              final message = await saveMediaToDevice(
                url: url,
                isVideo: isVideo,
              );
              messenger.showSnackBar(SnackBar(content: Text(message)));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: url == null
          ? const Center(
              child: Text('الوسائط غير متوفرة', style: TextStyle(color: Colors.white)),
            )
          : Center(
              child: isVideo
                  ? PostVideoViewer(url: url, autoPlay: true)
                  : InteractiveViewer(
                      minScale: 1,
                      maxScale: 5,
                      panEnabled: true,
                      child: Image.network(url),
                    ),
            ),
    );
  }
}