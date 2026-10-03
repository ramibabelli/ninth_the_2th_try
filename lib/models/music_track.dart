class MusicTrack {
  final String id;
  final String title;
  final String? description;
  final String? notes;
  final String? audioUrl;
  final DateTime? createdAt;

  const MusicTrack({
    required this.id,
    required this.title,
    this.description,
    this.notes,
    this.audioUrl,
    this.createdAt,
  });

  factory MusicTrack.fromJson(Map<String, dynamic> json) {
    return MusicTrack(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      description: json['description'] as String?,
      notes: json['notes'] as String?,
      audioUrl: json['audio_url'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (description != null) 'description': description,
      if (notes != null) 'notes': notes,
      if (audioUrl != null) 'audio_url': audioUrl,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  List<String> get parsedNotes {
    final value = notes;
    if (value == null || value.trim().isEmpty) return const [];
    return value
        .split(RegExp(r'[\s,\-–،•\n]+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }

  bool get hasAudio => audioUrl != null && audioUrl!.trim().isNotEmpty;
  bool get hasNotes => parsedNotes.isNotEmpty;
}