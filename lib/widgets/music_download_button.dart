import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/music_track.dart';
import '../services/music_cache_service.dart';

class MusicDownloadButton extends StatelessWidget {
  final MusicTrack track;
  final bool compact;

  const MusicDownloadButton({
    super.key,
    required this.track,
    this.compact = false,
  });

  Future<void> _handleTap(BuildContext context, MusicCacheService cache) async {
    if (cache.isCachedSync(track)) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('جاري تنزيل المعزوفة...')),
    );
    try {
      await cache.download(track);
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('تم تنزيل المعزوفة وحفظها محلياً')),
      );
    } catch (_) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: const Text('فشل التنزيل، تحقق من الاتصال'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cache = context.watch<MusicCacheService>();
    final downloading = cache.isDownloading(track);
    final cached = cache.isCachedSync(track);
    final theme = Theme.of(context);

    if (downloading) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            value: cache.progressFor(track),
            strokeWidth: 2,
          ),
        ),
      );
    }

    final label = cached ? 'محفوظة محلياً' : 'تنزيل للتشغيل دون إنترنت';
    return IconButton(
      icon: Icon(
        cached ? Icons.download_done_rounded : Icons.download_rounded,
        color: cached
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
        size: compact ? 20 : 24,
      ),
      tooltip: label,
      onPressed:
          cached ? null : () => _handleTap(context, cache),
    );
  }
}