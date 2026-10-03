import 'package:flutter/material.dart';

import '../models/profile.dart';

class UserAvatar extends StatelessWidget {
  final Profile? profile;
  final String? fullName;
  final String? imageUrl;
  final double radius;

  const UserAvatar({
    super.key,
    this.profile,
    this.fullName,
    this.imageUrl,
    this.radius = 22,
  });

  Color _colorFor(String seed) {
    final palette = <Color>[
      const Color(0xFF00696D),
      const Color(0xFF3F51B5),
      const Color(0xFF8E3FA0),
      const Color(0xFFB23C3C),
      const Color(0xFF00796B),
      const Color(0xFF5C6BC0),
      const Color(0xFFC2185B),
      const Color(0xFFF57C00),
    ];
    var hash = 0;
    for (final codeUnit in seed.codeUnits) {
      hash = (hash + codeUnit) * 31;
    }
    return palette[hash.abs() % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedUrl = imageUrl ?? profile?.avatarUrl;
    final name = fullName ?? profile?.displayName ?? 'كشاف';
    final initials = profile?.initials ?? _initials(name);

    Widget child;
    if (resolvedUrl != null && resolvedUrl.trim().isNotEmpty) {
      child = ClipOval(
        child: Image.network(
          resolvedUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _initialsCircle(initials, name, colorScheme),
        ),
      );
    } else {
      child = _initialsCircle(initials, name, colorScheme);
    }

    return Tooltip(
      message: name,
      child: child,
    );
  }

  Widget _initialsCircle(String initials, String name, ColorScheme colorScheme) {
    final bg = _colorFor(name).withValues(alpha: 0.28);
    final fg = Color.alphaBlend(_colorFor(name), colorScheme.surface);
    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(
        initials,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.75,
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(' ')
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '؟';
    if (parts.length == 1) return parts.first[0];
    return parts.first[0] + parts.last[0];
  }
}