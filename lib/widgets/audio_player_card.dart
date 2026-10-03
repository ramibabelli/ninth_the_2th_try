import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/music_track.dart';
import '../services/music_cache_service.dart';
import 'music_download_button.dart';

class AudioPlayerCard extends StatefulWidget {
  final MusicTrack track;

  const AudioPlayerCard({super.key, required this.track});

  @override
  State<AudioPlayerCard> createState() => _AudioPlayerCardState();
}

class _AudioPlayerCardState extends State<AudioPlayerCard> {
  final AudioPlayer _player = AudioPlayer();
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  PlayerState? _state;
  bool _failed = false;
  double _speed = 1.0;
  bool _isLocal = false;
  MusicCacheService? _cache;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<PlayerState>? _stateSub;

  bool get _isPlaying => _state == PlayerState.playing;

  @override
  void initState() {
    super.initState();
    _player.setReleaseMode(ReleaseMode.stop);
    _stateSub = _player.onPlayerStateChanged.listen((value) {
      setState(() => _state = value);
    });
    _durationSub = _player.onDurationChanged.listen((value) {
      setState(() => _duration = value);
    });
    _positionSub = _player.onPositionChanged.listen((value) {
      setState(() => _position = value);
    });
    _cache = context.read<MusicCacheService>();
    _cache?.addListener(_onCacheChanged);
    _resolveLocal();
  }

  void _onCacheChanged() {
    _resolveLocal();
  }

  Future<void> _resolveLocal() async {
    final path = await _cache?.localPathFor(widget.track);
    if (mounted) setState(() => _isLocal = path != null);
  }

  @override
  void dispose() {
    _cache?.removeListener(_onCacheChanged);
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _setSpeed(double value) async {
    setState(() => _speed = value);
    await _player.setPlaybackRate(value);
  }

  Source _sourceFor(String? localPath) {
    if (localPath != null) return DeviceFileSource(localPath);
    return UrlSource(widget.track.audioUrl!);
  }

  Future<void> _togglePlay() async {
    setState(() => _failed = false);
    try {
      if (_isPlaying) {
        await _player.pause();
      } else if (_state == PlayerState.completed ||
          _state == PlayerState.stopped ||
          _position >= _duration) {
        await _player.stop();
        final localPath = await _cache?.localPathFor(widget.track);
        if (mounted && _isLocal != (localPath != null)) {
          setState(() => _isLocal = localPath != null);
        }
        await _player.play(_sourceFor(localPath));
        await _player.setPlaybackRate(_speed);
      } else {
        await _player.resume();
      }
    } catch (_) {
      if (_state == null || _state == PlayerState.stopped) {
        try {
          await _player.play(UrlSource(widget.track.audioUrl!));
          await _player.setPlaybackRate(_speed);
        } catch (_) {
          if (mounted) setState(() => _failed = true);
        }
      }
    }
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _format(Duration duration) {
    final minutes = _twoDigits(duration.inMinutes.remainder(60));
    final seconds = _twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = _duration.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);

    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.headphones, color: colorScheme.onPrimaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                Icon(
                  _isLocal ? Icons.check_circle_rounded : Icons.cloud_rounded,
                  size: 18,
                  color: _isLocal
                      ? colorScheme.primary
                      : colorScheme.onPrimaryContainer.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  _isLocal ? 'من الجهاز' : 'من الإنترنت',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 4),
                MusicDownloadButton(track: widget.track, compact: true),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton.filled(
                  onPressed: _failed ? null : _togglePlay,
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.onPrimaryContainer,
                    foregroundColor: colorScheme.primaryContainer,
                  ),
                  icon: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 7,
                      ),
                    ),
                    child: Slider(
                      value: progress,
                      onChanged: _failed
                          ? null
                          : (value) async {
                              final newPosition = Duration(
                                milliseconds: (value *
                                        _duration.inMilliseconds)
                                    .round(),
                              );
                              setState(() => _position = newPosition);
                              await _player.seek(newPosition);
                            },
                    ),
                  ),
                ),
                SizedBox(
                  width: 92,
                  child: Text(
                    '${_format(_position)} / ${_format(_duration)}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.speed_rounded,
                  size: 18,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                const Text('0.5x', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: _speed,
                    min: 0.5,
                    max: 2.0,
                    divisions: 3,
                    label: '${_speed.toStringAsFixed(1)}x',
                    onChanged: _failed ? null : _setSpeed,
                  ),
                ),
                const Text('2.0x', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                Text(
                  '${_speed.toStringAsFixed(1)}x',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            if (_failed) ...[
              const SizedBox(height: 8),
              Text(
                'لا يمكن تشغيل التسجيل الصوتي الآن',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}