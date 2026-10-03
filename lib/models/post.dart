import 'profile.dart';

class Post {
  final String id;
  final String authorId;
  final String content;
  final String? imageUrl;
  final String? videoUrl;
  final DateTime createdAt;
  final Profile? author;

  const Post({
    required this.id,
    required this.authorId,
    required this.content,
    this.imageUrl,
    this.videoUrl,
    required this.createdAt,
    this.author,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'];
    return Post(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      content: (json['content'] as String?) ?? '',
      imageUrl: json['image_url'] as String?,
      videoUrl: json['video_url'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      author: profiles is Map<String, dynamic>
          ? Profile.fromJson(profiles)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'author_id': authorId,
      'content': content,
      if (imageUrl != null) 'image_url': imageUrl,
      if (videoUrl != null) 'video_url': videoUrl,
    };
  }
}