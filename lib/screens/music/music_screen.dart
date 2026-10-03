import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/music_service.dart';
import '../../models/music_track.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_retry.dart';
import '../../widgets/music_track_tile.dart';
import '../../widgets/responsive_page.dart';
import 'music_detail_screen.dart';
import 'add_music_track_screen.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MusicService>().fetchTracks();
      }
    });
  }

  Future<void> _confirmAndDelete(MusicTrack track) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المعزوفة'),
        content: Text('هل أنت متأكد من حذف "${track.title}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<MusicService>().deleteTrack(track.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف المعزوفة')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ، حاول مرة أخرى'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final canEditMusic = auth.canEditMusic;
    return Scaffold(
      appBar: AppBar(title: const Text('الأناشيد')),
      body: ResponsivePage(
        child: Consumer<MusicService>(
          builder: (context, service, _) {
            if (service.isLoading && service.tracks.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (service.error != null && service.tracks.isEmpty) {
              return ErrorRetry(
                message: service.error!,
                onRetry: service.fetchTracks,
              );
            }
            if (service.tracks.isEmpty) {
              return RefreshIndicator(
                onRefresh: service.fetchTracks,
                child: const EmptyState(
                  icon: Icons.music_off_outlined,
                  title: 'لا توجد أناشيد بعد',
                  subtitle: 'تنتظر الأناشيد الكشفية أن تُضاف هنا.',
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: service.fetchTracks,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: service.tracks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final track = service.tracks[index];
                  return MusicTrackTile(
                    track: track,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MusicDetailScreen(track: track),
                        ),
                      );
                    },
                    canEditMusic: canEditMusic,
                    onEdit: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              AddMusicTrackScreen(initialTrack: track),
                        ),
                      );
                    },
                    onDelete: () => _confirmAndDelete(track),
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: canEditMusic
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddMusicTrackScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('معزوفة جديدة'),
            )
          : null,
    );
  }
}