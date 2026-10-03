class Profile {
  final String id;
  final String? fullName;
  final String? avatarUrl;
  final DateTime? createdAt;
  final String? role;

  const Profile({
    required this.id,
    this.fullName,
    this.avatarUrl,
    this.createdAt,
    this.role,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'] as String),
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (fullName != null) 'full_name': fullName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (role != null) 'role': role,
    };
  }

  String get displayName {
    final value = fullName?.trim() ?? '';
    return value.isEmpty ? 'كشاف' : value;
  }

  String get initials {
    final parts = displayName.split(' ');
    final filtered =
        parts.where((p) => p.trim().isNotEmpty).map((p) => p.trim()).toList();
    if (filtered.isEmpty) return '؟';
    if (filtered.length == 1) return filtered.first[0];
    return filtered.first[0] + filtered.last[0];
  }
}