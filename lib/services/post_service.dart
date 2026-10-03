import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/post.dart';
import 'auth_service.dart';

class PostService extends ChangeNotifier {
  final SupabaseClient _client;
  final AuthService _authService;

  List<Post> _posts = const [];
  bool _isLoading = false;
  String? _error;

  PostService(this._client, this._authService);

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPosts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _client
          .from('posts')
          .select('*, profiles:author_id(*)')
          .order('created_at', ascending: false);
      _posts = data
          .map((row) => Post.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } catch (error) {
      _error = error.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => fetchPosts();

  Future<void> createPost({
    required String content,
    String? imageUrl,
    String? videoUrl,
  }) async {
    final userId = _authService.userId;
    if (userId == null) {
      throw StateError('لا يمكن إنشاء منشور دون تسجيل الدخول');
    }
    await _client.from('posts').insert({
      'author_id': userId,
      'content': content.trim(),
      if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
      if (videoUrl != null && videoUrl.isNotEmpty) 'video_url': videoUrl,
    });
    await fetchPosts();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updatePost({
    required String id,
    required String content,
    String? imageUrl,
    String? videoUrl,
  }) async {
    await _client.from('posts').update({
      'content': content.trim(),
      'image_url': imageUrl,
      'video_url': videoUrl,
    }).eq('id', id);
    await fetchPosts();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deletePost(String id) async {
    await _client.from('posts').delete().eq('id', id);
    await fetchPosts();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}