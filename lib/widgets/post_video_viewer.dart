import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PostVideoViewer extends StatefulWidget {
  final String url;
  final bool autoPlay;

  const PostVideoViewer({
    super.key,
    required this.url,
    this.autoPlay = false,
  });

  @override
  State<PostVideoViewer> createState() => _PostVideoViewerState();
}

class _PostVideoViewerState extends State<PostVideoViewer> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _failed = false;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      controller.addListener(_onPlayback);
      setState(() => _initialized = true);
      if (widget.autoPlay) {
        await controller.play();
        _onPlayback();
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _onPlayback() {
    if (!mounted || _controller == null) return;
    if (_controller!.value.isPlaying != _playing) {
      setState(() => _playing = _controller!.value.isPlaying);
    }
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String _format(Duration d) {
    String padTwo(int n) => n.toString().padLeft(2, '0');
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return '${padTwo(minutes)}:${padTwo(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_failed) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam_off_outlined,
                  color: colorScheme.outline, size: 40),
              const SizedBox(height: 8),
              Text('تعذّر تشغيل الفيديو',
                  style: TextStyle(color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    if (!_initialized || _controller == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final controller = _controller!;
    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: GestureDetector(
        onTap: _togglePlay,
        child: Stack(
          fit: StackFit.expand,
          children: [
            VideoPlayer(controller),
            if (!_playing)
              const Center(
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.black45,
                  child: Icon(Icons.play_arrow_rounded,
                      size: 40, color: Colors.white),
                ),
              ),
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_format(controller.value.position)} / '
                  '${_format(controller.value.duration)}',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}