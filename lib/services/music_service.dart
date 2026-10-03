import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/music_track.dart';

class MusicService extends ChangeNotifier {
  final SupabaseClient _client;

  List<MusicTrack> _tracks = const [];
  bool _isLoading = false;
  String? _error;

  MusicService(this._client);

  List<MusicTrack> get tracks => _tracks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchTracks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _client
          .from('music_tracks')
          .select()
          .order('created_at', ascending: false);
      _tracks = data
          .map((row) =>
              MusicTrack.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } catch (error) {
      _error = error.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => fetchTracks();

  Future<void> createTrack({
    required String title,
    String? description,
    String? notes,
    String? audioUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _client.from('music_tracks').insert({
        'title': title,
        if (description != null && description.trim().isNotEmpty)
          'description': description,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes,
        if (audioUrl != null && audioUrl.trim().isNotEmpty)
          'audio_url': audioUrl,
      }).select().single();
      final track = MusicTrack.fromJson(Map<String, dynamic>.from(data as Map));
      _tracks = [track, ..._tracks];
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTrack(MusicTrack track) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _client.from('music_tracks').update({
        'title': track.title,
        if (track.description != null) 'description': track.description,
        if (track.notes != null) 'notes': track.notes,
        'audio_url': track.audioUrl,
      }).eq('id', track.id);
      await fetchTracks();
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTrack(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _client.from('music_tracks').delete().eq('id', id);
      _tracks = _tracks.where((t) => t.id != id).toList();
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}