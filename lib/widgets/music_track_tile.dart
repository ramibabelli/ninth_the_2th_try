import 'package:flutter/material.dart';

import '../models/music_track.dart';
import 'music_download_button.dart';

class MusicTrackTile extends StatelessWidget {
  final MusicTrack track;
  final VoidCallback onTap;
  final bool canEditMusic;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MusicTrackTile({
    super.key,
    required this.track,
    required this.onTap,
    required this.canEditMusic,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.tertiaryContainer,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.music_note_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (track.description != null &&
                        track.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        track.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (track.hasAudio) ...[
                MusicDownloadButton(track: track, compact: true),
                Icon(
                  Icons.play_circle_fill,
                  color: colorScheme.primary,
                  size: 30,
                ),
              ] else
                Icon(Icons.chevron_left, color: colorScheme.onSurfaceVariant),
              if (canEditMusic) ...[
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  tooltip: 'تعديل',
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded),
                  tooltip: 'حذف',
                  onPressed: onDelete,
                  style: IconButton.styleFrom(
                    foregroundColor: colorScheme.error,
                  ),
                ),
              ] else ...[
                const Spacer(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
